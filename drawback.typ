#set page(paper: "a4", margin: 1.8cm)
#set text(font: ("LXGW WenKai GB", "Charter"), size: 10pt, lang: "zh")
#set par(first-line-indent: 0pt, leading: 0.55em)
#set heading(numbering: "1.")
#show raw: set text(size: 8.5pt)

#align(center, text(size: 18pt, weight: "bold")[当前限制与收敛情况])

= 配置载体限制

*原生 separator 设置会清空隐藏数据。* `terms-data` 把注册记录和配置放在 separator 末尾的 metadata 中。原生 `set terms(separator: ...)` 会丢弃载体。应使用安全接口：

```typ
#show: set_("terms", separator: [：])
```

载体只识别末尾的自有 metadata。在载体之后追加内容，也会让读取失效。

*列表配置只安装一次。* 主题已安装 `better-lists`，不要在同一作用域重复安装。局部配置使用 `set_`：

```typ
#show: set_("list-tight", marker-width: 2em)
#show: set_("enum-tight", number-width: 2em)
```

配置读写依赖 context，会增加求值工作和嵌套深度。当前只检查排版轮数和图像，不比较耗时。

= 当前收敛情况

测试日期：2026-10-14。编译器：Typst 0.15.0。输入：`notebook-demo.typ`。正式实现和额外注册一个配置命名空间的对照组，结果相同：

#table(
  columns: (auto, 1fr, 1fr),
  inset: 4pt,
  table.header([*正文可用轮数*], [*诊断*], [*与最终图像比较*]),
  [1], [编译成功，有收敛警告。], [全部 7 页有差异。],
  [2], [编译成功，有收敛警告。], [第 1、2、3、5 个物理页有差异。],
  [3], [仅剩 marginalia 状态的收敛警告。], [全部页面逐像素一致。],
  [4–5], [无收敛警告。], [全部页面逐像素一致。],
)

*边注仍需额外一轮确认状态稳定。* 本样例自然排版为 4 轮。三轮图像不变，不代表整篇内部状态已经收敛。该结果不代表其他输入或编译器版本。

= 复测

```sh
python scripts/notebook-convergence.py
# If Pillow is unavailable:
uv run --with pillow scripts/notebook-convergence.py
```

脚本默认比较正式实现与额外配置载体组。使用 #link("https://typst.app/universe/package/layout-ltd/")[layout-ltd 0.1.0] 为正文保留指定轮数，可用值为 1–5；该包不能提高编译器上限。计时追踪包含前置空轮，因此自然轮数另用不加载该包的编译测量。

图像以 96 PPI 导出，再用 Pillow 逐页比较。产物位于 `tmp/notebook-convergence/`：

- `pages/`、`overview/`、`diff/`：原始页面、逐轮总览和像素差异。
- `results.json`：编译状态、轮数、诊断、图像比较和输入摘要。
- `*.log`、`*.json`：诊断与计时追踪。`unlimited` 仅表示未加载 limiter，编译器仍使用默认上限。
