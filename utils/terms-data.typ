#import "common.typ": merge-dict
#import "content-utils.typ": sequence

// Only the final, marked metadata is a carrier; preserve all preceding content.
#let _split(separator) = {
  let children = if separator.func() == sequence { separator.children } else { (separator,) }
  if children != () {
    let tail = children.pop()
    if (
      tail.func() == metadata
        and type(tail.value) == dictionary
        and "__notebook-terms-data" in tail.value
    ) {
      let body = if children == () { [] } else { children.join() }
      return (body, tail.value.__notebook-terms-data)
    }
  }
  (separator, (registered: (:), overrides: (:)))
}

#let _settings(name, data) = merge-dict(
  data.registered.at(name).defaults,
  data.overrides.at(name, default: (:)),
)

#let _update-carrier(name, transform) = doc => context {
  let (separator, data) = _split(terms.separator)
  let (separator, data) = transform(separator, data)
  set terms(separator: separator + metadata((__notebook-terms-data: data)))
  let registration = data.registered.at(name, default: none)
  if registration != none and registration.apply != none {
    let wrapper = (registration.apply)(_settings(name, data))
    assert(type(wrapper) == function, message: "Namespace apply must return a styling wrapper.")
    wrapper(doc)
  } else {
    doc
  }
}

/// Install a namespace and its defaults with a show wrapper before reading it.
/// Registration is scoped; a name already registered in the current scope is rejected.
/// apply(settings) optionally returns a native styling wrapper, run at registration
/// and after updates so native fields resolve before element show transformations.
#let register(name, defaults: (:), apply: none) = {
  assert(type(name) == str and name != "", message: "Namespace name must be a non-empty string.")
  assert(name != "terms", message: "Namespace 'terms' is reserved.")
  assert(type(defaults) == dictionary, message: "Namespace defaults must be a dictionary.")
  assert(apply == none or type(apply) == function, message: "Namespace apply must be a function or none.")
  _update-carrier(name, (separator, data) => {
    assert(name not in data.registered, message: "Namespace '" + name + "' is already registered.")
    data.registered.insert(name, (defaults: defaults, apply: apply))
    (separator, data)
  })
}

/// Consume resolved settings in a receiver because context produces content.
/// The reserved terms namespace exposes only the visible separator.
#let get(name, receiver) = {
  assert(type(name) == str and name != "", message: "Namespace name must be a non-empty string.")
  context {
    let (separator, data) = _split(terms.separator)
    let settings = if name == "terms" {
      (separator: separator)
    } else {
      assert(name in data.registered, message: "Namespace '" + name + "' is not registered.")
      _settings(name, data)
    }
    receiver(settings)
  }
}

/// Set scoped overrides; nested dictionaries merge while other values replace.
/// Overrides may precede registration. Use the terms namespace to preserve the carrier
/// when changing the separator; a native terms.separator set discards all stored data.
#let set_(name, ..updates) = {
  assert(type(name) == str and name != "", message: "Namespace name must be a non-empty string.")
  assert(updates.pos() == (), message: "Namespace settings only accept named arguments after the name.")
  let patch = updates.named()
  if name == "terms" {
    assert(patch.keys().all(key => key == "separator"), message: "Namespace 'terms' only accepts the separator setting.")
  }
  _update-carrier(name, (separator, data) => {
    if name == "terms" {
      let replacement = patch.at("separator", default: separator)
      assert(type(replacement) == content, message: "The terms separator must be content.")
      separator = _split(replacement).first()
    } else {
      data.overrides.insert(name, merge-dict(data.overrides.at(name, default: (:)), patch))
    }
    (separator, data)
  })
}
