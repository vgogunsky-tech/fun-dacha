import os
from io import BytesIO
from typing import Tuple

from PIL import Image, ImageOps
from reportlab.pdfgen import canvas
from reportlab.lib.units import mm
from reportlab.lib.pagesizes import A6, A5, A3


BASE_DIR = os.path.dirname(os.path.abspath(__file__))
SRC_LOGO = os.path.join(BASE_DIR, "old_logo.jpg")
OUT_BASE = os.path.join(BASE_DIR, "FUN-DACHA")


def ensure_dir(path: str) -> None:
    os.makedirs(path, exist_ok=True)


def load_logo() -> Image.Image:
    img = Image.open(SRC_LOGO).convert("RGBA")
    return img


def fit_to_canvas(img: Image.Image, size: Tuple[int, int], bg=(255, 255, 255, 0)) -> Image.Image:
    canvas_img = Image.new("RGBA", size, bg)
    img_copy = img.copy()
    img_copy.thumbnail(size, Image.LANCZOS)
    x = (size[0] - img_copy.width) // 2
    y = (size[1] - img_copy.height) // 2
    canvas_img.paste(img_copy, (x, y), img_copy)
    return canvas_img


def save_png(img: Image.Image, path: str) -> None:
    ensure_dir(os.path.dirname(path))
    img.save(path, format="PNG")


def save_svg_with_raster(img: Image.Image, path: str) -> None:
    # Embed raster as data URI inside a basic SVG wrapper
    ensure_dir(os.path.dirname(path))
    buf = BytesIO()
    img.save(buf, format="PNG")
    data = buf.getvalue()
    import base64
    b64 = base64.b64encode(data).decode("ascii")
    w, h = img.size
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}"><image href="data:image/png;base64,{b64}" width="{w}" height="{h}"/></svg>'
    with open(path, "w", encoding="utf-8") as f:
        f.write(svg)


def generate_logo_set():
    logo = load_logo()
    # LOGO/main and horizontal
    main = fit_to_canvas(logo, (1024, 1024))
    save_png(main, os.path.join(OUT_BASE, "LOGO", "main-1024x1024.png"))

    horiz = fit_to_canvas(logo, (1024, 256))
    save_png(horiz, os.path.join(OUT_BASE, "LOGO", "horizontal-1024x256.png"))

    # Monochrome
    mono = ImageOps.grayscale(main).convert("L")
    mono = ImageOps.autocontrast(mono)
    mono_rgba = ImageOps.colorize(mono, black=(0, 0, 0), white=(0, 0, 0)).convert("RGBA")
    save_png(mono_rgba, os.path.join(OUT_BASE, "LOGO", "monochrome.png"))
    save_svg_with_raster(mono_rgba, os.path.join(OUT_BASE, "LOGO", "monochrome.svg"))

    # Favicons
    fav_out = os.path.join(OUT_BASE, "LOGO", "favicon")
    for sz in (512, 256, 128, 64):
        ico = fit_to_canvas(logo, (sz, sz))
        save_png(ico, os.path.join(fav_out, f"favicon-{sz}.png"))


def generate_digital():
    # Website banner 1920x600
    banner = fit_to_canvas(load_logo(), (1920, 600), bg=(255, 255, 255, 255))
    save_png(banner, os.path.join(OUT_BASE, "DIGITAL", "banners", "hero-1920x600.png"))

    # Social profile 1080x1080
    social = fit_to_canvas(load_logo(), (1080, 1080))
    save_png(social, os.path.join(OUT_BASE, "DIGITAL", "social", "profile-1080.png"))

    # Email signature 300x100
    email = fit_to_canvas(load_logo(), (300, 100), bg=(255, 255, 255, 0))
    save_png(email, os.path.join(OUT_BASE, "DIGITAL", "email", "signature-300x100.png"))

    # Invoice header 600x150
    inv = fit_to_canvas(load_logo(), (600, 150), bg=(255, 255, 255, 0))
    save_png(inv, os.path.join(OUT_BASE, "DIGITAL", "invoice", "header-600x150.png"))


def draw_pdf_with_logo(path: str, width_pt: float, height_pt: float, logo_scale: float = 0.6):
    ensure_dir(os.path.dirname(path))
    c = canvas.Canvas(path, pagesize=(width_pt, height_pt))
    # place raster logo centered
    logo = fit_to_canvas(load_logo(), (int(width_pt * logo_scale), int(height_pt * logo_scale)), bg=(255, 255, 255, 0))
    tmp = BytesIO()
    logo.save(tmp, format="PNG")
    tmp.seek(0)
    lw, lh = logo.size
    x = (width_pt - lw) / 2
    y = (height_pt - lh) / 2
    c.drawImage(ImageReader(tmp), x, y, width=lw, height=lh, mask='auto')
    c.showPage()
    c.save()


# Helper to embed PIL image into reportlab
from reportlab.lib.utils import ImageReader


def generate_print():
    # Stickers: Ø50mm and Ø70mm (simple square PDF with centered logo)
    draw_pdf_with_logo(os.path.join(OUT_BASE, "PRINT", "stickers", "sticker-50mm.pdf"), 50 * mm, 50 * mm, 0.8)
    draw_pdf_with_logo(os.path.join(OUT_BASE, "PRINT", "stickers", "sticker-70mm.pdf"), 70 * mm, 70 * mm, 0.8)

    # Paper bags: 25x30 cm and 35x45 cm
    draw_pdf_with_logo(os.path.join(OUT_BASE, "PRINT", "packaging", "paper-bag-25x30cm.pdf"), 250 * mm, 300 * mm, 0.5)
    draw_pdf_with_logo(os.path.join(OUT_BASE, "PRINT", "packaging", "paper-bag-35x45cm.pdf"), 350 * mm, 450 * mm, 0.5)

    # Thank-you card A6
    draw_pdf_with_logo(os.path.join(OUT_BASE, "PRINT", "packaging", "thank-you-card-A6.pdf"), A6[0], A6[1], 0.5)

    # Business cards 90x50 mm
    draw_pdf_with_logo(os.path.join(OUT_BASE, "PRINT", "business-cards", "business-card-90x50.pdf"), 90 * mm, 50 * mm, 0.6)

    # Poster A3
    draw_pdf_with_logo(os.path.join(OUT_BASE, "PRINT", "posters", "poster-A3.pdf"), A3[0], A3[1], 0.6)


def generate_brand_guides():
    # Simple placeholder PDFs
    for name in ("colors.pdf", "typography.pdf", "guidelines.pdf"):
        path = os.path.join(OUT_BASE, "BRAND_GUIDE", name)
        ensure_dir(os.path.dirname(path))
        c = canvas.Canvas(path, pagesize=(210 * mm, 297 * mm))
        c.setFont("Helvetica", 20)
        c.drawString(40, 800, f"FUN-DACHA — {name.replace('.pdf','').title()}")
        c.setFont("Helvetica", 12)
        c.drawString(40, 770, "Placeholder document. Replace with finalized brand guide.")
        c.showPage()
        c.save()


def main():
    if not os.path.isfile(SRC_LOGO):
        raise FileNotFoundError("old_logo.jpg not found in repository root")
    generate_logo_set()
    generate_digital()
    generate_print()
    generate_brand_guides()
    print(f"Assets generated under {OUT_BASE}")


if __name__ == "__main__":
    main()

