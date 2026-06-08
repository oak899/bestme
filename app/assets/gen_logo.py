#!/usr/bin/env python3
from PIL import Image, ImageDraw, ImageFilter
import math

SIZE = 2048
OUT = 1024
R = int(SIZE * 0.22)  # corner radius

img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))

# --- diagonal gradient background ---
for y in range(SIZE):
    for x in range(SIZE):
        t = (x + y) / (2 * SIZE)
        # #4F46E5 -> #7C3AED -> #06B6D4
        if t < 0.5:
            t2 = t * 2
            r = int(79 + (124 - 79) * t2)
            g = int(70 + (58 - 70) * t2)
            b = int(229 + (237 - 229) * t2)
        else:
            t2 = (t - 0.5) * 2
            r = int(124 + (6 - 124) * t2)
            g = int(58 + (182 - 58) * t2)
            b = int(237 + (212 - 237) * t2)
        img.putpixel((x, y), (r, g, b, 255))

# --- rounded rectangle mask ---
mask = Image.new('L', (SIZE, SIZE), 0)
mask_draw = ImageDraw.Draw(mask)
mask_draw.rounded_rectangle((0, 0, SIZE, SIZE), radius=R, fill=255)
img.putalpha(mask)

# --- white growth symbol (render at high res then composite) ---
symbol = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
sd = ImageDraw.Draw(symbol)

cx, cy = SIZE // 2, SIZE // 2 + SIZE // 40  # slight offset down

# Symbol: an upward chevron arrow with a circle ring below
# Outer ring (open at top)
ring_r = SIZE * 0.28
ring_w = SIZE * 0.055

# Draw arc for the ring (bottom half of a circle, open at top)
for angle in range(200, 340):
    rad = math.radians(angle)
    bx = cx + ring_r * math.cos(rad)
    by = cy + ring_r * math.sin(rad) + SIZE * 0.08
    sd.ellipse((bx - ring_w/2, by - ring_w/2, bx + ring_w/2, by + ring_w/2), fill=(255,255,255,255))

# Arrow shaft
shaft_w = SIZE * 0.06
shaft_top = cy - SIZE * 0.22
shaft_bottom = cy + SIZE * 0.12
sd.rounded_rectangle((cx - shaft_w/2, shaft_top, cx + shaft_w/2, shaft_bottom), radius=int(shaft_w/2), fill=(255,255,255,255))

# Arrow head (triangle)
head_h = SIZE * 0.18
head_w = SIZE * 0.22
points = [
    (cx, cy - SIZE * 0.32),                    # top point
    (cx - head_w/2, cy - SIZE * 0.16),         # left base
    (cx + head_w/2, cy - SIZE * 0.16),         # right base
]
sd.polygon(points, fill=(255,255,255,255))

# Blur slightly for anti-aliased edges, then threshold
symbol = symbol.filter(ImageFilter.GaussianBlur(radius=3))
# Threshold to clean edges
r, g, b, a = symbol.split()
a = a.point(lambda p: 255 if p > 30 else 0)
symbol.putalpha(a)

# Composite symbol onto background
img = Image.alpha_composite(img, symbol)

# Resize to final size
img = img.resize((OUT, OUT), Image.LANCZOS)

# Convert to RGB (remove alpha channel for iOS compatibility)
img_rgb = Image.new('RGB', img.size, (0, 0, 0))
img_rgb.paste(img, mask=img.split()[3])  # Use alpha as mask

img_rgb.save('/Users/johnnyfan/zfloo/bestme/app/assets/logo.png')
print('Generated assets/logo.png (RGB, no alpha)')
