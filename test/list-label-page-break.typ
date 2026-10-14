#let path = sys.inputs.at("module", default: "/elements/better-lists.typ")
#import path as lists

#set page(width: 12cm, height: 10cm, margin: 1cm)
#set text(font: ("Charter", "LXGW WenKai GB"), size: 11pt)
#show: (lists.better-lists)((
  list: (tight: (connector: (enabled: true, threshold: 0pt))),
  enum: (tight: (connector: (enabled: true, threshold: 0pt))),
))

#let sample(kind) = {
  let key(part) = (kind: kind, part: part)
  let marker = [#sym.zws#metadata(key("label"))•]
  let numbered(..numbers) = [#sym.zws#metadata(key("label"))#numbering(
      "1.",
      ..numbers.pos(),
    )]
  heading(level: 1, [#kind: label and first line stay together])
  metadata(key("start"))
  v(5.8cm)
  let first = [#metadata(key("body"))Tall first line $display(mat(1, 2; 3, 4; 5, 6; 7, 8; 9, 10))$.]
  if kind == "enum" {
    enum(numbering: numbered, tight: true, first, [Second item.])
  } else {
    list(marker: marker, tight: true, first, [Second item.])
  }
  context {
    let position(part) = query(metadata.where(value: key(part)))
      .first()
      .location()
      .position()
    let label = position("label")
    let body = position("body")
    assert(
      body.page > position("start").page,
      message: "The test must force the first line onto the next page.",
    )
    assert(
      label.page == body.page,
      message: "The label must move to the next page with the first body line.",
    )
    assert(
      calc.abs(label.y - body.y) < 0.01pt,
      message: "The label must share the tall first line's baseline.",
    )
  }
}

#sample("enum")
#pagebreak()
#sample("list")
