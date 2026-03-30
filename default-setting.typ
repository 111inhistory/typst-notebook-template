#import "/utils/numbly-utils.typ": partial-display
#import "/utils/utils.typ": merge-dict

/// Default connector settings for block-indent rendering.
/// `position` is measured from the body-side edge of the indent area.
/// A value of `0pt` places the connector right next to the body column.
/// A value equal to `indentation` places it at the far left edge.
#let default-connector-settings = (
  enabled: false,
  baseline-offset: 0.65em,
  position: 0.9em,
  stroke: (paint: luma(80%), thickness: 0.5pt, dash: (array: (4pt, 5pt), phase: 4pt)),
)

/// Global default settings for list styling.
#let default-settings = (
  lists: (
    enum: (
      numbering: partial-display("{1}.{2}.{3}.{4}."),
      post-numbering: none,
      full: false,
      tight: (
        type: "block-indent",
        spacing: 0.65em,
        indentation: 2em,
        body-indent: 0.5em,
        numbering-align: "right",
        connector: default-connector-settings,
      ),
      loose: (
        type: "first-line-indent",
        spacing: 1em,
        indentation: 2em,
        body-indent: 0.5em,
        numbering-align: "right",
      ),
    ),
    list: (
      marker: ([•], [‣], [–]),
      tight: (
        type: "block-indent",
        spacing: 0.65em,
        indentation: 2em,
        body-indent: 0.5em,
        marker-align: "right",
        connector: default-connector-settings,
      ),
      loose: (
        type: "first-line-indent",
        spacing: 1em,
        indentation: 2em,
        body-indent: 0.5em,
        marker-align: "right",
      ),
    ),
  ),
)
