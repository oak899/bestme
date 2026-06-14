#!/usr/bin/env python3
from PIL import Image, ImageDraw, ImageFilter
import math

SIZE = 2048
OUT = 1024
R = int(SIZE * 0.22)

img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))

# --- gradient background (purple to pink) ---
for y in range(SIZE):
    for x in range(SIZE):
        t = y / SIZE
        # #8B5CF6 (purple) -> #EC4899 (pink)
        r = int(139 + (236 - 139) * t)
        g = int(92 + (72 - 92) * t)
        b = int(246 + (153 - 246) * t)
        img.putpixel((x, y), (r, g, b, 255))

# --- rounded rectangle mask ---
mask = Image.new('L', (SIZE, SIZE), 0)
mask_draw = ImageDraw.Draw(mask)
mask_draw.rounded_rectangle((0, 0, SIZE, SIZE), radius=R, fill=255)
img.putalpha(mask)

# --- star symbol ---
symbol = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
sd = ImageDraw.Draw(symbol)

cx, cy = SIZE // 2, SIZE // 2

# Draw a 5-pointed star
outer_r = SIZE * 0.30
inner_r = SIZE * 0.12
points = []
for i in range(10):
    angle = math.radians(i * 36 - 90)
    r = outer_r if i % 2 == 0 else inner_r
    x = cx + r * math.cos(angle)
    y = cy + r * math.sin(angle)
    points.append((x, y))

sd.polygon(points, fill=(255,255,255,255))

# Add a smaller star inside
outer_r2 = SIZE * 0.18
inner_r2 = SIZE * 0.07
points2 = []
for i in range(10):
    angle = math.radians(i * 36 - 90)
    r = outer_r2 if i % 2 == 0 else inner_r2
    x = cx + r * math.cos(angle)
    y = cy + r * math.sin(angle)
    points2.append((x, y))

sd.polygon(points2, fill=(255,255,255,200))

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

img_rgb.save('/Users/johnnyfan/zfloo/bestme/app/assets/logo_star.png')
print('Generated assets/logo_star.png (RGB, no alpha)')
