(lang dune 2.9)

(name fire-emblem)
(generate_opam_files true)
(authors "Frank Rodriguez" "Albert Tsao" "Darren Tsai" "Ray Gu")
(maintainers "Tim McGilchrist <timmcgil@gmail.com>") 
(source (github tmcgilchrist/fire-emblem))

(package
 (name fire-emblem)
 (synopsis "Fire-Emblem is a recreation of the game boy game of the same name")
 (depends 
  (ocaml (>= 4.13.1))
   js_of_ocaml
   js_of_ocaml-ppx))