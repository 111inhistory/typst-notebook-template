#let notebook-link(
  it,
  text_color: rgb("#2b5f75"),
  underline_color: rgb("#6b95a8"),
  accent_background: rgb("#eef5f7"),
) = {
  box(
    inset: (x: 0.08em, y: 0em),
    outset: (y: 0.02em),
    radius: 0.18em,
    fill: accent_background,
  )[
    #set text(fill: text_color, weight: "medium")
    #underline(
      offset: 1.8pt,
      stroke: (thickness: 0.55pt, paint: underline_color),
      it,
    )
  ]
}
