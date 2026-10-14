#import "/lib.typ": notebook-theme, set_
#import "/utils/terms-data.typ": get

#show: set_("list-tight", marker-width: 2em)
#show: notebook-theme

= Public scoped list settings

- #metadata("theme-before")The override before theme installation is active.
- Another item.

#get("list-tight", settings => {
  assert(
    settings.marker-width == 2em,
    message: "The theme must preserve overrides made before installation.",
  )
})
#get("terms", settings => {
  assert(
    settings.separator == [：],
    message: "The theme must retain its visible terms separator.",
  )
})

#[
  #show: set_("list-tight", marker-width: 4em, connector: (enabled: false))
  - #metadata("theme-inside")The local marker width is four em.
  - Another local item.
  #get("list-tight", settings => {
    assert(
      settings.marker-width == 4em,
      message: "The public set API must update theme list settings locally.",
    )
  })
]

- #metadata("theme-after")The original two-em width is restored.
- Another restored item with $a/(b/(c/d))$.

#[
  #show: set_("terms", separator: [ — ])
  / Definition: A separator change must preserve list configuration.
  - #metadata("theme-safe")Lists still work after the safe separator change.
  #for name in ("list-tight", "list-loose", "enum-tight", "enum-loose") {
    get(name, settings => {
      assert(
        settings.overload in (false, true, "block-indent", "first-line-indent"),
        message: "Safe separator changes must retain all list namespaces.",
      )
    })
  }
]

#get("list-tight", settings => {
  assert(
    settings.marker-width == 2em,
    message: "Leaving local scopes must restore the outer list configuration.",
  )
})
#get("terms", settings => {
  assert(
    settings.separator == [：],
    message: "The visible separator must be restored outside its local scope.",
  )
})

#context {
  let position(name) = query(metadata.where(value: name))
    .first()
    .location()
    .position()
  let before = position("theme-before")
  let inside = position("theme-inside")
  let after = position("theme-after")
  let safe = position("theme-safe")
  assert(
    calc.abs(inside.x - before.x - 2em.to-absolute()) < 0.01pt,
    message: "Local set overrides must reach the rendered theme geometry.",
  )
  assert(
    calc.abs(before.x - after.x) < 0.01pt,
    message: "Leaving a local list scope must restore the body offset.",
  )
  assert(
    calc.abs(before.x - safe.x) < 0.01pt,
    message: "Changing the terms separator must not change list indentation.",
  )
}
