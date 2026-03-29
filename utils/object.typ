// 提供一套轻量的“类风格”对象工具。
// 核心思路是：对象本体使用字典表示，方法统一显式接收 self。

#import "utils.typ": merge-dict

#let _ensure-dictionary(name, value) = {
  assert(
    type(value) == dictionary,
    message: name + " 必须是 dictionary，实际为 " + repr(type(value)),
  )
  value
}

#let _normalize-methods(methods) = {
  let normalized = (:)
  for (name, method) in _ensure-dictionary("methods", methods).pairs() {
    assert(
      type(method) == function,
      message: "methods." + name + " 必须是 function，实际为 " + repr(type(method)),
    )
    normalized.insert(name, method)
  }
  normalized
}

/// 创建一个对象。
///
/// 传入的每个位置参数都必须是 dictionary，后面的配置会覆盖前面的配置。
/// 约定保留两个特殊字段：
/// - `methods`：方法字典，值必须是 `(self: none, ..args) => ...` 形式的函数
/// - `store`：对象内部的附加数据区
#let create(..parts) = {
  assert(parts.named().len() == 0, message: "create 不接受命名参数")

  let object = (:)
  for part in parts.pos() {
    object = merge-dict(object, _ensure-dictionary("part", part))
  }

  if "methods" in object {
    object.at("methods") = _normalize-methods(object.methods)
  } else {
    object.insert("methods", (:))
  }

  if "store" in object {
    object.at("store") = _ensure-dictionary("store", object.store)
  } else {
    object.insert("store", (:))
  }

  object
}

/// 基于现有对象创建一个新对象。
///
/// 这是推荐的“状态更新”方式：返回新对象，再由调用方决定是否重新绑定变量。
#let extend(self, ..parts) = {
  assert(parts.named().len() == 0, message: "extend 不接受命名参数")
  create(self, ..parts.pos())
}

/// 绑定单个方法。
#let bind(self, name) = {
  _ensure-dictionary("self", self)
  assert("methods" in self, message: "self 缺少 methods 字段")
  assert(name in self.methods, message: "未找到方法 " + name)

  let method = self.methods.at(name)
  assert(
    type(method) == function,
    message: "methods." + name + " 必须是 function",
  )

  return ((..args) => method(self: self, ..args))
}

/// 绑定对象上的全部方法，返回一个新的方法字典。
#let methods(self) = {
  _ensure-dictionary("self", self)
  assert("methods" in self, message: "self 缺少 methods 字段")

  let bound = (:)
  for name in self.methods.keys() {
    bound.insert(name, bind(self, name))
  }
  bound
}

/// 直接按名称调用对象方法。
#let call(self, name, ..args) = bind(self, name)(..args)

/// 创建一个对象工厂。
///
/// 工厂会先固定一份默认对象配置，随后每次调用都会基于该默认配置创建新对象。
#let factory(..defaults) = {
  assert(defaults.named().len() == 0, message: "factory 不接受命名参数")

  let blueprint = create(..defaults.pos())
  return ((..parts) => {
    assert(parts.named().len() == 0, message: "工厂实例化时不接受命名参数")
    create(blueprint, ..parts.pos())
  })
}
