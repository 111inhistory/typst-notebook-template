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
    line(length: length, angle: 90deg, stroke: segment.value.at("stroke")),
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
  let trim = compute-trimmed-segment(
    segment-base,
    desired-top-trim,
    desired-bottom-trim,
  )
  let segment-dy = if trim.length > 0pt {
    -segment-base + trim.top-trim
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
  let tail-trim = compute-trimmed-segment(
    tail-segment-base,
    desired-top-trim,
    desired-bottom-trim,
  )

  let overlay = place(
    top + left,
    render-block-prefix(prefix, prefix-width, alignment),
  )
  if connector.enabled and trim.length > 0pt {
    overlay += place(
      top + left,
      dx: connector-x,
      dy: segment-dy,
      line(length: trim.length, angle: 90deg, stroke: connector.stroke),
    )
  }
  if connector.enabled and tail-trim.length > 0pt {
    overlay += place(
      top + left,
      dx: connector-x,
      dy: tail-trim.top-trim,
      line(length: tail-trim.length, angle: 90deg, stroke: connector.stroke),
    )
  }

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
