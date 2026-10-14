"""Export notebook-demo iterations as PNG and compare them with Pillow."""

import argparse
from datetime import date
import hashlib
import json
import re
from pathlib import Path
import subprocess

from PIL import Image, ImageChops, ImageDraw, ImageOps


def replace_once(source, old, new):
    if source.count(old) != 1:
        raise ValueError(f"Expected one source match: {old!r}")
    return source.replace(old, new, 1)


def prepare(root, output, backend, terms_module):
    directory = output / backend
    directory.mkdir(parents=True, exist_ok=True)
    theme = (root / "theme/notebook.typ").read_text(encoding="utf-8")
    if backend != "plain":
        theme = '#import "/utils/terms-data.typ": register, get, set_\n' + theme
        theme = replace_once(
            theme, "  set terms(tight: false, separator: [：])",
            '  set terms(tight: false)\n  show: set_("terms", separator: [：])',
        )
    if backend == "terms":
        theme = replace_once(theme, "  better-lists, equation-numbering", "  equation-numbering")
        theme = f'#import "{terms_module}": better-lists\n' + theme
    elif backend == "carrier":
        theme = replace_once(
            theme, "  let par-spacing = 0.65em",
            '''  let par-spacing = 0.65em
  show: register("convergence-probe", defaults: (value: 0))
  show: set_("convergence-probe", value: 1)
  show: body => get("convergence-probe", values => {
    assert(values.value == 1, message: "The carrier probe must preserve its override.")
    body
  })''',
        )
    (directory / "notebook-theme.typ").write_text(theme, encoding="utf-8")
    source = (root / "notebook-demo.typ").read_text(encoding="utf-8")
    source = replace_once(source, '#import "lib.typ": notebook-theme, ', '#import "/lib.typ": ')
    source = replace_once(source, '#import "utils/typing-utils.typ"', '#import "/utils/typing-utils.typ"')
    theme_path = (directory / "notebook-theme.typ").relative_to(root).as_posix()
    source = f'#import "/{theme_path}": notebook-theme\n' + source
    (directory / "notebook-demo.typ").write_text(source, encoding="utf-8")
    (directory / "limited.typ").write_text(
        '#import "@preview/layout-ltd:0.1.0": layout-limiter\n'
        '#show: layout-limiter\n#include "notebook-demo.typ"\n',
        encoding="utf-8",
    )
    return directory


def load_page(root, row, index):
    if index >= len(row["pages"]):
        return None
    with Image.open(root / row["pages"][index]) as source:
        image = source.convert("RGBA")
        return Image.alpha_composite(Image.new("RGBA", image.size, "white"), image).convert("RGB")


def paste_thumbnail(sheet, page, position, size):
    if page is not None:
        thumbnail = ImageOps.contain(page, size)
        sheet.paste(thumbnail, position)


def overview(root, output, backend, rows):
    columns = sorted(rows, key=lambda row: 6 if row["limit"] is None else row["limit"])
    count = max(len(row["pages"]) for row in columns)
    sheet = Image.new("RGB", (220 * len(columns), 30 + 300 * count), "#dddddd")
    draw = ImageDraw.Draw(sheet)
    for column, row in enumerate(columns):
        label = "unlimited" if row["limit"] is None else str(row["limit"])
        draw.text((column * 220 + 8, 8), f"{backend} / {label}", fill="black")
        for index in range(count):
            position = (column * 220 + 5, 35 + index * 300)
            paste_thumbnail(sheet, load_page(root, row, index), position, (210, 285))
        if row["returncode"] != 0:
            draw.text((column * 220 + 8, 50), "Compilation failed", fill="red")
    path = output / "overview" / f"{backend}.png"
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path)


def compare_pair(root, output, before, after):
    label = lambda row: f"{row['backend']}-{'unlimited' if row['limit'] is None else row['limit']}"
    name = f"{label(before)}--{label(after)}"
    result = dict(name=name, comparable=before["returncode"] == after["returncode"] == 0)
    if not result["comparable"]:
        return result
    directory = output / "diff" / name
    directory.mkdir(parents=True, exist_ok=True)
    count = max(len(before["pages"]), len(after["pages"]))
    sheet = Image.new("RGB", (930, 30 + 410 * count), "#dddddd")
    draw = ImageDraw.Draw(sheet)
    for column, title in enumerate((label(before), label(after), "Changed pixels in red")):
        draw.text((column * 310 + 8, 8), title, fill="black")
    differences = []
    for index in range(count):
        left = load_page(root, before, index)
        right = load_page(root, after, index)
        size = (max(page.width for page in (left, right) if page is not None),
                max(page.height for page in (left, right) if page is not None))
        canvases = []
        for page in (left, right):
            canvas = Image.new("RGB", size, "white")
            if page is not None:
                canvas.paste(page, (0, 0))
            canvases.append(canvas)
        channels = ImageChops.difference(*canvases).split()
        mask = ImageChops.lighter(ImageChops.lighter(channels[0], channels[1]), channels[2])
        mask = mask.point(lambda value: 255 if value else 0)
        changed = mask.histogram()[255]
        marked = ImageOps.grayscale(canvases[1]).convert("RGB")
        marked.paste("red", (0, 0), mask)
        marked.save(directory / f"page-{index + 1}.png")
        for column, page in enumerate((*canvases, marked)):
            paste_thumbnail(sheet, page, (column * 310 + 5, 35 + index * 410), (300, 395))
        differences.append(dict(page=index + 1, changed_pixels=changed, bbox=mask.getbbox(),
                                missing_before=left is None, missing_after=right is None))
    sheet.save(directory / "comparison.png")
    result.update(identical=all(page["changed_pixels"] == 0 for page in differences), pages=differences)
    changed_pages = [page["page"] for page in differences if page["changed_pixels"]]
    print(f"DIFF {name}: {changed_pages or 'identical'}", flush=True)
    return result


def compare_exports(root, output, results):
    comparisons = []
    for backend in sorted({row["backend"] for row in results}):
        rows = [row for row in results if row["backend"] == backend]
        overview(root, output, backend, rows)
        rows.sort(key=lambda row: 6 if row["limit"] is None else row["limit"])
        comparisons.extend(compare_pair(root, output, a, b) for a, b in zip(rows, rows[1:]))
    baseline = next((row for row in results if row["backend"] == "plain" and row["limit"] is None), None)
    if baseline is not None:
        for row in results:
            if row["limit"] is None and row["backend"] != "plain":
                comparisons.append(compare_pair(root, output, baseline, row))
    return comparisons


def classify_warnings(stderr):
    warnings = []
    for block in re.split(r"(?m)(?=^warning:)", stderr):
        if not block.startswith("warning:"):
            continue
        message = block.splitlines()[0].removeprefix("warning: ")
        if message.startswith(("document did not converge", "layout did not converge")):
            continue
        warnings.append(dict(message=message, marginalia="@preview/marginalia:" in block))
    return warnings


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--backend", nargs="+", choices=("plain", "carrier", "terms"), default=["plain", "carrier", "terms"])
    parser.add_argument("--limits", default="1,2,3,4,5")
    parser.add_argument("--terms-module", default="/elements/better-lists-set.typ")
    parser.add_argument("--output", default="tmp/notebook-convergence")
    args = parser.parse_args()
    limits = [int(value) for value in args.limits.split(",")]
    if any(value not in range(1, 6) for value in limits):
        parser.error("Limits must be integers from 1 to 5.")
    root = Path(__file__).resolve().parents[1]
    output = (root / args.output).resolve()
    output.relative_to(root)
    version = subprocess.check_output(["typst", "--version"], text=True).strip()
    results = []
    print(version, flush=True)
    print("backend\tlimit\tstatus\tlayout passes\tnon-convergence\twarnings outside marginalia", flush=True)
    for backend in args.backend:
        directory = prepare(root, output, backend, args.terms_module)
        for limit in [None, *limits]:
            label = "unlimited" if limit is None else str(limit)
            stem = output / f"{backend}-{label}"
            source = directory / ("notebook-demo.typ" if limit is None else "limited.typ")
            command = ["typst", "compile", "--root", str(root), "--creation-timestamp", "0"]
            if limit is not None:
                command += ["--input", f"max-layout-iterations={limit}"]
            pages = output / "pages" / f"{backend}-{label}"
            pages.mkdir(parents=True, exist_ok=True)
            for previous in pages.glob("page-*.png"):
                previous.unlink()
            result = subprocess.run(
                [*command, "--ppi", "96", "--timings", str(stem.with_suffix(".json")), str(source), str(pages / "page-{p}.png")],
                capture_output=True, text=True,
            )
            stem.with_suffix(".log").write_text(result.stderr, encoding="utf-8")
            trace = json.loads(stem.with_suffix(".json").read_text())
            passes = sum(event.get("name") == "layout document" and event.get("ph") == "B" for event in trace)
            images = sorted(pages.glob("page-*.png"), key=lambda path: int(path.stem.split("-")[-1]))
            row = dict(backend=backend, limit=limit, returncode=result.returncode,
                       layout_passes=passes, non_convergence="did not converge" in result.stderr,
                       pages=[str(path.relative_to(root)) for path in images],
                       warnings=classify_warnings(result.stderr))
            results.append(row)
            other_warnings = sum(not warning["marginalia"] for warning in row["warnings"])
            print(f"{backend}\t{label}\t{'ok' if result.returncode == 0 else 'error'}\t{passes}\t{row['non_convergence']}\t{other_warnings}", flush=True)
    (output / "results.json").write_text(json.dumps(dict(
        version=version, date=date.today().isoformat(), terms_module=args.terms_module,
        source_sha256=hashlib.sha256((root / "notebook-demo.typ").read_bytes()).hexdigest(),
        results=results, comparisons=compare_exports(root, output, results),
    ), indent=2), encoding="utf-8")
    if any(row["returncode"] != 0 for row in results if row["limit"] in (None, 5)):
        raise SystemExit("A full-budget compilation failed; inspect tmp/notebook-convergence/*.log.")


if __name__ == "__main__":
    main()
