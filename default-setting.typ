#import "/utils/numbly-utils.typ": partial-display
#import "/utils/utils.typ": merge-dict

#let default-connector-settings = (
  enabled: false,
  offset: 0.5em,
  top-trim: 0.8em,
  bottom-trim: 0.5em,
  tail-length: 1em,
  after-gap: 0pt,
  stroke: (paint: luma(80%), thickness: 0.5pt, dash: "dotted"),
)

#let default-settings = (
  lists: (
    enum: (
      numbering: partial-display("{1}.{2}.{3}.{4}."),
      post-numbering: it => it,
      full: false,
      tight: (
        type: "hanging-indent",
        par-indent: 0.5em,
        indentation: 2em,
        spacing: 0.5em,
        numbering-align: "right",
        connector: default-connector-settings,
      ),
      loose: (
        type: "first-line-indent",
        par-indent: 1.2em,
        indentation: 2em,
        spacing: 0.5em,
        numbering-align: "right",
      ),
    ),
    list: (
      marker: ([•], [‣], [–]),
      tight: (
        type: "hanging-indent",
        par-indent: 0.5em,
        indentation: 2em,
        spacing: 0.5em,
        marker-align: "right",
        connector: merge-dict(
          default-connector-settings,
          (tail-length: 0em),
        ),
      ),
      loose: (
        type: "first-line-indent",
        par-indent: 1.2em,
        indentation: 2em,
        spacing: 0.5em,
        marker-align: "right",
      ),
    ),
  ),
)
