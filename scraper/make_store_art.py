#!/usr/bin/env python3
"""Generate Connect IQ Store artwork: a 1440x720 hero banner and a 512x512
cover image, using the app's burgundy / gold / cream identity.

Usage: python3 scraper/make_store_art.py <out_dir>
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

# Palette (matches the launcher icon).
BG_TOP = (46, 12, 16)       # deep burgundy
BG_BOT = (20, 8, 10)        # near black
COVER = (140, 22, 28)
COVER_HI = (176, 40, 46)
PAGES = (238, 232, 214)
GOLD = (226, 183, 74)
CREAM = (238, 232, 214)
GRAY = (170, 165, 158)

FONT_DIR = "/System/Library/Fonts/Supplemental"


def font(name, size):
    return ImageFont.truetype(f"{FONT_DIR}/{name}", size)


def vertical_gradient(w, h, top, bot):
    base = Image.new("RGB", (w, h), top)
    top_img = Image.new("RGB", (w, h), bot)
    mask = Image.new("L", (w, h))
    md = mask.load()
    for y in range(h):
        v = int(255 * (y / (h - 1)))
        for x in range(w):
            md[x, y] = v
    base.paste(top_img, (0, 0), mask)
    return base


def draw_bible(d, cx, cy, s):
    """Draw the Bible+cross centered at (cx, cy), overall size ~s px."""
    def R(fx0, fy0, fx1, fy1, fill, radius=0):
        box = [cx + (fx0 - 0.5) * s, cy + (fy0 - 0.5) * s,
               cx + (fx1 - 0.5) * s, cy + (fy1 - 0.5) * s]
        if radius:
            d.rounded_rectangle(box, radius=radius * s, fill=fill)
        else:
            d.rectangle(box, fill=fill)

    R(0.175, 0.125, 0.825, 0.875, COVER, radius=0.075)
    R(0.175, 0.125, 0.30, 0.875, COVER_HI, radius=0.075)
    R(0.75, 0.20, 0.825, 0.825, PAGES)
    R(0.275, 0.80, 0.775, 0.85, PAGES)
    R(0.45, 0.225, 0.55, 0.675, GOLD)   # vertical bar
    R(0.35, 0.35, 0.65, 0.425, GOLD)    # horizontal bar


def center_text(d, cx, y, text, fnt, fill):
    bbox = d.textbbox((0, 0), text, font=fnt)
    w = bbox[2] - bbox[0]
    d.text((cx - w / 2, y), text, font=fnt, fill=fill)
    return bbox[3] - bbox[1]


def make_hero(out):
    W, H = 1440, 720
    img = vertical_gradient(W, H, BG_TOP, BG_BOT)
    d = ImageDraw.Draw(img)

    # Bible icon on the left third.
    draw_bible(d, 380, H // 2, 340)

    # Text block on the right.
    tx = 720
    d.text((tx, 210), "Daily Word", font=font("Georgia Bold.ttf", 96), fill=CREAM)
    d.text((tx, 330), "Catholic Mass readings,", font=font("Georgia.ttf", 46), fill=GOLD)
    d.text((tx, 392), "at a glance.", font=font("Georgia.ttf", 46), fill=GOLD)
    d.text((tx, 480), "First reading · Psalm · Gospel", font=font("Arial.ttf", 34), fill=GRAY)
    d.text((tx, 528), "Lithuanian & English · updated daily",
           font=font("Arial.ttf", 34), fill=GRAY)

    img.save(out)
    print(f"wrote {out} (1440x720)")


def make_cover(out):
    S = 512
    img = vertical_gradient(S, S, BG_TOP, BG_BOT)
    d = ImageDraw.Draw(img)

    draw_bible(d, S // 2, 215, 300)
    center_text(d, S // 2, 400, "Daily Word", font("Georgia Bold.ttf", 52), CREAM)
    center_text(d, S // 2, 462, "Mass readings", font("Arial.ttf", 26), GOLD)

    img.save(out)
    print(f"wrote {out} (512x512)")


def main():
    out_dir = Path(sys.argv[1] if len(sys.argv) > 1 else "store-art")
    out_dir.mkdir(parents=True, exist_ok=True)
    make_hero(out_dir / "hero.png")
    make_cover(out_dir / "cover.png")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
