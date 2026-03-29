#let pos-y(id) = query(metadata.where(value: id)).first().location().position().y

#set page(
  paper: "a4",
  margin: (
    top: 2.5cm,
    bottom: 2.5cm,
    left: 2.5cm,
    right: 2.5cm,
  ),
)

#set par(leading: 1em)
#set text(28pt)

= Anchor Baseline Compare

grid 前置锚点：

#metadata("outer-start")
#grid(
  columns: (2em, 1fr),
  gutter: 0em,
  {
    context v(pos-y("outer-line") - pos-y("outer-start") - 0.65em)
    [1.]
  },
  [#sym.zws#metadata("outer-line")1甲Agjp 测试首行锚点位置$display(1/ (2 / 4))$],
)

#v(1.5cm)

单独 cell 锚点：

#grid(
  columns: (2em, 1fr),
  gutter: 0em,
  grid.cell(
    colspan: 2,
    metadata("cell-start"),
  ),
  {
    context v(pos-y("cell-line") - pos-y("cell-start") - 0.65em)
    [1.]
  },
  [#sym.zws#metadata("cell-line")1甲Agjp 测试首行锚点位置$display(1/ (2 / 4))$],
)

#v(1cm)

#context [
  outer-start y = #pos-y("outer-start"), \
  outer-line y = #pos-y("outer-line"), \
  cell-start y = #pos-y("cell-start"), \
  cell-line y = #pos-y("cell-line"), \
  外置方案差值 = #calc.abs((pos-y("outer-line") - pos-y("outer-start")) - (pos-y("cell-line") - pos-y("cell-start")))
]
