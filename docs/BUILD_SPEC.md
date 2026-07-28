# Tipper Truck App — Build Specification

**Role split:** Claude (architecture, schema, API contract, code review) → Claude Code (implementation).
**Repos:** `tippertruck-api` (Laravel 13.x) · `tippertruck-app` (Flutter 3.x)
**Source of truth for scope:** the GCTU project proposal (Chapter 3). This spec supersedes it wherever it says so — every deviation is listed in §8 so the write-up can be corrected to match the code.

---

## 1. Architecture

Three tiers, unchanged from the proposal — only the middle tier's implementation changes.

```
Flutter (Android/iOS)          Laravel 13 REST API              MySQL 8
─────────────────────          ────────────────────             ───────
Go Router + Provider    ──►    routes/api.php (v1)        ──►   6 tables
Dio + interceptors             Form Requests (validation)       + personal_access_tokens
flutter_secure_storage         API Resources (serialisation)
                               Services (business rules)
                               Filament v5 panel at /admin
```

**Why Laravel instead of hand-rolled PHP:** the proposal's requirements list — bcrypt hashing, prepared statements, JWT-style bearer tokens, parameterised queries, rate limiting, an admin dashboard — is roughly 800 lines of hand-written PHP you'd then have to defend in a viva. Laravel gives all of it as framework guarantees (Eloquent = prepared statements everywhere, `password_hash` bcrypt via the Hasher, Sanctum tokens, `throttle` middleware, Filament for FR20). It is still "a PHP REST API" for the purposes of Chapter 1/2 — see §8.1 for the exact wording change.

**Two apps, one backend.** The Filament panel is not a separate system; admins and truck operators both use it. That kills FR20 and, for near-zero extra cost, the operator use cases the proposal listed but excluded from scope (§8.5). A working operator flow makes the demo far stronger: examiner places an order on the phone, you flip status in the panel, the phone updates in ten seconds.

---

## 2. Data model

Six tables as specified, with four corrections.

### 2.1 Schema

**users** — `id`, `name`, `email` (unique), `password` (bcrypt cost 12), `phone` (nullable), `role` enum(`client`,`operator`,`admin`) default `client`, timestamps.

**sand_types** — `id`, `name`, `slug` (unique), `description`, `icon` (nullable), `is_active` bool, `sort_order`, timestamps.

**truck_types** — `id`, `name`, `slug` (unique), `capacity_label` (e.g. "4–7 tonnes"), `capacity_tonnes_min`, `capacity_tonnes_max` (nullable — null means no upper bound, e.g. "8+ tonnes"), `price_ghs` decimal(10,2), `is_popular` bool, `is_active` bool, `sort_order`, timestamps.

> **Note:** All `enum(…)` columns in this section are implemented as `VARCHAR` with PHP backed enum casts — see §8 item 9 for the rationale.

**orders** — `id`, `order_ref` (unique, `TT-YYYYMMDD-XXXX`), `user_id` FK→users **restrict**, `sand_type_id` FK→sand_types **restrict**, `truck_type_id` FK→truck_types **restrict**, `price_ghs` decimal(10,2), `delivery_fee_ghs` decimal(10,2) default 0, `total_ghs` decimal(10,2), `recipient_name`, `recipient_phone`, `street_address`, `region`, `city`, `landmark` (nullable), `delivery_note` (nullable), `payment_method` enum(`momo`,`cod`), `payment_status` enum(`pending`,`paid`,`failed`) default `pending`, `momo_name` (nullable), `momo_phone` (nullable), `momo_network` enum(`mtn`,`telecel`,`airteltigo`, nullable), `status` enum(`confirmed`,`on_the_way`,`delivered`,`cancelled`) default `confirmed`, `assigned_operator_id` FK→users nullable, `confirmed_at`, `dispatched_at`, `delivered_at`, timestamps. Indexes on `(user_id, created_at)` and `status`.

**issues** — `id`, `user_id` FK→users **cascade**, `order_id` FK→orders **nullable, set null**, `issue_type` enum (7 categories, §2.3), `description` text, `status` enum(`open`,`in_review`,`resolved`,`closed`) default `open`, `admin_response` text nullable, `resolved_at` nullable, timestamps.

**order_status_log** — `id`, `order_id` FK→orders **cascade**, `old_status` nullable, `new_status`, `changed_by` FK→users nullable, `note` nullable, `created_at`.

### 2.2 Corrections to the proposal's schema

1. **Price is snapshotted on the order.** The proposal makes pricing admin-editable *and* has orders reference `truck_types` by FK. If an admin raises the Medium price to GHS 500, every historical order silently becomes GHS 500 — the audit trail is a lie and the receipt no longer matches what the client paid. `orders.price_ghs` is written at creation and never recalculated. The FK stays for reporting; the money comes from the snapshot. Flag this in the viva; it's the kind of thing examiners like.
2. **`RESTRICT` on `sand_type_id` / `truck_type_id` too**, not just `user_id` — deactivate via `is_active`, never delete a type that orders point at.
3. **`issues.order_id` is `SET NULL`, not left dangling** — the proposal says nullable but doesn't say what happens when an order is removed.
4. **Status values are snake_case in the DB** (`on_the_way`), display strings live in the app. The proposal's "On The Way" as a stored value would break on any locale or casing change.

### 2.3 Fixed enumerations

- Sand types (seeded): River Sand, Quarry Sand, Filling Sand.
- Truck types (seeded): Small GHS 250 (1–3 t), Medium GHS 450 (4–7 t, popular), Large GHS 700 (8+ t).
- Regions: the 16 Ghana regions, seeded as a config constant returned by `/config` — not hardcoded in Dart, so the app never drifts from the API.
- Issue types: `late_delivery`, `wrong_sand_type`, `wrong_quantity`, `damaged_goods`, `payment_issue`, `driver_conduct`, `other`.

---

## 3. Order status machine

```
confirmed ──► on_the_way ──► delivered
    │              │
    └──────────────┴──► cancelled   (admin/operator only, or client while `confirmed`)
```

Enforced in `OrderStatusService`, not in a controller. Illegal transitions return `422` with a clear message. Every successful transition writes an `order_status_log` row inside the same DB transaction and stamps the matching `*_at` column. Nothing anywhere else may write `orders.status` directly — that rule is in both CLAUDE.md files and I will fail review on any code that bypasses it.

---

## 4. Authentication

**Decision: Laravel Sanctum personal access tokens, 7-day expiry** (`config/sanctum.php` → `'expiration' => 10080`), sent as `Authorization: Bearer <token>`.

This is functionally identical to the proposal's JWT design from the client's point of view — bearer token, 7-day expiry, secure storage on device, 401 → re-login. It differs internally: Sanctum tokens are opaque and DB-backed rather than self-contained HS256 payloads, which means you also get *revocation* (logout actually invalidates the token; a stateless JWT can't do that without a blocklist).

If your supervisor requires literal JWT for marking, the fallback is `firebase/php-jwt` behind a custom guard — same endpoints, same contract, roughly a day of extra work and a weaker security story. **Ask before Claude Code starts M1.** Either way §8.2 tells you what to change in the write-up.

Hardening included from day one (the proposal defers these to "future work" — they're twenty minutes each, so don't defer them):
- `throttle:5,1` on login and register, `throttle:60,1` on the rest.
- Password rule: min 8, mixed case + number. Bcrypt cost 12 in `config/hashing.php`.
- HTTPS enforced in production via `URL::forceScheme` + server redirect.
- Never store a MoMo PIN. Ever. Not even a column for it.

---

## 5. Tracking without GPS

The proposal promises "real-time tracking" but excludes GPS. What's actually built is **status tracking**, and the write-up should say so (§8.7).

Polling stays as specified (10s) because it's in the document, with three cheap mitigations Claude Code must implement:
- Poll only while the tracking screen is in the foreground; cancel the timer in `dispose()` and on `AppLifecycleState.paused`.
- Back off to 30s after five minutes, stop entirely on `delivered`/`cancelled`.
- `GET /orders/{id}` is a light query returning the order + status log; no eager-loaded collections.

FCM push is the correct answer and belongs in Chapter 5 as future work.

---

## 6. Milestones

Claude Code works one milestone at a time and **stops for review at each gate**. No milestone starts before the previous one's acceptance criteria pass.

| M | Scope | Done when |
|---|---|---|
| **M0** | Both repos scaffolded. Laravel 13 + `install:api` + MySQL connected + `.env.example`. Flutter project with the folder structure from the khayson-flutter skill, theme, router shell. | `php artisan test` green on a stub test; `flutter run` shows the Welcome screen. |
| **M1** | Migrations, models, relationships, factories, seeders (3 sand types, 3 truck types, admin + demo client). | `migrate:fresh --seed` clean; a Pest test asserts every FK constraint and the 6 tables. |
| **M2** | Auth: register, login, logout, me. Sanctum, throttling, validation, envelope responses. | Pest covers happy path + wrong password + duplicate email + throttle. Postman collection exported. |
| **M3** | `/config`, orders (create, list, show), the status machine + log, order_ref generation. | Pest: order creation snapshots price, illegal transition rejected, user A cannot read user B's order. |
| **M4** | Issues (create, list), chatbot endpoint (server-side rules, live prices). | Pest green; chatbot returns current DB price, not a hardcoded string. |
| **M5** | Filament v5 panel: orders (status actions), users, issues, sand/truck type + pricing CRUD. Operator role sees only assigned orders. | Admin can move an order through the full lifecycle and the log records it. |
| **M6** | Flutter: auth flow, secure storage, router guard, home/config caching. | Cold start with a valid token lands on Home; expired token lands on Welcome. |
| **M7** | Flutter: the 5-step booking flow + summary + payment + tracking. | End-to-end on a device against staging; status flipped in Filament appears on the phone inside 10s. |
| **M8** | Flutter: order history, issues, chatbot, profile, offline banner, empty/error states. | All 8 wireframe screens present; no unhandled Dio exception path. |
| **M9** | Polish: usability-test fixes, seeded demo data, README + API docs, screenshots for Chapter 4. | Fresh clone → running app in under 10 minutes following the README. |

Realistic pacing: M0–M5 is backend-heavy and should move fast; M6–M8 is where the time actually goes.

---

## 7. Conventions Claude Code must follow

**Backend**
- Controllers stay thin: validate (Form Request) → call a Service → return a Resource. No business logic in controllers, no queries in controllers.
- One response envelope everywhere, including validation failures and 500s (override the exception handler). The Flutter side parses one shape or nothing.
- API Resources for every response object. No `->toArray()` on a model into a JSON response.
- Pest feature tests per endpoint, written in the same milestone — not "later".
- `declare(strict_types=1)` in app code; Pint before every commit.

**Mobile**
- Follow the khayson-flutter skill structure exactly (`core/`, `services/`, `providers/`, `screens/`, `widgets/`).
- Booking state lives in a single `BookingProvider` draft object, **not** passed through five route `extra` payloads — back navigation must not lose the draft.
- Every API call goes through `ApiClient`; no bare `Dio()` instances, no `http` package.
- Every screen handles three states: loading, empty, error-with-retry. This is the single most common gap in FYP apps and the fastest way to lose marks in a demo.
- Material 3, `seedColor: #FF6600`, scaffold background `#F7F5F2`, min 14sp text, 48dp tap targets (NFR07).

---

## 8. Proposal corrections — do these before submission

The code and the document must agree, or you lose marks for both.

1. **§1.1, §2.1, §3.4.1:** "PHP for the backend API" → "PHP (Laravel 13) for the backend REST API". Add one sentence justifying the framework: mature ORM with parameterised queries by default, first-party token authentication, and a generated admin interface.
2. **§3.4.6 + NFR04:** if you go with Sanctum, "JWT tokens signed with HS256" → "Laravel Sanctum bearer tokens with 7-day expiry and server-side revocation". Everywhere JWT appears (§1.3 obj. 4, §2.1, §3.3.3 FR03–05, §3.3.6 steps 1–7, §3.4.1) needs the same swap. There are about nine occurrences — search the doc.
3. **§3.4.2:** add the price-snapshot rationale (§2.2 above). It's a defensible design decision and reads well.
4. **NFR04 / §3.4.6:** move rate limiting from "Future" to "Implemented".
5. **§3.3.5 use cases:** operator actions are listed but §1.4 excludes an operator module. Resolve it — recommendation: keep the use cases and state that operators are served through the web admin panel in this release, with a dedicated operator mobile app as future work.
6. **§3.4.5:** wireframes show Vodafone Cash. It's Telecel Cash now. Small detail, but a Ghanaian examiner will notice.
7. **§1.4, §2.1, FR15:** "real-time tracking" → "real-time order *status* tracking (GPS map tracking deferred)". You already say GPS is out of scope; make the two statements consistent.
8. **§1.6:** the offline regression is real. The mitigation actually built — cached config + cached order history + an offline banner — is worth documenting rather than leaving as pure future work.

9. **§2.1 all enum columns:** the spec and the proposal's Chapter 3 specify SQL `ENUM` column types. The implementation uses `VARCHAR` columns with PHP backed enum casts instead. MySQL `ENUM` bakes the allowed values into the column definition, so adding or removing a value requires a raw `ALTER TABLE … MODIFY COLUMN` — on a large table that rewrites every row. Application-level PHP enums give the same value-safety guarantee (invalid values are rejected before they reach the database) while allowing new values through a normal migration that adds no DDL. This is the standard Laravel approach and the one Eloquent's enum casting is designed for.

---

## 9. Explicitly out of scope

Live Paystack/MoMo processing, GPS map tracking, push notifications, a separate operator mobile app, multi-language. The payment layer is built behind a `PaymentGateway` interface with a `SimulatedGateway` implementation so that adding Paystack later is one class and a webhook route — say that in Chapter 5 and it reads as design foresight rather than an unfinished feature.
