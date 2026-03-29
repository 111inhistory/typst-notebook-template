#import "/modules/lists/connectors.typ": render-block-row

#let sequence = [].func()
#let parents = state("_list-enum-internal", ())
#let item-paths = state("_list-item-path", ())
#let block-indent-serial = state("_block-indent-serial", 0)

#let split-first-paragraph(body) = {
  if body.func() != sequence {
    return (
      first: body,
      rest: none,
    )
  }

  let first = []
  let rest = none
  let reached-rest = false

  for part in body.children {
    if not reached-rest and part.func() == parbreak {
      reached-rest = true
      rest = parbreak()
    } else if reached-rest {
      rest += part
    } else {
      first += part
    }
  }

  (
    first: first,
    rest: rest,
  )
}

#let resolve-enum-number(child, fallback) = if child.has("number") and child.number != auto {
  child.number
} else {
  fallback
}

#let render-number(settings, pattern, values) = (settings.at("post-numbering"))(
  numbering(pattern, ..values),
)

#let firstline-indent-enum(settings) = it => context {
  let spacing = it.body-indent
  let par-indent = it.indent
  let indent = settings.indentation
  let numbering-pattern = it.numbering
  let numbering-align = settings.numbering-align

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
  for child in it.children {
    number = resolve-enum-number(child, number)
    let split = split-first-paragraph(child.body)
    let num = render-number(settings, numbering-pattern, parents.get() + (number,))
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
                h(spacing)
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
  let ret = []
  for child in it.children {
    let split = split-first-paragraph(child.body)
    let left-back-len = if marker-align == "right" {
      spacing + measure(marker).width
    } else {
      indent - spacing
    }
    let body = if it.tight {
      text(
        {
          h(par-indent)
          h(-left-back-len)
          marker
          h(spacing)
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
                h(spacing)
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

#let block-indent-enum(settings) = it => context {
  let spacing = it.body-indent
  let par-indent = it.indent
  let indent = settings.indentation
  let numbering-pattern = it.numbering
  let numbering-align = settings.numbering-align
  let connector = settings.connector
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
    number = resolve-enum-number(child, number)
    let num = render-number(settings, numbering-pattern, parents.get() + (number,))
    let body = {
      parents.update(arr => arr + (number,))
      item-paths.update(arr => arr + (i,))
      child.body
      item-paths.update(arr => arr.slice(0, -1))
      parents.update(arr => arr.slice(0, -1))
    }
    number += delta
    ret += render-block-row(
      num,
      prefix-width,
      numbering-align,
      indent,
      body,
      connector,
      prev-anchor-id,
      current-anchor-id,
      tail-anchor-id,
    ) + parbreak()
  }
  ret
}

#let block-indent-list(settings) = it => context {
  let spacing = it.body-indent
  let par-indent = it.indent
  let indent = settings.indentation
  let marker-pattern = it.marker
  let connector = settings.connector
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
    ret += render-block-row(
      marker,
      prefix-width,
      marker-align,
      indent,
      body,
      connector,
      prev-anchor-id,
      current-anchor-id,
      tail-anchor-id,
    ) + parbreak()
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
    number = resolve-enum-number(child, number)
    let num = render-number(settings, numbering-pattern, parents.get() + (number,))
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

#let renderer-table = (
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
