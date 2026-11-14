"""Genera las capas PNG (fondo transparente) del avatar de SportZone.

Uso:  python3 tool/generate_avatar_assets.py
Salida: assets/avatar/<id>.png (400x560) y assets/avatar/thumbs/<id>.png

Todas las capas comparten el mismo lienzo y la misma posición, así se pueden
apilar con un Stack en Flutter: cuerpo -> inferior -> superior -> cabeza -> mano.
Si quieres cambiar el diseño por PNG hechos por un diseñador, solo reemplaza
los archivos manteniendo el mismo nombre y tamaño.
"""
import math
import os

from PIL import Image, ImageChops, ImageDraw, ImageFont

W, H = 400, 560
S = 3  # se dibuja 3 veces más grande y se reduce: bordes suaves
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'avatar')
FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'

OUTLINE = (30, 30, 40, 255)

# Geometría compartida (en coordenadas de 400x560)
SHOULDER_L, HAND_L = (146, 184), (104, 320)
SHOULDER_R, HAND_R = (254, 184), (296, 320)
ARM_W = 30


def new():
    img = Image.new('RGBA', (W * S, H * S), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def p(*pts):
    return [(x * S, y * S) for x, y in pts]


def box(x0, y0, x1, y1):
    return [x0 * S, y0 * S, x1 * S, y1 * S]


def lw(w):
    return int(w * S)


def save(img, name):
    os.makedirs(os.path.join(OUT, 'thumbs'), exist_ok=True)
    final = img.resize((W, H), Image.LANCZOS)
    final.save(os.path.join(OUT, f'{name}.png'), optimize=True)
    bbox = final.getbbox()
    crop = final.crop(bbox) if bbox else final
    side = max(crop.size) + 16
    square = Image.new('RGBA', (side, side), (0, 0, 0, 0))
    square.paste(crop, ((side - crop.size[0]) // 2, (side - crop.size[1]) // 2))
    square.resize((160, 160), Image.LANCZOS).save(os.path.join(OUT, 'thumbs', f'{name}.png'), optimize=True)


def arm_poly(shoulder, hand, t0, t1, width):
    """Polígono de un tramo del brazo entre t0 y t1 (0 = hombro, 1 = mano)."""
    (sx, sy), (hx, hy) = shoulder, hand
    dx, dy = hx - sx, hy - sy
    length = math.hypot(dx, dy)
    nx, ny = -dy / length * width / 2, dx / length * width / 2
    a = (sx + dx * t0, sy + dy * t0)
    b = (sx + dx * t1, sy + dy * t1)
    return p((a[0] + nx, a[1] + ny), (b[0] + nx, b[1] + ny), (b[0] - nx, b[1] - ny), (a[0] - nx, a[1] - ny))


def arm_point(shoulder, hand, t):
    return (shoulder[0] + (hand[0] - shoulder[0]) * t, shoulder[1] + (hand[1] - shoulder[1]) * t)


def masked(img, mask_fn, paint_fn):
    """Pinta algo (rayas, sombras) solo dentro de una forma."""
    mask = Image.new('L', img.size, 0)
    mask_fn(ImageDraw.Draw(mask))
    layer = Image.new('RGBA', img.size, (0, 0, 0, 0))
    paint_fn(ImageDraw.Draw(layer))
    alpha = ImageChops.multiply(layer.split()[3], mask)
    img.paste(layer, (0, 0), alpha)


def text(d, xy, s, size, fill):
    font = ImageFont.truetype(FONT, size * S)
    d.text((xy[0] * S, xy[1] * S), s, font=font, fill=fill, anchor='mm')


def darker(c, k=0.75):
    return tuple(int(v * k) for v in c[:3]) + (255,)


# ───────────────────────── CUERPO BASE ─────────────────────────
def body(name, skin):
    img, d = new()
    shade = darker(skin, 0.85)
    # piernas
    for x0 in (152, 206):
        d.rounded_rectangle(box(x0, 320, x0 + 42, 500), radius=lw(14), fill=skin, outline=OUTLINE, width=lw(3))
    # zapatillas
    for x0, x1 in ((138, 198), (202, 262)):
        d.rounded_rectangle(box(x0, 488, x1, 522), radius=lw(14), fill=(34, 34, 44, 255), outline=OUTLINE, width=lw(3))
        d.rectangle(box(x0 + 4, 510, x1 - 4, 515), fill=(235, 235, 235, 255))
    # brazos y manos
    for sh, hd in ((SHOULDER_L, HAND_L), (SHOULDER_R, HAND_R)):
        d.polygon(arm_poly(sh, hd, 0, 1, ARM_W), fill=skin, outline=OUTLINE, width=lw(3))
        d.ellipse(box(hd[0] - 17, hd[1] - 15, hd[0] + 17, hd[1] + 19), fill=skin, outline=OUTLINE, width=lw(3))
    # cuello
    d.rectangle(box(186, 140, 214, 178), fill=shade, outline=OUTLINE, width=lw(3))
    # torso (sin camiseta: la camiseta básica es una prenda aparte) y pantaloneta gris base
    d.rounded_rectangle(box(138, 168, 262, 342), radius=lw(30), fill=skin, outline=OUTLINE, width=lw(3))
    d.arc(box(150, 196, 202, 236), 20, 160, fill=shade, width=lw(3))   # pectorales
    d.arc(box(198, 196, 250, 236), 20, 160, fill=shade, width=lw(3))
    d.line(p((200, 246), (200, 300)), fill=shade, width=lw(2))         # abdomen
    for y in (262, 282):
        d.line(p((182, y), (218, y)), fill=shade, width=lw(2))
    d.ellipse(box(196, 304, 204, 312), fill=shade)                      # ombligo
    d.rounded_rectangle(box(146, 312, 254, 360), radius=lw(16), fill=(120, 126, 140, 255), outline=OUTLINE, width=lw(3))
    # cabeza (calva: el pelo es otra capa)
    for ex in (146, 254):
        d.ellipse(box(ex - 11, 88, ex + 11, 114), fill=skin, outline=OUTLINE, width=lw(3))  # orejas
    d.ellipse(box(150, 46, 250, 156), fill=skin, outline=OUTLINE, width=lw(3))
    # cara
    for ex in (182, 218):
        d.ellipse(box(ex - 7, 96, ex + 7, 112), fill=(30, 30, 40, 255))
        d.ellipse(box(ex - 2, 99, ex + 2, 103), fill=(255, 255, 255, 255))
        d.line(p((ex - 9, 88), (ex + 9, 86)), fill=(50, 36, 30, 255), width=lw(4))
    d.arc(box(182, 112, 218, 138), 20, 160, fill=(120, 40, 40, 255), width=lw(4))
    for cx in (166, 234):
        blush = tuple(int(skin[i] * 0.65 + (255, 120, 120)[i] * 0.35) for i in range(3)) + (255,)
        d.ellipse(box(cx - 8, 118, cx + 8, 128), fill=blush)
    save(img, name)


# ───────────────────────── PRENDAS SUPERIORES ─────────────────────────
def torso(d, color):
    d.rounded_rectangle(box(134, 164, 266, 338), radius=lw(30), fill=color, outline=OUTLINE, width=lw(3))


def sleeves(d, color, t1=0.42):
    for sh, hd in ((SHOULDER_L, HAND_L), (SHOULDER_R, HAND_R)):
        d.polygon(arm_poly(sh, hd, -0.04, t1, ARM_W + 12), fill=color, outline=OUTLINE, width=lw(3))


def football_top(name, color, number='10', stripes=None, trim=(255, 255, 255, 255)):
    img, d = new()
    sleeves(d, color)
    for sh, hd in ((SHOULDER_L, HAND_L), (SHOULDER_R, HAND_R)):
        d.polygon(arm_poly(sh, hd, 0.34, 0.42, ARM_W + 12), fill=trim, outline=OUTLINE, width=lw(2))
    torso(d, color)
    if stripes:
        masked(img,
               lambda m: m.rounded_rectangle(box(134, 164, 266, 338), radius=lw(30), fill=255),
               lambda l: [l.rectangle(box(x, 150, x + 16, 350), fill=stripes) for x in range(146, 266, 32)])
        d = ImageDraw.Draw(img)
        d.rounded_rectangle(box(134, 164, 266, 338), radius=lw(30), outline=OUTLINE, width=lw(3))
    d.polygon(p((182, 164), (218, 164), (200, 192)), fill=trim, outline=OUTLINE, width=lw(2))  # cuello en V
    text(d, (200, 250), number, 52, trim)
    save(img, name)


def nba_top(name, color, trim, number='23'):
    img, d = new()
    d.rounded_rectangle(box(140, 164, 260, 340), radius=lw(26), fill=color, outline=OUTLINE, width=lw(3))
    # sisas (hombros descubiertos) y cuello en U
    d.ellipse(box(170, 140, 230, 200), fill=(0, 0, 0, 0))
    d.arc(box(170, 140, 230, 200), 0, 180, fill=trim, width=lw(7))
    d.line(p((140, 210), (160, 168)), fill=trim, width=lw(7))
    d.line(p((260, 210), (240, 168)), fill=trim, width=lw(7))
    d.line(p((140, 214), (140, 334)), fill=trim, width=lw(5))
    d.line(p((260, 214), (260, 334)), fill=trim, width=lw(5))
    text(d, (200, 262), number, 64, trim)
    save(img, name)


def tennis_top(name, color, accent):
    img, d = new()
    sleeves(d, color, t1=0.34)
    torso(d, color)
    d.polygon(p((174, 162), (200, 186), (184, 202)), fill=(255, 255, 255, 255), outline=OUTLINE, width=lw(2))
    d.polygon(p((226, 162), (200, 186), (216, 202)), fill=(255, 255, 255, 255), outline=OUTLINE, width=lw(2))
    d.line(p((200, 186), (200, 226)), fill=OUTLINE, width=lw(2))
    for y in (198, 214):
        d.ellipse(box(196, y - 3, 204, y + 5), fill=accent)
    d.ellipse(box(222, 204, 240, 222), fill=accent)  # logo
    d.rectangle(box(134, 322, 266, 330), fill=accent)
    save(img, name)


# ───────────────────────── PRENDAS INFERIORES ─────────────────────────
def football_bottom(name, color, sock):
    img, d = new()
    # medias hasta la rodilla
    for x0 in (148, 202):
        d.rounded_rectangle(box(x0, 412, x0 + 50, 494), radius=lw(10), fill=sock, outline=OUTLINE, width=lw(3))
        d.rectangle(box(x0 + 2, 422, x0 + 48, 432), fill=darker(sock, 0.7))
    d.polygon(p((140, 306), (260, 306), (264, 392), (206, 392), (200, 366), (194, 392), (136, 392)),
              fill=color, outline=OUTLINE, width=lw(3))
    d.line(p((140, 318), (260, 318)), fill=darker(color, 0.8), width=lw(4))
    save(img, name)


def nba_bottom(name, color, trim):
    img, d = new()
    d.polygon(p((134, 304), (266, 304), (272, 432), (208, 432), (200, 380), (192, 432), (128, 432)),
              fill=color, outline=OUTLINE, width=lw(3))
    d.line(p((136, 318), (130, 428)), fill=trim, width=lw(8))
    d.line(p((264, 318), (270, 428)), fill=trim, width=lw(8))
    d.rectangle(box(136, 304, 264, 318), fill=trim)
    save(img, name)


def tennis_shorts(name):
    img, d = new()
    white = (248, 248, 248, 255)
    d.polygon(p((140, 306), (260, 306), (262, 386), (206, 386), (200, 362), (194, 386), (138, 386)),
              fill=white, outline=OUTLINE, width=lw(3))
    d.line(p((148, 330), (152, 384)), fill=(40, 120, 220, 255), width=lw(4))
    d.line(p((252, 330), (248, 384)), fill=(40, 120, 220, 255), width=lw(4))
    save(img, name)


def tennis_skirt(name):
    img, d = new()
    white = (248, 248, 248, 255)
    d.polygon(p((142, 306), (258, 306), (280, 392), (120, 392)), fill=white, outline=OUTLINE, width=lw(3))
    for x in range(140, 270, 20):
        d.line(p((x + (200 - x) * 0.12, 312), (x - (200 - x) * 0.18, 390)), fill=(200, 200, 210, 255), width=lw(2))
    d.rectangle(box(142, 306, 258, 316), fill=(255, 120, 60, 255))
    save(img, name)


# ───────────────────────── CABEZA ─────────────────────────
def headband(name, color):
    img, d = new()
    d.rounded_rectangle(box(146, 58, 254, 78), radius=lw(8), fill=color, outline=OUTLINE, width=lw(3))
    d.ellipse(box(192, 61, 208, 75), fill=(30, 30, 40, 255))
    save(img, name)


def cap(name, color):
    img, d = new()
    d.pieslice(box(142, 18, 258, 120), 180, 360, fill=color, outline=OUTLINE, width=lw(3))
    d.rounded_rectangle(box(150, 62, 292, 80), radius=lw(9), fill=darker(color, 0.8), outline=OUTLINE, width=lw(3))
    d.ellipse(box(193, 16, 207, 28), fill=darker(color, 0.7))
    d.ellipse(box(188, 36, 212, 58), fill=(255, 255, 255, 255))
    save(img, name)


def visor(name, color):
    img, d = new()
    d.rounded_rectangle(box(146, 56, 254, 74), radius=lw(8), fill=(250, 250, 250, 255), outline=OUTLINE, width=lw(3))
    d.pieslice(box(150, 52, 296, 96), 270, 360, fill=color, outline=OUTLINE, width=lw(3))
    d.rounded_rectangle(box(160, 64, 290, 80), radius=lw(8), fill=color, outline=OUTLINE, width=lw(3))
    save(img, name)


def crown(name):
    img, d = new()
    gold = (255, 200, 40, 255)
    d.polygon(p((152, 50), (156, 4), (178, 30), (200, 0), (222, 30), (244, 4), (248, 50)), fill=gold, outline=OUTLINE, width=lw(3))
    d.rectangle(box(152, 40, 248, 54), fill=darker(gold, 0.85), outline=OUTLINE, width=lw(3))
    for x, c in ((176, (230, 40, 60, 255)), (200, (40, 120, 240, 255)), (224, (40, 190, 90, 255))):
        d.ellipse(box(x - 6, 41, x + 6, 53), fill=c)
    save(img, name)


# ───────────────────────── MANO ─────────────────────────
def soccer_ball(name):
    img, d = new()
    cx, cy, r = 322, 486, 32  # a los pies
    d.ellipse(box(cx - r, cy - r, cx + r, cy + r), fill=(255, 255, 255, 255), outline=OUTLINE, width=lw(3))
    def pent(x, y, s):
        return p(*[(x + s * math.cos(math.radians(a - 90)), y + s * math.sin(math.radians(a - 90))) for a in range(0, 360, 72)])
    d.polygon(pent(cx, cy, 11), fill=(30, 30, 40, 255))
    for a in range(0, 360, 72):
        x = cx + 25 * math.cos(math.radians(a - 90))
        y = cy + 25 * math.sin(math.radians(a - 90))
        d.polygon(pent(x, y, 7), fill=(30, 30, 40, 255))
    save(img, name)


def gloves(name):
    img, d = new()
    for hx, hy in (HAND_L, HAND_R):
        d.rounded_rectangle(box(hx - 24, hy - 22, hx + 24, hy + 28), radius=lw(14), fill=(60, 220, 120, 255), outline=OUTLINE, width=lw(3))
        d.rectangle(box(hx - 22, hy - 24, hx + 22, hy - 14), fill=(30, 30, 40, 255))
        for k in (-10, 0, 10):
            d.line(p((hx + k, hy + 4), (hx + k, hy + 24)), fill=(30, 140, 70, 255), width=lw(2))
    save(img, name)


def captain(name):
    img, d = new()
    a = arm_point(SHOULDER_L, HAND_L, 0.48)
    d.polygon(arm_poly(SHOULDER_L, HAND_L, 0.43, 0.55, ARM_W + 6), fill=(255, 210, 40, 255), outline=OUTLINE, width=lw(3))
    text(d, a, 'C', 16, (30, 30, 40, 255))
    save(img, name)


def basketball(name):
    img, d = new()
    cx, cy, r = 322, 316, 36
    d.ellipse(box(cx - r, cy - r, cx + r, cy + r), fill=(240, 120, 30, 255), outline=OUTLINE, width=lw(3))
    d.line(p((cx - r, cy), (cx + r, cy)), fill=OUTLINE, width=lw(3))
    d.line(p((cx, cy - r), (cx, cy + r)), fill=OUTLINE, width=lw(3))
    d.arc(box(cx - r - 22, cy - r, cx + 10, cy + r), -60, 60, fill=OUTLINE, width=lw(3))
    d.arc(box(cx - 10, cy - r, cx + r + 22, cy + r), 120, 240, fill=OUTLINE, width=lw(3))
    save(img, name)


def wristbands(name, color):
    img, d = new()
    for sh, hd in ((SHOULDER_L, HAND_L), (SHOULDER_R, HAND_R)):
        d.polygon(arm_poly(sh, hd, 0.78, 0.92, ARM_W + 8), fill=color, outline=OUTLINE, width=lw(3))
    save(img, name)


def racket(name, frame, strings=(240, 240, 240, 255)):
    img, d = new()
    hx, hy = HAND_R
    cx, cy, rx, ry = hx + 30, hy - 140, 34, 46
    d.line(p((hx, hy + 6), (cx, cy + ry)), fill=(40, 40, 50, 255), width=lw(12))
    d.ellipse(box(cx - rx, cy - ry, cx + rx, cy + ry), fill=(0, 0, 0, 0), outline=frame, width=lw(9))
    masked(img,
           lambda m: m.ellipse(box(cx - rx + 4, cy - ry + 4, cx + rx - 4, cy + ry - 4), fill=255),
           lambda l: ([l.line(p((x, cy - ry), (x, cy + ry)), fill=strings, width=lw(2)) for x in range(cx - rx, cx + rx, 9)]
                      + [l.line(p((cx - rx, y), (cx + rx, y)), fill=strings, width=lw(2)) for y in range(cy - ry, cy + ry, 9)]))
    d = ImageDraw.Draw(img)
    d.ellipse(box(cx - rx, cy - ry, cx + rx, cy + ry), outline=OUTLINE, width=lw(2))
    # mano encima del mango
    d.ellipse(box(hx - 15, hy - 13, hx + 15, hy + 17), fill=(0, 0, 0, 0))
    save(img, name)


# ───────────────────────── CABELLO ─────────────────────────
FACE = (153, 49, 247, 153)  # zona de la cara que el pelo NO tapa


def _cut_face(d):
    d.ellipse(box(*FACE), fill=(0, 0, 0, 0))


def _fringe(d, color):
    d.pieslice(box(150, 40, 250, 110), 180, 360, fill=color)


def hair(name, style, color):
    img, d = new()
    if style == 'short':
        d.ellipse(box(144, 26, 256, 112), fill=color, outline=OUTLINE, width=lw(3))
        _cut_face(d)
        _fringe(d, color)
    elif style == 'buzz':
        d.pieslice(box(149, 42, 251, 112), 180, 360, fill=darker(color, 1.0))
        for x in range(158, 244, 8):
            d.line(p((x, 52), (x + 2, 70)), fill=darker(color, 0.7), width=lw(1))
    elif style == 'afro':
        d.ellipse(box(118, 0, 282, 128), fill=color, outline=OUTLINE, width=lw(3))
        for cx, cy in ((140, 40), (170, 14), (200, 6), (230, 14), (260, 40), (128, 80), (272, 80)):
            d.arc(box(cx - 18, cy - 18, cx + 18, cy + 18), 180, 330, fill=darker(color, 0.7), width=lw(3))
        _cut_face(d)
        d.pieslice(box(150, 34, 250, 106), 180, 360, fill=color)
    elif style == 'long':
        d.rounded_rectangle(box(132, 60, 168, 214), radius=lw(18), fill=color, outline=OUTLINE, width=lw(3))
        d.rounded_rectangle(box(232, 60, 268, 214), radius=lw(18), fill=color, outline=OUTLINE, width=lw(3))
        d.ellipse(box(140, 22, 260, 116), fill=color, outline=OUTLINE, width=lw(3))
        _cut_face(d)
        d.pieslice(box(150, 40, 250, 104), 180, 360, fill=color)
        d.polygon(p((150, 72), (200, 52), (186, 84)), fill=color)
    elif style == 'mohawk':
        d.polygon(p((186, 60), (190, 0), (200, 18), (206, -2), (212, 22), (216, 60)), fill=color, outline=OUTLINE, width=lw(3))
        d.pieslice(box(149, 42, 251, 112), 180, 360, fill=darker(color, 0.55))
        d.rectangle(box(184, 42, 216, 77), fill=color)
    elif style == 'bun':
        d.ellipse(box(176, 0, 224, 44), fill=color, outline=OUTLINE, width=lw(3))
        d.ellipse(box(144, 26, 256, 112), fill=color, outline=OUTLINE, width=lw(3))
        _cut_face(d)
        _fringe(d, color)
    elif style == 'curly':
        for cx, cy in ((156, 58), (176, 36), (200, 28), (224, 36), (244, 58), (148, 84), (252, 84)):
            d.ellipse(box(cx - 22, cy - 22, cx + 22, cy + 22), fill=color, outline=OUTLINE, width=lw(2))
        _cut_face(d)
        d.pieslice(box(152, 44, 248, 104), 180, 360, fill=color)
    save(img, name)


# ───────────────────────── TATUAJES ─────────────────────────
INK = (30, 50, 90, 235)


def tattoo(name, kind):
    img, d = new()
    if kind in ('tribal', 'full'):
        for t in (0.12, 0.24, 0.36):
            a = arm_point(SHOULDER_R, HAND_R, t)
            d.polygon(p((a[0] - 12, a[1] - 4), (a[0] + 12, a[1] - 10), (a[0] + 2, a[1] + 8)), fill=INK)
    if kind in ('sleeves', 'full'):
        for sh, hd in ((SHOULDER_L, HAND_L), (SHOULDER_R, HAND_R)):
            for k in range(6):
                t = 0.1 + k * 0.12
                a = arm_point(sh, hd, t)
                d.ellipse(box(a[0] - 6, a[1] - 6, a[0] + 6, a[1] + 6), outline=INK, width=lw(3))
                d.line(p((a[0] - 12, a[1] + 8), (a[0] + 12, a[1] + 2)), fill=INK, width=lw(2))
    if kind in ('chest', 'full'):
        # alas sobre el pecho
        for sgn in (-1, 1):
            pts = [(200, 214)] + [(200 + sgn * (20 + i * 9), 200 + (i % 2) * 14 - i * 2) for i in range(6)] + [(200 + sgn * 60, 230), (200, 226)]
            d.polygon(p(*pts), outline=INK, width=lw(3))
        d.ellipse(box(192, 206, 208, 222), fill=INK)
    if kind == 'rose':
        a = arm_point(SHOULDER_L, HAND_L, 0.7)
        for k in range(5):
            ang = math.radians(k * 72)
            d.ellipse(box(a[0] + 5 * math.cos(ang) - 5, a[1] + 5 * math.sin(ang) - 5, a[0] + 5 * math.cos(ang) + 5, a[1] + 5 * math.sin(ang) + 5), fill=(200, 40, 70, 230))
        d.line(p((a[0], a[1] + 8), (a[0] - 4, a[1] + 26)), fill=(40, 130, 60, 230), width=lw(3))
    save(img, name)


# ───────────────────────── CARA ─────────────────────────
def face(name, kind, color=(50, 36, 30, 255)):
    img, d = new()
    if kind == 'beard':
        d.chord(box(150, 70, 250, 160), 10, 170, fill=color, outline=OUTLINE, width=lw(2))
        d.ellipse(box(184, 120, 216, 140), fill=(0, 0, 0, 0))
        d.arc(box(184, 116, 216, 138), 20, 160, fill=(120, 40, 40, 255), width=lw(4))
        d.chord(box(178, 108, 222, 124), 180, 360, fill=color)  # bigote
    elif kind == 'stubble':
        for x in range(160, 242, 6):
            for y in range(118, 152, 6):
                if (x - 200) ** 2 / 50 ** 2 + (y - 101) ** 2 / 55 ** 2 < 1 and not (182 < x < 218 and 112 < y < 140):
                    d.point(p((x, y)), fill=darker(color, 1.0))
                    d.ellipse(box(x - 1, y - 1, x + 1, y + 1), fill=color)
    elif kind == 'sunglasses':
        for ex in (180, 220):
            d.rounded_rectangle(box(ex - 18, 92, ex + 18, 114), radius=lw(8), fill=(20, 20, 30, 255), outline=OUTLINE, width=lw(2))
            d.line(p((ex - 10, 97), (ex - 2, 97)), fill=(255, 255, 255, 160), width=lw(2))
        d.line(p((198, 98), (202, 98)), fill=(20, 20, 30, 255), width=lw(4))
        d.line(p((162, 98), (150, 96)), fill=(20, 20, 30, 255), width=lw(3))
        d.line(p((238, 98), (250, 96)), fill=(20, 20, 30, 255), width=lw(3))
    elif kind == 'paint':  # tricolor en las mejillas
        for cx in (166, 234):
            for k, c in enumerate(((252, 209, 22, 255), (0, 56, 147, 255), (206, 17, 38, 255))):
                d.rectangle(box(cx - 12, 114 + k * 5, cx + 12, 119 + k * 5), fill=c)
    elif kind == 'blackeye':
        d.ellipse(box(170, 90, 196, 118), outline=(110, 60, 140, 200), width=lw(4))
        d.rounded_rectangle(box(194, 108, 216, 118), radius=lw(3), fill=(245, 230, 200, 255), outline=OUTLINE, width=lw(1))
        d.line(p((222, 82), (236, 92)), fill=(200, 50, 50, 255), width=lw(2))
    elif kind == 'mouthguard':
        d.chord(box(182, 114, 218, 138), 20, 160, fill=color, outline=OUTLINE, width=lw(2))
    save(img, name)


# ───────────────────────── UFC / COMBATE ─────────────────────────
def fight_shorts(name, color, trim):
    img, d = new()
    d.polygon(p((140, 304), (260, 304), (266, 388), (208, 388), (200, 352), (192, 388), (134, 388)), fill=color, outline=OUTLINE, width=lw(3))
    d.rectangle(box(140, 304, 260, 320), fill=trim)
    for x0, x1 in ((134, 150), (250, 266)):
        d.polygon(p((x0, 360), (x1, 360), ((x0 + x1) / 2, 388)), fill=trim)
    text(d, (232, 340), 'SZ', 14, trim)
    save(img, name)


def rashguard(name, color, accent):
    img, d = new()
    for sh, hd in ((SHOULDER_L, HAND_L), (SHOULDER_R, HAND_R)):
        d.polygon(arm_poly(sh, hd, -0.04, 0.86, ARM_W + 6), fill=color, outline=OUTLINE, width=lw(3))
        d.polygon(arm_poly(sh, hd, 0.2, 0.3, ARM_W + 6), fill=accent)
    d.rounded_rectangle(box(136, 164, 264, 336), radius=lw(30), fill=color, outline=OUTLINE, width=lw(3))
    d.polygon(p((136, 250), (264, 210), (264, 236), (136, 276)), fill=accent)
    d.ellipse(box(184, 160, 216, 180), fill=color, outline=OUTLINE, width=lw(2))
    save(img, name)


def basic_tee(name, color, logo=None):
    img, d = new()
    sleeves(d, color, t1=0.36)
    torso(d, color)
    d.arc(box(180, 152, 220, 182), 0, 180, fill=darker(color, 0.8), width=lw(5))
    if logo:
        text(d, (200, 236), logo, 30, (255, 255, 255, 255) if sum(color[:3]) < 300 else (30, 30, 40, 255))
    save(img, name)


def mma_gloves(name, color):
    img, d = new()
    for hx, hy in (HAND_L, HAND_R):
        d.rounded_rectangle(box(hx - 21, hy - 20, hx + 21, hy + 20), radius=lw(14), fill=color, outline=OUTLINE, width=lw(3))
        d.rectangle(box(hx - 20, hy - 26, hx + 20, hy - 16), fill=(245, 245, 245, 255), outline=OUTLINE, width=lw(2))
        d.line(p((hx - 12, hy + 6), (hx + 12, hy + 6)), fill=OUTLINE, width=lw(2))
    save(img, name)


def hand_wraps(name):
    img, d = new()
    for sh, hd in ((SHOULDER_L, HAND_L), (SHOULDER_R, HAND_R)):
        d.polygon(arm_poly(sh, hd, 0.84, 1.0, ARM_W + 4), fill=(250, 250, 250, 255), outline=OUTLINE, width=lw(2))
        d.ellipse(box(hd[0] - 18, hd[1] - 14, hd[0] + 18, hd[1] + 18), fill=(250, 250, 250, 255), outline=OUTLINE, width=lw(2))
        for k in (-6, 2, 10):
            d.line(p((hd[0] - 16, hd[1] + k), (hd[0] + 16, hd[1] + k - 4)), fill=(200, 200, 210, 255), width=lw(2))
    save(img, name)


def title_belt(name, plate, strap=(25, 25, 30, 255)):
    img, d = new()
    d.rounded_rectangle(box(130, 300, 270, 332), radius=lw(10), fill=strap, outline=OUTLINE, width=lw(3))
    d.ellipse(box(166, 286, 234, 346), fill=plate, outline=OUTLINE, width=lw(3))
    d.ellipse(box(180, 298, 220, 334), fill=darker(plate, 0.8))
    text(d, (200, 316), 'SZ', 14, (255, 255, 255, 255))
    for x in (144, 156, 244, 256):
        d.ellipse(box(x - 5, 311, x + 5, 321), fill=plate)
    save(img, name)


# ───────────────────────── CUELLO ─────────────────────────
def medal(name, color):
    img, d = new()
    d.line(p((178, 160), (200, 236)), fill=(30, 90, 200, 255), width=lw(8))
    d.line(p((222, 160), (200, 236)), fill=(210, 40, 50, 255), width=lw(8))
    d.ellipse(box(184, 228, 216, 260), fill=color, outline=OUTLINE, width=lw(3))
    text(d, (200, 244), '1', 14, (90, 60, 0, 255))
    save(img, name)


def scarf(name, c1, c2):
    img, d = new()
    d.rounded_rectangle(box(170, 158, 230, 184), radius=lw(12), fill=c1, outline=OUTLINE, width=lw(3))
    d.polygon(p((206, 176), (232, 176), (240, 300), (214, 300)), fill=c1, outline=OUTLINE, width=lw(3))
    for y in (196, 236, 276):
        d.polygon(p((208 + (y - 176) * 0.06, y), (234 + (y - 176) * 0.06, y), (235 + (y - 176) * 0.06, y + 16), (209 + (y - 176) * 0.06, y + 16)), fill=c2)
    for x in range(214, 242, 6):
        d.line(p((x, 300), (x, 314)), fill=c1, width=lw(3))
    save(img, name)


def chain(name):
    img, d = new()
    for k in range(13):
        ang = math.radians(20 + k * 11.5)
        x, y = 200 + 40 * math.cos(ang), 160 + 48 * math.sin(ang)
        d.ellipse(box(x - 5, y - 4, x + 5, y + 4), outline=(230, 180, 40, 255), width=lw(3))
    save(img, name)


def tn_headband(name, color):
    img, d = new()
    d.rounded_rectangle(box(148, 66, 252, 82), radius=lw(7), fill=color, outline=OUTLINE, width=lw(3))
    d.polygon(p((246, 70), (270, 84), (264, 96), (244, 80)), fill=color, outline=OUTLINE, width=lw(2))
    save(img, name)


if __name__ == '__main__':
    import shutil
    shutil.rmtree(OUT, ignore_errors=True)
    # ── Cuerpo (5 tonos) ──
    for n, c in (('body_pale', (255, 226, 200, 255)), ('body_light', (250, 214, 180, 255)), ('body_medium', (214, 160, 110, 255)),
                 ('body_tan', (176, 118, 72, 255)), ('body_dark', (120, 78, 48, 255))):
        body(n, c)
    # ── Cabello ──
    BLACK, BROWN, BLOND, RED = (30, 26, 26, 255), (70, 46, 30, 255), (225, 185, 95, 255), (170, 70, 30, 255)
    hair('hair_short_brown', 'short', BROWN)
    hair('hair_short_black', 'short', BLACK)
    hair('hair_short_blond', 'short', BLOND)
    hair('hair_buzz', 'buzz', BLACK)
    hair('hair_afro', 'afro', BLACK)
    hair('hair_long_brown', 'long', BROWN)
    hair('hair_long_blond', 'long', BLOND)
    hair('hair_mohawk', 'mohawk', RED)
    hair('hair_bun', 'bun', BROWN)
    hair('hair_curly_red', 'curly', RED)
    # ── Cara ──
    face('face_beard', 'beard', BROWN)
    face('face_beard_black', 'beard', BLACK)
    face('face_stubble', 'stubble', (60, 45, 40, 255))
    face('face_sunglasses', 'sunglasses')
    face('face_paint', 'paint')
    # ── Básicos ──
    basic_tee('top_basic_white', (248, 248, 248, 255))
    basic_tee('top_basic_black', (35, 35, 45, 255), logo='SZ')
    basic_tee('top_basic_gray', (150, 156, 168, 255))
    crown('head_crown')
    medal('neck_medal_gold', (255, 200, 40, 255))
    chain('neck_chain')

    # ── Fútbol ──
    football_top('top_fb_red', (215, 35, 45, 255))
    football_top('top_fb_blue', (30, 90, 200, 255), number='7')
    football_top('top_fb_stripes', (20, 20, 30, 255), number='9', stripes=(245, 245, 245, 255), trim=(255, 200, 40, 255))
    football_top('top_fb_green', (20, 140, 70, 255), number='11')
    football_top('top_fb_white', (248, 248, 248, 255), number='5', trim=(30, 30, 40, 255))
    football_top('top_fb_yellow', (255, 210, 30, 255), number='10', trim=(20, 60, 150, 255))
    football_top('top_fb_sky', (120, 190, 240, 255), number='8', stripes=(250, 250, 250, 255), trim=(20, 20, 30, 255))
    football_top('top_fb_redblack', (200, 20, 30, 255), number='22', stripes=(25, 25, 30, 255))
    football_top('top_fb_gold', (240, 190, 40, 255), number='1', trim=(30, 30, 40, 255))
    football_bottom('bottom_fb_white', (245, 245, 245, 255), (215, 35, 45, 255))
    football_bottom('bottom_fb_black', (35, 35, 45, 255), (245, 245, 245, 255))
    football_bottom('bottom_fb_blue', (20, 50, 140, 255), (20, 50, 140, 255))
    football_bottom('bottom_fb_green', (20, 120, 60, 255), (245, 245, 245, 255))
    soccer_ball('hand_fb_ball')
    gloves('hand_fb_gloves')
    captain('hand_fb_captain')
    scarf('neck_fb_scarf_red', (210, 35, 45, 255), (250, 250, 250, 255))
    scarf('neck_fb_scarf_green', (20, 130, 60, 255), (250, 250, 250, 255))

    # ── NBA ──
    nba_top('top_nba_purple', (95, 40, 140, 255), (255, 195, 40, 255))
    nba_top('top_nba_green', (20, 120, 60, 255), (245, 245, 245, 255), number='33')
    nba_top('top_nba_red', (200, 20, 40, 255), (25, 25, 30, 255), number='3')
    nba_top('top_nba_blue', (20, 70, 170, 255), (255, 140, 30, 255), number='11')
    nba_top('top_nba_black', (25, 25, 30, 255), (200, 160, 60, 255), number='0')
    nba_top('top_nba_allstar', (30, 40, 70, 255), (255, 200, 40, 255), number='★')
    nba_bottom('bottom_nba_purple', (95, 40, 140, 255), (255, 195, 40, 255))
    nba_bottom('bottom_nba_green', (20, 120, 60, 255), (245, 245, 245, 255))
    nba_bottom('bottom_nba_red', (200, 20, 40, 255), (25, 25, 30, 255))
    nba_bottom('bottom_nba_blue', (20, 70, 170, 255), (255, 140, 30, 255))
    nba_bottom('bottom_nba_black', (25, 25, 30, 255), (200, 160, 60, 255))
    headband('head_nba_headband', (245, 245, 245, 255))
    headband('head_nba_headband_black', (30, 30, 36, 255))
    basketball('hand_nba_ball')
    wristbands('hand_nba_wristbands', (245, 245, 245, 255))
    chain('neck_nba_chain')

    # ── Tenis ──
    tennis_top('top_tn_white', (250, 250, 250, 255), (40, 160, 90, 255))
    tennis_top('top_tn_orange', (255, 140, 50, 255), (30, 30, 40, 255))
    tennis_top('top_tn_blue', (40, 110, 210, 255), (255, 255, 255, 255))
    tennis_top('top_tn_pink', (245, 120, 170, 255), (30, 30, 40, 255))
    tennis_shorts('bottom_tn_shorts')
    tennis_skirt('bottom_tn_skirt')
    cap('head_tn_cap', (40, 90, 200, 255))
    cap('head_tn_cap_white', (245, 245, 245, 255))
    visor('head_tn_visor', (40, 160, 90, 255))
    tn_headband('head_tn_headband', (210, 40, 50, 255))
    racket('hand_tn_racket', (220, 40, 50, 255))
    racket('hand_tn_gold_racket', (240, 190, 40, 255), strings=(255, 240, 180, 255))
    wristbands('hand_tn_wristbands', (40, 160, 90, 255))

    # ── UFC ──
    fight_shorts('bottom_ufc_red', (200, 25, 35, 255), (250, 250, 250, 255))
    fight_shorts('bottom_ufc_blue', (25, 70, 190, 255), (250, 250, 250, 255))
    fight_shorts('bottom_ufc_black', (25, 25, 30, 255), (230, 180, 40, 255))
    fight_shorts('bottom_ufc_white', (245, 245, 245, 255), (200, 25, 35, 255))
    rashguard('top_ufc_rashguard', (25, 25, 30, 255), (200, 25, 35, 255))
    rashguard('top_ufc_rashguard_blue', (25, 70, 190, 255), (250, 250, 250, 255))
    basic_tee('top_ufc_walkout', (25, 25, 30, 255), logo='FIGHT')
    mma_gloves('hand_ufc_gloves', (25, 25, 30, 255))
    mma_gloves('hand_ufc_gloves_red', (200, 25, 35, 255))
    hand_wraps('hand_ufc_wraps')
    title_belt('waist_ufc_belt', (255, 200, 40, 255))
    title_belt('waist_ufc_belt_silver', (200, 205, 215, 255))
    tattoo('tattoo_tribal', 'tribal')
    tattoo('tattoo_sleeves', 'sleeves')
    tattoo('tattoo_chest', 'chest')
    tattoo('tattoo_rose', 'rose')
    tattoo('tattoo_full', 'full')
    face('face_ufc_blackeye', 'blackeye')
    face('face_ufc_mouthguard', 'mouthguard', (40, 120, 220, 255))
    # Miniaturas de tatuajes: sobre la piel, si no la tinta no se ve en el catálogo.
    skin = Image.open(os.path.join(OUT, 'body_medium.png')).convert('RGBA')
    for t in ('tattoo_tribal', 'tattoo_sleeves', 'tattoo_chest', 'tattoo_rose', 'tattoo_full'):
        layer = Image.open(os.path.join(OUT, f'{t}.png')).convert('RGBA')
        comp = skin.copy()
        comp.alpha_composite(layer)
        comp.crop((84, 150, 316, 346)).resize((160, 135), Image.LANCZOS).save(os.path.join(OUT, 'thumbs', f'{t}.png'), optimize=True)
    print('Listo: assets/avatar/')
