#import "content-utils.typ": *
#import "utils.typ": modify-args


/// Hook nested elements by rebuilding the matched element itself.
/// This is intended for hooking internal package output. It uses
/// `terms.separator` as a hidden side-channel and stores a trailing
/// `metadata(array)` marker stack there.
/// - it: current matched element
/// - elem (function): the element type being hooked
/// - depth-hook (none | dict | function):
///   - none: return `it` unchanged
///   - dict: use the exact depth key to get a patch dictionary
///   - function: receives `(depth, it)` and returns `none | dict`
/// - pos-args-hook (dict):
///   maps named field names to positional-argument conversion rules.
///   - key: the field name to be removed from `it.fields()` and handled
///     as positional arguments during reconstruction
///   - value `none`: append the field value to `pos` as a single
///     positional argument
///   - value `function`: receives the field value and must return an
///     array; the returned array is extended into `pos`
#let nested-elem-set(
  it,
  elem,
  depth-hook,
  pos-args-hook: ("body": none, "children": it => it, "text": none),
) = context {
  if elem == none or depth-hook == none {
    return it
  }

  let elem-name = repr(elem)
  let depth-state = state("__" + elem-name + "-nested-depth", 0)
  let depth = depth-state.get()
  let sep = terms.separator

  let marker-dict = if sep.func() == sequence {
    let last = sep.children.last()
    if last.func() == metadata and type(last.value) == dictionary {
      last.value
    } else {
      none
    }
  } else {
    none
  }
  let sep-base = if marker-dict == none {
    sep
  } else {
    let ret = sep.children.first()
    for i in range(1, sep.children.len() - 1) {
      ret += sep.children.at(i)
    }
    ret
  }

  let consume-marker = {
    if marker-dict == none or str(depth - 1) not in marker-dict.keys() {
      none
    } else {
      let names = marker-dict.at(str(depth - 1))
      if elem-name not in names {
        none
      } else {
        let cloned = clone-dict(marker-dict)
        if names.len() == 1 {
          cloned.remove(str(depth - 1))
        } else {
          cloned.at(str(depth - 1)) = names.filter(name => name != elem-name)
        }
        if cloned.len() == 0 { sep-base } else { sep-base + metadata(cloned) }
      }
    }
  }

  let with-depth = body => {
    depth-state.update(n => n + 1)
    body
    depth-state.update(n => n - 1)
  }

  let rebuild-args = patch => {
    let fields = clone-dict(it.fields())
    let pos = ()
    for (arg, op) in pos-args-hook {
      if arg in fields {
        if op == none {
          pos.push(fields.remove(arg))
        } else if type(op) == function {
          for i in op(fields.remove(arg)) {
            pos.push(i)
          }
        }
      }
    }
    modify-args(arguments(..pos, ..fields), patch)
  }

  let push-marker = {
    let cloned = if marker-dict == none { (:) } else { clone-dict(marker-dict) }
    if str(depth) in cloned {
      cloned.at(str(depth)).push(elem-name)
    } else {
      cloned.at(str(depth)) = (elem-name,)
    }
    if marker-dict == none {
      sep + metadata(cloned)
    } else {
      sep-base + metadata(cloned)
    }
  }

  let patch = if type(depth-hook) == dictionary and str(depth) in depth-hook {
    depth-hook.at(str(depth))
  } else if type(depth-hook) == function {
    depth-hook(depth, it)
  } else {
    none
  }

  let stopped-sep = consume-marker
  if stopped-sep != none {
    return {
      set terms(separator: stopped-sep)
      it
    }
  }

  if patch == none {
    return with-depth(it)
  }

  let args = rebuild-args(patch)
  let ret-sep = push-marker
  with-depth({
    set terms(separator: ret-sep)
    elem(..args)
  })
}
