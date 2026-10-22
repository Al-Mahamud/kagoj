"""Draws the Kagoj logo and writes every icon the app needs.

The mark: a newspaper page with a folded corner, a bold Bangla "ক" (Kagoj = কাগজ,
"paper"), text lines with one highlighted like a selected word, and sound waves
for read-aloud, on the app's teal.

Usage (from the project root):
    python3 tool/generate_logo.py . [path/to/NotoSerifBengali-Bold.ttf]

Writes:
    android/app/src/main/res/mipmap-*/ic_launcher.png             legacy icon
    android/app/src/main/res/mipmap-*/ic_launcher_foreground.png  adaptive layer
    android/app/src/main/res/mipmap-*/ic_launcher_monochrome.png  Android 13 themed icon
    assets/brand/logo.png                                         in-app logo (512 px)
    assets/brand/logo_store.png                                   Play Store icon (512 px)
"""

import math
import os
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
FONT = sys.argv[2] if len(sys.argv) > 2 else "/usr/share/fonts/truetype/noto/NotoSerifBengali-Bold.ttf"

S = 4  # supersampling factor; the design grid is 1024
N = 1024 * S

PAGE = (0xF7, 0xF4, 0xEE)
FOLD = (0xDD, 0xD5, 0xC5)
INK = (0x13, 0x23, 0x3A)
LINE = (0xC9, 0xCD, 0xD4)
HIGHLIGHT = (0xF5, 0xB8, 0x3D)
WAVE = (0xFD, 0xE6, 0x8A)
TEAL_LIGHT = (0x1A, 0xA3, 0x94)
TEAL_MID = (0x0F, 0x76, 0x6E)
TEAL_DARK = (0x08, 0x47, 0x43)

# Page geometry on the 1024 grid.
X0, Y0, X1, Y1 = 250, 220, 640, 800
FOLD_SIZE = 120
GLYPH_CENTER = (432, 470)
GLYPH_SIZE = 300
LINES = [  # (x0, x1, y, colour)
    (300, 590, 652, LINE),
    (300, 540, 702, HIGHLIGHT),
    (300, 570, 752, LINE),
]
LINE_HEIGHT = 24
WAVE_CENTER = (600, 470)
WAVE_RADII = [150, 228, 306]
WAVE_ALPHA = [255, 190, 125]
WAVE_WIDTH = 38
WAVE_SPAN = 38  # degrees either side of horizontal


def p(*values):
    return [int(v * S) for v in values]


def blank_mask():
    return Image.new("L", (N, N), 0)


def page_mask():
    m = blank_mask()
    d = ImageDraw.Draw(m)
    d.rounded_rectangle(p(X0, Y0, X1, Y1), radius=40 * S, fill=255)
    d.polygon(p(X1 - FOLD_SIZE, Y0 - 1, X1 + 1, Y0 - 1, X1 + 1, Y0 + FOLD_SIZE), fill=0)
    return m


def fold_mask():
    m = blank_mask()
    ImageDraw.Draw(m).polygon(
        p(X1 - FOLD_SIZE, Y0, X1 - FOLD_SIZE, Y0 + FOLD_SIZE, X1, Y0 + FOLD_SIZE), fill=255
    )
    return m


def glyph_mask():
    m = blank_mask()
    font = ImageFont.truetype(FONT, GLYPH_SIZE * S)
    ImageDraw.Draw(m).text(p(*GLYPH_CENTER), "ক", font=font, fill=255, anchor="mm")
    return m


def line_mask(index):
    x0, x1, y, _ = LINES[index]
    m = blank_mask()
    ImageDraw.Draw(m).rounded_rectangle(
        p(x0, y, x1, y + LINE_HEIGHT), radius=LINE_HEIGHT // 2 * S, fill=255
    )
    return m


def wave_mask(radius):
    m = blank_mask()
    d = ImageDraw.Draw(m)
    cx, cy = WAVE_CENTER
    outer = radius + WAVE_WIDTH / 2
    d.arc(p(cx - outer, cy - outer, cx + outer, cy + outer), -WAVE_SPAN, WAVE_SPAN,
          fill=255, width=WAVE_WIDTH * S)
    for angle in (-WAVE_SPAN, WAVE_SPAN):  # rounded caps
        ex = cx + radius * math.cos(math.radians(angle))
        ey = cy + radius * math.sin(math.radians(angle))
        r = WAVE_WIDTH / 2
        d.ellipse(p(ex - r, ey - r, ex + r, ey + r), fill=255)
    return m


def layer(colour, mask, alpha=255):
    img = Image.new("RGBA", (N, N), colour + (0,))
    if alpha != 255:
        mask = mask.point(lambda v: v * alpha // 255)
    img.putalpha(mask)
    return img


def colour_mark():
    page = page_mask()
    mark = Image.new("RGBA", (N, N), (0, 0, 0, 0))

    shadow = ImageChops.offset(page, 0, 22 * S).filter(ImageFilter.GaussianBlur(26 * S))
    mark.alpha_composite(layer((0, 0, 0), shadow, 90))
    mark.alpha_composite(layer(PAGE, page))
    mark.alpha_composite(layer(FOLD, fold_mask()))
    mark.alpha_composite(layer(INK, ImageChops.multiply(glyph_mask(), page)))
    for i, (_, _, _, colour) in enumerate(LINES):
        mark.alpha_composite(layer(colour, line_mask(i)))
    for radius, alpha in zip(WAVE_RADII, WAVE_ALPHA):
        mark.alpha_composite(layer(WAVE, wave_mask(radius), alpha))
    return mark


def mono_mark():
    """Single-colour silhouette: page with the letter and lines cut out, plus waves."""
    alpha = ImageChops.subtract(page_mask(), glyph_mask())
    for i in range(len(LINES)):
        alpha = ImageChops.subtract(alpha, line_mask(i))
    for radius in WAVE_RADII:
        alpha = ImageChops.lighter(alpha, wave_mask(radius))
    return layer((255, 255, 255), alpha)


def fit(mark, size, *, box=None, diagonal=None):
    """Scales the mark's bounding box to a fraction of `size` and centres it."""
    cropped = mark.crop(mark.getchannel("A").getbbox())
    w, h = cropped.size
    scale = (box * size / max(w, h)) if box else (diagonal * size / math.hypot(w, h))
    scaled = cropped.resize((max(1, round(w * scale)), max(1, round(h * scale))),
                            Image.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(scaled, ((size - scaled.width) // 2, (size - scaled.height) // 2))
    return canvas


def gradient_square(size):
    """Smooth diagonal teal gradient, light top-left to dark bottom-right."""
    ramp = Image.linear_gradient("L").rotate(45, expand=True, resample=Image.BICUBIC)
    # Only the middle square (side / √2) of the rotated ramp has no empty corners.
    side = int(256 / math.sqrt(2)) - 2
    inset = (ramp.width - side) // 2
    t = ramp.crop((inset, inset, inset + side, inset + side)).resize((size, size), Image.BICUBIC)
    # Pass through TEAL_MID halfway so the middle doesn't go muddy.
    first = Image.composite(Image.new("RGB", (size, size), TEAL_MID),
                            Image.new("RGB", (size, size), TEAL_LIGHT),
                            t.point(lambda v: min(255, v * 2)))
    blended = Image.composite(Image.new("RGB", (size, size), TEAL_DARK), first,
                              t.point(lambda v: max(0, v * 2 - 255)))
    return blended.convert("RGBA")


def full_icon(mark, size, *, corner=0.225):
    big = size * S
    bg = gradient_square(big)
    mask = Image.new("L", (big, big), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, big - 1, big - 1),
                                           radius=int(big * corner), fill=255)
    bg.putalpha(mask)
    icon = bg.resize((size, size), Image.LANCZOS)
    icon.alpha_composite(fit(mark, size, box=0.72))
    return icon


def save(img, *parts):
    path = os.path.join(ROOT, *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, optimize=True)
    print("wrote", os.path.relpath(path, ROOT), img.size)


def main():
    mark = colour_mark()
    mono = mono_mark()

    densities = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
    res = ("android", "app", "src", "main", "res")
    for name, k in densities.items():
        folder = f"mipmap-{name}"
        save(full_icon(mark, round(48 * k)), *res, folder, "ic_launcher.png")
        # Adaptive layers are 108dp; launchers may crop to a 66dp circle, so the
        # mark's diagonal stays inside it.
        save(fit(mark, round(108 * k), diagonal=0.6), *res, folder, "ic_launcher_foreground.png")
        save(fit(mono, round(108 * k), diagonal=0.6), *res, folder, "ic_launcher_monochrome.png")

    save(full_icon(mark, 512), "assets", "brand", "logo.png")
    save(full_icon(mark, 512, corner=0), "assets", "brand", "logo_store.png")


if __name__ == "__main__":
    main()
