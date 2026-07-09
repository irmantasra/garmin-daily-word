#!/usr/bin/env python3
"""Render the Bible+cross launcher icon crisply at any size.

Usage: python3 scraper/make_icon.py <size> <out.png>
Coordinates are expressed as fractions of the canvas so the icon stays
proportional across every device's launcher-icon size.
"""
import sys

from PIL import Image, ImageDraw

COVER = (140, 22, 28, 255)     # burgundy
COVER_HI = (176, 40, 46, 255)  # lighter spine edge
PAGES = (238, 232, 214, 255)   # cream page block
GOLD = (226, 183, 74, 255)     # cross + page edge


def render(size: int) -> Image.Image:
    # Supersample 4x then downscale for smooth edges.
    ss = size * 4
    img = Image.new("RGBA", (ss, ss), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    def R(x0, y0, x1, y1, fill, radius=0):
        box = [x0 * ss, y0 * ss, x1 * ss, y1 * ss]
        if radius:
            d.rounded_rectangle(box, radius=radius * ss, fill=fill)
        else:
            d.rectangle(box, fill=fill)

    # Book body + spine highlight + page block.
    R(0.175, 0.125, 0.825, 0.875, COVER, radius=0.075)
    R(0.175, 0.125, 0.30, 0.875, COVER_HI, radius=0.075)
    R(0.75, 0.20, 0.825, 0.825, PAGES)
    R(0.275, 0.80, 0.775, 0.85, PAGES)

    # Gold cross on the cover.
    R(0.45, 0.225, 0.55, 0.675, GOLD)   # vertical bar
    R(0.35, 0.35, 0.65, 0.425, GOLD)    # horizontal bar

    return img.resize((size, size), Image.LANCZOS)


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: make_icon.py <size> <out.png>", file=sys.stderr)
        return 2
    size = int(sys.argv[1])
    render(size).save(sys.argv[2])
    print(f"wrote {sys.argv[2]} ({size}x{size})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
