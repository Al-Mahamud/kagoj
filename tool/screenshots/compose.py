"""Turns raw demo screenshots into the README images.

    python3 tool/screenshots/compose.py <shots-dir> <project-root>

Reads <shots-dir>/<screen>-<theme>.png (1170x2532, from shoot.mjs) and writes
docs/screenshots/{banner,features,dark-mode}.png plus docs/screenshots/raw/*.png.
"""

import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

SHOTS, ROOT = sys.argv[1], sys.argv[2]
OUT = os.path.join(ROOT, "docs", "screenshots")
FONTS = "/usr/share/fonts/truetype/noto"


def font(name, size):
    return ImageFont.truetype(os.path.join(FONTS, name), size)


BOLD = lambda size: font("NotoSans-Bold.ttf", size)  # noqa: E731
REGULAR = lambda size: font("NotoSans-Regular.ttf", size)  # noqa: E731
BANGLA = lambda size: font("NotoSansBengali-Bold.ttf", size)  # noqa: E731

INK = (11, 18, 32)
MUTED = (91, 100, 116)


def shot(name):
    return Image.open(os.path.join(SHOTS, f"{name}.png")).convert("RGB")


def gradient(size, start, end, diagonal=True):
    w, h = size
    ramp = Image.linear_gradient("L").resize((256, 256))
    if diagonal:
        ramp = ramp.rotate(45, expand=True, resample=Image.BICUBIC)
        side = int(256 / 2 ** 0.5) - 2
        inset = (ramp.width - side) // 2
        ramp = ramp.crop((inset, inset, inset + side, inset + side))
    mask = ramp.resize((w, h), Image.BICUBIC)
    return Image.composite(Image.new("RGB", size, end), Image.new("RGB", size, start), mask)


def rounded_mask(size, radius, scale=3):
    big = Image.new("L", (size[0] * scale, size[1] * scale), 0)
    ImageDraw.Draw(big).rounded_rectangle((0, 0, big.width - 1, big.height - 1),
                                          radius=radius * scale, fill=255)
    return big.resize(size, Image.LANCZOS)


def phone(screen, width, shadow_alpha=80):
    """An Android-style phone: thin dark bezel, rounded corners, punch-hole camera."""
    sw = width
    sh = round(screen.height * sw / screen.width)
    bezel = max(8, round(sw * 0.032))
    radius = round(sw * 0.12)
    fw, fh = sw + 2 * bezel, sh + 2 * bezel
    pad = round(sw * 0.12)  # room for the shadow

    canvas = Image.new("RGBA", (fw + 2 * pad, fh + 2 * pad), (0, 0, 0, 0))

    body = rounded_mask((fw, fh), radius)
    shadow = Image.new("L", canvas.size, 0)
    shadow.paste(body, (pad, pad + round(sw * 0.04)))
    shadow = shadow.filter(ImageFilter.GaussianBlur(sw * 0.045))
    canvas.paste((0, 0, 0, 255), (0, 0), shadow.point(lambda v: v * shadow_alpha // 255))

    frame = Image.new("RGBA", (fw, fh), (16, 19, 23, 255))
    edge = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
    ImageDraw.Draw(edge).rounded_rectangle((1, 1, fw - 2, fh - 2), radius=radius,
                                           outline=(58, 64, 72, 255), width=2)
    frame.alpha_composite(edge)

    content = screen.resize((sw, sh), Image.LANCZOS).convert("RGBA")
    frame.paste(content, (bezel, bezel), rounded_mask((sw, sh), radius - bezel))

    cam = max(6, round(sw * 0.028))
    cx, cy = fw // 2, bezel + round(sw * 0.03)
    ImageDraw.Draw(frame).ellipse((cx - cam // 2, cy - cam // 2, cx + cam // 2, cy + cam // 2),
                                  fill=(5, 7, 10, 255))

    canvas.paste(frame, (pad, pad), body)
    return canvas, pad


def wrap(draw, text, fnt, max_width):
    lines, line = [], ""
    for word in text.split():
        trial = f"{line} {word}".strip()
        if draw.textlength(trial, font=fnt) <= max_width:
            line = trial
        else:
            lines.append(line)
            line = word
    return lines + [line]


def save(img, name):
    os.makedirs(os.path.dirname(os.path.join(OUT, name)), exist_ok=True)
    path = os.path.join(OUT, name)
    img.convert("RGB").save(path, optimize=True)
    print("wrote", os.path.relpath(path, ROOT), img.size)


def glow(img, center, radius, colour, alpha):
    layer = Image.new("L", img.size, 0)
    x, y = center
    ImageDraw.Draw(layer).ellipse((x - radius, y - radius, x + radius, y + radius), fill=alpha)
    layer = layer.filter(ImageFilter.GaussianBlur(radius * 0.45))
    img.paste(colour, (0, 0), layer)


def banner():
    W, H = 2400, 1080
    img = gradient((W, H), (18, 137, 125), (8, 40, 48)).convert("RGBA")
    glow(img, (1850, 300), 520, (45, 212, 191), 46)
    glow(img, (300, 1000), 420, (253, 230, 138), 22)
    d = ImageDraw.Draw(img)

    logo = Image.open(os.path.join(ROOT, "assets", "brand", "logo.png")).convert("RGBA")
    img.alpha_composite(logo.resize((150, 150), Image.LANCZOS), (140, 230))

    d.text((140, 410), "Kagoj", font=BOLD(132), fill="white")
    title_w = d.textlength("Kagoj", font=BOLD(132))
    d.text((140 + title_w + 28, 470), "কাগজ", font=BANGLA(62), fill=(126, 231, 216))

    tagline = ["Read your daily e-paper,", "listen to it, and learn every word."]
    for i, line in enumerate(tagline):
        d.text((144, 600 + i * 62), line, font=REGULAR(46), fill=(232, 244, 242))

    # Translucent chips go on their own layer: drawing them straight onto the
    # image would replace pixels with the alpha value instead of blending.
    chips = Image.new("RGBA", img.size, (0, 0, 0, 0))
    cd = ImageDraw.Draw(chips)
    x = 144
    labels = ["Read aloud", "Tap for meaning", "Bangla + English", "Dark mode"]
    positions = []
    for chip in labels:
        w = d.textlength(chip, font=BOLD(28)) + 48
        cd.rounded_rectangle((x, 800, x + w, 860), radius=30, fill=(255, 255, 255, 38))
        positions.append(x)
        x += w + 16
    img.alpha_composite(chips)
    for chip, x in zip(labels, positions):
        d.text((x + 24, 830), chip, font=BOLD(28), fill="white", anchor="lm")

    for name, width, cx, top in [
        ("listen-light", 330, 1480, 205),
        ("home-light", 330, 2150, 205),
        ("meaning-light", 392, 1815, 105),
    ]:
        ph, pad = phone(shot(name), width, shadow_alpha=120)
        img.alpha_composite(ph, (cx - ph.width // 2, top - pad))
    save(img, "banner.png")


FEATURES = [
    ("home-light", "All your papers",
     "Prothom Alo and The Daily Star built in, plus any e-paper you add by link."),
    ("meaning-light", "Tap any word",
     "Meaning, pronunciation and Bangla translation in one tap."),
    ("translate-light", "Translate a sentence",
     "Select Bangla or English text and hear both versions read aloud."),
    ("listen-light", "Listen to the article",
     "Sentence-by-sentence read-aloud that highlights and follows along."),
    ("words-light", "Build your vocabulary",
     "Every word and sentence you save, with search and filters."),
]


def strip(items, path, *, bg, title_colour, text_colour, heading=None, shadow_alpha=80):
    phone_w, gap, margin = 430, 64, 80
    sample, pad = phone(shot(items[0][0]), phone_w)
    col_w = sample.width - 2 * pad
    W = margin * 2 + len(items) * col_w + (len(items) - 1) * gap
    head_h = 190 if heading else 0
    caption_h = 200 if any(title for _, title, _ in items) else 30
    H = head_h + caption_h + sample.height - 2 * pad + 110
    img = bg((W, H)).convert("RGBA")
    d = ImageDraw.Draw(img)

    if heading:
        title, subtitle = heading
        d.text((W // 2, 90), title, font=BOLD(56), fill=title_colour, anchor="mm")
        d.text((W // 2, 150), subtitle, font=REGULAR(30), fill=text_colour, anchor="mm")

    for i, (name, title, subtitle) in enumerate(items):
        x = margin + i * (col_w + gap)
        y = head_h + 60
        if title:
            d.text((x + col_w // 2, y), title, font=BOLD(38), fill=title_colour, anchor="mt")
            lines = wrap(d, subtitle, REGULAR(25), col_w - 20)
            assert len(lines) <= 2, f"caption too long for {name}: {lines}"
            for j, line in enumerate(lines):
                d.text((x + col_w // 2, y + 58 + j * 34), line, font=REGULAR(25),
                       fill=text_colour, anchor="mt")
        ph, pad = phone(shot(name), phone_w, shadow_alpha=shadow_alpha)
        img.alpha_composite(ph, (x - pad, head_h + caption_h - pad))
    save(img, path)


def raw():
    for f in sorted(os.listdir(SHOTS)):
        if f.endswith(".png"):
            im = shot(f[:-4])
            save(im.resize((585, round(im.height * 585 / im.width)), Image.LANCZOS),
                 os.path.join("raw", f))


if __name__ == "__main__":
    banner()
    strip(FEATURES, "features.png",
          bg=lambda s: gradient(s, (234, 244, 242), (245, 246, 248), diagonal=False),
          title_colour=INK, text_colour=MUTED)
    strip([("home-dark", "", ""), ("meaning-dark", "", ""), ("listen-dark", "", ""),
           ("settings-dark", "", "")],
          "dark-mode.png",
          bg=lambda s: gradient(s, (14, 18, 24), (9, 47, 46)),
          title_colour=(236, 240, 244), text_colour=(154, 164, 178),
          heading=("Easy on the eyes at night",
                   "Light, Dark, or follow the phone — switch any time in Settings."),
          shadow_alpha=160)
    raw()
