#show math.frac: math.display

#grid(
  columns: (1em, 0pt, 1em, 1fr),
  // stroke: black + 1pt,
  // first item
  grid.cell(
    colspan: 4,
  )[#metadata("numbering-start-1")],
  grid.cell(
    colspan: 3,
  )[
    #context v(query(metadata.where(value: "baseline-1")).first().location().position().y - query(metadata.where(value: "numbering-start-1")).first().location().position().y - 0.65em);1.#v(0.65em)
  ],
  grid.cell(
    rowspan: 2,
  )[
    #set text(cjk-latin-spacing: none)
    #sym.zws#metadata("baseline-1")$(1/2/3/4)/(1/2/3/4)$#lorem(100)#parbreak()#lorem(100)#parbreak()#lorem(100)#parbreak()#lorem(100)#parbreak()#lorem(100)#parbreak()#lorem(100)#parbreak()#lorem(100)
  ],
  [],
  grid.cell(stroke: red + 1pt)[],
  [],
  // insert a empty par to make sure the correct gap between two items
  grid.cell(
    colspan: 4,
  )[#parbreak()#sym.zws],
  // second item
  grid.cell(
    colspan: 4,
  )[#metadata("numbering-start-2")],
  grid.cell(
    colspan: 3,
  )[
    #context v(query(metadata.where(value: "baseline-2")).first().location().position().y - query(metadata.where(value: "numbering-start-2")).first().location().position().y - 0.65em);2.#v(0.65em)
  ],
  grid.cell(
    rowspan: 2,
  )[
    #set text(cjk-latin-spacing: none)
    #sym.zws#metadata("baseline-2")$(1/2/3/4)/(1/2/3/4)$#lorem(800)
  ],
  [],
  grid.cell(stroke: red + 1pt)[],
  [],
  // insert a empty par to make sure the correct gap between two items
  grid.cell(
    colspan: 4,
  )[#parbreak()#sym.zws],
)

#place(top, float: true)[
  #block(height: 10em, inset: 1em)[#align(center)[#lorem(50)]]
]
