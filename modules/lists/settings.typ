#import "/modules/lists/renderers.typ": renderer-table
#import "/default-setting.typ": default-connector-settings, default-settings as global-default-settings
#import "/utils/utils.typ": merge-dict

/// Default settings visible to the `lists` module.
#let default-settings = global-default-settings.at("lists")

/// Merge user settings and perform basic validation.
/// - settings (dictionary | none): User-provided partial settings.
/// -> dictionary
#let resolve-settings(settings) = {
  if settings != none and settings.at("lists", default: none) != none and settings.at("enum", default: none) == none and settings.at("list", default: none) == none {
    panic("`apply-settings` expects the `lists` module settings directly, not a top-level `(lists: ...)` wrapper.")
  }
  let resolved = merge-dict(default-settings, settings)
  let post-numbering = resolved.enum.at("post-numbering")
  assert(
    post-numbering == none or type(post-numbering) == function,
    message: "`enum.post-numbering` should be function or none。",
  )
  resolved
}

/// Normalize connector settings by filling in missing defaults.
/// - settings (dictionary): The style branch that may contain a `connector` field.
/// -> dictionary
#let normalize-connector(settings) = merge-dict(
  default-connector-settings,
  settings.at("connector", default: (:)),
)

/// Extract the minimal settings shape required by renderers.
/// - resolved (dictionary): Fully merged list settings.
/// -> dictionary
#let build-render-settings(resolved) = (
  enum: (
    tight: (
      type: resolved.enum.tight.at("type"),
      numbering-align: resolved.enum.tight.at("numbering-align"),
      connector: normalize-connector(resolved.enum.tight),
      post-numbering: resolved.enum.at("post-numbering"),
    ),
    loose: (
      type: resolved.enum.loose.at("type"),
      numbering-align: resolved.enum.loose.at("numbering-align"),
      connector: normalize-connector(resolved.enum.loose),
      post-numbering: resolved.enum.at("post-numbering"),
    ),
  ),
  list: (
    tight: (
      type: resolved.list.tight.at("type"),
      marker-align: resolved.list.tight.at("marker-align"),
      connector: normalize-connector(resolved.list.tight),
    ),
    loose: (
      type: resolved.list.loose.at("type"),
      marker-align: resolved.list.loose.at("marker-align"),
      connector: normalize-connector(resolved.list.loose),
    ),
  ),
)

/// Apply renderer rules for `enum`.
/// - settings (dictionary): Renderer-facing enum settings.
/// -> function
#let apply-enum-settings(settings) = doc => {
  show enum.where(tight: true): renderer-table.at(settings.tight.at("type")).at("enum")(settings.tight)
  show enum.where(tight: false): renderer-table.at(settings.loose.at("type")).at("enum")(settings.loose)
  doc
}

/// Apply renderer rules for `list`.
/// - settings (dictionary): Renderer-facing list settings.
/// -> function
#let apply-list-settings(settings) = doc => {
  show list.where(tight: true): renderer-table.at(settings.tight.at("type")).at("list")(settings.tight)
  show list.where(tight: false): renderer-table.at(settings.loose.at("type")).at("list")(settings.loose)
  doc
}

/// Public entry point for the lists module.
/// - settings (dictionary | none): User-provided partial list settings.
/// -> function
#let apply-settings(settings) = doc => {
  let resolved = resolve-settings(settings)
  let render-settings = build-render-settings(resolved)

  set enum(
    numbering: resolved.enum.at("numbering"),
    full: resolved.enum.at("full"),
  )
  set list(
    marker: resolved.list.at("marker"),
  )

  show list.where(tight: true): set list(
    indent: resolved.list.tight.at("indentation"),
    spacing: resolved.list.tight.at("spacing"),
    body-indent: resolved.list.tight.at("body-indent"),
  )
  show list.where(tight: false): set list(
    indent: resolved.list.loose.at("indentation"),
    spacing: resolved.list.loose.at("spacing"),
    body-indent: resolved.list.loose.at("body-indent"),
  )
  show enum.where(tight: true): set enum(
    indent: resolved.enum.tight.at("indentation"),
    spacing: resolved.enum.tight.at("spacing"),
    body-indent: resolved.enum.tight.at("body-indent"),
  )
  show enum.where(tight: false): set enum(
    indent: resolved.enum.loose.at("indentation"),
    spacing: resolved.enum.loose.at("spacing"),
    body-indent: resolved.enum.loose.at("body-indent"),
  )

  show: apply-list-settings(render-settings.list)
  show: apply-enum-settings(render-settings.enum)
  doc
}
