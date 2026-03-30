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
    if not reached-rest and part.func() == parbreak {
      reached-rest = true
      rest = parbreak()
    } else if reached-rest {
      rest += part
    } else {
      first += part
    }
  }

  (first: first, rest: rest)
}
