#!/usr/bin/env python3
"""
Turns the hand made artwork in ui/textures/*.png into WoW ready textures.

For every source image it:
  1. flood fills the near black background starting from the image border, so
     only the surrounding area becomes transparent while dark areas enclosed by
     the artwork (for example the inside of the plaque) stay opaque,
  2. crops to the remaining artwork,
  3. resizes to power of two dimensions (WoW refuses many non power of two files),
  4. writes an uncompressed 32 bit TGA into Images/.

Usage: python3 tools/convert_textures.py
"""

from PIL import Image
from collections import deque
import os

SRC_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "GUI", "Textures")
OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "images")

# source file -> (output name, target size)
#
# Sizes are kept just above the size the artwork is actually drawn at in game
# (plaque ~430x54, buttons ~115x24, progress bar ~890x24, window 908x710). The
# 1024x1024 sources would waste memory for detail nobody can see, and since the
# artwork is drawn as slices the middle sections are stretched anyway.
# Downscaling also anti aliases the cut out edges, which is why no soft masking
# is needed after the flood fill.
TARGETS = {
    "header_plaque.png": ("art_header_plaque.tga", (256, 64)),
    "button_blank.png":  ("art_button.tga",        (128, 32)),
}

# pixels this dark count as background when they are reachable from the border
BG_LUMA = 26


def luma(p):
    return (p[0] * 299 + p[1] * 587 + p[2] * 114) // 1000


def background_mask(img):
    """True where the pixel belongs to the outer background."""
    w, h = img.size
    px = img.load()
    mask = bytearray(w * h)
    queue = deque()

    def push(x, y):
        i = y * w + x
        if not mask[i] and luma(px[x, y]) <= BG_LUMA:
            mask[i] = 1
            queue.append((x, y))

    for x in range(w):
        push(x, 0)
        push(x, h - 1)
    for y in range(h):
        push(0, y)
        push(w - 1, y)

    while queue:
        x, y = queue.popleft()
        if x > 0:
            push(x - 1, y)
        if x < w - 1:
            push(x + 1, y)
        if y > 0:
            push(x, y - 1)
        if y < h - 1:
            push(x, y + 1)

    return mask


def convert(src_name, out_name, size):
    src = os.path.join(SRC_DIR, src_name)
    img = Image.open(src).convert("RGB")
    w, h = img.size
    mask = background_mask(img)

    out = img.convert("RGBA")
    px = out.load()
    for y in range(h):
        row = y * w
        for x in range(w):
            if mask[row + x]:
                px[x, y] = (0, 0, 0, 0)

    bbox = out.getchannel("A").getbbox()
    if bbox:
        out = out.crop(bbox)
    cropped = out.size
    out = out.resize(size, Image.LANCZOS)

    os.makedirs(OUT_DIR, exist_ok=True)
    out.save(os.path.join(OUT_DIR, out_name), format="TGA")
    print(f"  {src_name:24s} crop {cropped[0]}x{cropped[1]} -> {out_name} {size[0]}x{size[1]}")


def main():
    print("Converting artwork:")
    for src_name, (out_name, size) in TARGETS.items():
        convert(src_name, out_name, size)
    print("Done.")


if __name__ == "__main__":
    main()
