#import "/stylings/lists.typ": apply-settings
#set page(margin: 2.5cm)

#let list-style-settings = (
  enum: (
    post-numbering: it => strong(it),
    tight: (
      type: "first-line-indent",
      connector: (enabled: true),
    ),
    loose: (
      type: "block-indent",
      connector: (
        enabled: true,
        offset: 0.75em,
      ),
    ),
  ),
  list: (
    tight: (
      type: "first-line-indent",
      connector: (enabled: true),
    ),
    loose: (
      type: "block-indent",
      connector: (
        enabled: true,
        offset: 0.75em,
      ),
    ),
  ),
)

#show: apply-settings(list-style-settings)
#set par(first-line-indent: 2em)


#let demo = [
== Bulleted List (Tight)
- 这是第一项，文本稍长一些用于观察换行后的对齐效果。#lorem(11)
- 这是第二项，继续观察缩进行为。
  - 这是二级项，同样有较长文本用于测试换行对齐。
  - 第二个二级项。

== Bulleted List (Loose)
- 这是第一项（loose）。

- 这是第二项（loose），用于验证段间距和缩进不冲突。

  - 222#lorem(11)

  - 定位

    - 333333
  
  - 444

== Enumerated List (Tight)
+ 第一项，文本稍长一些用于观察编号与正文的关系。
+ 第二项。
  + 二级编号项，观察嵌套层级缩进。
  + 第二个二级编号项。

== Enumerated List (Loose)
这个是

+ 第一项（loose）。#lorem(11)

  111222

  这个是

  + 啊啊222#lorem(11)

  + 333#lorem(11)
    + 444#lorem(11)

    + 555#lorem(11)

  + 444这是什么，#lorem(111)

+ 12121212121212#lorem(111)

+ 第二项（loose），用于验证段间距和缩进表现。#lorem(111)
]

#demo
