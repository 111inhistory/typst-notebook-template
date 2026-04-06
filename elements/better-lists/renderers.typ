#import "/utils/anchor.typ": anchor-helper
#import "/utils/content-utils.typ": sequence, split-first-paragraph

// Tracks the current parent numbering path.
// `enum` stores real numbers, while `list` uses `0` as a placeholder.
#let parents = state("_list-enum-internal", ())
// Counts block-indent enum list instances.
#let block-indent-enum-counter = counter("_block-indent-enum")
// Counts block-indent bullet list instances.
#let block-indent-list-counter = counter("_block-indent-list")

/// Resolve optional connector settings for block-indent renderers.
/// - connector (dictionary | none): Connector configuration or explicit none.
/// -> dictionary
#let resolve-connector-state(connector) = {
  if connector == none {
    return (
      enabled: false,
      position: 0pt,
      stroke: none,
    )
  }

  assert(
    type(connector) == dictionary,
    message: "connector 必须是 dictionary 或 none，实际为 " + repr(type(connector)),
  )

  (
    enabled: connector.at("enabled"),
    position: connector.at("position"),
    stroke: connector.at("stroke"),
  )
}

/// Render a single block-indent row with an optional connector slot.
/// - prefix (str): Anchor prefix for the current list instance.
/// - index (int): Zero-based item index within the current list instance.
/// - label (content): Rendered marker or numbering content.
/// - body (content): Item body content.
/// - indent (length): Total indentation reserved for the label area.
/// - label-align (str): Alignment keyword, usually `"left"` or `"right"`.
/// - connector-enabled (bool): Whether the connector slot should be rendered.
/// - connector-position (length): Distance from the body-side edge of the indent area.
/// - connector-stroke (stroke | dictionary): Stroke used for the connector.
/// - has-next (bool): Whether another sibling item follows this row.
/// -> content
#let render-block-indent-row(
  prefix,
  index,
  label,
  body,
  indent,
  label-align,
  connector-enabled,
  connector-position,
  connector-stroke,
  has-next,
) = {
  let (create: body-anc-create, findpos: body-anc-findpos) = anchor-helper(prefix + "body-")
  let (create: num-anc-create, findpos: num-anc-findpos) = anchor-helper(prefix + "num-")

  let ret = ()

  // The first row only registers the numbering anchor.
  ret.push(grid.cell(
    colspan: 4,
    inset: 0pt,
  )[
    #num-anc-create(index)
  ])
  // The second row places the label inside the full indent slot.
  ret.push(grid.cell(
    colspan: 3,
    align: if label-align == "right" { right + top } else { left + top },
  )[
    #box[#context {
      let baseline-pos = body-anc-findpos(index)
      let numbering-pos = num-anc-findpos(index)
      // Move the label down until its bottom touches the measured first-line baseline.
      let v-spacing = if numbering-pos.page == baseline-pos.page {
        baseline-pos.y - numbering-pos.y - measure(label).height
      } else { 0pt }
      v(v-spacing)
      label
    }]
  ])
  // The body remains in normal flow and stretches the connector row through rowspan.
  ret.push(grid.cell(
    rowspan: 2,
    inset: 0pt,
    align: left + top,
  )[
    #set text(cjk-latin-spacing: none)
    #sym.zws#body-anc-create(index)#body
  ])
  // The connector is currently drawn as the left stroke of a dedicated slot cell.
  ret.push([])
  ret.push(grid.cell(stroke: if connector-enabled { connector-stroke }, inset: 0pt)[])
  ret.push([])
  if has-next {
    ret.push(grid.cell(
      colspan: 4,
      inset: 0pt,
    )[
      #parbreak()#sym.zws
    ])
  }
  ret
}

/// Render first-line-indent enums without using a grid layout.
/// - settings (dictionary): Renderer settings for this style variant.
/// -> function
#let firstline-indent-enum(settings) = it => context {
  let item-spacing = it.spacing
  let indent = it.indent
  let body-indent = it.body-indent
  let numbering-pattern = it.numbering
  let numbering-align = settings.numbering-align
  let post-numbering = settings.post-numbering

  set par(spacing: item-spacing, first-line-indent: 0em)
  // Start number of the current enum list.
  let start = if it.start != auto {
    it.start
  } else if (
    it.children.first().has("number") and it.children.first().number != auto
  ) {
    it.children.first().number
  } else if it.reversed {
    it.children.len()
  } else {
    1
  }

  let delta = if it.reversed { -1 } else { 1 }
  // Current item number.
  let number = start
  let ret = []
  for child in it.children {
    number = if child.has("number") and child.number != auto {
      child.number
    } else {
      number
    }
    let split = split-first-paragraph(child.body)
    let num = numbering(numbering-pattern, ..parents.get(), number)
    num = if post-numbering != none { post-numbering(num) } else { num }
    let left-back-len = if numbering-align == "right" {
      body-indent + measure(num).width
    } else { indent - body-indent }
    let body = if it.tight {
      text(
        {
          h(indent)
          h(-left-back-len)
          num
          h(body-indent)
          split.first
        },
        cjk-latin-spacing: none,
      )
      split.rest
    } else {
      parents.update(arr => arr + (number,))
      {
        par(
          [
            #text(
              {
                h(-left-back-len)
                num
                h(body-indent)
                split.first
              },
              cjk-latin-spacing: none,
            )
          ],
          first-line-indent: (all: true, amount: indent),
        )
        split.rest
      }
      parents.update(arr => arr.slice(0, -1))
    }
    number += delta
    if parents.get().len() > 0 {
      ret += h(indent) + body + parbreak()
    } else {
      ret += body + parbreak()
    }
  }
  ret
}

/// Render first-line-indent bullet lists without using a grid layout.
/// - settings (dictionary): Renderer settings for this style variant.
/// -> function
#let firstline-indent-list(settings) = it => context {
  let item-spacing = it.spacing
  let indent = it.indent
  let body-indent = it.body-indent
  let marker-pattern = it.marker

  set par(spacing: item-spacing, first-line-indent: 0em)
  let level = parents.get().len()
  let marker = if type(marker-pattern) == array {
    marker-pattern.at(calc.rem-euclid(level, marker-pattern.len()))
  } else if type(marker-pattern) == function {
    marker-pattern(level)
  } else {
    marker-pattern
  }
  let marker-align = settings.marker-align
  let ret = []
  for child in it.children {
    let split = split-first-paragraph(child.body)
    let left-back-len = if marker-align == "right" {
      body-indent + measure(marker).width
    } else {
      indent - body-indent
    }
    let body = if it.tight {
      text(
        {
          h(indent)
          h(-left-back-len)
          marker
          h(body-indent)
          split.first
        },
        cjk-latin-spacing: none,
      )
      split.rest
    } else {
      parents.update(arr => arr + (0,))
      {
        par(
          [
            #text(
              {
                h(-left-back-len)
                marker
                h(body-indent)
                split.first
              },
              cjk-latin-spacing: none,
            )
          ],
          first-line-indent: (all: true, amount: indent),
        )
        split.rest
      }
      parents.update(arr => arr.slice(0, -1))
    }
    if parents.get().len() > 0 {
      ret += h(indent) + body + parbreak()
    } else {
      ret += body + parbreak()
    }
  }
  ret
}

/// Render block-indent enums using the grid-based local layout.
/// - settings (dictionary): Renderer settings for this style variant.
/// -> function
#let block-indent-enum(settings) = it => context {
  let item-spacing = it.spacing
  let indent = it.indent
  let body-indent = it.body-indent
  let numbering-pattern = it.numbering
  let connector = resolve-connector-state(settings.connector)
  let post-numbering = settings.post-numbering

  set par(spacing: item-spacing)

  block-indent-enum-counter.step()
  let prefix = "_block-indent-enum-" + str(block-indent-enum-counter.get().first()) + "-"

  set par(spacing: item-spacing, first-line-indent: 0em)
  let start = if it.start != auto {
    it.start
  } else if (
    it.children.first().has("number") and it.children.first().number != auto
  ) {
    it.children.first().number
  } else if it.reversed {
    it.children.len()
  } else {
    1
  }

  let delta = if it.reversed { -1 } else { 1 }
  let number = start
  let grid-parts = ()
  for (i, child) in it.children.enumerate() {
    number = if child.has("number") and child.number != auto {
      child.number
    } else {
      number
    }
    let num = numbering(numbering-pattern, ..parents.get(), number)
    num = if settings.post-numbering != none { post-numbering(num) } else { num }
    num += h(body-indent)
    let body = {
      parents.update(arr => arr + (number,))
      child.body
      parents.update(arr => arr.slice(0, -1))
    }
    number += delta
    grid-parts += render-block-indent-row(
      prefix,
      i,
      num,
      body,
      indent,
      settings.numbering-align,
      connector.enabled,
      connector.position,
      connector.stroke,
      i < it.children.len() - 1,
    )
  }

  let connector-left-gap-width = if connector.enabled { indent - connector.position } else { indent }
  let connector-right-gap-width = if connector.enabled { connector.position } else { 0pt }
  let columns = (
    connector-left-gap-width,
    0pt,
    connector-right-gap-width,
    1fr,
  )
  let rows = ((0pt, auto, auto, item-spacing) * (it.children.len() - 1) + (0pt, auto, auto))
  grid(
    columns: columns,
    rows: rows,
    align: left + top,
    ..grid-parts,
  )
}

/// Render block-indent bullet lists using the same local grid template.
/// - settings (dictionary): Renderer settings for this style variant.
/// -> function
#let block-indent-list(settings) = it => context {
  let item-spacing = it.spacing
  let indent = it.indent
  let body-indent = it.body-indent
  let marker-pattern = it.marker
  let connector = resolve-connector-state(settings.connector)
  let marker-align = settings.marker-align

  block-indent-list-counter.step()
  let prefix = "_block-indent-list-" + str(block-indent-list-counter.get().first()) + "-"

  let level = parents.get().len()
  let marker = if type(marker-pattern) == array {
    marker-pattern.at(calc.rem-euclid(level, marker-pattern.len()))
  } else if type(marker-pattern) == function {
    marker-pattern(level)
  } else {
    marker-pattern
  }

  marker += h(body-indent)

  set par(spacing: item-spacing, first-line-indent: 0em)
  let grid-parts = ()
  for (i, child) in it.children.enumerate() {
    let body = {
      parents.update(arr => arr + (0,))
      child.body
      parents.update(arr => arr.slice(0, -1))
    }
    grid-parts += render-block-indent-row(
      prefix,
      i,
      marker,
      body,
      indent,
      marker-align,
      connector.enabled,
      connector.position,
      connector.stroke,
      i < it.children.len() - 1,
    )
  }
  let connector-left-gap-width = if connector.enabled { indent - connector.position } else { indent }
  let connector-right-gap-width = if connector.enabled { connector.position } else { 0pt }
  let columns = (
    connector-left-gap-width,
    0pt,
    connector-right-gap-width,
    1fr,
  )
  let rows = ((0pt, auto, auto, item-spacing) * (it.children.len() - 1) + (0pt, auto, auto))
  grid(
    columns: columns,
    rows: rows,
    align: left + top,
    ..grid-parts,
  )
}

/// Dispatch table keyed by renderer type name.
#let renderers = (
  block-indent: (
    enum: block-indent-enum,
    list: block-indent-list,
  ),
  first-line-indent: (
    enum: firstline-indent-enum,
    list: firstline-indent-list,
  ),
)
