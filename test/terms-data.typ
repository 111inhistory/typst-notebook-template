#import "/utils/terms-data.typ": register, get
#import "/lib.typ": set_

#set page(width: 16cm, height: auto, margin: 1cm)
#set text(font: ("Charter", "LXGW WenKai GB"), size: 11pt)
#set terms(separator: [：])

#let read-list-tight = get.with("list-tight")
#let read-enum-loose = get.with("enum-loose")
#show: register("list-tight", defaults: (size: 10, nested: (paint: red, weight: 400)))
#show: register("enum-loose", defaults: (enabled: false))

#let check(title, size, paint, weight, enabled) = read-list-tight(a => read-enum-loose(b => {
  assert(a == (size: size, nested: (paint: paint, weight: weight)), message: "Namespace values must inherit and merge correctly.")
  assert(b == (enabled: enabled), message: "Updating one namespace must preserve the other namespace.")
  block[
    #text(fill: paint, weight: weight)[#title]
    #h(0.6em)size = #a.size, beta = #repr(b.enabled)
  ]
}))

= Scoped terms data
#check("Registered defaults", 10, red, 400, false)

#show: set_("list-tight", size: 12)
#check("First update", 12, red, 400, false)

#show: set_("enum-loose", enabled: true)
#check("Independent namespace", 12, red, 400, true)

#show: set_("list-tight", nested: (paint: blue))
#check("Partial nested update", 12, blue, 400, true)

#[
  #show: set_("list-tight", size: 18, nested: (weight: 700))
  #check("Inner scope", 18, blue, 700, true)
  / Inner terms: The original colon must remain visible.
]

#check("Outer scope restored", 12, blue, 400, true)
/ Outer terms: The carrier must not replace the visible separator.

#[
  #show: set_("terms", separator: [ — ])
  #check("Safe separator change", 12, blue, 400, true)
  #show: set_("list-tight", size: 14)
  #check("Update after safe separator change", 14, blue, 400, true)
  #get("terms", settings => {
    assert(settings.separator == [ — ], message: "The reserved namespace must expose the visible separator without the carrier.")
  })
  #context {
    show: set_("terms", separator: terms.separator)
    get("terms", settings => {
      assert(settings.separator == [ — ], message: "Reusing the current separator must not duplicate its carrier.")
    })
    context {
      assert(terms.separator.children.filter(child => child.func() == metadata).len() == 1, message: "A reused separator must retain exactly one carrier.")
    }
  }
  / Custom separator: This definition must use an em dash.
]

#check("Outer scope restored again", 12, blue, 400, true)
/ Final terms: This definition must use the original colon.

#read-list-tight(a => context {
  let children = terms.separator.children
  assert(children.slice(0, -1).join() == [：], message: "The visible separator must be preserved.")
  assert(children.last().func() == metadata, message: "The carrier must be appended as the final metadata element.")
  assert(children.len() == 2, message: "Repeated updates must replace the carrier instead of accumulating metadata.")
  let data = children.last().value.__notebook-terms-data
  assert(data.overrides.at("list-tight").size == a.size, message: "The carrier must retain the current overrides.")
  assert(data.registered.keys().sorted() == ("enum-loose", "list-tight"), message: "Separator updates must preserve registrations without registering the reserved namespace.")
})

#[
  #show: set_("late-registration", value: 42)
  #show: register("late-registration", defaults: (value: 0, inherited: true))
  #get("late-registration", values => {
    assert(values == (value: 42, inherited: true), message: "Overrides must work before registration.")
  })
]

#[
  #show: set_("terms", separator: strong[ → ] + metadata("foreign metadata"))
  #show: set_("list-tight", size: 16)
  #check("Styled separator / foreign metadata", 16, blue, 400, true)
  #context {
    let children = terms.separator.children
    assert(children.len() == 3, message: "Updates must preserve foreign metadata without accumulating carriers.")
    assert(children.at(-2) == metadata("foreign metadata"), message: "Foreign metadata must not be consumed as a carrier.")
  }
  / Styled separator: The bold arrow must remain visible.
]

#[
  #show: set_("terms", separator: [])
  #show: set_("list-tight", size: 20)
  #show: set_("list-tight", nested: (paint: green))
  #check("Empty separator", 20, green, 400, true)
  #context {
    assert(terms.separator.children.len() == 1, message: "An empty separator must contain only one carrier after repeated updates.")
  }
  / Empty separator: No punctuation should appear between term and description.
]

#[
  #set terms(separator: [; ])
  #show: register("list-tight", defaults: (size: 10, nested: (paint: red, weight: 400)))
  #show: register("enum-loose", defaults: (enabled: false))
  #check("Native set discards registrations and overrides", 10, red, 400, false)
]

#check("Final outer scope", 12, blue, 400, true)

#let failure = sys.inputs.at("failure", default: none)
#if failure == "duplicate" {
  show: register("list-tight")
  [Unreachable.]
} else if failure == "reserved" {
  show: register("terms")
  [Unreachable.]
} else if failure == "terms-field" {
  show: set_("terms", tight: true)
  [Unreachable.]
} else if failure == "separator-type" {
  show: set_("terms", separator: 1)
  [Unreachable.]
} else if failure == "unregistered" {
  get("missing-namespace", _ => [])
}
