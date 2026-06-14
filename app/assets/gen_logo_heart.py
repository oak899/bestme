#!/usr/bin/env python3
from PIL import Image, ImageDraw, ImageFilter
import math

SIZE = 2048
OUT = 1024
R = int(SIZE * 0.22)

img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))

# --- gradient background (orange to red) ---
for y in range(SIZE):
    for x in range(SIZE):
        t = y / SIZE
        # #F59E0B (orange) -> #EF4444 (red)
        r = int(245 + (239 - 245) * t)
        g = int(158 + (68 - 158) * t)
        b = int(11 + (68 - 11) * t)
        img.putpixel((x, y), (r, g, b, 255))

# --- rounded rectangle mask ---
mask = Image.new('L', (SIZE, SIZE), 0)
mask_draw = ImageDraw.Draw(mask)
mask_draw.rounded_rectangle((0, 0, SIZE, SIZE), radius=R, fill=255)
img.putalpha(mask)

# --- heart symbol ---
symbol = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
sd = ImageDraw.Draw(symbol)

cx, cy = SIZE // 2, SIZE // 2 - SIZE // 40

# Draw heart using two circles and a triangle
heart_size = SIZE * 0.25
sd.ellipse((cx - heart_size, cy - heart_size, cx, cy), fill=(255,255,255,255))
sd.ellipse((cx, cy - heart_size, cx + heart_size, cy), fill=(255,255,255,255))
sd.polygon([
    (cx - heart_size, cy - heart_size * 0.5),
    (cx + heart_size, cy - heart_size * 0.5),
    (cx, cy + heart_size * 0.8)
], fill=(255,255,255,255))

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

img_rgb.save('/Users/johnnyfan/zfloo/bestme/app/assets/logo_heart.png')
print('Generated assets/logo_heart.png (RGB, no alpha)')
