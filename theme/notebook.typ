#import "/elements/elements.typ": *
#import "/utils/numbly-utils.typ": *
#import "/utils/size-utils.typ": 五号, 小四
#import "/typing-utils.typ": char-replace
#import "@preview/hydra:0.6.2": hydra
#import "@preview/zebraw:0.5.5": zebraw, zebraw-init
#import "@preview/cjk-spacer:0.2.0": cjk-spacer

#let notebook-theme(doc) = {
  let notebook-code-block-style = (
    inset: (x: 0.7em, y: 0.45em),
    background-color: rgb("#fdfbf6"),
    // highlight-color: luma(92.5%),
    comment-color: luma(88%),
    lang-color: rgb("#40444f"),
    lang-font-args: (
      fill: white,
      weight: "bold",
      size: 0.9em,
    ),
    numbering-font-args: (
      fill: luma(55%),
    ),
    numbering-separator: true,
  )

  let notebook-code-block(it) = {
    block(stroke: 1pt + luma(50%), radius: 0.4em, zebraw(it))
  }

  let notebook-list-marker(level) = {
    let fill = luma(22%)
    let shape = if level == 0 {
      circle(radius: 0.145em, fill: fill)
    } else if level == 1 {
      polygon(
        fill: fill,
        (0em, 0em),
        (0.29em, 0.17em),
        (0em, 0.34em),
      )
    } else {
      rect(width: 0.19em, height: 0.19em, fill: fill)
    }

    box(width: 1em, baseline: -3pt)[
      #align(center + horizon, shape)
    ]
  }

  let custom-list-settings = (
    enum: (
      numbering: partial-display("{1}.{2}.{3}.{4}."),
      post-numbering: none,
      full: false,
      loose: (
        type: "block-indent",
        connector: (
          enabled: true,
          position: 1em,
        ),
      ),
    ),
    list: (
      marker: notebook-list-marker,
      loose: (
        type: "block-indent",
        connector: (
          enabled: true,
          position: 1em,
        ),
      ),
    ),
  )
  show: better-lists(custom-list-settings)

  set page(
    paper: "a4",
    margin: (x: 1.91cm, y: 2.54cm),
    fill: luma(98%),
    numbering: "1",
    header: context {
      align(bottom, {
        set par(first-line-indent: 0pt)
        hydra(1)
        place(bottom, dy: 0.5em)[#line(
          length: 100%,
          stroke: 1pt + black,
        )]
      })
    },
  )

  // using a package to clean the spacing between two CJK source code line.
  show: cjk-spacer
  set text(
    size: 五号,
    fill: luma(20%),
    font: ("Source Han Serif SC", "Charter"),
    cjk-latin-spacing: auto,
    weight: "medium",
    hyphenate: true,
    lang: "zh",
  )

  set par(
    first-line-indent: (amount: 2em, all: true),
    spacing: 0.65em,
    justify: true,
    leading: 0.65em,
  )

  set heading(
    numbering: numbly("{1:一}、", "{1}.{2}", "{1}.{2}.{3}"),
    supplement: "章节",
  )

  show heading.where(level: 1): it => [
    #counter(math.equation).update(0)
    #it
  ]

  set figure(
    numbering: (..nums) => {
      let figure_pos = nums.at(0)
      numbering("1-1", (counter(heading).at(here())).first(), figure_pos)
    },
    scope: "parent",
    placement: auto,
  )

  set underline(
    offset: 2pt,
    stroke: (
      paint: blue,
      thickness: 0.75pt,
    ),
  )

  show raw: set text(
    font: ("Maple Mono", "LXGW Wenkai GB"),
    size: 五号,
  )

  show heading: set text(
    fill: luma(20%),
    font: ("Arial", "HarmonyOS Sans SC"),
  )

  show link: notebook-link

  show raw.where(block: false): notebook-inline-code
  show raw.where(block: true): notebook-code-block

  show emph: it => {
    show regex("[\\u4e00-\\u9fa5\\uFF00-\\uFFEF]+"): it => {
      text(font: "LXGW WenKai GB")[#it]
    }
    set text(style: "italic")
    it
  }

  show figure.where(kind: "image"): set figure(supplement: "图")
  show figure.where(kind: "table"): set figure(supplement: "表")
  show math.equation: set math.equation(supplement: "公式")
  // show figure: it => {
  //   block()[#it]
  // }

  show: zebraw-init.with(..notebook-code-block-style)

  show math.equation: set text(
    features: ("cv01",),
    font: ("New Computer Modern Math", "Source Han Serif SC"),
    weight: 500,
    cjk-latin-spacing: auto
  )

  show math.equation.where(block: false): math.display
  show math.equation.where(block: false): set math.frac(style: "horizontal")
  show math.equation.where(block: false): it => [#h(0.3em)#it#h(0.3em)]

  set math.equation(numbering: n => {
    numbering("(1.1)", counter(heading).at(here()).first(), n)
  })

  show: char-replace

  doc
}
