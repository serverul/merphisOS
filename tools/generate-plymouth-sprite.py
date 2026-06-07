#!/usr/bin/env python3
# MerphisOS Plymouth Theme Generator
# Generează sprite-urile de boot
from PIL import Image, ImageDraw, ImageFont
import os

SIZE = 256
CENTER = SIZE // 2
OUT_DIR = "/tmp/merphisos-plymouth"

os.makedirs(OUT_DIR, exist_ok=True)

# Generăm 36 de frame-uri pentru animația de rotire
# Un "M" stilizat care se rotește
for frame in range(36):
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    angle = frame * 10  # 10 grade per frame
    
    # Desenăm un M stilizat
    # Coordonate pentru M
    pts = [
        (CENTER - 40, CENTER - 30),  # stânga sus
        (CENTER - 10, CENTER - 30),  # mijloc stânga sus
        (CENTER, CENTER - 5),         # vârf jos
        (CENTER + 10, CENTER - 30),  # mijloc dreapta sus
        (CENTER + 40, CENTER - 30),  # dreapta sus
        (CENTER + 20, CENTER + 30),  # dreapta jos
        (CENTER + 10, CENTER + 10),  # interior dreapta
        (CENTER, CENTER + 15),       # interior jos
        (CENTER - 10, CENTER + 10),  # interior stânga
        (CENTER - 20, CENTER + 30),  # stânga jos
    ]
    
    # Rotim punctele în jurul centrului
    import math
    rad = math.radians(angle)
    cos_a = math.cos(rad)
    sin_a = math.sin(rad)
    
    rotated = []
    for x, y in pts:
        rx = CENTER + (x - CENTER) * cos_a - (y - CENTER) * sin_a
        ry = CENTER + (x - CENTER) * sin_a + (y - CENTER) * cos_a
        rotated.append((rx, ry))
    
    # Desenăm M cu gradient cyan → albastru
    for i in range(len(rotated) - 1):
        draw.line([rotated[i], rotated[i+1]], fill=(0, 200, 255, 255), width=8)
    
    # Închidem forma
    draw.line([rotated[-1], rotated[0]], fill=(0, 200, 255, 255), width=8)
    
    # Adăugăm keyhole în centru
    key_x, key_y = CENTER, CENTER + 10
    draw.ellipse([key_x-8, key_y-8, key_x+8, key_y+8], outline=(255, 255, 255, 255), width=3)
    draw.rectangle([key_x-3, key_y+2, key_x+3, key_y+15], fill=(255, 255, 255, 255))
    
    # Salvăm frame-ul
    img.save(os.path.join(OUT_DIR, f'merphisos-{frame:03d}.png'))

print(f"✅ Generated {36} frames in {OUT_DIR}")

# Create sprite sheet (6x6 grid)
sprite = Image.new('RGBA', (SIZE * 6, SIZE * 6), (0, 0, 0, 0))
for i in range(36):
    x = (i % 6) * SIZE
    y = (i // 6) * SIZE
    frame_img = Image.open(os.path.join(OUT_DIR, f'merphisos-{i:03d}.png'))
    sprite.paste(frame_img, (x, y), frame_img)

sprite.save(os.path.join(OUT_DIR, 'merphisos-sprite.png'))
print(f"✅ Sprite sheet: {OUT_DIR}/merphisos-sprite.png")
