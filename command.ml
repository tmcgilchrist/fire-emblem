open Types
open Gui
open Js_of_ocaml

module Html = Dom_html
let js = Js.string




let keydown event =
  Dom.preventDefault event;
  let () =match event##keyCode with
      |90 ->input := A (* Mapped to Z used to select units *)
      |88 ->input := B (* Mapped to X used to deselect *)
      |65 ->input := LT
      |38 ->input := Up
      |40 ->input := Down
      |37 ->input := Left
      |39 ->input := Right
      |_  ->input := Nothing
  in Js._true
