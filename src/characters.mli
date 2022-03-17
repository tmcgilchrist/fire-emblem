open Types

(** 
 *  [character] handles all the functions that involve reading and editing
 *  character values 
*)

val equipped : character -> item option
(**
 *  [equipped] returns the character's equipped item
*)

val equippable : character -> item -> bool
(**
 *  [equippable] returns whether or not a character can equip an item
*)

val stat_up : character -> stat -> int -> unit
(** 
 *  [stat_up] increases a stat by a certain amount
*)

val level_up : character -> unit
(**
 *  level_up returns the character with its level increased and stats
 *  incremented.
*)

val update_health : character -> int -> unit
(** 
 *  [update_health ch] will return the character [ch] with its health incremented
*)

val update_character : character -> unit
(**
 *  [update character] updates all the character  
*)

val add_item : character -> item -> unit
(**
 *  [add_item] adds an item to a characters inventory. If there is no space
 *  then it does nothing
*)

val remove_item : character -> int -> unit
(**
 *  [remove_item] removes an item from a characters inventory 
*)

val move_to_top : character -> int -> unit
(**
 *  [move_to_top] moves an item to the top of the inventory 
*)

val use : item option -> item option
(**
 *  [use i] decrements the number of uses on an item by 1 
*)
