open Types

(* Why is this here?? -Frank *)
(**The current map*)
(* type map *)

(**The current state of the game*)

(* type state = {
  player: character list;
  items : item list;
  enemies: character list;
  won : bool;
  active_tile: tile;
  active_unit: character option;
  menus: (string * menu) list;
  current_menu : menu;
  menu_active: bool;
  menu_cursor: int;
  funds : int;
   } *)

type state = {
  player: character list;
  items : item list;
  enemies: character list;
  allies: character list;
  won : bool;
  active_tile: tile;
  active_unit: character option;
  act_map: map;
  menus:(string * menu) list;
  current_menu : menu;
  menu_active: bool;
  menu_cursor: int;
  funds : int;
}

val dijkstra's_helper : (tile * int) list -> (int*int) list -> tile -> int -> map -> (int*int) list
val dijkstra's: character -> map -> (int*int) list
val get_rng : unit -> int


(**[do' act st] returns the state after an input action [act]*)
val do' : state -> state
