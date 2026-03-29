#let bind-methods(self) = (
  inc: (delta: 1) => (self.methods.inc)(self: self, delta: delta),
  render: () => (self.methods.render)(self: self),
)

#let Counter(init: 0) = {
  let self = (
    value: init,
    methods: (
      inc: (self: none, delta: 1) => {
        self.value = self.value + delta
      },
      render: (self: none) => [count = #self.value],
    ),
  )
  self
}

#let c = Counter()
#let m = bind-methods(c)

#(m.inc)(delta: 2)
#(m.render)()
