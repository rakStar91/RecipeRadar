#!/usr/bin/env python3
"""
Generates all custom UI textures for the RecipeRadar addon (Dark theme look).

Output (images/):
  fill_panel.tga        dark inset background (lists, detail panel)
  fill_frame.tga        main window background
  fill_btn_normal.tga   dropdown arrow background
  fill_row_selected.tga selected list row (teal tint)
  fill_progress.tga     progress bar fill (green)

Fill textures are 8 x 64 vertical gradients. They are stretched to any size
in-game via SetAllPoints, which is lossless for smooth gradients. Borders are
drawn in Lua with WHITE8X8 + SetVertexColor, so no border assets are needed.

Usage: python3 tools/generate_textures.py
"""

from PIL import Image
import os
import math

OUT_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "images"
)

FILL_W, FILL_H = 8, 64


def lerp(a, b, t):
    return a + (b - a) * t


def save(img, name):
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, name)
    img.save(path, format="TGA")
    print(f"  {name:24s} {img.width}x{img.height}")


def make_fill(name, top_rgb, bottom_rgb, top_a=1.0, bottom_a=1.0, sheen=0.0):
    """Vertical gradient fill. `sheen` adds a subtle glossy highlight near the top."""
    img = Image.new("RGBA", (FILL_W, FILL_H), (0, 0, 0, 0))
    for y in range(FILL_H):
        t = y / (FILL_H - 1)
        r = lerp(top_rgb[0], bottom_rgb[0], t)
        g = lerp(top_rgb[1], bottom_rgb[1], t)
        b = lerp(top_rgb[2], bottom_rgb[2], t)
        a = lerp(top_a, bottom_a, t)

        if sheen > 0.0:
            # soft highlight band in the upper third
            band = math.exp(-((t - 0.18) ** 2) / 0.012) * sheen
            r = min(1.0, r + band)
            g = min(1.0, g + band)
            b = min(1.0, b + band)

        px = (int(r * 255), int(g * 255), int(b * 255), int(a * 255))
        for x in range(FILL_W):
            img.putpixel((x, y), px)
    save(img, name)


def main():
    print("Generating MTSL UI textures:")

    # backgrounds
    make_fill("fill_frame.tga", (0.055, 0.055, 0.060), (0.030, 0.030, 0.034),
              top_a=0.96, bottom_a=0.96)
    make_fill("fill_panel.tga", (0.035, 0.035, 0.040), (0.018, 0.018, 0.022),
              top_a=0.97, bottom_a=0.97)

    # buttons (only the dropdown arrow background still uses a fill texture,
    # CreateDarkButton renders its own states by tinting art_button.tga instead)
    make_fill("fill_btn_normal.tga", (0.120, 0.120, 0.135), (0.055, 0.055, 0.065),
              top_a=0.95, bottom_a=0.95, sheen=0.030)

    # list row selection + progress bar
    make_fill("fill_row_selected.tga", (0.080, 0.260, 0.250), (0.040, 0.150, 0.145),
              top_a=0.75, bottom_a=0.75)
    # deliberately muted: the prototype bar is understated, not neon green
    make_fill("fill_progress.tga", (0.105, 0.300, 0.190), (0.055, 0.175, 0.110),
              top_a=0.92, bottom_a=0.92, sheen=0.020)

    print("Done.")


if __name__ == "__main__":
    main()
