#import "/stylings/lists.typ": apply-settings

#set page(
  paper: "a4",
  margin: (
    top: 2.5cm,
    bottom: 2.5cm,
    left: 2.5cm,
    right: 2.5cm,
  ),
)

#show: apply-settings((
  enum: (
    loose: (
      type: "block-indent",
      connector: (
        enabled: true,
        offset: 0.75em,
        top-trim: 0.3em,
        bottom-trim: 0.3em,
        stroke: (paint: red, thickness: 1.6pt),
      ),
    ),
  ),
))

= Block Indent Float Case

下面这个例子用于测试 `block-indent` 连接线在跨页时，遇到
`place(float: true)` 大块内容的实际表现。

+ 第一项。先放一段足够长的正文，把浮动块推到下一页顶部附近。#lorem(180)

  #place(
    top,
    float: true,
    clearance: 0pt,
  )[
    #block(
      width: 100%,
      height: 13cm,
      inset: 8pt,
      stroke: 1pt + blue,
      fill: luma(235),
    )[
      #set align(center)
      #set text(11pt, weight: "bold", fill: blue)
      浮动图表模拟块

      #v(4pt)
      #text(9pt, fill: blue)[
        这是一个通过 place(float: true) 放置的固定高度块。
      ]
    ]
  ]

  浮动块之后继续正文，用于观察下一项开始前的连接线是否会穿过浮动块。
  #lorem(60)

+ 第二项。这里作为上一项连接线的终点，用于观察跨页连接段在第二页上的起止位置。
  #lorem(35)

+ 第三项。作为额外参照，便于确认第二项之后的连接线是否恢复正常。#lorem(30)

#pagebreak()

= Block Indent Deferred Float Case

下面这个例子把浮动块的插入点推迟到页内更靠后的位置，观察它是否被延后到下一页。

+ 第一项。先用连续正文占满第一页大部分空间，随后再插入浮动块。#lorem(260)

  这里是浮动块之前的补充文字，用于把插入点推到本页靠后位置。#lorem(50)

  #place(
    top,
    float: true,
    clearance: 0pt,
  )[
    #block(
      width: 100%,
      height: 16cm,
      inset: 8pt,
      stroke: 1pt + green,
      fill: luma(240),
    )[
      #set align(center)
      #set text(11pt, weight: "bold", fill: green + rgb("#1f6f2a"))
      延后插入的浮动图表模拟块

      #v(4pt)
      #text(9pt, fill: green + rgb("#1f6f2a"))[
        如果它被推到下一页，连接线是否会避让它。
      ]
    ]
  ]

  浮动块之后继续正文。#lorem(35)

+ 第二项。观察上一项到这一项的连接线在跨页时是否穿过绿色浮动块。#lorem(30)
