#!/usr/bin/env python3
from PIL import Image, ImageDraw, ImageFilter
import math

SIZE = 2048
OUT = 1024
R = int(SIZE * 0.22)

img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))

# --- gradient background (green to blue) ---
for y in range(SIZE):
    for x in range(SIZE):
        t = y / SIZE
        # #10B981 (green) -> #3B82F6 (blue)
        r = int(16 + (59 - 16) * t)
        g = int(185 + (130 - 185) * t)
        b = int(129 + (246 - 129) * t)
        img.putpixel((x, y), (r, g, b, 255))

# --- rounded rectangle mask ---
mask = Image.new('L', (SIZE, SIZE), 0)
mask_draw = ImageDraw.Draw(mask)
mask_draw.rounded_rectangle((0, 0, SIZE, SIZE), radius=R, fill=255)
img.putalpha(mask)

# --- tree symbol ---
symbol = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
sd = ImageDraw.Draw(symbol)

cx, cy = SIZE // 2, SIZE // 2 + SIZE // 20

# Trunk
trunk_w = SIZE * 0.08
trunk_h = SIZE * 0.25
sd.rounded_rectangle((cx - trunk_w/2, cy + SIZE * 0.15, cx + trunk_w/2, cy + SIZE * 0.15 + trunk_h), 
                     radius=int(trunk_w/4), fill=(255,255,255,255))

# Foliage (3 circles)
foliage_r = SIZE * 0.22
sd.ellipse((cx - foliage_r, cy - SIZE * 0.25, cx + foliage_r, cy + SIZE * 0.15), fill=(255,255,255,255))
sd.ellipse((cx - foliage_r * 0.7, cy - SIZE * 0.35, cx + foliage_r * 0.3, cy + SIZE * 0.05), fill=(255,255,255,255))
sd.ellipse((cx - foliage_r * 0.3, cy - SIZE * 0.35, cx + foliage_r * 0.7, cy + SIZE * 0.05), fill=(255,255,255,255))

# Blur and threshold
symbol = symbol.filter(ImageFilter.GaussianBlur(radius=2))
r, g, b, a = symbol.split()
a = a.point(lambda p: 255 if p > 30 else 0)
symbol.putalpha(a)

img = Image.alpha_composite(img, symbol)
img = img.resize((OUT, OUT), Image.LANCZOS)

# Convert to RGB
img_rgb = Image.new('RGB', img.size, (0, 0, 0))
img_rgb.paste(img, mask=img.split()[3])

img_rgb.save('/Users/johnnyfan/zfloo/bestme/app/assets/logo_tree.png')
print('Generated assets/logo_tree.png (RGB, no alpha)')
