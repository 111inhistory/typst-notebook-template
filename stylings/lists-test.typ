#import "/utils/numbly-utils.typ": *
#import "/utils/utils.typ": *
#import "/utils/content-utils.typ": *

#let parents = state("_list-enum-internal", ())
#let item-paths = state("_list-item-path", ())
#let block-indent-serial = state("_block-indent-serial", 0)
#let page-frame = (
  width: 210mm,
  height: 297mm,
  margin: (
    top: 2.5cm,
    bottom: 2.5cm,
    left: 2.5cm,
    right: 2.5cm,
  ),
)
#let default-block-connector = (
  enabled: false,
  offset: 0.5em,
  top-trim: 1.25em,
  bottom-trim: 0.25em,
  tail-length: 1em,
  // TODO: Typst doesn't expose the actual inter-item paragraph gap here.
  // Keep this as an explicit placeholder for future manual tuning.
  after-gap: 0pt,
  stroke: (paint: luma(80%), thickness: 0.5pt, dash: "dotted"),
)

#let resolve-block-connector(settings) = merge-dict(
  default-block-connector,
  settings.at("connector", default: (:)),
)

#let resolve-length(length) = measure(v(length)).height

#let compute-trimmed-segment(base, desired-top-trim, desired-bottom-trim) = {
  let min-segment-length = resolve-length(0.2em)
  let desired-trim = desired-top-trim + desired-bottom-trim
  let trim-budget = if base > min-segment-length {
    base - min-segment-length
  } else {
    0pt
  }
  let trim-scale = if desired-trim > 0pt and trim-budget < desired-trim {
    trim-budget / desired-trim
  } else {
    1
  }
  let top-trim = desired-top-trim * trim-scale
  let bottom-trim = desired-bottom-trim * trim-scale
  let length = if base > top-trim + bottom-trim {
    base - top-trim - bottom-trim
  } else {
    0pt
  }
  (
    top-trim: top-trim,
    bottom-trim: bottom-trim,
    length: length,
  )
}

#let render-block-prefix(prefix, width, alignment) = box(width: width)[
  #align(
    if alignment == "right" { top + right } else { top + left },
    prefix,
  )
]

#let make-loc-anchor(id) = metadata(id)

#let make-tail-anchor(id, amount) = {
  if id != none {
    [
      #linebreak()
      #make-loc-anchor(id)
      #v(-amount)
    ]
  }
}

#let find-anchor-position(id) = {
  let pos = none
  for item in query(metadata) {
    if item.value == id {
      pos = item.location().position()
      break
    }
  }
  pos
}

#let make-cross-page-segment(start-id, end-id, connector-x, connector) = {
  metadata((
    kind: "block-connector-segment",
    start: start-id,
    end: end-id,
    x: connector-x,
    stroke: connector.stroke,
    top-trim: resolve-length(connector.top-trim),
    bottom-trim: resolve-length(connector.bottom-trim),
  ))
}

#let render-cross-page-segment(segment, current-page) = {
  let start-pos = find-anchor-position(segment.value.at("start"))
  let end-pos = find-anchor-position(segment.value.at("end"))
  if start-pos == none or end-pos == none or start-pos.page == end-pos.page {
    return none
  }
  if current-page < start-pos.page or current-page > end-pos.page {
    return none
  }
  let body-top = page-frame.margin.top
  let body-bottom = page-frame.height - page-frame.margin.bottom

  let start-y = if current-page == start-pos.page {
    calc.max(start-pos.y + segment.value.at("top-trim"), body-top)
  } else {
    body-top
  }
  let end-y = if current-page == end-pos.page {
    calc.min(end-pos.y - segment.value.at("bottom-trim"), body-bottom)
  } else {
    body-bottom
  }
  let length = if end-y > start-y { end-y - start-y } else { 0pt }
  if length <= 0pt {
    return none
  }

  place(
    top + left,
    dx: start-pos.x + segment.value.at("x"),
    dy: start-y,
    line(length: length, angle: 90deg, stroke: 2pt + red),
  )
}

#let draw-cross-page-connectors() = context {
  let current-page = counter(page).get().first()
  let overlay = []
  for item in query(metadata) {
    if type(item.value) == dictionary and item.value.at("kind", default: none) == "block-connector-segment" {
      overlay += render-cross-page-segment(item, current-page)
    }
  }
  overlay
}

#let render-block-row(
  prefix,
  prefix-width,
  alignment,
  indent,
  body,
  connector,
  prev-anchor-id,
  current-anchor-id,
  tail-anchor-id,
) = context {
  let body-block = pad(left: indent, body)
  let connector-x = resolve-length(indent) - resolve-length(connector.offset)
  let desired-top-trim = resolve-length(connector.top-trim)
  let desired-bottom-trim = resolve-length(connector.bottom-trim)
  let current-pos = here().position()
  let segment-base = if prev-anchor-id != none {
    let prev-pos = find-anchor-position(prev-anchor-id)
    if prev-pos != none and current-pos.page == prev-pos.page and current-pos.y > prev-pos.y {
      current-pos.y - prev-pos.y + resolve-length(connector.after-gap)
    } else {
      0pt
    }
  } else {
    0pt
  }
  let trim = compute-trimmed-segment(segment-base, desired-top-trim, desired-bottom-trim)
  let top-trim = trim.top-trim
  let bottom-trim = trim.bottom-trim
  let segment-length = trim.length
  let segment-dy = if segment-length > 0pt {
    -segment-base + top-trim
  } else {
    0pt
  }
  let tail-segment-base = if tail-anchor-id != none {
    let tail-pos = find-anchor-position(tail-anchor-id)
    if tail-pos != none and tail-pos.page == current-pos.page and tail-pos.y > current-pos.y {
      tail-pos.y - current-pos.y + resolve-length(connector.after-gap)
    } else {
      0pt
    }
  } else {
    0pt
  }
  let tail-trim = compute-trimmed-segment(tail-segment-base, desired-top-trim, desired-bottom-trim)
  let tail-top-trim = tail-trim.top-trim
  let tail-segment-length = tail-trim.length
  let overlay-content = place(top + left, render-block-prefix(prefix, prefix-width, alignment))
  if connector.enabled and segment-length > 0pt {
    overlay-content += place(
      top + left,
      dx: connector-x,
      dy: segment-dy,
      line(length: segment-length, angle: 90deg, stroke: connector.stroke),
    )
  }
  if connector.enabled and tail-segment-length > 0pt {
    overlay-content += place(
      top + left,
      dx: connector-x,
      dy: tail-top-trim,
      line(length: tail-segment-length, angle: 90deg, stroke: connector.stroke),
    )
  }
  let overlay = overlay-content

  block(width: 100%)[
    #overlay
    #make-loc-anchor(current-anchor-id)
    #if connector.enabled and prev-anchor-id != none [
      #make-cross-page-segment(prev-anchor-id, current-anchor-id, connector-x, connector)
    ]
    #body-block
    #make-tail-anchor(tail-anchor-id, connector.tail-length)
    #if connector.enabled and tail-anchor-id != none [
      #make-cross-page-segment(current-anchor-id, tail-anchor-id, connector-x, connector)
    ]
  ]
}

#let firstline-indent-enum(settings) = it => context {
  let spacing = it.body-indent
  let par-indent = it.indent
  let indent = settings.indentation
  let numbering-pattern = it.numbering
  let numbering-align = settings.numbering-align

  set par(spacing: par-indent, first-line-indent: 0em)
  // traverse the children to create the content using paragraph
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
  let ret = []
  for child in it.children {
    number = if child.has("number") and child.number != auto {
      child.number
    } else { number }
    // find the first paragraph of the child body, then just modify the settings of the first paragraph
    let first-par = none
    let rest-body = none
    if child.body.func() == sequence {
      let idx = -1
      for (i, subcontent) in child.body.children.enumerate() {
        if subcontent.func() == parbreak {
          idx = i
          break
        }
      }
      if idx != -1 {
        if idx > 0 {
          first-par = slice-text-content(child.body.children.at(0), end: idx)
        }
        for i in range(0, idx) {
          first-par += child.body.children.at(i)
        }
        rest-body = parbreak()
        for i in range(idx, child.body.children.len()) {
          rest-body += child.body.children.at(i)
        }
      } else {
        first-par = child.body
        rest-body = none
      }
    } else {
      first-par = child.body
    }
    let num = numbering(numbering-pattern, ..parents.get(), number)
    let left-back-len = if numbering-align == "right" {
      spacing + measure(num).width
    } else {
      indent - spacing
    }
    let body = if it.tight {
      text(
        {
          h(par-indent)
          h(-left-back-len)
          num
          h(spacing)
          first-par
        },
        cjk-latin-spacing: none,
      )
      rest-body
    } else {
      parents.update(arr => arr + (number,))
      {
        par(
          [
            #text(
              {
                h(-left-back-len)
                num
                h(spacing)
                first-par
              },
              cjk-latin-spacing: none,
            )
          ],
          first-line-indent: (all: true, amount: indent),
        )
        rest-body
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

#let firstline-indent-list(settings) = it => context {
  let spacing = it.body-indent
  let par-indent = it.indent
  let indent = settings.indentation
  let marker-pattern = it.marker

  set par(spacing: par-indent, first-line-indent: 0em)
  let level = parents.get().len()
  let marker = if type(marker-pattern) == array {
    marker-pattern.at(calc.rem-euclid(level, marker-pattern.len()))
  } else if type(marker-pattern) == function {
    marker-pattern(level)
  } else {
    marker-pattern
  }
  let marker-align = settings.marker-align
  // traverse the children to create the content using paragraph
  let ret = []
  for child in it.children {
    // find the first paragraph of the child body, then just modify the settings of the first paragraph
    let first-par = none
    let rest-body = none
    if child.body.func() == sequence {
      let idx = -1
      for (i, subcontent) in child.body.children.enumerate() {
        if subcontent.func() == parbreak {
          idx = i
          break
        }
      }
      if idx != -1 {
        for i in range(0, idx) {
          first-par += child.body.children.at(i)
        }
        rest-body = parbreak()
        for i in range(idx, child.body.children.len()) {
          rest-body += child.body.children.at(i)
        }
      } else {
        first-par = child.body
        rest-body = none
      }
    } else {
      first-par = child.body
    }
    let left-back-len = if marker-align == "right" {
      spacing + measure(marker).width
    } else {
      indent - spacing
    }
    let body = if it.tight {
      text(
        {
          h(it.indent)
          h(-left-back-len)
          marker
          h(spacing)
          first-par
        },
        cjk-latin-spacing: none,
      )
      rest-body
    } else {
      parents.update(arr => arr + (0,))
      {
        par(
          [
            #text(
              {
                h(-left-back-len)
                marker
                h(spacing)
                first-par
              },
              cjk-latin-spacing: none,
            )
          ],
          first-line-indent: (all: true, amount: indent),
        )
        rest-body
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

#let block-indent-enum(settings) = it => context {
  let spacing = it.body-indent
  let par-indent = it.indent
  let indent = settings.indentation
  let numbering-pattern = it.numbering
  let numbering-align = settings.numbering-align
  let connector = resolve-block-connector(settings)
  let post-numbering = settings.post-numbering
  let prefix-width = indent - spacing
  let serial = block-indent-serial.get()
  block-indent-serial.update(n => n + 1)

  set par(spacing: par-indent, first-line-indent: 0em)
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
  let ret = []
  for (i, child) in it.children.enumerate() {
    let path = item-paths.get() + (i,)
    let current-anchor-id = "block-enum-" + str(serial) + "-" + path.map(str).join("-")
    let tail-anchor-id = if i == it.children.len() - 1 {
      current-anchor-id + "-tail"
    } else {
      none
    }
    let prev-anchor-id = if i > 0 {
      "block-enum-" + str(serial) + "-" + (item-paths.get() + (i - 1,)).map(str).join("-")
    } else {
      none
    }
    number = if child.has("number") and child.number != auto {
      child.number
    } else { number }
    let num = post-numbering(numbering(numbering-pattern, ..parents.get(), number))
    let body = {
      parents.update(arr => arr + (number,))
      item-paths.update(arr => arr + (i,))
      child.body
      item-paths.update(arr => arr.slice(0, -1))
      parents.update(arr => arr.slice(0, -1))
    }
    number += delta
    let row = render-block-row(
      num,
      prefix-width,
      numbering-align,
      indent,
      body,
      connector,
      prev-anchor-id,
      current-anchor-id,
      tail-anchor-id,
    )
    ret += row + parbreak()
  }
  ret
}

#let block-indent-list(settings) = it => context {
  let spacing = it.body-indent
  let par-indent = it.indent
  let indent = settings.indentation
  let marker-pattern = it.marker
  let connector = resolve-block-connector(settings)
  let prefix-width = indent - spacing
  let serial = block-indent-serial.get()
  block-indent-serial.update(n => n + 1)

  let level = parents.get().len()
  let marker = if type(marker-pattern) == array {
    marker-pattern.at(calc.rem-euclid(level, marker-pattern.len()))
  } else if type(marker-pattern) == function {
    marker-pattern(level)
  } else {
    marker-pattern
  }
  let marker-align = settings.marker-align

  set par(spacing: par-indent, first-line-indent: 0em)
  let ret = []
  for (i, child) in it.children.enumerate() {
    let path = item-paths.get() + (i,)
    let current-anchor-id = "block-list-" + str(serial) + "-" + path.map(str).join("-")
    let tail-anchor-id = if i == it.children.len() - 1 {
      current-anchor-id + "-tail"
    } else {
      none
    }
    let prev-anchor-id = if i > 0 {
      "block-list-" + str(serial) + "-" + (item-paths.get() + (i - 1,)).map(str).join("-")
    } else {
      none
    }
    let body = {
      parents.update(arr => arr + (0,))
      item-paths.update(arr => arr + (i,))
      child.body
      item-paths.update(arr => arr.slice(0, -1))
      parents.update(arr => arr.slice(0, -1))
    }
    let row = render-block-row(
      marker,
      prefix-width,
      marker-align,
      indent,
      body,
      connector,
      prev-anchor-id,
      current-anchor-id,
      tail-anchor-id,
    )
    ret += row + parbreak()
  }
  ret
}

#let hanging-indent-enum(settings) = it => context {
  let spacing = it.body-indent
  let par-indent = it.indent
  let indent = settings.indentation
  let numbering-pattern = it.numbering
  let numbering-align = settings.numbering-align

  set par(spacing: par-indent)
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
  let ret = []
  for child in it.children {
    number = if child.has("number") and child.number != auto {
      child.number
    } else { number }
    let num = numbering(numbering-pattern, ..parents.get(), number)
    let left-back-len = if numbering-align == "right" {
      spacing + measure(num).width
    } else {
      indent - spacing
    }
    let body = {
      parents.update(arr => arr + (number,))
      {
        set par(hanging-indent: indent)
        text(
          {
            h(-left-back-len)
            num
            h(spacing)
            child.body
          },
          cjk-latin-spacing: none,
        )
      }
      parents.update(arr => arr.slice(0, -1))
    }
    number += delta
    if parents.get().len() > 0 {
      ret += h(indent) + body + linebreak()
    } else {
      ret += body + parbreak()
    }
  }
  ret
}

#let hanging-indent-list(settings) = it => context {
  let spacing = it.body-indent
  let par-indent = it.indent
  let indent = settings.indentation
  let marker-pattern = it.marker

  set par(spacing: par-indent)
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
    let left-back-len = if marker-align == "right" {
      spacing + measure(marker).width
    } else {
      indent - spacing
    }
    let body = {
      parents.update(arr => arr + (0,))
      {
        set par(hanging-indent: indent)
        text(
          {
            h(-left-back-len)
            marker
            h(spacing)
            child.body
          },
          cjk-latin-spacing: none,
        )
      }
      parents.update(arr => arr.slice(0, -1))
    }
    if parents.get().len() > 0 {
      ret += h(indent) + body + linebreak()
    } else {
      ret += body + parbreak()
    }
  }
  ret
}

#let type-dict = (
  hanging-indent: (
    enum: hanging-indent-enum,
    list: hanging-indent-list,
  ),
  block-indent: (
    enum: block-indent-enum,
    list: block-indent-list,
  ),
  first-line-indent: (
    enum: firstline-indent-enum,
    list: firstline-indent-list,
  ),
)

#let apply-enum-settings(settings) = doc => {
  show enum.where(tight: true): type-dict.at(settings.tight.at("type")).at("enum")(settings.tight)
  show enum.where(tight: false): type-dict.at(settings.loose.at("type")).at("enum")(settings.loose)
  doc
}

#let apply-list-settings(settings) = doc => {
  show list.where(tight: true): type-dict.at(settings.tight.at("type")).at("list")(settings.tight)
  show list.where(tight: false): type-dict.at(settings.loose.at("type")).at("list")(settings.loose)
  doc
}

// Configurable Aspects of lists or list-like:
// - whether is tight or not (and other parameters can be set separately)
// - numbering (numbered list only, recommend using `numbly` package)/marker (bulleted list only, either an array of content, a function from nesting level to content, or a single content)
// - fixed indentation
// - spacing between numbering/marker and the body
// - numbering/marker alignment (left, right)
// - indentation (hanging indent, block indent, first-line indent)
// - custom paragraph settings

#let default-settings = (
  enum: (
    numbering: partial-display("{1}.{2}.{3}.{4}."), // either a funciton, a string, or none for default numbering
    post-numbering: it => it, // function from computed numbering content to final display content
    full: false, // if full is true, eg. numbering("1.a)") will produce like "1.", "1.a)" or so
    tight: (
      type: "hanging-indent", // or "block-indent" or "first-line-indent"
      par-indent: 0.5em,
      indentation: 2em,
      spacing: 0.5em, // space between number and body
      numbering-align: "right", // or "left"
      connector: (
        enabled: false,
        offset: 0.5em,
        top-trim: 0.8em,
        bottom-trim: 0.5em,
        tail-length: 1em,
        after-gap: 0pt,
        stroke: (paint: luma(80%), thickness: 0.5pt, dash: "dotted"),
      ),
    ),
    loose: (
      type: "first-line-indent", // or "block-indent" or "hanging-indent"
      par-indent: 1.2em,
      indentation: 2em,
      spacing: 0.5em, // space between number and body
      numbering-align: "right", // or "left"
      // connector: (
      //   enabled: false,
      //   offset: 0.5em,
      //   top-trim: 0.8em,
      //   bottom-trim: 0.5em,
      //   tail-length: 1em,
      //   after-gap: 0pt,
      //   stroke: (paint: luma(80%), thickness: 0.5pt, dash: "dotted"),
      // ),
    ),
  ),
  list: (
    marker: ([•], [‣], [–]), // either an array of content, a function from nesting level to content, or a single content, or none for default marker
    tight: (
      type: "hanging-indent", // or "block-indent" or "first-line-indent"
      par-indent: 0.5em,
      indentation: 2em,
      spacing: 0.5em, // space between number and body
      marker-align: "right", // or "left"
      connector: (
        enabled: false,
        offset: 0.5em,
        top-trim: 0.8em,
        bottom-trim: 0.5em,
        tail-length: 1em,
        after-gap: 0pt,
        stroke: (paint: luma(80%), thickness: 0.5pt, dash: "dotted"),
      ),
    ),
    loose: (
      type: "first-line-indent", // or "block-indent" or "hanging-indent"
      par-indent: 1.2em,
      indentation: 2em,
      spacing: 0.5em, // space between number and body
      marker-align: "right", // or "left"
      // connector: (
      //   enabled: false,
      //   offset: 0.5em,
      //   top-trim: 0.8em,
      //   bottom-trim: 0.5em,
      //   tail-length: 1em,
      //   after-gap: 0pt,
      //   stroke: (paint: luma(80%), thickness: 0.5pt, dash: "dotted"),
      // ),
    ),
  ),
)

#let apply-settings(settings) = doc => {
  // Some settings should be set as the property of the list/enum element, and some settings should be passed
  // to the child function of customize the style of enums and lists
  let setting = merge-dict(default-settings, settings)
  if type(setting.enum.at("post-numbering")) != function {
    panic("`enum.post-numbering` must be a function.")
  }
  set enum(
    numbering: setting.enum.at("numbering"),
    full: setting.enum.at("full"),
  )
  set list(
    marker: setting.list.at("marker"),
  )
  show list.where(tight: true): set list(
    indent: setting.list.tight.at("par-indent"),
    body-indent: setting.list.tight.at("spacing"),
  )
  show list.where(tight: false): set list(
    indent: setting.list.loose.at("par-indent"),
    body-indent: setting.list.loose.at("spacing"),
  )
  show enum.where(tight: true): set enum(
    indent: setting.enum.tight.at("par-indent"),
    body-indent: setting.enum.tight.at("spacing"),
  )
  show enum.where(tight: false): set enum(
    indent: setting.enum.loose.at("par-indent"),
    body-indent: setting.enum.loose.at("spacing"),
  )
  // export the settings that should be passed to the factory function of the customized list/enum style
  let ret-enum-settings = (
    tight: (
      type: setting.enum.tight.at("type"),
      numbering-align: setting.enum.tight.at("numbering-align"),
      indentation: setting.enum.tight.at("indentation"),
      connector: setting.enum.tight.at("connector"),
      post-numbering: setting.enum.at("post-numbering"),
    ),
    loose: (
      type: setting.enum.loose.at("type"),
      numbering-align: setting.enum.loose.at("numbering-align"),
      indentation: setting.enum.loose.at("indentation"),
      connector: setting.enum.loose.at("connector"),
      post-numbering: setting.enum.at("post-numbering"),
    ),
  )
  let ret-list-settings = (
    tight: (
      type: setting.list.tight.at("type"),
      marker-align: setting.list.tight.at("marker-align"),
      indentation: setting.list.tight.at("indentation"),
      connector: setting.list.tight.at("connector"),
    ),
    loose: (
      type: setting.list.loose.at("type"),
      marker-align: setting.list.loose.at("marker-align"),
      indentation: setting.list.loose.at("indentation"),
      connector: setting.list.loose.at("connector"),
    ),
  )
  show: apply-list-settings(ret-list-settings)
  show: apply-enum-settings(ret-enum-settings)
  set page(foreground: draw-cross-page-connectors())
  doc
}
