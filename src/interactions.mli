open Types

val damage : character -> character -> int
(**Calculates how much damamge one character does to another*)

val combat : character -> character -> unit
(** handles all combat procedures*)

val heal : character -> character -> int -> unit
(** heals a character *)

val consumable : character -> int -> unit
(** consumable takes a character and returns that character with its stats
 *  accordingly.
*)

val chest : character -> terrain -> int -> unit
(** loot a chest.*)

val door : character -> terrain -> int -> unit
(** open a door.*)

val village : character -> terrain -> unit
(** visits a village*)

val trade : character -> character -> int -> int -> unit
(** trades two items between two characters*)
