(lang dune 2.9)

(name fire-emblem)
(generate_opam_files true)

(package
 (name fire-emblem)
 (synopsis "Fire-Emblem is a recreation of the game boy game of the same name.")
 (depends 
   js_of_ocaml
   js_of_ocaml-ppx))