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