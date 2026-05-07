/// Create independent figure-backed frame constructors.
#let frames(style, ..definitions) = {
  assert(
    type(style) == function,
    message: "frame style 必须是 function，实际为 " + repr(type(style)),
  )
  assert(
    definitions.pos() == (),
    message: "frames 只接受命名 frame 定义。",
  )

  let constructors = (:)
  for (kind, definition) in definitions.named().pairs() {
    let args = if type(definition) == array {
      definition
    } else {
      (definition,)
    }
    assert(args.len() > 0, message: "frame 定义必须至少包含 supplement。")

    let supplement = args.at(0)
    let accent-color = args.at(1, default: rgb("#4f86a8"))
    assert(
      type(accent-color) == color,
      message: "frame accent color 必须是 color，实际为 " + repr(type(accent-color)),
    )

    constructors.insert(kind, (..title-and-tags, body) => {
      let title = none
      let tags = ()
      if title-and-tags.pos().len() > 0 {
        title = title-and-tags.pos().first()
        tags = title-and-tags.pos().slice(1)
      }
      let caption-body = if title not in (none, [], "") {
        title
      } else if tags.len() > 0 {
        tags.join([、])
      } else {
        []
      }

      {
        show figure.where(kind: kind): it => it.body
        figure(
          kind: kind,
          supplement: supplement,
          caption: caption-body,
          {
            context {
              let number = counter(figure.where(kind: kind)).display()
              style(title, tags, body, supplement, number, accent-color)
            }
          },
          ..title-and-tags.named(),
        )
      }
    })
  }

  constructors
}
