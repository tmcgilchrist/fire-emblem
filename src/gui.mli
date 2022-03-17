open Types
open State
open Js_of_ocaml

(* drawing canvas width *)
val canvas_width : float

(* drawing canvas height *)
val canvas_height : float

val draw_state : Dom_html.canvasRenderingContext2D Js.t -> state -> unit
(** [draw_state st] will draw the GUI for [st]*)
