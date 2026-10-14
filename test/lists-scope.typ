#import "/elements/better-lists.typ": better-lists
#import "/utils/terms-data.typ": get, set_

#set page(width: 17cm, height: auto, margin: 1cm)
#set text(font: ("Charter", "LXGW WenKai GB"), size: 11pt)

// Overrides before installation must also reach native show-set fields.
#show: set_("list-tight", overload: false, indentation: 0.75em)
#show: better-lists((:))

= Scoped list settings

== Initial native rendering
- #metadata("native-before")Native bullet before the local changes.
- A second native item.

#[
  #show: set_("list-tight", overload: true, indentation: 0pt, marker-width: 2em)
  == Local fixed-width grid
  - #metadata("grid-body")The body starts after a two-em marker column.
  - A second grid item.

  #[
    #show: set_("list-tight", overload: false, marker-width: 8cm)
    == Native inside grid scope
    - #metadata("native-inside")The eight-cm grid width must be ignored.
    - This must use the native list renderer.
  ]

  - #metadata("grid-restored")The fixed grid column is restored after the native scope.

  #list(
    indent: 1cm,
    [#metadata("explicit-indent")Explicit native indentation takes priority over namespace defaults.],
  )
]

== Outer native rendering restored
- #metadata("native-after")Same indentation as the initial native list.
- A second restored native item.

#[
  #show: set_("list-loose", overload: "first-line-indent", indentation: 2em)
  == Loose first-line indentation
  - First paragraph in a loose item.

    Its second paragraph uses first-line indentation as well.

  - Another loose item.
]

#[
  #show: set_(
    "enum-tight",
    overload: true,
    indentation: 0pt,
    number-width: 2em,
    number-align: start + top,
  )
  #show: set_(
    "enum-loose",
    overload: "first-line-indent",
    post-numbering: number => text(fill: blue, number),
  )
  == Tight enum and nested loose enum
  + Fixed-width enum item.
  + Second enum item.
    #enum(
      tight: false,
      [First nested loose paragraph.

        The next paragraph keeps first-line indentation.],
      [Second nested loose item.],
    )
]

#[
  #show: set_("list-tight", overload: true, connector: (
    enabled: true,
    stroke: blue,
    foot-stroke: blue,
    threshold: 0pt,
  ))
  #show: set_("terms", separator: [ — ])
  == Connectors and safe separator change
  #list(
    tight: true,
    [First paragraph.

      The following paragraph makes the connector visible.],
    [Second item.],
  )
  / Definition: The em dash must not clear the four list namespaces.
  #get("enum-loose", settings => {
    assert(
      settings.overload == "first-line-indent",
      message: "Safe separator changes must preserve all list namespaces.",
    )
  })
]

#context {
  let position(name) = query(metadata.where(value: name))
    .first()
    .location()
    .position()
  let before = position("native-before")
  let after = position("native-after")
  let inner = position("native-inside")
  let grid = position("grid-body")
  let restored = position("grid-restored")
  assert(
    calc.abs(before.x - after.x) < 0.01pt,
    message: "Leaving a local grid scope must restore native indentation.",
  )
  assert(
    inner.x < 3cm,
    message: "Disabling overload must bypass the grid renderer even inside an enabled scope.",
  )
  assert(
    calc.abs(grid.x - (1cm + 2.5em).to-absolute()) < 0.01pt,
    message: "Local fixed marker width must control the grid body offset.",
  )
  assert(
    calc.abs(grid.x - restored.x) < 0.01pt,
    message: "Leaving the nested native scope must restore the grid settings.",
  )
  assert(
    calc.abs(position("explicit-indent").x - (2cm + 2.5em).to-absolute())
      < 0.01pt,
    message: "Explicit native arguments must take precedence over namespace defaults.",
  )
}

#get("list-tight", settings => {
  assert(
    settings.overload == false and settings.indentation == 0.75em,
    message: "Overrides before installation must survive local updates.",
  )
})

#if sys.inputs.at("failure", default: none) == "duplicate" {
  show: better-lists((:))
  [Unreachable.]
}
