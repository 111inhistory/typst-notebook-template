#import "/stylings/lists.typ": apply-settings
#import "/utils/numbly-utils.typ": partial-display

#set page(margin: 2.5cm)

#let default-connector-settings = (
  enabled: true,
  baseline-offset: 0.65em,
  position: 0.9em,
  stroke: (paint: luma(70%), thickness: 0.5pt, dash: (array: (4pt, 5pt), phase: 4pt)),
)

#let list-style-settings = (
  enum: (
    numbering: partial-display("{1}.{2}.{3}.{4}."),
    post-numbering: none,
    full: false,
    tight: (
      type: "block-indent",
      spacing: 0.65em,
      indentation: 2em,
      body-indent: 0.5em,
      numbering-align: "right",
      connector: default-connector-settings,
    ),
    loose: (
      type: "block-indent",
      spacing: 1em,
      indentation: 2em,
      body-indent: 0.5em,
      numbering-align: "right",
      connector: default-connector-settings,
    ),
  ),
  list: (
    marker: ([•], [‣], [–]),
    tight: (
      type: "block-indent",
      spacing: 0.65em,
      indentation: 2em,
      body-indent: 0.5em,
      marker-align: "right",
      connector: default-connector-settings,
    ),
    loose: (
      type: "block-indent",
      spacing: 1em,
      indentation: 2em,
      body-indent: 0.5em,
      marker-align: "right",
      connector: default-connector-settings,
    ),
  ),
)

#show: apply-settings(list-style-settings)
#set par(first-line-indent: 2em)



== Bulleted List (Tight)

- 这是第一项，文本稍长一些用于观察换行后的对齐效果。#lorem(11)
- 这是第二项，继续观察缩进行为。
  - 这是二级项，同样有较长文本用于测试换行对齐。#lorem(100)
  - 第二个二级项。
    - 111
  - 333
    - 123019782103

== Bulleted List (Loose)
- 这是第一项（loose）。

- 这是第二项（loose），用于验证段间距和缩进不冲突。
  #set par(spacing: 0.5em)

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
<1>
+ 啊啊222#lorem(11)

+ 333#lorem(11)

  abcdefghijk

  + 444#lorem(11)

  + 555#lorem(11)$(1/2/3/4/(1/2/3/4))/(1/2/3/4/(1/2/3/4))$

+ 444这是什么，#lorem(111)

+ 12121212121212#lorem(111)

+ 第二项（loose），用于验证段间距和缩进表现。#lorem(111)
