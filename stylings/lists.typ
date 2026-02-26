#import "/utils/numbly-utils.typ": *


#let firstline-indent(settings) = it => context {
  let item-len = it.children.len()
}

#let block-indent(settings) = it => context {}

#let hanging-indent(settings) = it => context {}

#let type-dict = (
  hanging-indent: hanging-indent,
  block-indent: block-indent,
  first-line-indent: firstline-indent,
)

#let apply-enum-settings(settings) = doc => {
  show enum.where(tight: true): type-dict.at(settings.tight.at("type"))(settings.tight)
  show enum.where(tight: false): type-dict.at(settings.loose.at("type"))(settings.loose)
  doc
}

#let apply-list-settings(settings) = doc => {
  show list.where(tight: true): type-dict.at(settings.tight.at("type"))(settings.tight)
  show list.where(tight: false): type-dict.at(settings.loose.at("type"))(settings.loose)
  doc
}

// Configurable Aspects of lists or list-like:
// - whether is tight or not (and other parameters can be set separately)
// - numbering (numbered list only, recommend using `numbly` package)/marker (bulleted list only, either an array of content, a function from nesting level to content, or a single content)
// - fixed indentation or dynamic indentation
// - spacing between numbering/marker and the body
// - numbering/marker alignment (left, right)
// - indentation (hanging indent, block indent, first-line indent)
// - custom paragraph settings

#let default-settings = (
  enum: (
    numbering: partial-display("{1}.{2}.{3}.{4}."), // either a funciton, a string, or none for default numbering
    full: false, // if full is true, eg. numbering("1.a)") will produce like "1.", "1.a)" or so
    tight: (
      type: "hanging-indent", // or "block-indent" or "first-line-indent"
      indentation: 2em, // or mark "dynamic"
      spacing: 0.5em, // space between number and body
      numbering-align: "right", // or "left"
    ),
    loose: (
      type: "first-line-indent", // or "block-indent" or "hanging-indent"
      indentation: 2em, // or mark "dynamic"
      spacing: 0.5em, // space between number and body
      numbering-align: "right", // or "left"
    ),
  ),
  list: (
    marker: ([•], [‣], [–]), // either an array of content, a function from nesting level to content, or a single content, or none for default marker
    tight: (
      type: "hanging-indent", // or "block-indent" or "first-line-indent"
      indentation: 2em, // or mark "dynamic"
      spacing: 0.5em, // space between number and body
      marker-align: "right", // or "left"
    ),
    loose: (
      type: "first-line-indent", // or "block-indent" or "hanging-indent"
      indentation: 2em, // or mark "dynamic"
      spacing: 0.5em, // space between number and body
      marker-align: "right", // or "left"
    ),
  ),
)

#let apply-settings(settings) = doc => {
  // Some settings should be set as the property of the list/enum element, and some settings should be passed
  // to the child function of customize the style of enums and lists
  let settings = merge-dict(default-settings, settings)
  set enum(
    numbering: settings.enum.at("numbering"),
    full: settings.enum.at("full", false),
  )
  set list(
    marker: settings.list.at("marker", none),
    full: settings.list.at("full", false),
  )
  show list.where(tight: true): set list(
    indent: settings.list.tight.at("indentation"),
    body-indent: settings.list.tight.at("spacing"),
  )
  show list.where(tight: false): set list(
    indent: settings.list.loose.at("indentation"),
    body-indent: settings.list.loose.at("spacing"),
  )
  show enum.where(tight: true): set enum(
    indent: settings.enum.tight.at("indentation"),
    body-indent: settings.enum.tight.at("spacing"),
  )
  show enum.where(tight: false): set enum(
    indent: settings.enum.loose.at("indentation"),
    body-indent: settings.enum.loose.at("spacing"),
  )
  // export the settings that should be passed to the factory function of the customized list/enum style
  let ret-enum-settings = (
    tight: (
      type: settings.enum.tight.at("type"),
      numbering-align: settings.enum.tight.at("numbering-align"),
    ),
    loose: (
      type: settings.enum.loose.at("type"),
      numbering-align: settings.enum.loose.at("numbering-align"),
    ),
  )
  let ret-list-settings = (
    tight: (
      type: settings.list.tight.at("type"),
      marker-align: settings.list.tight.at("marker-align"),
    ),
    loose: (
      type: settings.list.loose.at("type"),
      marker-align: settings.list.loose.at("marker-align"),
    ),
  )
  show list: apply-list-settings(ret-list-settings)
  show enum: apply-enum-settings(ret-enum-settings)
  doc
}
