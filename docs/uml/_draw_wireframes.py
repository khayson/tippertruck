"""Phone-frame wireframes for proposal Figures 3.6–3.13. Fictional demo data only."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(r"C:\Users\VICTUS\Desktop\tippertruck")
OUT = ROOT / "docs" / "uml" / "wireframes"
ASSETS = ROOT / "mobile" / "assets" / "images"

AMBER = (212, 90, 18)
LATERITE = (140, 58, 23)
INK = (25, 23, 19)
SLATE = (107, 101, 92)
BONE = (244, 240, 232)
SIGNAL = (30, 107, 76)
WHITE = (255, 255, 255)
WASH = (212, 200, 184)
TRACK = (239, 231, 217)
DOCK = (25, 23, 19)

W, H = 390, 844  # logical dp
SCALE = 2
PW, PH = W * SCALE, H * SCALE


def _font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    name = "segoeuib.ttf" if bold else "segoeui.ttf"
    path = Path(r"C:\Windows\Fonts") / name
    try:
        return ImageFont.truetype(str(path), size * SCALE)
    except OSError:
        return ImageFont.load_default()


F12 = _font(12)
F13 = _font(13)
F14 = _font(14)
F14B = _font(14, True)
F16 = _font(16)
F16B = _font(16, True)
F18B = _font(18, True)
F22B = _font(22, True)
F28B = _font(28, True)
F32B = _font(32, True)


def S(x: int, y: int | None = None):
    if y is None:
        return x * SCALE
    return x * SCALE, y * SCALE


def new_screen(bg=BONE) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    im = Image.new("RGB", (PW, PH), bg)
    return im, ImageDraw.Draw(im)


def rr(d: ImageDraw.ImageDraw, xy, r: int, fill=None, outline=None, width: int = 1):
    d.rounded_rectangle(xy, radius=S(r), fill=fill, outline=outline, width=width * SCALE)


def text(d, xy, s, font, fill=INK, anchor="lt"):
    d.text((S(xy[0]), S(xy[1])), s, font=font, fill=fill, anchor=anchor)


def status_bar(d: ImageDraw.ImageDraw, dark: bool = False):
    c = WHITE if dark else INK
    text(d, (24, 14), "9:41", F13, c)
    text(d, (366, 14), "LTE  100%", F12, c, anchor="rt")


def back_row(d, title: str):
    d.polygon(
        [S(22, 48), S(34, 40), S(34, 56)],
        fill=INK,
    )
    text(d, (195, 48), title, F16B, anchor="mm")


def step_bar(d, current: int, y: int = 72):
    labels = ["Sand", "Truck", "Place", "Review", "Pay"]
    x0, gap = 28, 72
    for i, lab in enumerate(labels):
        x = x0 + i * gap
        col = AMBER if i <= current else TRACK
        d.ellipse([S(x, y), S(x + 14, y + 14)], fill=col)
        text(d, (x + 7, y + 22), lab, F12, AMBER if i <= current else SLATE, "mt")
        if i < 4:
            d.line([S(x + 16, y + 7), S(x + gap - 4, y + 7)], fill=TRACK, width=S(2))


def pill(d, xy, label, filled=True, dark=True):
    x1, y1, x2, y2 = xy
    if filled:
        fill = INK if dark else AMBER
        tc = WHITE
        outline = None
    else:
        fill = None
        tc = INK
        outline = INK
    rr(d, [S(x1, y1), S(x2, y2)], 22, fill=fill or WHITE, outline=outline, width=2)
    text(d, ((x1 + x2) // 2, (y1 + y2) // 2), label, F16B, tc, "mm")


def field(d, y, label, value):
    text(d, (24, y), label, F12, SLATE)
    rr(d, [S(24, y + 16), S(366, y + 58)], 12, fill=WHITE, outline=TRACK, width=1)
    text(d, (38, y + 37), value, F14, INK, "lm")


def card(d, xy, fill=WHITE):
    rr(d, [S(xy[0], xy[1]), S(xy[2], xy[3])], 16, fill=fill, outline=TRACK, width=1)


def dock(d, selected: int = 0):
    rr(d, [S(18, 756), S(372, 828)], 28, fill=DOCK)
    items = ["Home", "Orders", "Chat", "Profile"]
    slot = (372 - 18) / 4
    for i, name in enumerate(items):
        cx = 18 + slot * i + slot / 2
        if i == selected:
            rr(d, [S(cx - 36, 766), S(cx + 36, 818)], 16, fill=AMBER)
            col = WHITE
        else:
            col = (255, 255, 255, )
            col = (180, 176, 170)
        d.ellipse([S(cx - 8, 776), S(cx + 8, 792)], outline=col, width=S(2))
        text(d, (int(cx), 806), name, F12, col, "mt")


def paste_fit(base: Image.Image, path: Path, box):
    if not path.exists():
        return
    img = Image.open(path).convert("RGBA")
    x1, y1, x2, y2 = [S(v) for v in box]
    img.thumbnail((x2 - x1, y2 - y1), Image.Resampling.LANCZOS)
    px = x1 + (x2 - x1 - img.width) // 2
    py = y1 + (y2 - y1 - img.height) // 2
    base.paste(img, (px, py), img)


def chrome(screen: Image.Image) -> Image.Image:
    """Device frame on a white page background."""
    pad = 36
    frame = 18
    out_w = PW + (pad + frame) * 2
    out_h = PH + (pad + frame) * 2
    canvas = Image.new("RGB", (out_w, out_h), WHITE)
    d = ImageDraw.Draw(canvas)
    d.rounded_rectangle(
        [pad, pad, out_w - pad, out_h - pad],
        radius=48,
        fill=INK,
    )
    inner = Image.new("RGB", (PW, PH), BONE)
    inner.paste(screen)
    mask = Image.new("L", (PW, PH), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, PW - 1, PH - 1], radius=36, fill=255)
    canvas.paste(inner, (pad + frame, pad + frame), mask)
    # notch
    nx = out_w // 2
    d.rounded_rectangle([nx - 60, pad + 10, nx + 60, pad + 22], radius=8, fill=(15, 14, 12))
    return canvas


def welcome() -> Image.Image:
    im, d = new_screen(WASH)
    status_bar(d)
    paste_fit(im, ASSETS / "tipper_hero.png", (20, 70, 370, 380))
    text(d, (28, 420), "Skip the quarry", F28B, INK)
    text(d, (28, 456), "queue —", F28B, INK)
    text(d, (28, 498), "order sand", F28B, AMBER)
    text(d, (28, 534), "in minutes.", F28B, INK)
    pill(d, (24, 720, 186, 776), "Login", filled=False)
    pill(d, (204, 720, 366, 776), "Get Started", filled=True, dark=True)
    return im


def home() -> Image.Image:
    im, d = new_screen(BONE)
    status_bar(d)
    text(d, (24, 52), "Hello, Ama", F22B)
    d.ellipse([S(330, 40), S(370, 80)], fill=AMBER)
    text(d, (350, 60), "A", F16B, WHITE, "mm")
    rr(d, [S(24, 100), S(366, 188)], 18, fill=AMBER)
    text(d, (44, 128), "Book a truck", F18B, WHITE)
    text(d, (44, 156), "River, quarry or filling sand  →", F13, WHITE)
    text(d, (24, 212), "Sand types", F16B)
    sands = [
        (ASSETS / "sand_river.jpg", "River sand", "Plaster and finishing"),
        (ASSETS / "sand_quarry.jpg", "Quarry sand", "Concrete and foundations"),
        (ASSETS / "sand_filling.jpg", "Filling sand", "Backfill and levelling"),
    ]
    y = 244
    for path, name, blurb in sands:
        card(d, (24, y, 366, y + 92))
        if path.exists():
            thumb = Image.open(path).convert("RGB")
            thumb = thumb.resize((S(72), S(72)), Image.Resampling.LANCZOS)
            im.paste(thumb, S(36, y + 10))
        else:
            rr(d, [S(36, y + 10), S(108, y + 82)], 10, fill=TRACK)
        text(d, (124, y + 28), name, F16B)
        text(d, (124, y + 54), blurb, F13, SLATE)
        y += 104
    text(d, (24, 568), "Quick actions", F14B, SLATE)
    actions = ["Orders", "Chat", "Issues", "Profile"]
    for i, a in enumerate(actions):
        x = 24 + i * 86
        rr(d, [S(x, 592), S(x + 78, 668)], 14, fill=WHITE, outline=TRACK)
        d.ellipse([S(x + 27, 606), S(x + 51, 630)], outline=AMBER, width=S(2))
        text(d, (x + 39, 648), a, F12, INK, "mt")
    dock(d, 0)
    return im


def truck() -> Image.Image:
    im, d = new_screen(BONE)
    status_bar(d)
    back_row(d, "Truck size")
    step_bar(d, 1)
    text(d, (24, 118), "River sand", F13, AMBER)
    text(d, (24, 142), "How big a load?", F22B)
    trucks = [
        ("Small", "GHS 250", "1–3 tonnes · tight access", False),
        ("Medium", "GHS 450", "4–7 tonnes · most jobs", True),
        ("Large", "GHS 700", "8+ tonnes · bulk fills", False),
    ]
    y = 188
    for name, price, blurb, popular in trucks:
        outline = AMBER if popular else TRACK
        rr(d, [S(24, y), S(366, y + 108)], 16, fill=WHITE, outline=outline, width=2 if popular else 1)
        text(d, (40, y + 22), name, F16B)
        text(d, (350, y + 22), price, F16B, AMBER, "rt")
        text(d, (40, y + 52), blurb, F13, SLATE)
        if popular:
            rr(d, [S(40, y + 74), S(128, y + 96)], 10, fill=(255, 243, 232))
            text(d, (84, y + 85), "Popular", F12, LATERITE, "mm")
        y += 120
    pill(d, (24, 760, 366, 816), "Continue", filled=True, dark=True)
    return im


def delivery() -> Image.Image:
    im, d = new_screen(BONE)
    status_bar(d)
    back_row(d, "Delivery")
    step_bar(d, 2)
    text(d, (24, 118), "Where should we unload?", F18B)
    field(d, 156, "Recipient name", "Ama Boateng")
    field(d, 228, "Phone", "0200000003")
    field(d, 300, "Street", "15 Demo Street")
    field(d, 372, "Region", "Greater Accra")
    field(d, 444, "City", "Tesano")
    field(d, 516, "Landmark (optional)", "Near the new site fence")
    rr(d, [S(24, 600), S(48, 624)], 4, fill=AMBER)
    text(d, (60, 612), "Save this address on this device", F13, INK, "lm")
    pill(d, (24, 760, 366, 816), "Continue", filled=True, dark=True)
    return im


def summary() -> Image.Image:
    im, d = new_screen(BONE)
    status_bar(d)
    back_row(d, "Summary")
    step_bar(d, 3)
    text(d, (24, 118), "Review order", F22B)
    rr(d, [S(24, 168), S(366, 268)], 18, fill=AMBER)
    text(d, (44, 198), "Total", F13, WHITE)
    text(d, (44, 230), "GHS 450", F32B, WHITE)
    card(d, (24, 288, 366, 430))
    rows = [
        ("Sand", "River sand"),
        ("Truck", "Medium"),
        ("When", "As soon as confirmed"),
    ]
    for i, (k, v) in enumerate(rows):
        yy = 312 + i * 36
        text(d, (40, yy), k, F13, SLATE)
        text(d, (350, yy), v, F14B, INK, "rt")
    card(d, (24, 450, 366, 560))
    text(d, (40, 470), "Deliver to", F13, SLATE)
    text(d, (40, 498), "Ama Boateng · 0200000003", F14B)
    text(d, (40, 524), "15 Demo Street, Tesano", F13, SLATE)
    card(d, (24, 580, 366, 700))
    text(d, (40, 600), "Price (from server)", F13, SLATE)
    text(d, (40, 632), "Medium truck", F14)
    text(d, (350, 632), "GHS 450", F14B, INK, "rt")
    text(d, (40, 664), "Delivery surcharge", F14)
    text(d, (350, 664), "FREE", F14B, SIGNAL, "rt")
    pill(d, (24, 760, 366, 816), "Proceed to payment", filled=True, dark=True)
    return im


def payment() -> Image.Image:
    im, d = new_screen(BONE)
    status_bar(d)
    back_row(d, "Payment")
    step_bar(d, 4)
    rr(d, [S(24, 118), S(366, 200)], 18, fill=AMBER)
    text(d, (44, 142), "Amount due", F13, WHITE)
    text(d, (44, 172), "GHS 450", F28B, WHITE)
    text(d, (24, 224), "Delivering to Ama Boateng · 0200000003", F13, SLATE)
    text(d, (24, 258), "Payment method", F16B)
    rr(d, [S(24, 288), S(366, 360)], 14, fill=WHITE, outline=AMBER, width=2)
    d.ellipse([S(40, 314), S(64, 338)], outline=AMBER, width=S(2))
    d.ellipse([S(46, 320), S(58, 332)], fill=AMBER)
    text(d, (80, 324), "Mobile Money (simulated)", F14B, INK, "lm")
    rr(d, [S(24, 376), S(366, 448)], 14, fill=WHITE, outline=TRACK)
    d.ellipse([S(40, 402), S(64, 426)], outline=SLATE, width=S(2))
    text(d, (80, 412), "Cash on delivery", F14B, INK, "lm")
    field(d, 468, "MoMo name", "Ama Boateng")
    field(d, 540, "MoMo phone", "0200000003")
    text(d, (24, 612), "Network", F12, SLATE)
    for i, net in enumerate(("MTN", "Telecel", "AirtelTigo")):
        x = 24 + i * 114
        fill, tc, ol = (AMBER, WHITE, AMBER) if net == "MTN" else (WHITE, INK, TRACK)
        rr(d, [S(x, 632), S(x + 106, 672)], 12, fill=fill, outline=ol)
        text(d, (x + 53, 652), net, F13, tc, "mm")
    text(d, (24, 696), "No Mobile Money PIN is requested or stored.", F12, SLATE)
    pill(d, (24, 760, 366, 816), "Confirm & place order", filled=True, dark=True)
    return im


def tracking() -> Image.Image:
    im, d = new_screen(BONE)
    status_bar(d)
    back_row(d, "Tracking")
    text(d, (24, 80), "TT-20260901-0004", F14B, AMBER)
    text(d, (24, 108), "River sand · Medium", F18B)
    text(d, (24, 140), "On the way", F14, SIGNAL)
    rr(d, [S(24, 172), S(366, 188)], 6, fill=TRACK)
    rr(d, [S(24, 172), S(250, 188)], 6, fill=SIGNAL)
    text(d, (350, 180), "66%", F13, SIGNAL, "rm")
    steps = [("Confirmed", True), ("On the way", True), ("Delivered", False)]
    y = 220
    for label, done in steps:
        col = SIGNAL if done else TRACK
        d.ellipse([S(28, y), S(52, y + 24)], fill=col)
        text(d, (68, y + 12), label, F16B if done else F16, INK if done else SLATE, "lm")
        y += 48
    card(d, (24, 380, 366, 520))
    text(d, (40, 400), "Drop-off", F13, SLATE)
    text(d, (40, 428), "15 Demo Street, Tesano", F14B)
    text(d, (40, 456), "Greater Accra", F13, SLATE)
    text(d, (40, 488), "Payment: Mobile Money (paid)", F13, SLATE)
    text(d, (24, 548), "Status is polled while this screen is open.", F12, SLATE)
    text(d, (24, 568), "Not a live GPS map.", F12, SLATE)
    pill(d, (24, 680, 366, 736), "View history", filled=False)
    pill(d, (24, 752, 366, 808), "New order", filled=True, dark=True)
    return im


def chatbot() -> Image.Image:
    im, d = new_screen(BONE)
    rr(d, [S(0, 0), S(390, 96)], 0, fill=AMBER)
    status_bar(d, dark=True)
    text(d, (24, 56), "Tipper Bot", F18B, WHITE)
    text(d, (24, 80), "Prices, sand types, delivery", F12, WHITE)
    # bot bubble
    rr(d, [S(24, 120), S(300, 210)], 16, fill=WHITE)
    text(d, (40, 142), "Hi — ask about sand types,", F13)
    text(d, (40, 164), "truck prices, or your delivery.", F13)
    for i, chip in enumerate(("Prices", "Sand types", "Delivery")):
        x = 40 + i * 82
        rr(d, [S(x, 178), S(x + 76, 200)], 10, fill=(255, 243, 232))
        text(d, (x + 38, 189), chip, F12, LATERITE, "mm")
    # user
    rr(d, [S(110, 230), S(366, 286)], 16, fill=INK)
    text(d, (128, 258), "How much is a medium truck?", F13, WHITE, "lm")
    # bot reply
    rr(d, [S(24, 306), S(330, 400)], 16, fill=WHITE)
    text(d, (40, 328), "A medium truck of river sand", F13)
    text(d, (40, 350), "is GHS 450 (from the live", F13)
    text(d, (40, 372), "rate card — not calculated here).", F13)
    rr(d, [S(18, 760), S(300, 820)], 22, fill=WHITE, outline=TRACK)
    text(d, (36, 790), "Ask a question", F14, SLATE, "lm")
    d.ellipse([S(320, 766), S(372, 818)], fill=AMBER)
    text(d, (346, 792), "→", F18B, WHITE, "mm")
    return im


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    screens = {
        "welcome": welcome,
        "home": home,
        "truck": truck,
        "delivery": delivery,
        "summary": summary,
        "payment": payment,
        "tracking": tracking,
        "chatbot": chatbot,
    }
    for name, fn in screens.items():
        framed = chrome(fn())
        path = OUT / f"{name}.png"
        framed.save(path, "PNG", optimize=True)
        print(path.name, framed.size)


if __name__ == "__main__":
    main()
