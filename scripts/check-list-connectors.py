"""Reject connector-colored pixels inside enum label bounds."""

import argparse
import json
import math
from pathlib import Path
import subprocess

from PIL import Image


def points(value):
    return float(value.removesuffix("pt"))


def is_connector(pixel):
    red, green, blue = pixel
    return red > 180 and green < 100 and blue > 180


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--module", default="/elements/better-lists.typ")
    parser.add_argument("--filler", default="10.3")
    parser.add_argument("--output", default="tmp/list-connector-check")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    output = (root / args.output).resolve()
    output.relative_to(root)
    output.mkdir(parents=True, exist_ok=True)
    for previous in output.glob("page-*.png"):
        previous.unlink()
    source = root / "test/list-connector-label.typ"
    command = ["typst", "--root", str(root), "--input", f"module={args.module}", "--input", f"filler={args.filler}"]
    subprocess.run([command[0], "compile", *command[1:], "--ppi", "144", str(source), str(output / "page-{p}.png")], check=True)
    expression = '''query(metadata)
      .filter(it => type(it.value) == dictionary and it.value.at("test", default: none) == "connector-label")
      .map(it => (..it.value, position: it.location().position()))'''
    result = subprocess.check_output([command[0], "eval", *command[1:], "--in", str(source), expression], text=True)
    labels = json.loads(result)
    assert labels, "The connector fixture must produce label metadata."
    images = {}
    overlaps = []
    missing_stems = []
    for label in labels:
        position = label["position"]
        page = position["page"]
        if page not in images:
            with Image.open(output / f"page-{page}.png") as image:
                images[page] = image.convert("RGB")
        image = images[page]
        x, y = points(position["x"]), points(position["y"])
        left = max(0, math.floor(2 * x))
        right = min(image.width, math.ceil(2 * (x + points(label["width"]))))
        top = max(0, math.floor(2 * (y - points(label["ascent"]))))
        bottom = min(image.height, math.ceil(2 * (y + 0.25)))
        if any(is_connector(image.getpixel((px, py)))
               for py in range(top, bottom) for px in range(left, right)):
            overlaps.append(dict(page=page, x=x, y=y))
        if label["expect-stem"]:
            stem_x = round(2 * (x + points(label["stem-offset"])))
            if not any(is_connector(image.getpixel((px, py)))
                       for py in range(math.ceil(2 * (y + 6)), math.ceil(2 * (y + 16)))
                       for px in range(stem_x - 1, stem_x + 2)):
                missing_stems.append(dict(page=page, x=x, y=y))
    (output / "result.json").write_text(json.dumps(dict(
        labels=len(labels), overlaps=overlaps, missing_stems=missing_stems,
    ), indent=2))
    if overlaps:
        raise SystemExit(f"Connector overlaps label bounds: {overlaps}")
    if missing_stems:
        raise SystemExit(f"Expected connector stems are missing: {missing_stems}")
    print(f"PASS: {len(labels)} labels have no connector overlap and expected stems remain; images: {output.relative_to(root)}")


if __name__ == "__main__":
    main()
