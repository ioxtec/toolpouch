from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parent
BACKGROUND = ROOT / "Working/Backgrounds" / "toolpouch-gradient-v1.png"
SCREENSHOT = Path(
    "/var/folders/yl/qqht6p810dl5x_w600c4mlyr0000gn/T/TemporaryItems/"
    "NSIRD_screencaptureui_GUTkez/Zrzut ekranu 2026-10-12 o 17.13.29.png"
)
COMPACT_SCREENSHOT = Path(
    "/var/folders/yl/qqht6p810dl5x_w600c4mlyr0000gn/T/TemporaryItems/"
    "NSIRD_screencaptureui_uKVxkG/Zrzut ekranu 2026-10-12 o 17.11.01.png"
)
OUTPUT = ROOT / "Working/Archive" / "toolpouch-appstore-preview-v2-dual-mode.png"

CANVAS = (2880, 1800)
FONT = "/System/Library/Fonts/SFNS.ttf"
FONT_ROUNDED = "/System/Library/Fonts/SFNSRounded.ttf"


def crop_black_border(image: Image.Image) -> Image.Image:
    rgb = image.convert("RGB")
    mask = Image.new("L", rgb.size)
    mask.putdata(
        [255 if max(pixel) > 12 else 0 for pixel in rgb.getdata()]
    )
    bbox = mask.getbbox()
    return image.crop(bbox) if bbox else image


def fit_cover(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize(
        (round(image.width * scale), round(image.height * scale)),
        Image.Resampling.LANCZOS,
    )
    left = (resized.width - size[0]) // 2
    top = (resized.height - size[1]) // 2
    return resized.crop((left, top, left + size[0], top + size[1]))


def main() -> None:
    canvas = fit_cover(Image.open(BACKGROUND).convert("RGB"), CANVAS).convert("RGBA")

    # Darken the middle slightly to keep the interface and type crisp.
    shade = Image.new("RGBA", CANVAS, (4, 7, 27, 35))
    canvas = Image.alpha_composite(canvas, shade)

    screenshot = crop_black_border(Image.open(SCREENSHOT).convert("RGBA"))
    max_w, max_h = 1740, 1340
    scale = min(max_w / screenshot.width, max_h / screenshot.height)
    screenshot = screenshot.resize(
        (round(screenshot.width * scale), round(screenshot.height * scale)),
        Image.Resampling.LANCZOS,
    )

    sx = 1030
    sy = (CANVAS[1] - screenshot.height) // 2 + 55

    shadow = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_box = (sx - 25, sy + 25, sx + screenshot.width + 25, sy + screenshot.height + 75)
    shadow_draw.rounded_rectangle(shadow_box, radius=56, fill=(0, 0, 0, 165))
    shadow = shadow.filter(ImageFilter.GaussianBlur(55))
    canvas = Image.alpha_composite(canvas, shadow)
    canvas.alpha_composite(screenshot, (sx, sy))

    # Show the exact same tool in its compact menu-bar form, layered in front.
    compact = crop_black_border(Image.open(COMPACT_SCREENSHOT).convert("RGBA"))
    compact_w = 500
    compact_scale = compact_w / compact.width
    compact = compact.resize(
        (compact_w, round(compact.height * compact_scale)),
        Image.Resampling.LANCZOS,
    )
    cx, cy = 790, 690
    compact_shadow = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    compact_shadow_draw = ImageDraw.Draw(compact_shadow)
    compact_shadow_draw.rounded_rectangle(
        (cx - 24, cy + 20, cx + compact.width + 24, cy + compact.height + 55),
        radius=52,
        fill=(0, 0, 0, 205),
    )
    compact_shadow = compact_shadow.filter(ImageFilter.GaussianBlur(42))
    canvas = Image.alpha_composite(canvas, compact_shadow)
    canvas.alpha_composite(compact, (cx, cy))

    draw = ImageDraw.Draw(canvas)
    pill_font = ImageFont.truetype(FONT, 31)
    title_font = ImageFont.truetype(FONT_ROUNDED, 128)
    subtitle_font = ImageFont.truetype(FONT, 43)

    left = 150
    pill_y = 430
    pill_text = "TOOL POUCH FOR MAC"
    pill_bbox = draw.textbbox((0, 0), pill_text, font=pill_font)
    pill_w = pill_bbox[2] - pill_bbox[0] + 54
    draw.rounded_rectangle(
        (left, pill_y, left + pill_w, pill_y + 64),
        radius=32,
        fill=(20, 18, 48, 150),
        outline=(255, 255, 255, 90),
        width=2,
    )
    draw.text((left + 27, pill_y + 14), pill_text, font=pill_font, fill=(245, 241, 255, 230))

    draw.text(
        (left, 540),
        "Do more.\nSwitch less.",
        font=title_font,
        fill=(255, 255, 255, 255),
        spacing=-8,
        stroke_width=1,
        stroke_fill=(255, 255, 255, 90),
    )
    draw.text(
        (left, 890),
        "Everyday utilities, beautifully\norganized in one native workspace.",
        font=subtitle_font,
        fill=(224, 222, 239, 235),
        spacing=14,
    )

    # Small accent rule echoes the app's magenta graph line.
    draw.rounded_rectangle((left, 1085, left + 180, 1098), radius=7, fill=(255, 94, 183, 255))

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(OUTPUT, quality=95, optimize=True)
    print(OUTPUT)


if __name__ == "__main__":
    main()
