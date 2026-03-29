#import "../utils/object.typ": create, extend, methods, call, factory

#let make-anchor = factory(
  (
    kind: "anchor",
    prefix: "sec-",
    store: (
      level: 1,
    ),
    methods: (
      render: (self: none, label) => [
        #self.prefix#label
      ],
      with-prefix: (self: none, prefix) => extend(self, (prefix: prefix)),
      describe: (self: none) => [
        kind=#self.kind, prefix=#self.prefix, level=#self.store.level
      ],
    ),
  ),
)

#let first-anchor = make-anchor()
#let second-anchor = call(first-anchor, "with-prefix", "fig-")
#let second-methods = methods(second-anchor)
#let plain-object = create(
  (
    name: "plain",
    methods: (
      label: (self: none) => [对象 #self.name],
    ),
  ),
)

= 对象工厂测试

默认对象：#call(first-anchor, "describe")

派生对象：#(second-methods.describe)()

渲染结果：#(second-methods.render)("intro")

普通对象：#call(plain-object, "label")
