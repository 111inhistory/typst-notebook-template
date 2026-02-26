// some common utilities

#let merge-dict(raw, mod) = {
  if mod == none { return raw }
  let raw_keys = raw.keys()
  for key in mod.keys() {
    if raw_keys.contains(key) {
      let raw_val = raw.at(key)
      let mod_val = mod.at(key)

      if type(raw_val) == type(mod_val) == dictionary {
        raw.at(key) = merge-dict(raw_val, mod_val)
      } else {
        raw.at(key) = mod_val
      }
    } else {
      raw.insert(key, mod.at(key))
    }
  }
  return raw
}
