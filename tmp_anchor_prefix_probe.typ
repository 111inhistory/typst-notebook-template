#let draw-probe(id, stroke) = context {
  let match = query(metadata.where(value: id))
  if match.len() == 0 {
    return none
  }
  let pos = match.first().location().position()
  place(
    top + left,
    dx: 0pt,
    dy: pos.y,
    line(length: 100%, stroke: stroke),
  )
}

#set page(
  paper: "a4",
  margin: (
    top: 2.5cm,
    bottom: 2.5cm,
    left: 2.5cm,
    right: 2.5cm,
  ),
  foreground: context {
    draw-probe("plain", 1pt + red)
    draw-probe("zwsp", 1pt + blue)
    draw-probe("wj", 1pt + green)
    draw-probe("none", 1pt + black)
  },
)

#set text(28pt)
#set par(leading: 0.8em)

= Anchor Prefix Probe

红线：普通字符前缀

甲#metadata("plain")Agjp 普通字符前缀

#v(1.2cm)

蓝线：零宽空格前缀

#sym.zws#metadata("zwsp")gjp 零宽空格前缀

#v(1.2cm)

绿线：WORD JOINER 前缀

#metadata("wj")Agjp WORD JOINER 前缀

#v(1.2cm)

黑线：无前导字符

#metadata("none")Agjp 无前导字符
