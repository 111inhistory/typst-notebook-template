/// An enhanced list/enum styling module for Typst, providing more accurate numbering alignment, flexible connector rendering, and improved support for loose lists.
/// Labels share the first body line's baseline and page break.
#import "/utils/numbly-utils.typ": partial-display
#import "/utils/common.typ": merge-dict, modify-dict
#import "/utils/content-utils.typ": sequence, split-first-paragraph
#import "/utils/terms-data.typ" as terms-data

/// Default connector settings for block-indent rendering.
/// `position` is measured from the body-side edge of the indent area.
/// A value of `0pt` places the connector right next to the body column.
/// The indent area includes indentation, label width, and body-indent.
#let default-connector-settings = (
  enabled: false,
  position: 0.9em,
  foot-width: 0.5em,
  threshold: 0.5em,
  stroke: stroke(paint: luma(65%), thickness: 0.75pt, dash: (array: (4pt, 5pt), phase: 4pt)),
  foot-stroke: stroke(paint: luma(65%), thickness: 0.75pt, cap: "round", dash: none),
)

/// Global default settings for list styling.
/// Block-indent accepts fixed number-width / marker-width, excluding body-indent.
/// `auto` measures labels; first-line-indent keeps its original indentation model.
/// overload: false keeps native rendering; true selects block-indent; strings select a renderer.
#let default-list-settings = (
  enum: (
    numbering: partial-display("{1}.{2}.{3}.{4}."),
    post-numbering: none,
    full: false,
    tight: (
      overload: true,
      spacing: 0.65em,
      indentation: 2em,
      body-indent: 0.5em,
      number-width: auto,
      number-align: end,
      connector: default-connector-settings,
    ),
    loose: (
      overload: "first-line-indent",
      spacing: 1em,
      indentation: 2em,
      body-indent: 0.5em,
      number-width: auto,
      number-align: end,
    ),
  ),
  list: (
    marker: ([•], [‣], [–]),
    tight: (
      overload: true,
      spacing: 0.65em,
      indentation: 2em,
      body-indent: 0.5em,
      marker-width: auto,
      marker-align: end,
      connector: default-connector-settings,
    ),
    loose: (
      overload: "first-line-indent",
      spacing: 1em,
      indentation: 2em,
      body-indent: 0.5em,
      marker-width: auto,
      marker-align: end,
    ),
  ),
)

/// Only logical start/end are supported; vertical components are discarded.
/// Other alignment values (including center) are ignored and fall back to end.
#let normalize-label-align(value) = {
  assert(type(value) == alignment, message: "Label alignment must be an alignment value.")
  if value.x in (start, end) { value.x } else { end }
}

/// Normalize optional connector settings and atomic native stroke values.
#let normalize-connector(connector) = {
  if connector == none {
    return none
  }
  let connector = merge-dict(default-connector-settings, connector)
  // Strokes are atomic styles, not recursively merged configuration dictionaries.
  for key in ("stroke", "foot-stroke") {
    if connector.at(key) != none {
      connector.at(key) = stroke(connector.at(key))
    }
  }
  connector
}

/// Map one namespace to the native fields applied before show transformations.
#let build-set-settings(kind, settings) = {
  let fields = (
    indent: settings.indentation,
    spacing: settings.spacing,
    body-indent: settings.body-indent,
  )
  let align-key = if kind == "enum" { "number-align" } else { "marker-align" }
  fields.insert(align-key, normalize-label-align(settings.at(align-key)))
  fields
}

#let build-render-settings(kind, settings) = {
  let align-key = if kind == "enum" { "number-align" } else { "marker-align" }
  let width-key = if kind == "enum" { "number-width" } else { "marker-width" }
  let fields = (
    overload: settings.overload,
    label-width: settings.at(width-key),
    connector: normalize-connector(settings.at("connector", default: none)),
    post-numbering: settings.at("post-numbering", default: none),
  )
  fields.insert(align-key, normalize-label-align(settings.at(align-key)))
  fields
}

#let register-variant(kind, tight, defaults) = terms-data.register(
  kind + if tight { "-tight" } else { "-loose" },
  defaults: defaults,
  apply: settings => {
    if kind == "enum" {
      assert(
        settings.post-numbering == none or type(settings.post-numbering) == function,
        message: "`post-numbering` must be a function or none.",
      )
    }
    let fields = build-set-settings(kind, settings)
    let element = if kind == "enum" { enum } else { list }
    doc => {
      show element.where(tight: tight): set element(..fields)
      doc
    }
  },
)

// Tracks the current parent numbering path.
// `enum` stores real numbers, while `list` uses `0` as a placeholder.
#let parents = state("__list-enum-internal", ())

/// Collect tight nested item nodes and rebuild them as an explicit container.
#let tight-rest(rest, kind) = {
  if rest == none {
    return none
  }

  let items = ()
  if repr(rest.func()) == "item" {
    items.push(rest)
  } else if rest.func() == sequence {
    for part in rest.children {
      if repr(part.func()) == "item" {
        items.push(part)
      } else if part.func() != [ ].func() {
        return rest
      }
    }
  } else {
    return rest
  }

  if items.len() == 0 {
    return none
  }

  if kind == "enum" {
    enum(..items.map(item => enum.item(item.body)))
  } else {
    list(..items.map(item => list.item(item.body)))
  }
}

/// Render first-line-indent lists and enums without a grid layout.
#let first-line-indent(kind, settings) = it => context {
  let item-spacing = it.spacing
  let indent = it.indent
  let body-indent = it.body-indent
  let marker = none
  let number = none
  let delta = 1
  let level = parents.get().len() + 1

  set par(spacing: item-spacing, first-line-indent: 0em)

  if kind == "list" {
    let marker-level = level - 1
    let pattern = it.marker
    marker = if type(pattern) == array {
      pattern.at(calc.rem-euclid(marker-level, pattern.len()))
    } else if type(pattern) == function {
      pattern(marker-level)
    } else {
      pattern
    }
  } else {
    number = if it.start != auto {
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
    delta = if it.reversed { -1 } else { 1 }
  }

  let ret = []
  for child in it.children {
    let parent-part = if kind == "enum" {
      number = if child.has("number") and child.number != auto {
        child.number
      } else {
        number
      }
      let num = numbering(it.numbering, ..parents.get(), number)
      if settings.post-numbering != none {
        num = (settings.post-numbering)(num)
      }
      num
    } else {
      marker
    }

    let align = if kind == "enum" {
      settings.number-align
    } else {
      settings.marker-align
    }
    let left-back-len = if align == end {
      body-indent + measure(parent-part).width
    } else {
      indent - body-indent
    }

    let child-parent = if kind == "enum" { number } else { 0 }
    let split = split-first-paragraph(child.body)
    let body = if it.tight {
      {
        // Tight children are emitted as bare item nodes by Typst.
        parents.update(arr => arr + (child-parent,))
        text(
          {
            h(indent)
            h(-left-back-len)
            parent-part
            h(body-indent)
            split.first
          },
          cjk-latin-spacing: none,
        )
        tight-rest(split.rest, kind)
        parents.update(arr => arr.slice(0, -1))
      }
    } else {
      {
        parents.update(arr => arr + (child-parent,))
        par(
          first-line-indent: (all: true, amount: indent),
        )[
          #set text(cjk-latin-spacing: none)
          #{
            h(-left-back-len)
            parent-part
            h(body-indent)
            split.first
          }
        ]
        set par(first-line-indent: (amount: indent, all: true))
        split.rest
        parents.update(arr => arr.slice(0, -1))
      }
    }

    if kind == "enum" {
      number += delta
    }
    if level > 1 {
      ret += pad(left: indent, body) + parbreak()
    } else {
      ret += body + parbreak()
    }
  }
  ret
}

/// Render block-indent lists and enums using one local grid template.
#let block-indent(kind, settings) = it => context {
  let item-spacing = it.spacing
  let indent = it.indent
  let body-indent = it.body-indent
  let connector = if settings.connector == none {
    (enabled: false, position: 0pt, stroke: none)
  } else {
    settings.connector
  }

  let stem-stroke = if connector.enabled { connector.stroke } else { none }
  let foot-padding = if (
    stem-stroke != none and connector.foot-stroke != none
      and stem-stroke.cap in ("square", "round")
  ) {
    if stem-stroke.thickness == auto { 1pt } else { stem-stroke.thickness }
  } else { 0pt }

  let marker = none
  let number = none
  let delta = 1
  if kind == "list" {
    let level = parents.get().len()
    let pattern = it.marker
    marker = if type(pattern) == array {
      pattern.at(calc.rem-euclid(level, pattern.len()))
    } else if type(pattern) == function {
      pattern(level)
    } else {
      pattern
    }
  } else {
    number = if it.start != auto {
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
    delta = if it.reversed { -1 } else { 1 }
  }

  // Location-scoped anchors stay stable when threshold queries trigger relayout.
  let instance = here()
  let anchor-value(kind, index) = (instance: instance, kind: kind, index: index)
  let create-anchor(kind, index) = metadata(anchor-value(kind, index))
  let anchor-pos(kind, index) = {
    let matches = query(metadata.where(value: anchor-value(kind, index)))
    if matches.len() == 0 { none } else { matches.first().location().position() }
  }
  let body-create(i) = create-anchor("baseline", i)
  let body-pos(i) = anchor-pos("baseline", i)
  let bottom-create(i) = create-anchor("bottom", i)
  let bottom-pos(i) = anchor-pos("bottom", i)

  set par(spacing: item-spacing, first-line-indent: 0em)

  let rows-per-item = if connector.enabled { 6 } else { 4 }
  // Fixed label widths exclude body-indent and do not grow for longer labels.
  let fixed-width = settings.label-width != auto
  if fixed-width {
    assert(settings.label-width.to-absolute() >= 0pt, message: "Label width must be non-negative.")
  }
  let label-width = if fixed-width { settings.label-width + body-indent } else { 0pt }
  let label-align = if kind == "enum" { settings.number-align } else { settings.marker-align }
  // Resolve the widest label before placing any zero-width prefixes.
  let items = ()
  for child in it.children {
    let parent-part = if kind == "enum" {
      number = if child.has("number") and child.number != auto {
        child.number
      } else {
        number
      }
      let num = numbering(it.numbering, ..parents.get(), number)
      if settings.post-numbering != none {
        num = (settings.post-numbering)(num)
      }
      num
    } else {
      marker
    }
    let label = if fixed-width {
      box(width: settings.label-width, align(label-align, parent-part))
    } else {
      parent-part
    } + h(body-indent)
    if not fixed-width {
      label-width = calc.max(label-width, measure(label).width)
    }
    items.push((child: child, label: label, parent: if kind == "enum" { number } else { 0 }))
    if kind == "enum" {
      number += delta
    }
  }

  let cells = ()
  for (i, item) in items.enumerate() {
    let child = item.child
    let body = {
      parents.update(arr => arr + (item.parent,))
      let split = split-first-paragraph(child.body)
      // The zero-width label shares the first line's baseline and page break.
      let prefix = box(width: 0pt, {
        h(-label-width)
        box(width: label-width, align(if fixed-width { end } else { label-align }, item.label))
      })
      text(prefix + split.first, top-edge: "ascender")
      split.rest
      parents.update(arr => arr.slice(0, -1))
    }

    cells.push(grid.cell(colspan: 5, inset: 0pt)[])
    cells.push(grid.cell(colspan: 4, inset: 0pt)[])
    cells.push(grid.cell(rowspan: if connector.enabled { 3 } else { 2 }, inset: 0pt, align: start + top)[
      #set text(cjk-latin-spacing: none)
      #sym.zws#body-create(i)#body
    ])
    for _ in range(4) {
      cells.push(grid.cell(inset: 0pt)[])
    }
    if connector.enabled {
      // Cap clearance is inside the body span, so nested feet share the body bottom.
      for _ in range(4) {
        cells.push(grid.cell(inset: 0pt)[])
      }
      cells.push(grid.cell(colspan: 5, inset: 0pt, align: start + top)[#bottom-create(i)])
      let baseline = body-pos(i)
      let bottom = bottom-pos(i)
      // Anchors become available after this context has emitted its first layout.
      let visible = if baseline == none or bottom == none {
        false
      } else {
        (
          baseline.page != bottom.page
            or bottom.y - baseline.y > connector.threshold.to-absolute()
        )
      }
      // Visibility affects strokes only, so anchor positions remain stable.
      cells.push(grid.vline(
        x: 2,
        start: rows-per-item * i + 2,
        end: rows-per-item * i + 3,
        stroke: if visible { connector.stroke } else { none },
      ))
      if connector.foot-stroke != none {
        cells.push(grid.hline(
          y: rows-per-item * i + 4,
          start: 1,
          end: 3,
          stroke: if visible { connector.foot-stroke } else { none },
        ))
      }
    }

    if i < it.children.len() - 1 {
      cells.push(grid.cell(colspan: 5, inset: 0pt)[#parbreak()#sym.zws])
    }
  }

  // Native indent precedes the label; body-indent follows it.
  let body-offset = indent + label-width
  let left-gap = if connector.enabled {
    body-offset - connector.position
  } else {
    body-offset
  }
  let right-gap = if connector.enabled { connector.position } else { 0pt }
  let half-foot = if connector.enabled { connector.foot-width.to-absolute() / 2 } else { 0pt }
  assert(half-foot >= 0pt, message: "connector.foot-width must be non-negative.")
  // Clip the foot to the indent area when the stem is near either edge.
  let left-foot = calc.min(half-foot, left-gap.to-absolute())
  let right-foot = calc.min(half-foot, right-gap.to-absolute())
  grid(
    columns: (left-gap - left-foot, left-foot, right-foot, right-gap - right-foot, 1fr),
    rows: {
      let item-rows = if connector.enabled { (0pt, auto, auto, foot-padding, 0pt) } else { (0pt, auto, auto) }
      (item-rows + (item-spacing,)) * (it.children.len() - 1) + item-rows
    },
    align: start + top,
    ..cells,
  )
}

/// false preserves native rendering; true selects the grid renderer.
#let resolve-list-renderer(overload) = {
  assert(
    overload in (false, true, "block-indent", "first-line-indent"),
    message: "`overload` must be false, true, block-indent, or first-line-indent.",
  )
  if overload == false {
    none
  } else if overload == "first-line-indent" {
    first-line-indent
  } else {
    block-indent
  }
}

/// Returning the original element for false preserves its show guard and native layout.
#let render-list(kind, it) = terms-data.get(
  kind + if it.tight { "-tight" } else { "-loose" },
  settings => {
    let renderer = resolve-list-renderer(settings.overload)
    if renderer == none {
      it
    } else {
      renderer(kind, build-render-settings(kind, settings))(it)
    }
  },
)

/// Install once; local changes use set_("list-tight", ..), and the other three variants.
#let better-lists(settings) = doc => {
  let resolved = modify-dict(default-list-settings, settings)
  let variant(kind, tight) = {
    let base = resolved.at(kind)
    let settings = base.at(if tight { "tight" } else { "loose" })
    if kind == "enum" {
      settings.insert("post-numbering", base.post-numbering)
    }
    if "connector" in settings {
      settings.connector = normalize-connector(settings.connector)
    }
    settings
  }

  set enum(numbering: resolved.enum.numbering, full: resolved.enum.full)
  set list(marker: resolved.list.marker)

  show: register-variant("list", true, variant("list", true))
  show: register-variant("list", false, variant("list", false))
  show: register-variant("enum", true, variant("enum", true))
  show: register-variant("enum", false, variant("enum", false))

  show list: it => render-list("list", it)
  show enum: it => render-list("enum", it)
  doc
}
