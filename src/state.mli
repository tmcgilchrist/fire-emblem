open Types
open Interactions

val unit_menu : menu

val confirm_menu : menu

type state = {
  player : character list;
  enemies : character list;
  won : bool;
  lose : bool;
  mutable round : bool;
  mutable welcome : bool;
  active_tile : tile;
  active_unit : character option;
  active_item : int;
  act_map : map;
  current_menu : menu;
  menu_active : bool;
  menu_cursor : int;
  last_character : character option;
}
(**
 *  The type of the state of the game
*)

val attack_range : character -> (int * int) list
(**
 *  Finds the attack range of a character
*)

val add_init_characters : character list -> map -> map
(**[add_init_characters plst map] adds the characters in [plst] to [map].
  *requires:
  * -[plst] is a list of characters
  * -[map] is the current map
*)

val set_act_tile : state -> state
(**[sea_act_tile st] sets the active_tile field of [st] to be
  *on one of the players in the player list in [st]. Also, sets
  *the last_character field to be that player.
  *requires:
  * -[st] is the current state
*)

val set_init_ch_movement : character list -> state -> state
(**[set_init_ch_movement plst st] sets the movement field appropriately for
  *each character in [plst].
  *requires:
  * -[plst] is a list of characters
  * -[st] is the current state
*)

val do' : state -> state
(**[do' act st] returns the state after an input action [act]*)
