#import "/elements/better-lists.typ": (
  better-lists, normalize-connector, normalize-label-align,
  resolve-list-renderer,
)
#import "/utils/terms-data.typ": set_
#import "/utils/numbly-utils.typ": partial-display

#assert(
  normalize-label-align(start + top) == start,
  message: "Vertical alignment must not override start.",
)
#assert(
  normalize-label-align(end + bottom) == end,
  message: "Vertical alignment must not override end.",
)
#for value in (top, bottom, horizon, center, left, right, center + top) {
  assert(
    normalize-label-align(value) == end,
    message: "Unsupported label alignment must fall back to end.",
  )
}

#assert(
  resolve-list-renderer(false) == none,
  message: "False must preserve native rendering.",
)
#assert(
  resolve-list-renderer(true) == resolve-list-renderer("block-indent"),
  message: "True must select block-indent.",
)
#assert(
  resolve-list-renderer("first-line-indent") != resolve-list-renderer(true),
  message: "First-line indentation must select a separate renderer.",
)

#assert(
  normalize-connector(none) == none,
  message: "A disabled connector must remain none.",
)
#for style in (blue, 1pt + blue, (paint: blue, thickness: 1pt), stroke(blue)) {
  let connector = normalize-connector((stroke: style, foot-stroke: style))
  assert(
    connector.stroke == stroke(style),
    message: "Connector stroke must use native stroke normalization.",
  )
  assert(
    connector.foot-stroke == stroke(style),
    message: "Foot stroke must use native stroke normalization.",
  )
}
#let disabled-strokes = normalize-connector((stroke: none, foot-stroke: none))
#assert(
  disabled-strokes.stroke == none and disabled-strokes.foot-stroke == none,
  message: "Disabled strokes must remain none.",
)

#let list-settings = (
  enum: (
    numbering: partial-display("{1}.{2}.{3}.{4}."),
    post-numbering: none,
    full: false,
    tight: (
      overload: true,
      spacing: 0.65em,
      indentation: 1.5em,
      body-indent: 0.65em,
      number-align: end,
      connector: (
        enabled: true,
        position: 0.9em,
        foot-width: 0.3em,
        threshold: 1em,
        stroke: (
          paint: rgb("#66ccff"),
          thickness: 1pt,
          cap: "round",
          dash: (array: (4pt, 5pt, 1145140000pt), phase: 4pt),
        ),
        foot-stroke: (
          paint: rgb("#66ccff"),
          thickness: 1pt,
          cap: "round",
          dash: none,
        ),
      ),
    ),
    loose: (
      overload: "block-indent",
      spacing: 1em,
      indentation: 1.5em,
      body-indent: 0.5em,
      number-align: end,
      connector: (
        enabled: true,
        position: 0.9em,
        foot-width: 0.3em,
        threshold: 1em,
        stroke: (
          paint: rgb("#66ccff"),
          thickness: 1pt,
          cap: "round",
          dash: (array: (4pt, 5pt, 1145140000pt), phase: 4pt),
        ),
        foot-stroke: (
          paint: rgb("#66ccff"),
          thickness: 1pt,
          cap: "round",
          dash: none,
        ),
      ),
    ),
  ),
  list: (
    marker: ([•], [‣], [–]),
    tight: (
      overload: true,
      spacing: 0.65em,
      indentation: 1.5em,
      body-indent: 0.5em,
      marker-align: end,
      connector: (
        enabled: true,
        position: 0.75em,
        foot-width: 0.3em,
        threshold: 1em,
        stroke: (
          paint: rgb("#66ccff"),
          thickness: 1pt,
          cap: "round",
          dash: (array: (4pt, 5pt, 1145140000pt), phase: 4pt),
        ),
        foot-stroke: (
          paint: rgb("#66ccff"),
          thickness: 1pt,
          cap: "round",
          dash: none,
        ),
      ),
    ),
    loose: (
      overload: "block-indent",
      spacing: 1em,
      indentation: 1.5em,
      body-indent: 0.5em,
      marker-align: end,
      connector: (
        enabled: true,
        position: 0.68em,
        foot-width: 0.3em,
        threshold: 1em,
        stroke: (
          paint: rgb("#66ccff"),
          thickness: 1pt,
          cap: "round",
          dash: (array: (4pt, 5pt, 1145140000pt), phase: 4pt),
        ),
        foot-stroke: (
          paint: rgb("#66ccff"),
          thickness: 1pt,
          cap: "round",
          dash: none,
        ),
      ),
    ),
  ),
)

#let alignment-sample = [
  - #metadata("list-indent-test")First alignment item.

    Second paragraph.
  - Second alignment item.

    Another paragraph.
]

= Native alignment reference
#block[
  #let native-variant = (
    overload: false,
    indentation: list-settings.list.loose.indentation,
    body-indent: list-settings.list.loose.body-indent,
    spacing: list-settings.list.loose.spacing,
    marker-width: 8cm,
    connector: (enabled: true),
  )
  #show: better-lists((list: (tight: native-variant, loose: native-variant)))
  #set list(
    marker: list-settings.list.marker,
    indent: list-settings.list.loose.indentation,
    body-indent: list-settings.list.loose.body-indent,
    spacing: list-settings.list.loose.spacing,
  )
  #alignment-sample
]

#show: better-lists(list-settings)

= Connector alignment reference
#alignment-sample
#context {
  let anchors = query(metadata.where(value: "list-indent-test"))
  assert(
    anchors.len() == 2,
    message: "Expected native and grid alignment anchors.",
  )
  let native-x = anchors.first().location().position().x
  let grid-x = anchors.last().location().position().x
  assert(
    calc.abs(native-x - grid-x) < 0.01pt,
    message: "Grid body indentation must match native list indentation.",
  )
}

#pagebreak()
= Better lists

== List

- First list item
  - Nested list item
    - Deeply nested list item
  - Another nested list item
- List item with multiple paragraphs.

  This is the second paragraph of the same list item. It verifies that
  paragraph boundaries do not terminate the item.

  This is the third paragraph of the same list item.
  - Nested item after multiple paragraphs
- Second list item

- First list item
  - Nested list item
    - Deeply nested list item
  - Another nested list item

- List item with multiple paragraphs.

  This is the second paragraph of the same list item. It verifies that
  paragraph boundaries do not terminate the item.

  This is the third paragraph of the same list item.
  - Nested item after multiple paragraphs

- Second list item

== Enum

+ First enum item
  + Nested enum item
    + Deeply nested enum item
  + Another nested enum item
+ Enum item with multiple paragraphs.

  This is the second paragraph of the same enum item. It verifies that
  paragraph boundaries do not terminate the item.

  This is the third paragraph of the same enum item.
  + Nested item after multiple paragraphs
+ Second enum item

== Loose enum

+ First loose enum item

+ Enum item with multiple paragraphs.

  This is the second paragraph of the same enum item.

  This is the third paragraph of the same enum item.
  + Nested enum item
    + Deeply nested enum item

+ Last loose enum item


== Formula Test

- $display(a = mat(1, 2, 3; 4, 5, 6; 7, 8, 9))$
- a#box($display(integral \ mat(1, 2, 3; 4, 5, 6))$, baseline: 2em)
- 2

== Cross Page Test

- $display(a = mat(1, 2, 3; 4, 5, 6; 7, 8, 9))$
  - #v(200em)2#v(200em)2#v(200em)

#pagebreak()
#set page(width: 12cm, height: 14cm, margin: 1cm)

== Tight cross-page alignment

#set list(marker: level => [#sym.zws#metadata("tight-marker")•])
- #metadata("tight-body")A tall inline formula $display(mat(1, 2; 3, 4; 5, 6; 7, 8))$.
  #for i in range(24) [Line #i in the same item. #linebreak()]
- Next item, after the split.
  - Nested item with $display(mat(1, 2; 3, 4; 5, 6; 7, 8))$.
    #for i in range(10) [Nested continuation #i. #linebreak()]
  - Nested last item.
- Final item.

#context {
  let marker = query(metadata.where(value: "tight-marker"))
    .first()
    .location()
    .position()
  let body = query(metadata.where(value: "tight-body"))
    .first()
    .location()
    .position()
  assert(
    marker.page == body.page,
    message: "Tight marker and body must start on the same page.",
  )
  assert(
    calc.abs(marker.y - body.y) < 0.01pt,
    message: "Tight marker must retain its baseline offset across a split grid.",
  )
}

#pagebreak()
== Tight enum cross-page alignment

#set enum(numbering: (..numbers) => [#sym.zws#metadata(
    "tight-enum-marker",
  )#numbering("1.", ..numbers)])
+ First item.
+ #metadata("tight-enum-body")An inline formula $display(mat(1, 2; 3, 4; 5, 6; 7, 8))$.
  #for i in range(24) [Continuation #i. #linebreak()]
+ Last item.

#context {
  let marker = query(metadata.where(value: "tight-enum-marker"))
    .at(1)
    .location()
    .position()
  let body = query(metadata.where(value: "tight-enum-body"))
    .first()
    .location()
    .position()
  assert(
    marker.page == body.page,
    message: "Tight numbering and body must start on the same page.",
  )
  assert(
    calc.abs(marker.y - body.y) < 0.01pt,
    message: "Tight numbering must retain its baseline offset across a split grid.",
  )
}

#pagebreak()
#set text(
  font: ((name: "Charter", covers: "latin-in-cjk"), "LXGW WenKai GB"),
  size: 12pt,
)
== 中文页首序号

#set enum(numbering: (..numbers) => [#sym.zws#metadata(
    "chinese-enum-marker",
  )#numbering("1.", ..numbers)])
+ #metadata("chinese-enum-body")第一步：读取输入并完成基本校验。
  #for i in range(24) [同一项内的跨页正文，第 #i 行。#linebreak()]
+ #metadata("chinese-enum-body")第二步：构建元素树与上下文。
+ #metadata("chinese-enum-body")第三步：执行渲染并输出结果。
  + #metadata("chinese-enum-body")子步骤：记录耗时。
  + #metadata("chinese-enum-body")子步骤：检查边界条件。
+ #metadata("chinese-enum-body")第四步：写入日志并返回状态。

#context {
  let markers = query(metadata.where(value: "chinese-enum-marker"))
  let bodies = query(metadata.where(value: "chinese-enum-body"))
  assert(
    markers.len() == bodies.len(),
    message: "Chinese numbering must have one marker per body.",
  )
  for (marker, body) in markers.zip(bodies) {
    let marker = marker.location().position()
    let body = body.location().position()
    assert(
      marker.page == body.page,
      message: "Chinese numbering and body must start on the same page.",
    )
    assert(
      calc.abs(marker.y - body.y) < 0.01pt,
      message: "Chinese numbering must align with the body baseline.",
    )
  }
}

#pagebreak()
// Only the zero-height grid row fits before the page break.
#v(11.9cm)
#set enum(numbering: (..numbers) => [#sym.zws#metadata(
    "page-top-marker",
  )#numbering("1.", ..numbers)])
+ #metadata("page-top-body")页首高公式 $display(mat(1, 2; 3, 4; 5, 6; 7, 8))$。
  #for i in range(24) [跨页正文，第 #i 行。#linebreak()]
+ 最后一项。

#context {
  let marker = query(metadata.where(value: "page-top-marker"))
    .first()
    .location()
    .position()
  let body = query(metadata.where(value: "page-top-body"))
    .first()
    .location()
    .position()
  assert(
    marker.page == body.page,
    message: "Page-top numbering and body must start on the same page.",
  )
  assert(
    calc.abs(marker.y - body.y) < 0.01pt,
    message: "Page-top numbering must retain the tall first-line offset.",
  )
}

#pagebreak()
#block[
  #show: set_("list-loose", overload: "first-line-indent", connector: none)
  #show: set_("enum-loose", overload: "first-line-indent", connector: none)
  == Loose first-line indent

  - 第一项的首段足够长，用于观察首行缩进，以及换行后的正文是否回到左边界，而不是继续悬挂缩进。

    第二段同样足够长，用于观察每一段的首行都保留缩进，并检查普通中文与 English 混排的行为。

  - 第二项用于确认标记与段落的基本排版。

    这是第二项的后续段落。

    + 第一项有序列表的首段足够长，用于观察编号与首行缩进，以及换行后的正文是否回到左边界。

      后续段落继续使用首行缩进，不采用整块缩进。

    + 第二项用于确认有序列表的基本编号。

      这是第二项的后续段落。

      + 第一项有序列表的首段足够长，用于观察编号与首行缩进，以及换行后的正文是否回到左边界。

      后续段落继续使用首行缩进，不采用整块缩进。

    + 第二项用于确认有序列表的基本编号。

      这是第二项的后续段落。
]

#let fixed-width-sample(direction, connectors: false, label-align: end) = {
  set text(dir: direction, font: ("Noto Sans Arabic", "Charter"), size: 12pt)
  let variant = (
    overload: true,
    indentation: 0pt,
    body-indent: 0.5em,
    connector: (enabled: connectors),
  )
  show: set_(
    "enum-tight",
    ..variant,
    number-width: 2em,
    number-align: label-align,
  )
  show: set_(
    "list-tight",
    ..variant,
    marker-width: 2em,
    marker-align: label-align,
  )
  heading(level: 2, if direction == rtl { [RTL fixed widths] } else {
    [LTR fixed widths]
  })
  let body = if direction == rtl { [مرحبا بالعالم] } else {
    [Fixed-width item body.]
  }
  enum(
    start: 8,
    numbering: n => [#sym.zws#metadata((direction, "number-marker"))#numbering(
        "1.",
        n,
      )],
    ..range(4).map(_ => [#metadata((direction, "number-body"))#body]),
  )
  list(
    marker: [#sym.zws#metadata((direction, "bullet-marker"))※],
    ..range(2).map(_ => [#metadata((direction, "bullet-body"))#body]),
  )
  context {
    let expected-x = if direction == rtl { page.width - 1cm - 2.5em } else {
      1cm + 2.5em
    }
    for kind in ("number", "bullet") {
      let markers = query(metadata.where(value: (direction, kind + "-marker")))
      let bodies = query(metadata.where(value: (direction, kind + "-body")))
      assert(
        markers.len() == bodies.len(),
        message: "Each fixed-width item must have one marker.",
      )
      for (marker, body) in markers.zip(bodies) {
        let marker = marker.location().position()
        let body = body.location().position()
        assert(
          calc.abs(body.x - expected-x.to-absolute()) < 0.01pt,
          message: "Fixed label width must determine the body column.",
        )
        assert(
          calc.abs(marker.y - body.y) < 0.01pt,
          message: "Fixed-width markers must align with the body baseline.",
        )
      }
    }
  }
}

#pagebreak()
#fixed-width-sample(ltr, label-align: start + top)
#pagebreak()
#fixed-width-sample(rtl, connectors: true, label-align: end + bottom)
