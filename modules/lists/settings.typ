#import "/modules/lists/connectors.typ": draw-cross-page-connectors
#import "/modules/lists/renderers.typ": renderer-table
#import "/default-setting.typ": default-connector-settings, default-settings as global-default-settings
#import "/utils/utils.typ": merge-dict

#let default-settings = global-default-settings.at("lists")

#let resolve-settings(settings) = {
  let resolved = merge-dict(default-settings, settings)
  if type(resolved.enum.at("post-numbering")) != function {
    panic("`enum.post-numbering` 必须是 function。")
  }
  resolved
}

#let normalize-connector(settings) = merge-dict(
  default-connector-settings,
  settings.at("connector", default: (:)),
)

#let build-render-settings(resolved) = (
  enum: (
    tight: (
      type: resolved.enum.tight.at("type"),
      numbering-align: resolved.enum.tight.at("numbering-align"),
      indentation: resolved.enum.tight.at("indentation"),
      connector: normalize-connector(resolved.enum.tight),
      post-numbering: resolved.enum.at("post-numbering"),
    ),
    loose: (
      type: resolved.enum.loose.at("type"),
      numbering-align: resolved.enum.loose.at("numbering-align"),
      indentation: resolved.enum.loose.at("indentation"),
      connector: normalize-connector(resolved.enum.loose),
      post-numbering: resolved.enum.at("post-numbering"),
    ),
  ),
  list: (
    tight: (
      type: resolved.list.tight.at("type"),
      marker-align: resolved.list.tight.at("marker-align"),
      indentation: resolved.list.tight.at("indentation"),
      connector: normalize-connector(resolved.list.tight),
    ),
    loose: (
      type: resolved.list.loose.at("type"),
      marker-align: resolved.list.loose.at("marker-align"),
      indentation: resolved.list.loose.at("indentation"),
      connector: normalize-connector(resolved.list.loose),
    ),
  ),
)

#let apply-enum-settings(settings) = doc => {
  show enum.where(tight: true): renderer-table.at(settings.tight.at("type")).at("enum")(settings.tight)
  show enum.where(tight: false): renderer-table.at(settings.loose.at("type")).at("enum")(settings.loose)
  doc
}

#let apply-list-settings(settings) = doc => {
  show list.where(tight: true): renderer-table.at(settings.tight.at("type")).at("list")(settings.tight)
  show list.where(tight: false): renderer-table.at(settings.loose.at("type")).at("list")(settings.loose)
  doc
}

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
    indent: resolved.list.tight.at("par-indent"),
    body-indent: resolved.list.tight.at("spacing"),
  )
  show list.where(tight: false): set list(
    indent: resolved.list.loose.at("par-indent"),
    body-indent: resolved.list.loose.at("spacing"),
  )
  show enum.where(tight: true): set enum(
    indent: resolved.enum.tight.at("par-indent"),
    body-indent: resolved.enum.tight.at("spacing"),
  )
  show enum.where(tight: false): set enum(
    indent: resolved.enum.loose.at("par-indent"),
    body-indent: resolved.enum.loose.at("spacing"),
  )

  show: apply-list-settings(render-settings.list)
  show: apply-enum-settings(render-settings.enum)
  set page(foreground: draw-cross-page-connectors())
  doc
}
