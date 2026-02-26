#let base-style(type-name) = (
  type: type-name,
  indentation: 2em,
  spacing: 0.5em,
  numbering-align: "right",
)

#let mk-settings(type-name) = (
  enum: (
    numbering: "1.",
    tight: base-style(type-name),
    loose: base-style(type-name),
  ),
  list: (
    marker: none,
    tight: base-style(type-name),
    loose: base-style(type-name),
  ),
)

#let demo-content = [
== Bulleted List (Tight)
- 这是第一项，文本稍长一些用于观察换行后的对齐效果。
- 这是第二项，继续观察缩进行为。
  - 这是二级项，同样有较长文本用于测试换行对齐。
  - 第二个二级项。

== Bulleted List (Loose)
- 这是第一项（loose）。

- 这是第二项（loose），用于验证段间距和缩进不冲突。

== Enumerated List (Tight)
+ 第一项，文本稍长一些用于观察编号与正文的关系。
+ 第二项。
  + 二级编号项，观察嵌套层级缩进。
  + 第二个二级编号项。

== Enumerated List (Loose)
+ 第一项（loose）。

+ 第二项（loose），用于验证段间距和缩进表现。
]

= Hanging Indent
#custom-list-enum(demo-content, mk-settings("hanging-indent"))

#pagebreak()

= Block Indent
#custom-list-enum(demo-content, mk-settings("block-indent"))

#pagebreak()

= First-line Indent
#custom-list-enum(demo-content, mk-settings("first-line-indent"))
