#import "/utils/content-utils.typ": *

#let equation-type = state("__equation-type", none)
#let equation-has-label = state("__equation-has-label", true)

/// Store local math hook state in `terms.separator`.
/// Source: https://forum.typst.app/t/how-to-detect-a-paragraph-break/5072
#let math-state-marker(state) = metadata((__notebook-math-hook-state: state))

#let math-state-from(separator) = {
  if (
    separator.func() == metadata
      and "__notebook-math-hook-state" in separator.value
  ) {
    return separator.value.__notebook-math-hook-state
  }
  (:)
}

#let math-state-with(separator, ..updates) = {
  let state = math-state-from(separator)
  for (key, value) in updates.named().pairs() {
    state.insert(key, value)
  }
  math-state-marker(state)
}

/// Render nested fractions with improved readability.
#let v-h-frac(it) = context {
  let original-separator = terms.separator
  let state = math-state-from(original-separator)
  let depth = state.at("frac-depth", default: 0)
  show <__math-frac-depth-stop>: set terms(separator: math-state-with(
    terms.separator,
    frac-depth: calc.min(depth + 1, 3),
  ))
  [
    #context {
      let current-state = math-state-from(terms.separator)
      set terms(separator: original-separator)
      if current-state.at("frac-depth", default: none) == none {
        let is-nested = (
          has-func(it.num, math.frac) or has-func(it.denom, math.frac)
        )
        let style = if depth == 0 or is-nested { "vertical" } else {
          "horizontal"
        }
        math.frac(it.num, it.denom, style: style)
      } else {
        it
      }
    }
    <__math-frac-depth-stop>
  ]
}

#let equation-numbering(..nums) = context {
  if equation-has-label.at(here()) {
    numbering("(1.1)", counter(heading).at(here()).first(), nums.pos().first())
  } else {
    none
  }
}

/// Render block equations without breaking the surrounding paragraph when supported.
#let render-block-equation-inlinable(it) = {
  block(inlinable: true)[
    #state("__equation-type", none).update("block")
    #equation-has-label.update(it.has("label"))
    #it
  ]
}

/// Render block equations for compilers without user-visible inlinable blocks.
#let render-block-equation-legacy(it) = [
  #state("__equation-type", none).update("block")
  #equation-has-label.update(it.has("label"))
  #it
]


/// Install hooks to indicate whether an equation is block-level or inline, and handles equation numbering based on the presence of the `label` attribute. This hook should be applied at the document level to take effect.
#let math-hook(doc, inlinable-block: false) = {
  show math.equation.where(block: true): if inlinable-block {
    render-block-equation-inlinable
  } else {
    render-block-equation-legacy
  }
  show math.equation.where(block: false): it => {
    state("__equation-type", none).update("inline")
    it
  }
  doc
}
