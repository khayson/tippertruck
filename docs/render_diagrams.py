"""
Render both high-resolution ER diagrams for the Tipper Truck App using Pillow.
1. Peter Chen's Conceptual ERD (Different Shapes: Rectangles, Diamonds, Ovals, Double shapes)
2. Corrected Crow's Foot Relational Database Schema ERD (Table Boxes with PK/FK and accurate cardinalities)
"""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(r"c:\Users\KHAYSON\Desktop\tippertruck")
DOCS = ROOT / "docs"

# Colors
BG = (250, 248, 245)
CARD_BG = (255, 255, 255)
PRIMARY = (212, 90, 18)        # #D45A12 Tipper Amber
PRIMARY_LIGHT = (255, 247, 237) # #FFF7ED
PRIMARY_DARK = (168, 66, 9)     # #A84209
SECONDARY = (217, 119, 6)      # #D97706 Amber
SECONDARY_LIGHT = (254, 243, 199) # #FEF3C7
TEXT_DARK = (25, 23, 19)        # #191713
TEXT_MUTED = (107, 101, 92)     # #6B655C
BORDER_GRAY = (156, 163, 175)   # #9CA3AF
LINE_GRAY = (107, 101, 92)      # #6B655C
WEAK_GRAY = (75, 85, 99)        # #4B5563
ROW_EVEN = (250, 247, 242)
ROW_ODD = (255, 255, 255)

SCALE = 2  # 2x for sharp retina rendering

def get_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    name = "segoeuib.ttf" if bold else "segoeui.ttf"
    path = Path(r"C:\Windows\Fonts") / name
    try:
        return ImageFont.truetype(str(path), size * SCALE)
    except OSError:
        return ImageFont.load_default()

F_TITLE = get_font(20, bold=True)
F_SUBTITLE = get_font(12, bold=False)
F_HEADER = get_font(13, bold=True)
F_BODY = get_font(11, bold=False)
F_BODY_BOLD = get_font(11, bold=True)
F_SMALL = get_font(9, bold=False)
F_SMALL_BOLD = get_font(9, bold=True)
F_CARDINALITY = get_font(13, bold=True)

# -------------------------------------------------------------
# 1. RENDER CHEN NOTATION ERD
# -------------------------------------------------------------
def render_chen_erd(out_path: Path):
    W, H = 1750, 1250
    img = Image.new("RGB", (W * SCALE, H * SCALE), BG)
    draw = ImageDraw.Draw(img)

    # Title Banner
    bx1, by1, bx2, by2 = 50 * SCALE, 30 * SCALE, (W - 50) * SCALE, 115 * SCALE
    draw.rounded_rectangle([bx1, by1, bx2, by2], radius=8*SCALE, fill=CARD_BG, outline=PRIMARY, width=2*SCALE)
    draw.text((75 * SCALE, 46 * SCALE), "Figure 3.5a: Conceptual Entity-Relationship Model (Peter Chen Notation)", font=F_TITLE, fill=PRIMARY)
    draw.text((75 * SCALE, 82 * SCALE), "System domain entities (Rectangles), relationships (Diamonds), weak entities (Double Rectangles), and attributes (Ovals)", font=F_SUBTITLE, fill=TEXT_MUTED)

    # Positions
    # Entities:
    pos_user = (1320 * SCALE, 330 * SCALE)
    pos_order = (780 * SCALE, 630 * SCALE)
    pos_sand = (340 * SCALE, 330 * SCALE)
    pos_truck = (340 * SCALE, 930 * SCALE)
    pos_zone = (780 * SCALE, 220 * SCALE)
    pos_issue = (1320 * SCALE, 930 * SCALE)
    pos_log = (780 * SCALE, 1040 * SCALE)
    pos_chat = (1420 * SCALE, 630 * SCALE)

    # Helper: draw relationship line
    def draw_rel_line(p1, p2, dashed=False, double=False):
        if double:
            offset = 2 * SCALE
            draw.line([(p1[0]-offset, p1[1]), (p2[0]-offset, p2[1])], fill=LINE_GRAY, width=2*SCALE)
            draw.line([(p1[0]+offset, p1[1]), (p2[0]+offset, p2[1])], fill=LINE_GRAY, width=2*SCALE)
        elif dashed:
            # draw dashed line
            x1, y1 = p1
            x2, y2 = p2
            dist = ((x2 - x1)**2 + (y2 - y1)**2)**0.5
            steps = int(dist // (10 * SCALE))
            for s in range(0, steps, 2):
                t1 = s / steps
                t2 = min((s + 1) / steps, 1.0)
                draw.line([(x1 + (x2 - x1)*t1, y1 + (y2 - y1)*t1),
                           (x1 + (x2 - x1)*t2, y1 + (y2 - y1)*t2)], fill=LINE_GRAY, width=2*SCALE)
        else:
            draw.line([p1, p2], fill=LINE_GRAY, width=2*SCALE)

    # Diamonds positions:
    dia_places = (1050 * SCALE, 480 * SCALE)
    dia_assign = (1000 * SCALE, 570 * SCALE)
    dia_sand = (560 * SCALE, 480 * SCALE)
    dia_truck = (560 * SCALE, 780 * SCALE)
    dia_price = (340 * SCALE, 630 * SCALE)
    dia_log = (780 * SCALE, 835 * SCALE)
    dia_change = (1070 * SCALE, 885 * SCALE)
    dia_report = (1320 * SCALE, 630 * SCALE)
    dia_concern = (1050 * SCALE, 780 * SCALE)
    dia_zone = (780 * SCALE, 425 * SCALE)
    dia_chat = (1420 * SCALE, 480 * SCALE)

    # Draw lines from entities to diamonds
    draw_rel_line(pos_user, dia_places)
    draw_rel_line(dia_places, pos_order)

    draw_rel_line(pos_user, dia_assign)
    draw_rel_line(dia_assign, pos_order)

    draw_rel_line(pos_sand, dia_sand)
    draw_rel_line(dia_sand, pos_order)

    draw_rel_line(pos_truck, dia_truck)
    draw_rel_line(dia_truck, pos_order)

    draw_rel_line(pos_sand, dia_price)
    draw_rel_line(dia_price, pos_truck)

    draw_rel_line(pos_order, dia_log, double=True)
    draw_rel_line(dia_log, pos_log, double=True)

    draw_rel_line(pos_user, dia_change)
    draw_rel_line(dia_change, pos_log)

    draw_rel_line(pos_user, dia_report)
    draw_rel_line(dia_report, pos_issue)

    draw_rel_line(pos_order, dia_concern)
    draw_rel_line(dia_concern, pos_issue)

    draw_rel_line(pos_zone, dia_zone, dashed=True)
    draw_rel_line(dia_zone, pos_order, dashed=True)

    draw_rel_line(pos_user, dia_chat)
    draw_rel_line(dia_chat, pos_chat)

    # Attributes connector lines
    def draw_attr_line(p_ent, p_attr):
        draw.line([p_ent, p_attr], fill=BORDER_GRAY, width=1*SCALE)

    # Attributes dict
    user_attrs = [
        ((1180*SCALE, 210*SCALE), "id", True),
        ((1290*SCALE, 190*SCALE), "name", False),
        ((1400*SCALE, 190*SCALE), "email", False),
        ((1510*SCALE, 210*SCALE), "role", False),
        ((1530*SCALE, 280*SCALE), "phone", False),
        ((1530*SCALE, 350*SCALE), "provider", False),
    ]
    for p, n, pk in user_attrs: draw_attr_line(pos_user, p)

    order_attrs = [
        ((640*SCALE, 530*SCALE), "id", True),
        ((630*SCALE, 630*SCALE), "order_ref", False),
        ((640*SCALE, 730*SCALE), "price_ghs", False),
        ((920*SCALE, 530*SCALE), "total_ghs", False),
        ((930*SCALE, 630*SCALE), "status", False),
        ((920*SCALE, 730*SCALE), "region", False),
    ]
    for p, n, pk in order_attrs: draw_attr_line(pos_order, p)

    sand_attrs = [
        ((200*SCALE, 240*SCALE), "id", True),
        ((310*SCALE, 220*SCALE), "name", False),
        ((420*SCALE, 220*SCALE), "slug", False),
        ((190*SCALE, 320*SCALE), "is_active", False),
        ((190*SCALE, 380*SCALE), "sort_order", False),
    ]
    for p, n, pk in sand_attrs: draw_attr_line(pos_sand, p)

    truck_attrs = [
        ((190*SCALE, 880*SCALE), "id", True),
        ((190*SCALE, 940*SCALE), "name", False),
        ((190*SCALE, 1000*SCALE), "capacity", False),
        ((300*SCALE, 1040*SCALE), "min_tonnes", False),
        ((410*SCALE, 1040*SCALE), "is_popular", False),
    ]
    for p, n, pk in truck_attrs: draw_attr_line(pos_truck, p)

    zone_attrs = [
        ((650*SCALE, 150*SCALE), "id", True),
        ((780*SCALE, 140*SCALE), "region", False),
        ((910*SCALE, 150*SCALE), "surcharge", False),
    ]
    for p, n, pk in zone_attrs: draw_attr_line(pos_zone, p)

    issue_attrs = [
        ((1180*SCALE, 1000*SCALE), "id", True),
        ((1290*SCALE, 1030*SCALE), "issue_type", False),
        ((1400*SCALE, 1030*SCALE), "status", False),
        ((1500*SCALE, 970*SCALE), "admin_reply", False),
    ]
    for p, n, pk in issue_attrs: draw_attr_line(pos_issue, p)

    log_attrs = [
        ((640*SCALE, 1130*SCALE), "id", True),
        ((750*SCALE, 1150*SCALE), "new_status", False),
        ((860*SCALE, 1140*SCALE), "note", False),
    ]
    for p, n, pk in log_attrs: draw_attr_line(pos_log, p)

    chat_attrs = [
        ((1550*SCALE, 590*SCALE), "id", True),
        ((1560*SCALE, 650*SCALE), "top_intent", False),
        ((1550*SCALE, 710*SCALE), "confidence", False),
    ]
    for p, n, pk in chat_attrs: draw_attr_line(pos_chat, p)

    price_attr = ((210*SCALE, 630*SCALE), "price_ghs", False)
    draw_attr_line(dia_price, price_attr[0])

    # Draw Ovals
    all_attrs = user_attrs + order_attrs + sand_attrs + truck_attrs + zone_attrs + issue_attrs + log_attrs + chat_attrs + [price_attr]
    for (cx, cy), name, is_pk in all_attrs:
        rx = (44 if len(name) > 6 else 36) * SCALE
        ry = 17 * SCALE
        fill = (255, 251, 235) if is_pk else (255, 255, 255)
        stroke = PRIMARY if is_pk else BORDER_GRAY
        draw.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=fill, outline=stroke, width=2*SCALE)
        font = F_SMALL_BOLD if is_pk else F_SMALL
        text_fill = PRIMARY if is_pk else TEXT_DARK
        bbox = draw.textbbox((0, 0), name, font=font)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        draw.text((cx - tw // 2, cy - th // 2 - 1*SCALE), name, font=font, fill=text_fill)
        if is_pk:
            # underline
            draw.line([(cx - tw // 2, cy + th // 2 + 2*SCALE), (cx + tw // 2, cy + th // 2 + 2*SCALE)], fill=PRIMARY, width=2*SCALE)

    # Draw Diamonds (Relationships)
    def draw_diamond(cx, cy, text, subtext="", identifying=False):
        rw, rh = 68 * SCALE, 36 * SCALE
        pts = [(cx, cy - rh), (cx + rw, cy), (cx, cy + rh), (cx - rw, cy)]
        draw.polygon(pts, fill=SECONDARY_LIGHT, outline=SECONDARY, width=2*SCALE)
        if identifying:
            rw2, rh2 = rw - 6*SCALE, rh - 5*SCALE
            pts2 = [(cx, cy - rh2), (cx + rw2, cy), (cx, cy + rh2), (cx - rw2, cy)]
            draw.polygon(pts2, fill=None, outline=SECONDARY, width=2*SCALE)
        
        bbox = draw.textbbox((0, 0), text, font=F_BODY_BOLD)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        y_offset = -th//2 - (4*SCALE if subtext else 0)
        draw.text((cx - tw // 2, cy + y_offset), text, font=F_BODY_BOLD, fill=PRIMARY_DARK)
        if subtext:
            bbox2 = draw.textbbox((0, 0), f"({subtext})", font=F_SMALL)
            tw2 = bbox2[2] - bbox2[0]
            draw.text((cx - tw2 // 2, cy + 8*SCALE), f"({subtext})", font=F_SMALL, fill=PRIMARY_DARK)

    draw_diamond(dia_places[0], dia_places[1], "Places")
    draw_diamond(dia_assign[0], dia_assign[1], "Assigned", "operator")
    draw_diamond(dia_sand[0], dia_sand[1], "Includes")
    draw_diamond(dia_truck[0], dia_truck[1], "Uses")
    draw_diamond(dia_price[0], dia_price[1], "Priced At", "M:N matrix")
    draw_diamond(dia_log[0], dia_log[1], "Has Log", identifying=True)
    draw_diamond(dia_change[0], dia_change[1], "Changes", "changed_by")
    draw_diamond(dia_report[0], dia_report[1], "Reports")
    draw_diamond(dia_concern[0], dia_concern[1], "Concerns", "order_id")
    draw_diamond(dia_zone[0], dia_zone[1], "Covers", "zone")
    draw_diamond(dia_chat[0], dia_chat[1], "Initiates", "chat")

    # Draw Entity Rectangles
    def draw_entity(cx, cy, name, sub="", weak=False):
        rw, rh = 85 * SCALE, 34 * SCALE
        x1, y1 = cx - rw, cy - rh
        x2, y2 = cx + rw, cy + rh
        fill = (249, 250, 251) if weak else PRIMARY_LIGHT
        stroke = WEAK_GRAY if weak else PRIMARY
        draw.rounded_rectangle([x1, y1, x2, y2], radius=4*SCALE, fill=fill, outline=stroke, width=2*SCALE)
        if weak:
            draw.rounded_rectangle([x1+4*SCALE, y1+4*SCALE, x2-4*SCALE, y2-4*SCALE], radius=2*SCALE, fill=None, outline=stroke, width=2*SCALE)
        
        bbox = draw.textbbox((0, 0), name, font=F_HEADER)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        y_text = cy - th//2 - (5*SCALE if sub else 0)
        draw.text((cx - tw // 2, y_text), name, font=F_HEADER, fill=TEXT_DARK)
        if sub:
            bbox2 = draw.textbbox((0, 0), sub, font=F_SMALL)
            tw2 = bbox2[2] - bbox2[0]
            draw.text((cx - tw2 // 2, cy + 8*SCALE), sub, font=F_SMALL, fill=TEXT_MUTED)

    draw_entity(pos_user[0], pos_user[1], "USERS", "Clients, Operators, Admins")
    draw_entity(pos_order[0], pos_order[1], "ORDERS", "Booking Records")
    draw_entity(pos_sand[0], pos_sand[1], "SAND_TYPES", "Material Catalogue")
    draw_entity(pos_truck[0], pos_truck[1], "TRUCK_TYPES", "Fleet Vehicles")
    draw_entity(pos_zone[0], pos_zone[1], "DELIVERY_ZONES", "Service Regions")
    draw_entity(pos_issue[0], pos_issue[1], "ISSUES", "User Complaints")
    draw_entity(pos_log[0], pos_log[1], "ORDER_STATUS_LOG", "Audit Trail", weak=True)
    draw_entity(pos_chat[0], pos_chat[1], "CHATBOT_LOGS", "Unmatched Queries")

    # Cardinalities
    draw.text((1240*SCALE, 385*SCALE), "1", font=F_CARDINALITY, fill=SECONDARY)
    draw.text((860*SCALE, 590*SCALE), "N", font=F_CARDINALITY, fill=SECONDARY)

    draw.text((1200*SCALE, 450*SCALE), "1 (0..1)", font=F_CARDINALITY, fill=SECONDARY)
    draw.text((870*SCALE, 615*SCALE), "N", font=F_CARDINALITY, fill=SECONDARY)

    draw.text((430*SCALE, 385*SCALE), "1", font=F_CARDINALITY, fill=SECONDARY)
    draw.text((690*SCALE, 590*SCALE), "N", font=F_CARDINALITY, fill=SECONDARY)

    draw.text((430*SCALE, 875*SCALE), "1", font=F_CARDINALITY, fill=SECONDARY)
    draw.text((690*SCALE, 670*SCALE), "N", font=F_CARDINALITY, fill=SECONDARY)

    draw.text((355*SCALE, 430*SCALE), "M", font=F_CARDINALITY, fill=SECONDARY)
    draw.text((355*SCALE, 830*SCALE), "N", font=F_CARDINALITY, fill=SECONDARY)

    draw.text((795*SCALE, 710*SCALE), "1", font=F_CARDINALITY, fill=SECONDARY)
    draw.text((795*SCALE, 950*SCALE), "N", font=F_CARDINALITY, fill=SECONDARY)

    draw.text((1220*SCALE, 550*SCALE), "1 (0..1)", font=F_CARDINALITY, fill=SECONDARY)
    draw.text((870*SCALE, 980*SCALE), "N", font=F_CARDINALITY, fill=SECONDARY)

    draw.text((1335*SCALE, 430*SCALE), "1", font=F_CARDINALITY, fill=SECONDARY)
    draw.text((1335*SCALE, 830*SCALE), "N", font=F_CARDINALITY, fill=SECONDARY)

    draw.text((870*SCALE, 690*SCALE), "1 (0..1)", font=F_CARDINALITY, fill=SECONDARY)
    draw.text((1230*SCALE, 875*SCALE), "N", font=F_CARDINALITY, fill=SECONDARY)

    draw.text((795*SCALE, 310*SCALE), "1", font=F_CARDINALITY, fill=SECONDARY)
    draw.text((795*SCALE, 530*SCALE), "N", font=F_CARDINALITY, fill=SECONDARY)

    draw.text((1380*SCALE, 390*SCALE), "1 (0..1)", font=F_CARDINALITY, fill=SECONDARY)
    draw.text((1435*SCALE, 560*SCALE), "N", font=F_CARDINALITY, fill=SECONDARY)

    # Save
    img.save(out_path, quality=95)
    print(f"Rendered Chen ERD -> {out_path}")

# -------------------------------------------------------------
# 2. RENDER CROW'S FOOT RELATIONAL SCHEMA ERD
# -------------------------------------------------------------
def render_crows_foot_erd(out_path: Path):
    W, H = 1750, 1250
    img = Image.new("RGB", (W * SCALE, H * SCALE), BG)
    draw = ImageDraw.Draw(img)

    # Title Banner
    bx1, by1, bx2, by2 = 50 * SCALE, 30 * SCALE, (W - 50) * SCALE, 115 * SCALE
    draw.rounded_rectangle([bx1, by1, bx2, by2], radius=8*SCALE, fill=CARD_BG, outline=PRIMARY, width=2*SCALE)
    draw.text((75 * SCALE, 46 * SCALE), "Figure 3.5b: Physical Relational Database Schema (Crow's Foot Notation)", font=F_TITLE, fill=PRIMARY)
    draw.text((75 * SCALE, 82 * SCALE), "MySQL 8 database tables with primary keys (PK), foreign keys (FK), unique constraints (UK), and accurate cardinalities", font=F_SUBTITLE, fill=TEXT_MUTED)

    # Entity Table Definition: (x, y, w, title, rows: [(type, name, key, note)])
    tables = {
        "USERS": (1320, 180, 360, "USERS", [
            ("bigint", "id", "PK", ""),
            ("string", "name", "", ""),
            ("string", "email", "UK", ""),
            ("string", "password", "", "nullable"),
            ("string", "phone", "", "nullable"),
            ("string", "role", "", ""),
            ("string", "provider", "", "nullable"),
            ("string", "provider_id", "", "nullable"),
        ]),
        "SAND_TYPES": (340, 180, 300, "SAND_TYPES", [
            ("bigint", "id", "PK", ""),
            ("string", "name", "", ""),
            ("string", "slug", "UK", ""),
            ("string", "description", "", ""),
            ("string", "icon", "", "nullable"),
            ("string", "image", "", "nullable"),
            ("boolean", "is_active", "", ""),
            ("int", "sort_order", "", ""),
        ]),
        "TRUCK_TYPES": (60, 200, 310, "TRUCK_TYPES", [
            ("bigint", "id", "PK", ""),
            ("string", "name", "", ""),
            ("string", "slug", "UK", ""),
            ("string", "capacity_label", "", ""),
            ("decimal", "capacity_tonnes_min", "", ""),
            ("decimal", "capacity_tonnes_max", "", "nullable"),
            ("decimal", "price_ghs", "", "deprecated"),
            ("boolean", "is_popular", "", ""),
            ("boolean", "is_active", "", ""),
            ("int", "sort_order", "", ""),
        ]),
        "DELIVERY_ZONES": (690, 180, 270, "DELIVERY_ZONES", [
            ("bigint", "id", "PK", ""),
            ("string", "region", "UK", ""),
            ("decimal", "surcharge_ghs", "", ""),
            ("boolean", "is_active", "", ""),
        ]),
        "SAND_TRUCK_PRICES": (180, 600, 310, "SAND_TRUCK_PRICES", [
            ("bigint", "id", "PK", ""),
            ("bigint", "sand_type_id", "FK", "RESTRICT"),
            ("bigint", "truck_type_id", "FK", "RESTRICT"),
            ("decimal", "price_ghs", "", "matrix base"),
        ]),
        "ORDERS": (690, 520, 340, "ORDERS", [
            ("bigint", "id", "PK", ""),
            ("string", "order_ref", "UK", ""),
            ("bigint", "user_id", "FK", "RESTRICT"),
            ("bigint", "sand_type_id", "FK", "RESTRICT"),
            ("bigint", "truck_type_id", "FK", "RESTRICT"),
            ("bigint", "assigned_operator_id", "FK", "nullable"),
            ("decimal", "price_ghs", "", "snapshotted"),
            ("decimal", "delivery_fee_ghs", "", "snapshotted"),
            ("decimal", "total_ghs", "", "snapshotted"),
            ("string", "region", "", "zone match"),
            ("string", "payment_method", "", ""),
            ("string", "payment_status", "", ""),
            ("string", "status", "", ""),
        ]),
        "ORDER_STATUS_LOG": (690, 970, 340, "ORDER_STATUS_LOG", [
            ("bigint", "id", "PK", ""),
            ("bigint", "order_id", "FK", "CASCADE"),
            ("string", "old_status", "", "nullable"),
            ("string", "new_status", "", ""),
            ("bigint", "changed_by", "FK", "nullable"),
            ("string", "note", "", "nullable"),
        ]),
        "ISSUES": (1320, 720, 330, "ISSUES", [
            ("bigint", "id", "PK", ""),
            ("bigint", "user_id", "FK", "CASCADE"),
            ("bigint", "order_id", "FK", "nullable"),
            ("string", "issue_type", "", ""),
            ("text", "description", "", ""),
            ("string", "status", "", ""),
            ("text", "admin_response", "", "nullable"),
        ]),
        "CHATBOT_UNMATCHED_LOGS": (1320, 480, 330, "CHATBOT_UNMATCHED_LOGS", [
            ("bigint", "id", "PK", ""),
            ("bigint", "user_id", "FK", "nullable"),
            ("text", "message", "", ""),
            ("string", "top_intent", "", "nullable"),
            ("decimal", "confidence", "", "nullable"),
        ]),
    }

    # Draw table function
    def draw_table_box(x, y, w, title, rows):
        row_h = 24 * SCALE
        header_h = 32 * SCALE
        h = header_h + len(rows) * row_h
        rx1, ry1, rx2, ry2 = x * SCALE, y * SCALE, (x + w) * SCALE, (y * SCALE + h)
        
        # Outer box
        draw.rounded_rectangle([rx1, ry1, rx2, ry2], radius=4*SCALE, fill=CARD_BG, outline=PRIMARY, width=2*SCALE)
        # Header box
        draw.rounded_rectangle([rx1, ry1, rx2, ry1 + header_h], radius=4*SCALE, fill=PRIMARY_LIGHT, outline=PRIMARY, width=2*SCALE)
        draw.rectangle([rx1, ry1 + header_h - 4*SCALE, rx2, ry1 + header_h], fill=PRIMARY_LIGHT)
        draw.line([(rx1, ry1 + header_h), (rx2, ry1 + header_h)], fill=PRIMARY, width=2*SCALE)
        
        # Header text
        bbox = draw.textbbox((0, 0), title, font=F_HEADER)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        draw.text((rx1 + ((rx2 - rx1) - tw)//2, ry1 + (header_h - th)//2 - 1*SCALE), title, font=F_HEADER, fill=TEXT_DARK)

        # Rows
        curr_y = ry1 + header_h
        for i, (col_type, col_name, col_key, col_note) in enumerate(rows):
            row_bg = ROW_EVEN if i % 2 == 0 else ROW_ODD
            draw.rectangle([rx1 + 1*SCALE, curr_y, rx2 - 1*SCALE, curr_y + row_h], fill=row_bg)
            
            # Type
            draw.text((rx1 + 12*SCALE, curr_y + 4*SCALE), col_type, font=F_BODY, fill=TEXT_MUTED)
            # Name
            draw.text((rx1 + 80*SCALE, curr_y + 4*SCALE), col_name, font=F_BODY_BOLD if col_key else F_BODY, fill=PRIMARY_DARK if col_key else TEXT_DARK)
            # Key
            if col_key:
                k_fill = PRIMARY if col_key == "PK" else (SECONDARY if col_key == "FK" else WEAK_GRAY)
                draw.text((rx2 - 120*SCALE, curr_y + 4*SCALE), col_key, font=F_SMALL_BOLD, fill=k_fill)
            # Note
            if col_note:
                draw.text((rx2 - 80*SCALE, curr_y + 4*SCALE), col_note, font=F_SMALL, fill=TEXT_MUTED)

            curr_y += row_h

    # Draw all tables
    for key, (x, y, w, title, rows) in tables.items():
        draw_table_box(x, y, w, title, rows)

    # Crow's Foot Connector Lines with symbols
    def draw_crows_foot_connector(p1, p2, p1_sym="||", p2_sym="o{", label="", dashed=False):
        # Draw path
        if dashed:
            x1, y1 = p1
            x2, y2 = p2
            dist = ((x2 - x1)**2 + (y2 - y1)**2)**0.5
            steps = int(dist // (10 * SCALE))
            for s in range(0, steps, 2):
                t1 = s / steps
                t2 = min((s + 1) / steps, 1.0)
                draw.line([(x1 + (x2 - x1)*t1, y1 + (y2 - y1)*t1),
                           (x1 + (x2 - x1)*t2, y1 + (y2 - y1)*t2)], fill=LINE_GRAY, width=2*SCALE)
        else:
            draw.line([p1, p2], fill=LINE_GRAY, width=2*SCALE)

        # Draw label if present
        if label:
            mx = (p1[0] + p2[0]) // 2
            my = (p1[1] + p2[1]) // 2
            bbox = draw.textbbox((0, 0), label, font=F_SMALL_BOLD)
            lw = bbox[2] - bbox[0] + 12*SCALE
            lh = bbox[3] - bbox[1] + 8*SCALE
            draw.rounded_rectangle([mx - lw//2, my - lh//2, mx + lw//2, my + lh//2], radius=3*SCALE, fill=CARD_BG, outline=BORDER_GRAY, width=1*SCALE)
            draw.text((mx - (lw-12*SCALE)//2, my - (lh-8*SCALE)//2), label, font=F_SMALL_BOLD, fill=TEXT_DARK)

    # 1. USERS to ORDERS (places: user_id RESTRICT) -> Mandatory 1 to Many
    p_u1 = (1320 * SCALE, 300 * SCALE)
    p_o1 = (1030 * SCALE, 560 * SCALE)
    draw_crows_foot_connector(p_u1, p_o1, p1_sym="||", p2_sym="o{", label="places (user_id RESTRICT)")

    # 2. USERS to ORDERS (assigned operator: SET NULL) -> Optional 0..1 to Many
    p_u2 = (1320 * SCALE, 360 * SCALE)
    p_o2 = (1030 * SCALE, 620 * SCALE)
    draw_crows_foot_connector(p_u2, p_o2, p1_sym="|o", p2_sym="o{", label="assigned operator (SET NULL)")

    # 3. SAND_TYPES to ORDERS (sand_type_id RESTRICT)
    p_s1 = (490 * SCALE, 380 * SCALE)
    p_o3 = (690 * SCALE, 580 * SCALE)
    draw_crows_foot_connector(p_s1, p_o3, p1_sym="||", p2_sym="o{", label="sand_type_id RESTRICT")

    # 4. TRUCK_TYPES to ORDERS (truck_type_id RESTRICT)
    p_t1 = (370 * SCALE, 440 * SCALE)
    p_o4 = (690 * SCALE, 640 * SCALE)
    draw_crows_foot_connector(p_t1, p_o4, p1_sym="||", p2_sym="o{", label="truck_type_id RESTRICT")

    # 5. SAND_TYPES to SAND_TRUCK_PRICES
    p_s2 = (340 * SCALE, 400 * SCALE)
    p_sp1 = (300 * SCALE, 600 * SCALE)
    draw_crows_foot_connector(p_s2, p_sp1, p1_sym="||", p2_sym="o{", label="sand_type_id RESTRICT")

    # 6. TRUCK_TYPES to SAND_TRUCK_PRICES
    p_t2 = (220 * SCALE, 450 * SCALE)
    p_sp2 = (220 * SCALE, 600 * SCALE)
    draw_crows_foot_connector(p_t2, p_sp2, p1_sym="||", p2_sym="o{", label="truck_type_id RESTRICT")

    # 7. ORDERS to ORDER_STATUS_LOG (order_id CASCADE)
    p_o5 = (860 * SCALE, 870 * SCALE)
    p_log1 = (860 * SCALE, 970 * SCALE)
    draw_crows_foot_connector(p_o5, p_log1, p1_sym="||", p2_sym="o{", label="order_id CASCADE")

    # 8. USERS to ORDER_STATUS_LOG (changed_by SET NULL) -> Optional 0..1 to Many
    p_u3 = (1320 * SCALE, 420 * SCALE)
    p_log2 = (1030 * SCALE, 1020 * SCALE)
    draw_crows_foot_connector(p_u3, p_log2, p1_sym="|o", p2_sym="o{", label="changed_by (SET NULL)")

    # 9. USERS to ISSUES (user_id CASCADE)
    p_u4 = (1480 * SCALE, 400 * SCALE)
    p_iss1 = (1480 * SCALE, 720 * SCALE)
    draw_crows_foot_connector(p_u4, p_iss1, p1_sym="||", p2_sym="o{", label="user_id CASCADE")

    # 10. ORDERS to ISSUES (order_id SET NULL) -> Optional 0..1 to Many
    p_o6 = (1030 * SCALE, 720 * SCALE)
    p_iss2 = (1320 * SCALE, 800 * SCALE)
    draw_crows_foot_connector(p_o6, p_iss2, p1_sym="|o", p2_sym="o{", label="order_id (SET NULL)")

    # 11. USERS to CHATBOT_UNMATCHED_LOGS (user_id CASCADE) -> Optional 0..1 to Many
    p_u5 = (1420 * SCALE, 400 * SCALE)
    p_chat = (1420 * SCALE, 480 * SCALE)
    draw_crows_foot_connector(p_u5, p_chat, p1_sym="|o", p2_sym="o{", label="user_id (0..1 CASCADE)")

    # 12. DELIVERY_ZONES to ORDERS (region match, no FK) -> Dashed 1 to N
    p_z1 = (820 * SCALE, 300 * SCALE)
    p_o7 = (820 * SCALE, 520 * SCALE)
    draw_crows_foot_connector(p_z1, p_o7, p1_sym="||", p2_sym="o{", label="region matched at create (no FK)", dashed=True)

    # Save
    img.save(out_path, quality=95)
    print(f"Rendered Crow's Foot ERD -> {out_path}")

if __name__ == "__main__":
    render_chen_erd(DOCS / "erd_chen.png")
    render_crows_foot_erd(DOCS / "erd_crows_foot.png")
    # Also update docs/erd.png and docs/erd.jpg
    render_crows_foot_erd(DOCS / "erd.png")
    render_crows_foot_erd(DOCS / "erd.jpg")
    print("All image assets generated successfully!")
