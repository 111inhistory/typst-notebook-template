#let path = sys.inputs.at("module", default: "/elements/better-lists.typ")
#import path as lists

#set page(width: 12cm, height: 14cm, margin: 1cm)
#set text(font: "Charter", size: 12pt)
#show: (lists.better-lists)((
  enum: (
    tight: (
      indentation: 1.5em,
      connector: (
        enabled: true,
        position: 1em,
        threshold: 0pt,
        stroke: (paint: rgb("ff00ff"), thickness: 1pt),
        foot-stroke: (paint: rgb("ff00ff"), thickness: 1pt),
      ),
    ),
  ),
))

#set enum(numbering: (..numbers) => context {
  let label = numbering("1.", numbers.pos().last())
  sym.zws
  metadata((
    test: "connector-label",
    width: measure(label).width,
    ascent: measure(text(
      label,
      top-edge: "ascender",
      bottom-edge: "baseline",
    )).height,
    stem-offset: (measure(label).width - 0.5em).to-absolute(),
    expect-stem: numbers.pos().len() == 1 and numbers.pos().last() in (1, 3),
  ))
  label
})

= Nested enum
#enum(
  start: 3,
  [Parent item.
    #enum(start: 1, [First child.], [Second child.])],
  [Next parent.],
)

= Tall first line
+ Tall formula $display(mat(1, 2; 3, 4; 5, 6; 7, 8; 9, 10))$.
  #for i in range(4) [Continuation #i. #linebreak()]
+ Next item.

#pagebreak()
= First line forced onto the next page
#v(float(sys.inputs.at("filler", default: "10.3")) * 1cm)
+ Tall formula $display(mat(1, 2; 3, 4; 5, 6; 7, 8; 9, 10))$.
  #for i in range(24) [Cross-page continuation #i. #linebreak()]
+ Next item.
