from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parent
sheet = Image.new("RGB", (1240, 1230), "#e5e8e4")
draw = ImageDraw.Draw(sheet)
for index, path in enumerate(sorted((root / "RC").glob("*.png"))):
    thumbnail = Image.open(path).convert("RGB").resize((600, 375), Image.Resampling.LANCZOS)
    x = 10 + (index % 2) * 620
    y = 10 + (index // 2) * 410
    sheet.paste(thumbnail, (x, y))
    draw.text((x, y + 383), path.stem, fill="#25302b")
sheet.save(root / "Working/rc-small-preview.jpg", quality=94)
