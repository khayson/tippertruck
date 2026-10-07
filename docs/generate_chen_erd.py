"""
Script to generate Peter Chen notation ERD in SVG format for Tipper Truck App.
Entities: Rectangles
Weak Entities: Double Rectangles
Relationships: Diamonds
Identifying Relationships: Double Diamonds
Attributes: Ovals (Primary keys underlined)
Cardinalities: 1, M, N labeled on connector lines.
"""

from pathlib import Path

OUT_FILE = Path("docs/erd_chen_notation.svg")

def generate_chen_svg():
    svg_parts = []
    
    # SVG Header
    svg_parts.append('''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1700 1250" width="100%" height="100%" style="background:#FAF8F5; font-family:'Segoe UI', Arial, sans-serif;">
  <defs>
    <filter id="shadow" x="-8%" y="-8%" width="116%" height="116%">
      <feDropShadow dx="2" dy="3" stdDeviation="3" flood-color="#000000" flood-opacity="0.08"/>
    </filter>
  </defs>

  <!-- Title Header -->
  <rect x="50" y="30" width="1600" height="85" rx="8" fill="#FFFFFF" stroke="#D45A12" stroke-width="1.5" filter="url(#shadow)"/>
  <text x="80" y="66" font-size="22" font-weight="bold" fill="#D45A12">Tipper Truck App — Conceptual Entity-Relationship Diagram (Peter Chen Notation)</text>
  <text x="80" y="94" font-size="14" fill="#6B655C">Demonstrating different geometric shapes: Rectangles (Entities), Diamonds (Relationships), and Ovals (Attributes)</text>

  <!-- Legend -->
  <g transform="translate(1080, 42)">
    <!-- Entity -->
    <rect x="0" y="5" width="75" height="28" rx="3" fill="#FFF7ED" stroke="#D45A12" stroke-width="2"/>
    <text x="37" y="23" font-size="11" font-weight="bold" fill="#191713" text-anchor="middle">Entity</text>
    
    <!-- Relationship -->
    <polygon points="120,5 145,19 120,33 95,19" fill="#FEF3C7" stroke="#D97706" stroke-width="2"/>
    <text x="120" y="23" font-size="10" font-weight="bold" fill="#78350F" text-anchor="middle">Relation</text>

    <!-- Attribute -->
    <ellipse cx="185" cy="19" rx="30" ry="14" fill="#FFFFFF" stroke="#6B655C" stroke-width="1.5"/>
    <text x="185" y="23" font-size="10" fill="#191713" text-anchor="middle">Attribute</text>

    <!-- Key Attribute -->
    <ellipse cx="255" cy="19" rx="30" ry="14" fill="#FFFFFF" stroke="#6B655C" stroke-width="1.5"/>
    <text x="255" y="23" font-size="10" font-weight="bold" text-decoration="underline" fill="#D45A12" text-anchor="middle"><u>PK Key</u></text>

    <!-- Weak Entity -->
    <rect x="300" y="5" width="80" height="28" rx="3" fill="#F3F4F6" stroke="#4B5563" stroke-width="1"/>
    <rect x="303" y="8" width="74" height="22" rx="2" fill="none" stroke="#4B5563" stroke-width="1.8"/>
    <text x="340" y="23" font-size="10" font-weight="bold" fill="#374151" text-anchor="middle">Weak Ent.</text>

    <!-- Identifying Rel -->
    <polygon points="415,3 442,19 415,35 388,19" fill="#FEF3C7" stroke="#D97706" stroke-width="1"/>
    <polygon points="415,6 438,19 415,32 392,19" fill="none" stroke="#D97706" stroke-width="1.8"/>
    <text x="415" y="23" font-size="9" font-weight="bold" fill="#78350F" text-anchor="middle">Ident. Rel</text>
  </g>
''')

    # Lines layer (Background)
    svg_parts.append('  <!-- ================= RELATIONSHIP CONNECTOR LINES ================= -->\n  <g stroke="#6B655C" stroke-width="1.8">\n')

    def add_line(x1, y1, x2, y2, dashed=False):
        dash = ' stroke-dasharray="6,4"' if dashed else ''
        svg_parts.append(f'    <line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}"{dash}/>\n')

    # Positions of core elements
    # USERS: (1300, 320)
    # ORDERS: (750, 620)
    # SAND_TYPES: (320, 320)
    # TRUCK_TYPES: (320, 920)
    # ISSUES: (1300, 920)
    # ORDER_STATUS_LOG: (750, 1020)
    # DELIVERY_ZONES: (750, 220)
    # CHATBOT_UNMATCHED_LOGS: (1400, 620)

    # Relationships:
    # 1. USER - Places - ORDER
    # User (1300, 320) -> Diamond Places (1025, 470) -> Order (750, 620)
    add_line(1300, 320, 1025, 470)
    add_line(1025, 470, 750, 620)

    # 2. USER - Assigned As Operator - ORDER
    # User (1300, 320) -> Diamond Assigned (980, 560) -> Order (750, 620)
    add_line(1300, 320, 980, 560)
    add_line(980, 560, 750, 620)

    # 3. SAND_TYPES - Includes Sand - ORDERS
    # Sand (320, 320) -> Diamond SandOrder (535, 470) -> Order (750, 620)
    add_line(320, 320, 535, 470)
    add_line(535, 470, 750, 620)

    # 4. TRUCK_TYPES - Uses Truck - ORDERS
    # Truck (320, 920) -> Diamond TruckOrder (535, 770) -> Order (750, 620)
    add_line(320, 920, 535, 770)
    add_line(535, 770, 750, 620)

    # 5. SAND_TYPES - Priced At - TRUCK_TYPES (Associative M:N)
    # Sand (320, 320) -> Diamond PricedAt (320, 620) -> Truck (320, 920)
    add_line(320, 320, 320, 620)
    add_line(320, 620, 320, 920)

    # 6. ORDERS - Has Status Log - ORDER_STATUS_LOG (Identifying)
    # Double lines for identifying relationship in Chen notation
    # Order (750, 620) -> Diamond HasStatusLog (750, 820) -> OrderStatusLog (750, 1020)
    add_line(748, 620, 748, 820)
    add_line(752, 620, 752, 820)
    add_line(748, 820, 748, 1020)
    add_line(752, 820, 752, 1020)

    # 7. USERS - Changed By - ORDER_STATUS_LOG
    # User (1300, 320) -> Diamond ChangedBy (1050, 870) -> OrderStatusLog (750, 1020)
    add_line(1300, 320, 1050, 870)
    add_line(1050, 870, 750, 1020)

    # 8. USERS - Reports - ISSUES
    # User (1300, 320) -> Diamond Reports (1300, 620) -> Issue (1300, 920)
    add_line(1300, 320, 1300, 620)
    add_line(1300, 620, 1300, 920)

    # 9. ORDERS - Concerns - ISSUES
    # Order (750, 620) -> Diamond Concerns (1025, 770) -> Issue (1300, 920)
    add_line(750, 620, 1025, 770)
    add_line(1025, 770, 1300, 920)

    # 10. DELIVERY_ZONES - Covers - ORDERS
    # DeliveryZone (750, 220) -> Diamond Covers (750, 420) -> Order (750, 620)
    add_line(750, 220, 750, 420, dashed=True)
    add_line(750, 420, 750, 620, dashed=True)

    # 11. USERS - Initiates - CHATBOT_UNMATCHED_LOGS
    # User (1300, 320) -> Diamond Initiates (1400, 470) -> ChatbotLog (1400, 620)
    add_line(1300, 320, 1400, 470)
    add_line(1400, 470, 1400, 620)

    svg_parts.append('  </g>\n\n')

    # Cardinality Labels
    svg_parts.append('  <!-- ================= CARDINALITY LABELS ================= -->\n  <g font-size="14" font-weight="bold" fill="#B45309">\n')
    # USERS 1 --- M ORDERS (Places)
    svg_parts.append('    <text x="1220" y="375">1</text>\n')
    svg_parts.append('    <text x="830" y="580">N</text>\n')

    # USERS 1 --- M ORDERS (Operator)
    svg_parts.append('    <text x="1190" y="440">1 (0..1)</text>\n')
    svg_parts.append('    <text x="840" y="605">N</text>\n')

    # SAND_TYPES 1 --- M ORDERS
    svg_parts.append('    <text x="400" y="375">1</text>\n')
    svg_parts.append('    <text x="670" y="580">N</text>\n')

    # TRUCK_TYPES 1 --- M ORDERS
    svg_parts.append('    <text x="400" y="865">1</text>\n')
    svg_parts.append('    <text x="670" y="660">N</text>\n')

    # SAND_TYPES M --- N TRUCK_TYPES (Priced At)
    svg_parts.append('    <text x="335" y="420">M</text>\n')
    svg_parts.append('    <text x="335" y="820">N</text>\n')

    # ORDERS 1 === N ORDER_STATUS_LOG
    svg_parts.append('    <text x="765" y="700">1</text>\n')
    svg_parts.append('    <text x="765" y="940">N</text>\n')

    # USERS 1 --- N ORDER_STATUS_LOG (Changed By)
    svg_parts.append('    <text x="1200" y="540">1 (0..1)</text>\n')
    svg_parts.append('    <text x="840" y="970">N</text>\n')

    # USERS 1 --- N ISSUES
    svg_parts.append('    <text x="1315" y="420">1</text>\n')
    svg_parts.append('    <text x="1315" y="820">N</text>\n')

    # ORDERS 1 --- N ISSUES (Concerns)
    svg_parts.append('    <text x="840" y="680">1 (0..1)</text>\n')
    svg_parts.append('    <text x="1210" y="865">N</text>\n')

    # DELIVERY_ZONES 1 --- N ORDERS (Covers)
    svg_parts.append('    <text x="765" y="310">1</text>\n')
    svg_parts.append('    <text x="765" y="530">N</text>\n')

    # USERS 1 --- N CHATBOT_LOGS
    svg_parts.append('    <text x="1360" y="380">1 (0..1)</text>\n')
    svg_parts.append('    <text x="1415" y="550">N</text>\n')
    svg_parts.append('  </g>\n\n')

    # Attribute Lines
    svg_parts.append('  <!-- ================= ATTRIBUTE CONNECTOR LINES ================= -->\n  <g stroke="#9CA3AF" stroke-width="1.2">\n')
    
    def add_attr(parent_x, parent_y, attr_x, attr_y, name, is_pk=False):
        svg_parts.append(f'    <line x1="{parent_x}" y1="{parent_y}" x2="{attr_x}" y2="{attr_y}"/>\n')

    # Attributes for USERS (1300, 320)
    user_attrs = [
        (1160, 210, "id", True),
        (1270, 190, "name", False),
        (1380, 190, "email", False),
        (1490, 210, "role", False),
        (1510, 280, "phone", False),
        (1510, 350, "provider", False),
    ]
    for x, y, name, is_pk in user_attrs:
        add_attr(1300, 320, x, y, name, is_pk)

    # Attributes for ORDERS (750, 620)
    order_attrs = [
        (610, 520, "id", True),
        (600, 620, "order_ref", False),
        (610, 720, "price_ghs", False),
        (890, 520, "total_ghs", False),
        (900, 620, "status", False),
        (890, 720, "region", False),
    ]
    for x, y, name, is_pk in order_attrs:
        add_attr(750, 620, x, y, name, is_pk)

    # Attributes for SAND_TYPES (320, 320)
    sand_attrs = [
        (190, 230, "id", True),
        (300, 210, "name", False),
        (410, 210, "slug", False),
        (180, 310, "is_active", False),
        (180, 370, "sort_order", False),
    ]
    for x, y, name, is_pk in sand_attrs:
        add_attr(320, 320, x, y, name, is_pk)

    # Attributes for TRUCK_TYPES (320, 920)
    truck_attrs = [
        (180, 870, "id", True),
        (180, 930, "name", False),
        (180, 990, "capacity", False),
        (290, 1030, "min_tonnes", False),
        (400, 1030, "is_popular", False),
    ]
    for x, y, name, is_pk in truck_attrs:
        add_attr(320, 920, x, y, name, is_pk)

    # Attributes for DELIVERY_ZONES (750, 220)
    zone_attrs = [
        (620, 150, "id", True),
        (750, 140, "region", False),
        (880, 150, "surcharge", False),
    ]
    for x, y, name, is_pk in zone_attrs:
        add_attr(750, 220, x, y, name, is_pk)

    # Attributes for ISSUES (1300, 920)
    issue_attrs = [
        (1170, 990, "id", True),
        (1280, 1020, "issue_type", False),
        (1390, 1020, "status", False),
        (1480, 960, "admin_reply", False),
    ]
    for x, y, name, is_pk in issue_attrs:
        add_attr(1300, 920, x, y, name, is_pk)

    # Attributes for ORDER_STATUS_LOG (750, 1020)
    log_attrs = [
        (620, 1110, "id", True),
        (730, 1130, "new_status", False),
        (840, 1120, "note", False),
    ]
    for x, y, name, is_pk in log_attrs:
        add_attr(750, 1020, x, y, name, is_pk)

    # Attributes for CHATBOT_UNMATCHED_LOGS (1400, 620)
    chat_attrs = [
        (1530, 580, "id", True),
        (1540, 640, "top_intent", False),
        (1530, 700, "confidence", False),
    ]
    for x, y, name, is_pk in chat_attrs:
        add_attr(1400, 620, x, y, name, is_pk)

    # Attribute on M:N Relationship Diamond "Priced At" (320, 620)
    # price_ghs is an attribute of the relationship in Chen notation!
    add_attr(320, 620, 200, 620, "price_ghs", False)

    svg_parts.append('  </g>\n\n')

    # Attributes (Ovals)
    svg_parts.append('  <!-- ================= ATTRIBUTE OVALS ================= -->\n  <g filter="url(#shadow)">\n')
    
    def draw_oval(cx, cy, label, is_pk=False):
        fill = "#FFFBEB" if is_pk else "#FFFFFF"
        stroke = "#D45A12" if is_pk else "#6B7280"
        width = 42 if len(label) > 6 else 34
        svg_parts.append(f'    <ellipse cx="{cx}" cy="{cy}" rx="{width}" ry="16" fill="{fill}" stroke="{stroke}" stroke-width="1.5"/>\n')
        if is_pk:
            svg_parts.append(f'    <text x="{cx}" y="{cy+4}" font-size="11" font-weight="bold" text-decoration="underline" fill="#D45A12" text-anchor="middle">{label}</text>\n')
        else:
            svg_parts.append(f'    <text x="{cx}" y="{cy+4}" font-size="11" fill="#374151" text-anchor="middle">{label}</text>\n')

    all_attrs = (
        user_attrs + order_attrs + sand_attrs + truck_attrs +
        zone_attrs + issue_attrs + log_attrs + chat_attrs +
        [(200, 620, "price_ghs", False)]
    )
    for x, y, label, is_pk in all_attrs:
        draw_oval(x, y, label, is_pk)

    svg_parts.append('  </g>\n\n')

    # Relationships (Diamonds)
    svg_parts.append('  <!-- ================= RELATIONSHIP DIAMONDS ================= -->\n  <g filter="url(#shadow)">\n')
    
    def draw_diamond(cx, cy, label, is_identifying=False, sublabel=None):
        w, h = 65, 34
        pts = f"{cx},{cy-h} {cx+w},{cy} {cx},{cy+h} {cx-w},{cy}"
        svg_parts.append(f'    <polygon points="{pts}" fill="#FEF3C7" stroke="#D97706" stroke-width="2"/>\n')
        if is_identifying:
            w2, h2 = w - 6, h - 5
            pts2 = f"{cx},{cy-h2} {cx+w2},{cy} {cx},{cy+h2} {cx-w2},{cy}"
            svg_parts.append(f'    <polygon points="{pts2}" fill="none" stroke="#D97706" stroke-width="1.8"/>\n')
        
        y_text = cy + (1 if sublabel else 4)
        svg_parts.append(f'    <text x="{cx}" y="{y_text}" font-size="11" font-weight="bold" fill="#78350F" text-anchor="middle">{label}</text>\n')
        if sublabel:
            svg_parts.append(f'    <text x="{cx}" y="{cy+14}" font-size="9" fill="#92400E" text-anchor="middle">({sublabel})</text>\n')

    draw_diamond(1025, 470, "Places")
    draw_diamond(980, 560, "Assigned", sublabel="operator")
    draw_diamond(535, 470, "Includes")
    draw_diamond(535, 770, "Uses")
    draw_diamond(320, 620, "Priced At", sublabel="M:N matrix")
    draw_diamond(750, 820, "Has Log", is_identifying=True)
    draw_diamond(1050, 870, "Changes", sublabel="changed_by")
    draw_diamond(1300, 620, "Reports")
    draw_diamond(1025, 770, "Concerns", sublabel="order_id")
    draw_diamond(750, 420, "Covers", sublabel="zone")
    draw_diamond(1400, 470, "Initiates", sublabel="chat")

    svg_parts.append('  </g>\n\n')

    # Entities (Rectangles)
    svg_parts.append('  <!-- ================= ENTITY RECTANGLES ================= -->\n  <g filter="url(#shadow)">\n')

    def draw_entity(cx, cy, name, is_weak=False, subtitle=""):
        w, h = 80, 32
        x, y = cx - w, cy - h
        fill = "#FFF7ED" if not is_weak else "#F9FAFB"
        stroke = "#D45A12" if not is_weak else "#4B5563"
        stroke_w = 2.5 if not is_weak else 1.2
        
        svg_parts.append(f'    <rect x="{x}" y="{y}" width="{w*2}" height="{h*2}" rx="4" fill="{fill}" stroke="{stroke}" stroke-width="{stroke_w}"/>\n')
        if is_weak:
            svg_parts.append(f'    <rect x="{x+4}" y="{y+4}" width="{w*2-8}" height="{h*2-8}" rx="2" fill="none" stroke="{stroke}" stroke-width="2"/>\n')
        
        y_text = cy + (0 if subtitle else 5)
        svg_parts.append(f'    <text x="{cx}" y="{y_text}" font-size="14" font-weight="bold" fill="#191713" text-anchor="middle">{name}</text>\n')
        if subtitle:
            svg_parts.append(f'    <text x="{cx}" y="{cy+15}" font-size="10" fill="#6B7280" text-anchor="middle">{subtitle}</text>\n')

    draw_entity(1300, 320, "USERS", subtitle="Clients, Operators, Admins")
    draw_entity(750, 620, "ORDERS", subtitle="Booking Records")
    draw_entity(320, 320, "SAND_TYPES", subtitle="Material Catalogue")
    draw_entity(320, 920, "TRUCK_TYPES", subtitle="Fleet Vehicles")
    draw_entity(750, 220, "DELIVERY_ZONES", subtitle="Service Regions")
    draw_entity(1300, 920, "ISSUES", subtitle="User Complaints")
    draw_entity(750, 1020, "ORDER_STATUS_LOG", is_weak=True, subtitle="Audit Trail")
    draw_entity(1400, 620, "CHATBOT_LOGS", subtitle="Unmatched Assistant Queries")

    svg_parts.append('  </g>\n')

    # Notes Box
    svg_parts.append('''
  <!-- Key Distinctions Note Box -->
  <g transform="translate(50, 1140)">
    <rect x="0" y="0" width="1600" height="75" rx="6" fill="#FFFBEB" stroke="#F59E0B" stroke-width="1.2"/>
    <text x="25" y="26" font-size="13" font-weight="bold" fill="#92400E">Academic Note on Peter Chen Notation vs Relational Schema:</text>
    <text x="25" y="46" font-size="12" fill="#78350F">1. <tspan font-weight="bold">Different Shapes:</tspan> Entities are Rectangles, Relationships are Diamonds, Attributes are Ovals. Primary keys have underlined labels.</text>
    <text x="25" y="64" font-size="12" fill="#78350F">2. <tspan font-weight="bold">Associative Relationship:</tspan> The price matrix (SAND_TRUCK_PRICES) is represented as an M:N relationship (Priced At) bearing the attribute [price_ghs].</text>
    <text x="880" y="46" font-size="12" fill="#78350F">3. <tspan font-weight="bold">Weak Entity:</tspan> ORDER_STATUS_LOG is a weak entity (double rectangle) dependent on ORDERS via an identifying relationship (double diamond).</text>
    <text x="880" y="64" font-size="12" fill="#78350F">4. <tspan font-weight="bold">Cardinality Numbers:</tspan> 1, M, N explicitly mark mapping constraints instead of Crow's feet.</text>
  </g>
</svg>''')

    with open(OUT_FILE, "w", encoding="utf-8") as f:
        f.write("".join(svg_parts))
    print(f"Generated {OUT_FILE} successfully!")

if __name__ == "__main__":
    generate_chen_svg()
