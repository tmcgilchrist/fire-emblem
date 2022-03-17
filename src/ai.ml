open Types
open Interactions

(*[path_tile] store the intermediary values of our Djikstra's shortest
  *path algorithm*)
type path_tile = { length : int; prev : (int * int) option }

(*[path_map] is a data type to mirror our ingame map but store the paths to
  *traverse to an allied unit from an enemy*)
type path_map = { width : int; length : int; grid : path_tile array array }

(*[check_exist] ensures if a specific item exists in a list*)
let rec check_exist co lst =
  match lst with
  | [] -> false
  | h :: t -> if fst h = co then true else check_exist co t

(*[a_range_add] adds on to my attack range area*)
let a_range_add ma i co fl ml sl =
  let addon =
    if i > ma then []
    else
      let nleft = (fst co - 1, snd co) in
      let cleft =
        if
          fst co - 1 < 0
          || List.mem nleft ml || List.mem nleft sl || check_exist nleft fl
        then []
        else [ (nleft, i) ]
      in
      let nright = (fst co + 1, snd co) in
      let cright =
        if
          fst co + 1 > 14
          || List.mem nright ml || List.mem nright sl || check_exist nright fl
        then cleft
        else (nright, i) :: cleft
      in
      let nup = (fst co, snd co - 1) in
      let cup =
        if
          snd co - 1 < 0
          || List.mem nup ml || List.mem nup sl || check_exist nup fl
        then cright
        else (nup, i) :: cright
      in
      let ndown = (fst co, snd co + 1) in
      let cdown =
        if
          snd co + 1 > 14
          || List.mem ndown ml || List.mem ndown sl || check_exist ndown fl
        then cup
        else (ndown, i) :: cup
      in
      cdown
  in
  fl @ addon

(*[attack_range_helper] helps construct an attack range based on a weapon's range*)
let rec attack_range_helper mi ma i co fl ml sl =
  let nml = if i < mi then co :: ml else ml in
  let nsl = if i >= mi then co :: sl else sl in
  let nfl = a_range_add ma (i + 1) co fl ml sl in
  match nfl with
  | [] -> nsl
  | (h, x) :: t -> attack_range_helper mi ma x h t nml nsl

(*[attack_range] returns a list of coordinates within a character's attack range*)
let attack_range c =
  let w = extract c.inv.(c.eqp) in
  attack_range_helper (fst w.range) (snd w.range) 0 c.location [] [] []

(*[add_f2] is a list of frontier tiles sorted in increasing distance from a
  * a settled node, as this is a grid map we know every frontier node is
  * adjacent to a settled node therefore it's distance is its movement cost*)
let rec add_f2 (tile : tile) (i : int) (f : (tile * int) list) :
    (tile * int) list =
  match f with
  | [] -> [ (tile, i) ]
  | h :: t ->
      if fst h = tile then if i < snd h then (tile, i) :: t else h :: t
      else h :: add_f2 tile i t

(*[check_valid] is whether or not given a location you can move in a certain
 * direction *)
let check_valid d (m : map) loc =
  match d with
  | North -> snd loc - 1 > 0
  | East -> fst loc + 1 < m.width
  | South -> snd loc + 1 < m.length
  | West -> fst loc - 1 > 0

(*[check_adjacent] is whether or not given two tiles are adjacent on a map*)
let check_adjacent (t : tile) (f : tile) (m : map) =
  match (t.coordinate, f.coordinate) with
  | (x, y), (a, b) -> (abs (b - y) = 1 && a = x) || (abs (a - x) = 1 && b = y)

(*[check_settled] is whether or not a given tile is already in the settled set*)
let rec check_settled (s : tile list) (tl : tile) =
  match s with
  | [] -> false
  | h :: t -> if h = tl then true else check_settled t tl

(*[check_dir] ensures movement in a certain direction is valid and adds the
  *node to the frontier if it is viable or returns the same frontier if its not*)
let check_dir (d : direction) (t : tile) (map : map) (s : tile list)
    (f : (tile * int) list) : (tile * int) list =
  let mapg = map.grid in
  match t.coordinate with
  | x, y ->
      if check_valid d map t.coordinate then
        let next =
          match d with
          | North -> mapg.(x).(y - 1)
          | East -> mapg.(x + 1).(y)
          | South -> mapg.(x).(y + 1)
          | West -> mapg.(x - 1).(y)
        in
        match next.ground with
        | Wall -> f
        | Door -> f
        | Damaged_wall x -> f
        | Mountain -> f
        | Ocean -> f
        | Peaks -> if check_settled s next then f else add_f2 next 3 f
        | Forest -> if check_settled s next then f else add_f2 next 2 f
        | Desert -> if check_settled s next then f else add_f2 next 2 f
        | _ -> if check_settled s next then f else add_f2 next 1 f
      else f

(*[check_surround] checks movement in all directions of a given coordinate
  *to expand the frontier set*)
let check_surround s t map f : (tile * int) list =
  f |> check_dir South t map s |> check_dir East t map s
  |> check_dir North t map s |> check_dir West t map s

(*[fill_map] initializes the path_map necessary to compute Djikstra's*)
let fill_map len wid =
  let (t : path_tile) = { length = 1000; prev = None } in
  Array.make_matrix len wid t

(*[new_map] refreshes the map for a new target destination*)
let new_map (c : character) (pmap : path_map) =
  let (t : path_tile) = { length = 1000; prev = None } in
  let pmap2 =
    {
      length = pmap.length;
      width = pmap.width;
      grid = Array.make_matrix pmap.length pmap.width t;
    }
  in
  pmap2.grid.(fst c.location).(snd c.location) <- { length = 0; prev = None };
  pmap2

(*[update_map] takes a [path_map] and updates its values if a shorter path is
  * found by the algorithm*)
let update_map (pmap : path_map) x y (ptile : path_tile) : path_map =
  pmap.grid.(x).(y) <- ptile;
  pmap

(*[path_adjust] removes the movement cost of the tile the character is currently
 * on from the shortest path cost*)
let rec path_adjust (lst : (int * (int * int)) list) acc sub =
  match lst with
  | [] -> acc
  | h :: t -> ( match h with x, y -> path_adjust t ((x - sub, y) :: acc) sub)

(*[path_finder] searches a completed [path_map] to output a list of coordinates
  * from the ally unit to the original enemy unit's coordinates*)
let rec path_finder coor pmap acc =
  match coor with
  | x, y -> (
      match pmap.grid.(x).(y).prev with
      | None ->
          if List.length acc > 0 then
            List.rev (path_adjust acc [] (fst (List.hd acc)))
          else acc
      | Some t -> path_finder t pmap ((pmap.grid.(x).(y).length, t) :: acc))

(*[update_frontier] finds the updated costs of the frontier set adjacent to the
 * newest settled node [tl]*)
let rec update_frontier (f : (tile * int) list) (tl : tile) (m : map)
    (pmap : path_map) =
  match f with
  | [] -> pmap
  | h :: t -> (
      match (fst h).coordinate with
      | x, y ->
          let cost =
            match m.grid.(x).(y).ground with
            | Peaks -> 3
            | Forest -> 2
            | Desert -> 2
            | _ -> 1
          in
          let curr = pmap.grid.(fst tl.coordinate).(snd tl.coordinate).length in
          if
            check_adjacent tl (fst h) m
            && curr + cost < pmap.grid.(x).(y).length
          then
            let newt : path_tile =
              { length = curr + cost; prev = Some tl.coordinate }
            in
            let pmap2 = update_map pmap x y newt in
            update_frontier t tl m pmap2
          else update_frontier t tl m pmap)

(*[found_frontier] returns the lowest cost adjacent tile in the settled set to
  * traverse to a given tile in the frontier*)
let rec found_frontier (last : int * int) (s : tile list) (tile : tile)
    (map : map) (pmap : path_map) mini =
  match s with
  | [] ->
      if pmap.grid.(fst tile.coordinate).(snd tile.coordinate).length = 0 then
        pmap
      else
        update_map pmap (fst tile.coordinate) (snd tile.coordinate)
          { length = mini; prev = Some last }
  | h :: t ->
      if check_adjacent h tile map then
        let cost =
          match map.grid.(fst h.coordinate).(snd h.coordinate).ground with
          | Peaks -> 3
          | Forest -> 2
          | Desert -> 2
          | _ -> 1
        in
        let new_length =
          pmap.grid.(fst h.coordinate).(snd h.coordinate).length + cost
        in
        let pre = h.coordinate in
        if new_length < mini then found_frontier pre t tile map pmap new_length
        else found_frontier last t tile map pmap mini
      else found_frontier last t tile map pmap mini

(*[naive_frontier] returns an arbitrary adjacent tile in the settled set to
 * traverse to a given tile in the frontier*)
let rec naive_frontier c (s : tile list) (tile : tile) (map : map)
    (pmap : path_map) =
  match s with
  | [] ->
      if pmap.grid.(fst tile.coordinate).(snd tile.coordinate).length = 0 then
        (fst tile.coordinate, snd tile.coordinate)
      else c.location
  | h :: t ->
      if check_adjacent h tile map then
        let pre = h.coordinate in
        pre
      else naive_frontier c t tile map pmap

(*[print_frontier] debugging helper to print out frontier entries*)
let rec print_frontier lst =
  match lst with
  | [] -> ()
  | h :: t ->
      print_string
        ("Frontier Entry:"
        ^ string_of_int (fst (fst h).coordinate)
        ^ " "
        ^ string_of_int (snd (fst h).coordinate));
      print_frontier t

(*[path_helper] runs djikstra's algorithm on the given map to find the shortest
  * path from the enemy unit to the player unit it is targeting, and then calls
  *[path_finder] to output a complete path
  * f = frontier set, tile * int (move) list
  * s = settled set, tile list
  * t = current tile
  * m = moves left
  * map = map*)
let rec path_helper (c : character) (dest : int * int) (f : (tile * int) list)
    (s : tile list) tile (map : map) pmap =
  let new_f = check_surround s tile map f in
  match new_f with
  | [] -> path_finder dest pmap []
  | h :: t -> (
      match (fst h).coordinate with
      | x, y ->
          if (fst h).coordinate = dest then
            let pmap2 =
              found_frontier
                (naive_frontier c s tile map pmap)
                s tile map pmap 1000
            in
            path_finder dest pmap2 []
          else
            let pmap2 = update_frontier new_f tile map pmap in
            path_helper c dest t (fst h :: s) (fst h) map pmap2)

(*[search_helper] picks the closest player unit to attack and outputs the
  * coordinates of the unit*)
let rec search_helper (m : map) (c : character) (lst : character list) pmap
    target =
  match lst with
  | [] -> target
  | h :: t -> (
      match c.location with
      | x, y ->
          let check =
            path_helper c h.location []
              [ m.grid.(x).(y) ]
              m.grid.(x).(y)
              m (new_map c pmap)
          in
          if
            List.length check > 0
            && fst (List.hd (List.rev check)) < fst (List.hd (List.rev target))
            && fst h.health > 0
          then search_helper m c t (new_map c pmap) check
          else search_helper m c t (new_map c pmap) target)

(*[run] returns a free tile from a set that is not inhabited by another character*)
let rec run (lst : (int * int) list) (m : map) (loc : int * int) =
  match lst with
  | [] -> loc
  | h :: t -> (
      match h with
      | x, y ->
          if x >= 0 && x < m.width && y >= 0 && y < m.length then
            match m.grid.(x).(y).c with Some k -> run t m loc | None -> (x, y)
          else run t m loc)

(*[near_enemy] is a helper for [step_back] and it finds the enemy that is within
 * an enemies minimum attack range*)
let rec near_enemy (lst : (int * int) list) (m : map) (c : int * int) loc acc =
  match lst with
  | [] -> loc
  | h :: t -> (
      match h with
      | x, y ->
          if x >= 0 && x < m.width && y >= 0 && y < m.length then
            match m.grid.(x).(y).c with
            | Some k ->
                if not (k.allegiance = Enemy) then run (acc @ t) m loc
                else near_enemy t m c loc (h :: acc)
            | None -> near_enemy t m c loc (h :: acc)
          else near_enemy t m c loc acc)

(*[step_back] finds enemies that are adjacent to a character and returns a location
 * for the character to run to*)
let step_back (m : map) (c : int * int) loc =
  match c with
  | x, y ->
      near_enemy [ (x, y - 1); (x + 1, y); (x, y + 1); (x - 1, y) ] m c loc []

(*[move] iterates through the shortest path to a target enemy unit, and moves as
  * far on the path as permitted by its movement stats*)
let rec move (m : map) lst (c : character) range last (attk : int * int) loc =
  match lst with
  | [] -> last
  | h :: t -> (
      match h with
      | a, b ->
          if a <= range && List.length t > fst attk then
            match t with
            | [] ->
                if m.grid.(fst b).(snd b).c = None then
                  move m t c range b attk b
                else loc
            | s :: r -> (
                match s with
                | q, w ->
                    if q <= range then move m t c range b attk b
                    else if m.grid.(fst b).(snd b).c = None then
                      move m t c range b attk b
                    else loc)
          else if List.length t + 1 < fst attk then step_back m c.location loc
          else loc)

(*[update_move] updates both characters and maps upon a character moving to a different
  * position on the board*)
let update_move (m : map) (c : character) (init : int * int) (loc : int * int) =
  c.location <- loc;
  match (init, loc) with
  | (x, y), (h, t) ->
      let replace_tile = m.grid.(x).(y) in
      let new_tile = m.grid.(h).(t) in
      m.grid.(x).(y) <-
        {
          coordinate = replace_tile.coordinate;
          ground = replace_tile.ground;
          tile_type = replace_tile.tile_type;
          c = None;
        };
      m.grid.(h).(t) <-
        {
          coordinate = new_tile.coordinate;
          ground = new_tile.ground;
          tile_type = new_tile.tile_type;
          c = Some c;
        }

(*[attack_inrange] will directly attack a player character only if it is standing
 * on a space that is within its attack range*)
let rec attack_inrange m (c : character) (lst : character list) =
  match lst with
  | [] -> ()
  | h :: t -> (
      match (h.location, c.location) with
      | (x, y), (a, b) ->
          if c.eqp > -1 && fst h.health > 0 && fst c.health > 0 then
            let ar = attack_range c in
            if List.exists (fun (q, r) -> q = x && r = y) ar = true then
              combat c h
            else attack_inrange m c t
          else ())

(*[search] finds the nearest enemy, and the moves and attacks for the enemy unit
 * depending on the distance and tendencies of unit of that difficulty level
 * AI Difficulty Behavior Detailed Below:
 * Insane -> Omniscient unit that will track and move towards nearest player
 * controlled unit no matter where it is on the board
 * Hard -> Can sense player units within four times its movement zone, and will
 * move towards players that enter that zone and attack if possible
 * Normal -> Can sense player units within two times its movement zone and will
 * move towards players that enter that zone and attack if possible
 * Easy -> Will never move but will attack if player enters attack range*)
let search (m : map) (c : character) (lst : character list) pm
    (attk : int * int) =
  if fst c.health = 0 then ()
  else
    match c.behave with
    | Insane -> (
        match lst with
        | [] -> ()
        | h :: t ->
            let init =
              match c.location with
              | x, y ->
                  path_helper c h.location []
                    [ m.grid.(x).(y) ]
                    m.grid.(x).(y)
                    m (new_map c pm)
            in
            let shortestpath = search_helper m c t pm init in
            print_int (List.length shortestpath);
            if List.length shortestpath > 0 then (
              let dest = snd (List.hd shortestpath) in
              let go = move m shortestpath c c.mov c.location attk dest in
              update_move m c c.location go;
              attack_inrange m c lst))
    | Hard -> (
        match lst with
        | [] -> ()
        | h :: t ->
            let init =
              match c.location with
              | x, y ->
                  path_helper c h.location []
                    [ m.grid.(x).(y) ]
                    m.grid.(x).(y)
                    m (new_map c pm)
            in
            let close = search_helper m c t pm init in
            if
              List.length close > 0
              && fst (List.hd (List.rev close)) <= c.mov * 4
            then (
              let dest = snd (List.hd close) in
              let go = move m close c c.mov c.location attk dest in
              update_move m c c.location go;
              attack_inrange m c lst))
    | Normal -> (
        match lst with
        | [] -> ()
        | h :: t ->
            let init =
              match c.location with
              | x, y ->
                  path_helper c h.location []
                    [ m.grid.(x).(y) ]
                    m.grid.(x).(y)
                    m (new_map c pm)
            in
            let close = search_helper m c t pm init in
            if
              List.length close > 0
              && fst (List.hd (List.rev close)) <= c.mov * 2
            then (
              let dest = snd (List.hd close) in
              let go = move m close c c.mov c.location attk dest in
              update_move m c c.location go;
              attack_inrange m c lst))
    | Easy -> (
        if c.eqp > -1 then
          let ind = c.eqp in
          let item = c.inv.(ind) in
          match item with None -> () | Some i -> attack_inrange m c lst)

(*[ai_helper] iterates through enemy units and moves and attacks for them
 * through calls to the helper functions*)
let rec ai_helper (m : map) (clist : character list) plist =
  match clist with
  | [] -> ()
  | h :: t ->
      let new_pm =
        { width = m.width; length = m.length; grid = fill_map m.length m.width }
      in
      if h.eqp > -1 then (
        search m h plist new_pm (extract h.inv.(h.eqp)).range;
        ai_helper m t plist)
      else ai_helper m t plist

(*[step] returns unit after all enemy characters have performed
  * their desired actions*)
let step (e : character list) (p : character list) (m : map) = ai_helper m e p
