open Types
open State
open Characters
open Items

type ability

type combatResolutions = Kill | Hit | Miss

let combatQ = Queue.create()

let expQ = Queue.create()


let survive (d:character) i =
  i > fst d.health

let rec penalty_helper (p: (stat * (int * int)) list) (s:stat) =
  match p with
  |[]   -> (0,0)
  |h::t -> if fst h = s then snd h else
      penalty_helper t s

let find_penalty a s =
  match a.eqp with
  |None -> (0, 0)
  |Some x -> penalty_helper x.penalty s

let damage a d =
  match a.eqp with
  | None -> 0
  | Some x ->
    match x.wtype with
    |Tome -> a.atk - d.res
    |_ -> a.atk - d.def

let item_eqp a =
  match a.eqp with
  |None -> false
  |Some x -> true

let eqp_use a =
  match a.eqp with
  |None -> 0
  |Some x -> x.uses

let distance a b =
  abs (fst a.location.coordinate - fst b.location.coordinate) +
  abs (snd a.location.coordinate - snd b.location.coordinate)

let in_range a d =
  match a.eqp with
  |None   -> false
  |Some x -> let l = distance a d in l >= fst x.range && l <= snd x.range

let kill_xp a d =
  if d.ai = BossStay || d.ai = BossHunt then
    match a.level - d.level with
    | 2 -> {a with exp = a.exp + 90}
    | 3 -> {a with exp = a.exp + 80}
    | 4 -> {a with exp = a.exp + 70}
    | x -> if x > 4 then {a with exp = a.exp + 60}
      else {a with exp = a.exp + 100}
  else
    match a.level - d.level with
    | -4 -> {a with exp = a.exp + 60}
    | -3 -> {a with exp = a.exp + 51}
    | -2 -> {a with exp = a.exp + 43}
    | -1 -> {a with exp = a.exp + 36}
    |  0 -> {a with exp = a.exp + 30}
    |  1 -> {a with exp = a.exp + 25}
    |  2 -> {a with exp = a.exp + 19}
    |  3 -> {a with exp = a.exp + 12}
    |  4 -> {a with exp = a.exp + 4}
    |  x -> if x > 4 then {a with exp = a.exp + 1}
      else {a with exp = a.exp + 70}

let hit_xp a d =
  if d.ai = BossStay || d.ai = BossHunt then
    match a.level - d.level with
    | 2 -> {a with exp = a.exp + 30}
    | 3 -> {a with exp = a.exp + 27}
    | 4 -> {a with exp = a.exp + 24}
    | x -> if x > 4 then {a with exp = a.exp + 20}
      else {a with exp = a.exp + 33}
  else
    match a.level - d.level with
    | -4 -> {a with exp = a.exp + 20}
    | -3 -> {a with exp = a.exp + 17}
    | -2 -> {a with exp = a.exp + 14}
    | -1 -> {a with exp = a.exp + 12}
    |  0 -> {a with exp = a.exp + 10}
    |  1 -> {a with exp = a.exp + 8}
    |  2 -> {a with exp = a.exp + 6}
    |  3 -> {a with exp = a.exp + 4}
    |  4 -> {a with exp = a.exp + 1}
    |  x -> if x > 4 then {a with exp = a.exp + 1}
      else {a with exp = a.exp + 23}

let comp_outcome a t =
  match a, t with
  |Kill, _ -> a
  |_, Kill -> t
  |Hit, _ -> a
  |_, Hit -> t
  |_, _ -> a

let find_player_character t =
  if (fst t).allegiance = Player then fst t else snd t

let award_xp t =
  let outcome = Queue.fold comp_outcome Miss expQ in
  Queue.clear expQ;
  match outcome, t with
  |Kill, (a, d) -> if (fst t).allegiance = Player then
      (kill_xp (fst t) (snd t), snd t) else (fst t, kill_xp (snd t) (fst t))
  |Hit, (a, d) -> if (fst t).allegiance = Player then
      (hit_xp (fst t) (snd t), snd t) else (fst t, hit_xp (snd t) (fst t))
  |Miss, _ -> t

let award_levels t =
  (level_up (fst t), level_up (snd t))

let resolveE a d =
  if not (item_eqp a) then (a, d)
  else if (get_rng () + get_rng())/2 > a.hit - d.avoid then begin
    Queue.add Miss expQ;
    ({a with eqp = use a.eqp}, d)
  end
  else
    let new_d =
      if get_rng () > a.crit - d.lck then update_health d (3 * (damage a d))
      else update_health d (damage a d) in
    if fst new_d.health = 0 then
      Queue.clear combatQ;
    if fst new_d.health = 0 && a.allegiance = Player then
      Queue.add Kill expQ;
    if a.allegiance = Player then
      Queue.add Hit expQ;
    ({a with eqp = use a.eqp}, new_d)

let rec resolveQ acc =
  if Queue.is_empty combatQ then acc else
    let round = Queue.pop combatQ in
    resolveQ (resolveE (fst round) (snd round))

let combat a d =
  let new_a_speed = a.spd + fst (find_penalty a Spd) in
  let new_d_speed = d.spd + snd (find_penalty d Spd) in
  let double = new_a_speed > new_d_speed + 5 in
  let redouble = new_d_speed > new_a_speed + 5 in
  Queue.add (a, d) combatQ;
  let counter = in_range a d in
  if counter then Queue.add (d, a) combatQ;
  if double then Queue.add (a, d) combatQ
  else if counter && redouble then Queue.add (d, a) combatQ;
  (a, d) |> resolveQ |> award_xp |> award_levels

let heal a t = failwith "Unimplemented"
