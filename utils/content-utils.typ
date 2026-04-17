#import "utils.typ": *

#let sequence = [].func()
#let styled = text(red, "").func()
#let space = [ ].func()

#let slice-text-content(elem, start: 0, end: -1) = {
  if type(elem) == content {
    if elem.func() == sequence {
      let ret = slice-text-content(elem)
    }
  } else {
    return none
  }
}

/// Receives a content element, returns the first paragraph as `first` and the rest of the content as `rest`.
/// If the first paragraph is the only content, `rest` will be `none`.
/// - body (sequence): The content to be split.
/// -> dictionary
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
    // Tight nested lists are emitted as trailing `item` nodes without a parbreak.
    let starts-rest = part.func() == parbreak or repr(part.func()) == "item"
    if not reached-rest and starts-rest {
      reached-rest = true
      rest = if part.func() == parbreak { parbreak() } else { part }
    } else if reached-rest {
      rest += part
    } else {
      first += part
    }
  }

  (first: first, rest: rest)
}

/// Checks whether the given content contains any content whose func() equals the given func.
/// - body (content): The content to be checked.
/// - func (string): The function to look for.
/// -> boolean
#let has-func(body, func) = {
  if body.func() == sequence {
    for i in body.children {
      if has-func(i, func) {
        return true
      }
    }
  } else if body.func() == func {
    return true
  }
  return false
}
