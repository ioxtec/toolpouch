from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parent
RC = ROOT / "RC"
BACKGROUNDS = ROOT / "Working/Backgrounds"
CANVAS = (2880, 1800)
FONT = "/System/Library/Fonts/SFNS.ttf"
FONT_ROUNDED = "/System/Library/Fonts/SFNSRounded.ttf"
FONT_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"

SCREENSHOTS = {
    "home": ROOT / "SourceScreenshots/2026-10-12/01-menu-dashboard.png",
    "wifi": ROOT / "SourceScreenshots/2026-10-12/03-window-wifi-scanner.png",
    "calculator": ROOT / "SourceScreenshots/2026-10-12/05-window-scientific-calculator.png",
    "graph_compact": ROOT / "SourceScreenshots/2026-10-13/08-function-graphs-dracula.png",
    "map": ROOT / "SourceScreenshots/2026-10-12/08-window-map-coordinates.png",
    "stats": ROOT / "SourceScreenshots/2026-10-12/09-menu-system-stats.png",
    "hash": ROOT / "SourceScreenshots/2026-10-12/12-menu-hash-checksum.png",
    "password": ROOT / "SourceScreenshots/2026-10-12/14-menu-password-generator.png",
    "image_toolkit": ROOT / "SourceScreenshots/2026-10-12/07-window-image-toolkit.png",
    "converter": ROOT / "SourceScreenshots/2026-10-12/04-window-unit-converter.png",
    "graph_full": ROOT / "SourceScreenshots/2026-10-12/06-window-function-graphs.png",
    "theme_mint": ROOT / "SourceScreenshots/2026-10-13/04-menu-slate-mint.png",
    "theme_orange": ROOT / "SourceScreenshots/2026-10-13/05-menu-graphite-orange.png",
    "theme_lime": ROOT / "SourceScreenshots/2026-10-13/07-menu-graphite-lime.png",
}

APP_ICON = ROOT.parent / "design/icon-concepts/toolpouch-app-icon-coyote.png"


def crop_black_border(image: Image.Image) -> Image.Image:
    rgb = image.convert("RGB")
    mask = Image.new("L", rgb.size)
    mask.putdata([255 if max(pixel) > 12 else 0 for pixel in rgb.getdata()])
    bbox = mask.getbbox()
    return image.crop(bbox) if bbox else image


def cover(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
    x = (resized.width - size[0]) // 2
    y = (resized.height - size[1]) // 2
    return resized.crop((x, y, x + size[0], y + size[1]))


def backdrop(filename: str, dim: int = 34) -> Image.Image:
    image = cover(Image.open(BACKGROUNDS / "toolpouch-misty-landscape.avif").convert("RGB"), CANVAS)
    image = image.filter(ImageFilter.GaussianBlur(16)).convert("RGBA")
    # A quiet woodland palette keeps the landscape recognizable and supports
    # white headlines without the bright streaks of the former backgrounds.
    return Image.alpha_composite(image, Image.new("RGBA", CANVAS, (19, 32, 30, 150)))


def scaled_screenshot(name: str, width: int) -> Image.Image:
    image = crop_black_border(Image.open(SCREENSHOTS[name]).convert("RGBA"))
    scale = width / image.width
    return image.resize((width, round(image.height * scale)), Image.Resampling.LANCZOS)


def place_window(canvas: Image.Image, image: Image.Image, xy: tuple[int, int], blur: int = 44, opacity: int = 190) -> None:
    x, y = xy
    shadow = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow)
    draw.rounded_rectangle(
        (x - 24, y + 20, x + image.width + 24, y + image.height + 58),
        radius=52,
        fill=(0, 0, 0, opacity),
    )
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(blur)))
    canvas.alpha_composite(image, xy)


def add_copy(canvas: Image.Image, description: str, accent=(255, 94, 183, 255)) -> None:
    draw = ImageDraw.Draw(canvas)
    left = 150
    font = ImageFont.truetype(FONT_ROUNDED, 88)
    draw.multiline_text((left, 500), description, font=font, fill="white", spacing=16)
    bottom = draw.multiline_textbbox((left, 500), description, font=font, spacing=16)[3]
    draw.rounded_rectangle((left, bottom + 65, left + 180, bottom + 78), radius=7, fill=accent)


def add_tag(canvas: Image.Image) -> None:
    add_brand(canvas)


def add_brand(canvas: Image.Image) -> None:
    icon = Image.open(APP_ICON).convert("RGBA").resize((180, 180), Image.Resampling.LANCZOS)
    icon_shadow = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(icon_shadow)
    shadow_draw.rounded_rectangle((150, 110, 330, 290), radius=34, fill=(0, 0, 0, 100))
    canvas.alpha_composite(icon_shadow.filter(ImageFilter.GaussianBlur(28)))
    canvas.alpha_composite(icon, (150, 100))

    draw = ImageDraw.Draw(canvas)
    font = ImageFont.truetype(FONT_BOLD, 62)
    draw.text((365, 140), "Tool Pouch", font=font, fill="white")
    draw.text((368, 220), "YOUR EVERYDAY TOOLKIT FOR MAC", font=ImageFont.truetype(FONT, 25), fill=(231, 237, 230, 255))


def slide_dual_mode() -> Path:
    canvas = backdrop("toolpouch-gradient-v1.png")
    add_copy(
        canvas,
        "Open your tools\nfrom the menu bar\nor work in a\nfull window.",
    )
    full = scaled_screenshot("graph_full", 1500)
    compact = scaled_screenshot("graph_compact", 470)
    baseline = 1570
    place_window(canvas, full, (1320, baseline - full.height), opacity=165)
    place_window(canvas, compact, (930, baseline - compact.height), blur=40, opacity=215)
    add_brand(canvas)
    output = RC / "01-toolpouch-dual-mode.png"
    canvas.convert("RGB").save(output, quality=95, optimize=True)
    return output


def slide_diagnostics() -> Path:
    canvas = backdrop("toolpouch-gradient-connectivity.png", 42)
    add_copy(
        canvas,
        "Explore nearby\nWi-Fi networks\nand check how\nyour Mac is running.",
        accent=(73, 211, 255, 255),
    )
    # Keep the full workspace large enough for its rows and labels to remain
    # legible at App Store preview size. The compact panel overlaps it as the
    # secondary view, matching the visual scale used on the opening slide.
    wifi = scaled_screenshot("wifi", 1400)
    stats = scaled_screenshot("stats", 500)
    baseline = 1570
    place_window(canvas, wifi, (1360, baseline - wifi.height), blur=42, opacity=195)
    place_window(canvas, stats, (1050, baseline - stats.height), opacity=215)
    add_tag(canvas)
    output = RC / "02-toolpouch-diagnostics.png"
    canvas.convert("RGB").save(output, quality=95, optimize=True)
    return output


def slide_calculate() -> Path:
    canvas = backdrop("toolpouch-gradient-calculate.png", 30)
    add_copy(
        canvas,
        "Plot a function\nto see how it behaves\nand convert between\neveryday units.",
        accent=(255, 112, 177, 255),
    )
    # Two large, immediately readable examples communicate more than three
    # thumbnail-sized windows. Let the workspace run close to the right edge
    # and use the menu-bar graph as a strong foreground detail.
    graph = scaled_screenshot("graph_compact", 650)
    converter = scaled_screenshot("converter", 1500)
    baseline = 1570
    place_window(canvas, converter, (1260, baseline - converter.height), blur=40, opacity=195)
    place_window(canvas, graph, (1160, baseline - graph.height), opacity=215)
    add_tag(canvas)
    output = RC / "03-toolpouch-calculate.png"
    canvas.convert("RGB").save(output, quality=95, optimize=True)
    return output


def slide_everyday() -> Path:
    canvas = backdrop("toolpouch-gradient-everyday.png", 44)
    add_copy(
        canvas,
        "Find a place,\ncopy its coordinates\nand check whether\na file has changed.",
        accent=(84, 235, 208, 255),
    )
    # Feature the useful parts at presentation scale instead of showing a row
    # of complete but unreadable windows.
    map_view = scaled_screenshot("map", 1400)
    hash_view = scaled_screenshot("hash", 610)
    baseline = 1580
    place_window(canvas, map_view, (1370, baseline - map_view.height), blur=42, opacity=195)
    place_window(canvas, hash_view, (1040, baseline - hash_view.height), opacity=220)
    add_tag(canvas)
    output = RC / "04-toolpouch-everyday-tools.png"
    canvas.convert("RGB").save(output, quality=95, optimize=True)
    return output


def slide_files_and_security() -> Path:
    canvas = backdrop("toolpouch-gradient-connectivity.png", 48)
    add_copy(
        canvas,
        "Resize your images,\ncheck file integrity\nand generate\nstrong passwords.",
        accent=(91, 255, 199, 255),
    )
    toolkit = scaled_screenshot("image_toolkit", 1300)
    hash_view = scaled_screenshot("hash", 610)
    password = scaled_screenshot("password", 610)
    baseline = 1570
    place_window(canvas, toolkit, (1400, baseline - toolkit.height), blur=42, opacity=190)
    place_window(canvas, hash_view, (1040, baseline - hash_view.height), opacity=220)
    place_window(canvas, password, (2150, baseline - password.height), opacity=220)
    add_tag(canvas)
    output = RC / "05-toolpouch-files-security.png"
    canvas.convert("RGB").save(output, quality=95, optimize=True)
    return output


def slide_themes() -> Path:
    canvas = backdrop("toolpouch-gradient-everyday.png", 50)
    add_copy(
        canvas,
        "Choose a color theme\nto match your mood\nor your workspace.",
        accent=(183, 255, 60, 255),
    )
    mint = scaled_screenshot("theme_mint", 780)
    orange = scaled_screenshot("theme_orange", 780)
    lime = scaled_screenshot("theme_lime", 780)
    # Large staggered panels fill the available space while keeping a
    # 120-pixel outer margin and the copy clear of every screenshot.
    place_window(canvas, mint, (980, 1450 - mint.height), opacity=205)
    place_window(canvas, orange, (1480, 1530 - orange.height), opacity=220)
    place_window(canvas, lime, (1980, 1610 - lime.height), opacity=220)
    add_tag(canvas)
    output = RC / "06-toolpouch-themes.png"
    canvas.convert("RGB").save(output, quality=95, optimize=True)
    return output


if __name__ == "__main__":
    RC.mkdir(parents=True, exist_ok=True)
    for result in (
        slide_dual_mode(),
        slide_diagnostics(),
        slide_calculate(),
        slide_everyday(),
        slide_files_and_security(),
        slide_themes(),
    ):
        print(result)
