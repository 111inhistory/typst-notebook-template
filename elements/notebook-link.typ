#let notebook-link(it, text_color: rgb("#037aa9"), underline_color: rgb("#037aa9")) = {
  box()[
    #set text(text_color)
    #underline(it, stroke: (thickness: 0.5pt, paint: underline_color))
  ]
}
