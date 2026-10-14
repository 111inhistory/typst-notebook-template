#let notebook-frame-style(title, tags, body, supplement, number, accent-color) = {
  let has-title = title not in (none, [], "")
  let has-number = number not in (none, [], "")
  let heading-font = ("Source Han Sans SC", "Arial")
  let surface = accent-color.transparentize(83%)

  let title-cell = {
    set par(first-line-indent: 0pt, justify: false)
    set text(font: heading-font, size: 10pt, weight: "semibold", fill: accent-color.darken(15%))
    supplement
    if has-number {
      h(0.3em)
      number
    }
    if has-title {
      h(0.85em)
      text(title, size: 11pt, weight: "semibold", fill: luma(18%))
    }
  }

  let tags-cell = {
    set par(first-line-indent: 0pt, justify: false)
    set text(font: heading-font, size: 8.5pt, weight: "regular", fill: luma(48%))
    tags.join([ · ])
  }

  let body-cell = {
    set par(first-line-indent: 0pt, justify: false)
    align(left, body)
  }

  // The grid owns the accent rail and repeats the heading across page breaks.
  grid(
    inset: 0pt,
    stroke: none,
    fill: surface,
    columns: (1fr, auto),
    rows: (auto, auto),
    gutter: 0pt,
    grid.vline(x: 0, stroke: (paint: accent-color, thickness: 1.8pt, cap: "butt")),
    grid.header(
      repeat: true,
      grid.cell(
        inset: (left: 1em, right: 0.5em, top: 0.7em, bottom: 0.35em),
        align: left + horizon,
        title-cell,
      ),
      grid.cell(
        inset: (left: 0.5em, right: 1em, top: 0.7em, bottom: 0.35em),
        align: right + horizon,
        tags-cell,
      ),
    ),
    grid.cell(
      colspan: 2,
      inset: (x: 1em, top: 0.2em, bottom: 0.75em),
      align: left,
      breakable: true,
      body-cell,
    ),
  )
}
