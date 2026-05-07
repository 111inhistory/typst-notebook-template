#let a = [#lorem(10)#text(fill: red)[12345] #[ 123 #text("1234")]$nabla Psi(arrow(r), t) = "xxx"$ #sym.acute]
#{
  let func-list = ()
  for child in a.children {
    if not child.func() in func-list {
      func-list.push(child.func())
    }
  }
  func-list
}

#a

#let b = [] + []

#b.children.len()