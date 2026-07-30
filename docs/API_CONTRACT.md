# Tipper Truck API — Contract v1

Base URL: `https://<host>/api/v1`
All requests/responses JSON. All protected routes require `Authorization: Bearer <token>`.

**This file is the contract between the two repos. Neither side changes it unilaterally — a change here is a review item, and both CLAUDE.md files point at this document.**

---

## Response envelope

Every response, including errors, validation failures and 500s:

```json
{ "success": true, "message": "Order created", "data": { }, "errors": null }
```

```json
{ "success": false, "message": "The given data was invalid.", "data": null,
  "errors": { "recipient_phone": ["Phone number must start with 0."] } }
```

Status codes: `200` ok · `201` created · `401` unauthenticated · `403` forbidden · `404` not found · `422` validation/illegal transition · `429` throttled · `500` server error.

---

## Auth

### POST /auth/register
`name`, `email`, `password`, `password_confirmation`, `phone?`
→ `201` `{ user, token }`

### POST /auth/login
`email`, `password` → `200` `{ user, token }` · `401` on bad credentials · `429` after 5 attempts/min per email+IP (and 20/min per IP). `429` responses include `Retry-After` and `X-RateLimit-*` headers.

### POST /auth/logout *(auth)*
Revokes the current token. → `200`

### GET /auth/me *(auth)*
→ `200` `{ user }`. Used by the app on cold start to validate a stored token.

**User object:** `id`, `name`, `email`, `phone`, `role`, `created_at`.

---

## Config

### GET /config
Public. Everything the app needs to render the booking flow.

```json
{ "sand_types": [ { "id":1, "name":"River Sand", "slug":"river-sand",
                    "description":"...", "icon":"wave" } ],
  "truck_types": [ { "id":2, "name":"Medium Truck", "slug":"medium",
                     "capacity_label":"4–7 tonnes", "price_ghs":"450.00",
                     "is_popular":true } ],
  "regions": ["Greater Accra", "Ashanti", "..."],
  "issue_types": [ { "value":"late_delivery", "label":"Late delivery" } ],
  "payment_networks": [ { "value":"mtn", "label":"MTN MoMo" },
                        { "value":"telecel", "label":"Telecel Cash" },
                        { "value":"airteltigo", "label":"AirtelTigo Money" } ],
  "config_version": "2026-07-28T10:00:00Z" }
```

Only `is_active` rows, ordered by `sort_order`. The app caches this and refreshes on launch; `config_version` lets it skip a rebuild when unchanged.

---

## Orders

### POST /orders *(auth)*
```json
{ "sand_type_id": 1, "truck_type_id": 2,
  "recipient_name": "Kwame Asante", "recipient_phone": "0241234567",
  "street_address": "No. 12 Osu Road", "region": "Greater Accra", "city": "Accra",
  "landmark": "Near Osu Presby", "delivery_note": "Call on arrival",
  "payment_method": "momo",
  "momo_name": "Kwame Asante", "momo_phone": "0241234567", "momo_network": "mtn" }
```
Server-side rules: `recipient_phone` and `momo_phone` — 10 digits, must start with `0`. MoMo fields required only when `payment_method = momo`. **Price is never accepted from the client** — the server reads `truck_types.price_ghs` and snapshots it onto the order. `order_ref` generated server-side.

→ `201` `{ order }`

### GET /orders *(auth)*
Authenticated user's orders, newest first. `?status=` optional filter. Paginated (15/page), pagination meta in `data.meta`.

### GET /orders/{id} *(auth)*
Owner or admin/assigned operator only — anyone else gets `403`, never `404`-as-cover. Returns the order plus `status_log`. This is the polling endpoint.

### POST /orders/{id}/cancel *(auth)*
Client may cancel only while `confirmed`. → `200` with updated order, or `422`.

**Order object:**
```json
{ "id": 12, "order_ref": "TT-20260728-0042",
  "sand_type": { "id":1, "name":"River Sand" },
  "truck_type": { "id":2, "name":"Medium Truck", "capacity_label":"4–7 tonnes" },
  "price_ghs":"450.00", "delivery_fee_ghs":"0.00", "total_ghs":"450.00",
  "status":"on_the_way", "status_label":"On The Way", "progress_percent": 66,
  "delivery": { "recipient_name":"...", "recipient_phone":"...", "street_address":"...",
                "region":"...", "city":"...", "landmark":null, "delivery_note":null },
  "payment": { "method":"momo", "status":"pending", "network":"mtn", "momo_phone":"024*****67" },
  "confirmed_at":"...", "dispatched_at":"...", "delivered_at":null,
  "created_at":"...",
  "status_log": [ { "old_status":null, "new_status":"confirmed", "created_at":"..." } ] }
```

`status_label` and `progress_percent` are computed server-side so the app never owns that mapping (`confirmed` 33, `on_the_way` 66, `delivered` 100, `cancelled` 0). MoMo phone is masked on output.

---

## Issues

### POST /issues *(auth)*
`issue_type` (one of the 7), `description` (min 10 chars), `order_id?` (must belong to the user) → `201` `{ issue }`

### GET /issues *(auth)*
User's issues, newest first, with `status`, `admin_response`, and the linked `order_ref` when present.

---

## Chatbot

### POST /chatbot/message *(auth)*
```json
{ "message": "how much is a medium truck", "unmatched_count": 0 }
```

`unmatched_count` is optional (default `0`). The client should echo back the `unmatched_count` from the previous response so the server can track consecutive misses and offer escalation.

→ `200`
```json
{ "reply": "Medium Truck costs GHS 450.00 and carries 4–7 tonnes.",
  "matched_rule": "pricing",
  "confidence": 0.90,
  "entities": { "truck_type": { "id": 2, "name": "Medium Truck" } },
  "quick_replies": [ { "label": "Sand types", "message": "What sand types do you have?" } ],
  "unmatched_count": 0,
  "suggested_issue_type": null }
```

**Response fields:**
- `reply` — the bot's answer, with prices and type names interpolated from the database at request time.
- `matched_rule` — the rule name that won scoring (`"fallback"` when no rule scored above the confidence threshold).
- `confidence` — `0.00`–`1.00` float derived from the winning rule's score. Below the threshold the response is treated as uncertain.
- `entities` — extracted truck type and/or sand type from the input, as `{ "truck_type": { "id", "name" }, "sand_type": { "id", "name" } }`. Empty object `{}` when no entity was detected. When an entity is present, the reply answers about that entity specifically rather than listing everything.
- `quick_replies` — suggested follow-up messages. When the bot is uncertain, these are the top 3 scoring intents. After 2+ consecutive misses (`unmatched_count >= 2`), a "Report an issue" quick reply is appended. When a complaint is detected, the first quick reply carries an `issue_type` field so the app can open the issue form pre-filled.
- `unmatched_count` — echoed back (or incremented on a miss) so the client can pass it on the next request.
- `suggested_issue_type` — when the `report_issue` intent detects specific complaint vocabulary (e.g. "late", "damaged", "paid but"), this field contains the matching `issue_type` enum value (`late_delivery`, `payment_issue`, `wrong_quantity`, `wrong_sand_type`, `damaged_goods`, `driver_conduct`). `null` for all other intents and for general report_issue matches without specific complaint vocabulary.

Rules live server-side and **interpolate live prices from the database**. If an admin changes the Medium price, the bot says the new number without an app update — hardcoding prices in Dart is the mistake to avoid here. The app ships a small fallback rule set for offline use and labels those replies as offline.

Sixteen rules: greeting, pricing, sand types, truck sizes, how to book, payment methods, MoMo help, cash on delivery, report issue, order status, order cancellation, tracking stages, delivery time, delivery coverage, order history, human handoff, plus fallback.

**Matching engine:** input is normalised (lowercased, punctuation stripped, contractions expanded, synonyms mapped to canonical terms) and tokenised. Every rule declares weighted patterns; all rules are scored and the highest total wins, with ties broken by an explicit priority. Word-boundary matching prevents substring collisions (e.g. "hi" does not match "this"). Tokens of 5+ characters tolerate Levenshtein distance 1 (distance 2 for 8+ characters); shorter tokens require exact matches. Entity bonuses are typed: a sand entity boosts only sand-related intents, a truck entity boosts truck/pricing intents only when price vocabulary is also present — this prevents entity detection from pulling unrelated intents.

**Complaint routing:** when the `report_issue` intent wins, the engine scans the normalised input for complaint vocabulary mapped to `issue_type` values. If found, `suggested_issue_type` is set and the first quick reply carries an `issue_type` field so the mobile app can pre-fill the issue form.

**Order status intent:** when the user asks about their order, the bot looks up the authenticated user's most recent non-terminal order and replies with its `order_ref`, status label, and progress percent. If no active order exists, it offers to help book one.

**Order cancellation intent:** explains that orders can be cancelled while in "Confirmed" status, and directs users to report an issue if the order has already been dispatched.

**Delivery coverage intent:** lists the regions served (read from config, not hardcoded). Resolves named cities (Accra, Kumasi, Takoradi, Tamale, Cape Coast, Koforidua, Sunyani, Ho, Wa, Bolgatanga) to their region.

**Human handoff intent:** informs the user there is no live chat agent and routes them to the issue reporting flow.

---

## Admin

No public admin API in v1 — administration is the Filament panel at `/admin`, session-authenticated, restricted to `role in (admin, operator)`. Operators see only orders assigned to them.
