#let notebook_ref(it, text_color: rgb("#037aa9"), underline_stroke: none) = context {
  let a = state("bib").final()
  if it.element == none and (a == none or not a.keys().contains(str(it.target))) {
    text(fill: orange.darken(10%), weight: "bold", "[? " + str(it.target) + "]")
  } else {
    set text(text_color)
    if stroke != none {
      underline(it, stroke: underline_stroke)
    } else {
      underline(it)
    }
  }
}
