#import "/utils/anchor.typ": anchor-helper

#let anchor = anchor-helper("114")
#let count = counter("114")

#let draw-series(ids, stroke: 1pt + red) = context {
  let offset-pos = here().position()
  for i in range(0, ids.len() - 1) {
    let from = query(metadata.where(value: ids.at(i))).at(0).location().position()
    let to = query(metadata.where(value: ids.at(i + 1))).at(0).location().position()

    if from.page == here().page() and to.page == here().page() {
      box(
        place(dx: from.x - offset-pos.x - measure([1.]).width - 0.5em, dy: from.y - offset-pos.y)[L],
      )
    }
  }
}

// #set page(
//   foreground: draw-series(("114-1", "114-2", "114-3")),
// )

#lorem(20)
#context count.step()
#context (anchor.create)(..count.get())

#lorem(20)
#lorem(800)

#lorem(10)

#context count.step()
#context (anchor.create)(..count.get())


#context count.step()
#lorem(20)
#context (anchor.create)(..count.get())
// #draw-series(("114-1", "114-2", "114-3"))

#place(dy: -12cm)[AAA]
