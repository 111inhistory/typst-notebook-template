#set page(paper: "a4", margin: 1.8cm)
#set text(font: ("LXGW WenKai GB", "Charter"), size: 10pt, lang: "zh")
#set par(first-line-indent: 0pt, leading: 0.55em)
#set heading(numbering: "1.")
#show raw: set text(size: 8.5pt)

#align(center, text(size: 18pt, weight: "bold")[已知缺陷与收敛记录])

= 已知缺陷

*已修复：编号与正文首行分处两页。* 原实现查询正文位置，再用竖直位移定位编号，存在布局反馈。两套网格渲染器现已改用零宽悬挂盒，让编号与首行共享基线和分页，不再查询编号位置。

*本次修复没有增加全局排版轮数。* 在当前样例中，忽略 marginalia 后，列表依赖从 4 轮降到 3 轮。整篇自然排版仍为 4 轮，因为 marginalia 还需下一轮。编译器轮数上限未变。

*原生 separator 设置会清空隐藏数据。* `terms-data` 把注册记录和配置放在 separator 的末尾 metadata 中。原生 `set terms(separator: ...)` 会丢弃载体。安全修改应使用：

```typ
#show: set_("terms", separator: [：])
```

载体只识别末尾的自有 metadata。其他代码在载体之后追加内容，也会让读取失效。增加 context 会增加求值工作和嵌套深度；本次只测轮数和图像，不比较耗时。

= 修改前的 notebook-demo 对照

测试日期：2026-10-14。编译器：Typst 0.15.0。以下记录悬挂盒修复前的基线。输入为 `notebook-demo.typ`；三组使用相同正文、字体和页面设置。

#table(
  columns: (auto, 1fr, auto),
  inset: 4pt,
  align: (left, left, center),
  table.header([*组别*], [*测试副本的区别*], [*自然排版轮数*]),
  [plain], [原版主题与原版 better-lists。], [4],
  [carrier], [原版列表，增加一次无视觉变化的注册、设置和读取。], [4],
  [terms], [使用 better-lists-set；separator 改用安全接口。], [4],
)

不加 limiter 时，三组最终各有 7 页，图像逐像素一致。本样例没有观察到 terms-data 增加全局排版轮数。这个结果不代表其他输入或编译器版本的结果。

#table(
  columns: (auto, 1fr, 1fr),
  inset: 4pt,
  table.header([*正文可用轮数*], [*编译结果（三组相同）*], [*与最终图像比较*]),
  [1], [失败：编号定位访问尚不存在的位置；有收敛警告。], [未导出页面。],
  [2], [成功，但有收敛警告。], [第 1、2、3、5 个物理页有差异。],
  [3], [成功；metadata 位置和边注状态仍有收敛警告。], [全部页面逐像素一致。],
  [4], [成功，无收敛警告。], [全部页面逐像素一致。],
  [5], [成功，无收敛警告。], [全部页面逐像素一致。],
)

限制为 3 轮时图像已不变，但编译器还需下一轮确认依赖稳定。编号拆页在最终图像的第 3、4 个物理页仍存在。不要把“无像素差异”当作“内部状态已收敛”。

= 复测与图片

使用 #link("https://typst.app/universe/package/layout-ltd/")[layout-ltd 0.1.0]。该包先排空前面的轮次，再给正文留下指定轮数。可用值为 1–5；该包不能把上限提高到 6。计时追踪中的总轮数包含空轮，所以自然轮数另用不加载该包的编译测量。

```sh
python test/notebook-convergence.py
# If Pillow is unavailable:
uv run --with pillow test/notebook-convergence.py
```

脚本让 Typst 直接输出 96 PPI 的 PNG，再用 Pillow 逐页比较。文件位于 `tmp/notebook-convergence/`：

- `pages/`：各组、各轮数的原始页面；修改前导出了 105 张。
- `overview/`：三组各一张逐轮总览。
- `diff/`：相邻轮次和最终跨组对照；红色表示不同像素。
- `results.json`：轮数、编译状态、像素差异和原示例摘要。
- `*.log`、`*.json`：诊断与计时追踪。文件名中的 `unlimited` 仅指不加载 limiter，编译器仍使用默认上限。

#pagebreak()
= 已应用的编号定位修复

零宽悬挂盒已应用到 `elements/better-lists.typ` 和 `elements/better-lists-set.typ`。主题配置入口未切换。复测仍使用同一份 `notebook-demo.typ`，忽略 marginalia 的警告，但不忽略列表的 metadata 警告。

#table(
  columns: (auto, 1fr, 1fr),
  inset: 4pt,
  table.header([*版本*], [*限制为 3 轮时*], [*列表回归*]),
  [修改前], [列表位置仍未稳定；需要 4 轮。], [原基线。],
  [top.typ], [仅剩 marginalia 警告。], [高公式等基线断言失败。],
  [悬挂盒（已应用）], [仅剩 marginalia 警告。], [两套列表回归与局部作用域断言通过。],
)

*本样例的列表依赖少需一轮。* 直接顶对齐和零宽悬挂盒都去掉了编号定位回查，但直接顶对齐会破坏高公式的基线。零宽悬挂盒让编号与正文首行共享基线和分页，没有出现这些回归失败。

*整篇自然排版仍为 4 轮。* marginalia 仍需下一轮。忽略 marginalia 后，两个简化版在 3 轮时均无其他警告。不要将此结果写成“整篇编译已降到 3 轮”。

悬挂盒版在当前样例中还消除了编号与首行分处两页的问题。三轮图像与四轮、五轮和自然排版逐像素一致。新增 `test/list-label-page-break.typ` 检查编号与高公式首行共同换页；原版和 terms-data 版通过，修复前的实现触发断言。图片与诊断：

- `tmp/list-baseline-experiment/page-break-before-after.png`：分页前后对照。
- `tmp/notebook-convergence-hanging/overview/plain.png`：正式修复后的逐轮总览。
- `tmp/notebook-convergence-hanging/terms-3.log`：仅剩 marginalia 警告。
