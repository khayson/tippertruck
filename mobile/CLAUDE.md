# CLAUDE.md — tippertruck-app

Flutter client for the Tipper Truck sand ordering app (GCTU final year project). Talks to `tippertruck-api` (Laravel 13).

**Read `BUILD_SPEC.md` and `API_CONTRACT.md` first, and follow the `khayson-flutter` skill for structure, the Dio client, and error handling — it is the house style, not a suggestion.**

## Stack

Flutter 3.x / Dart 3.x (null safety) · Material 3 · go_router · provider · dio · flutter_secure_storage · shared_preferences · connectivity_plus · intl

## Design system

- Palette: tipperAmber `#D45A12` (primary), laterite `#8C3A17` (pressed), ink `#191713` (text), slate `#6B655C` (secondary text), bone `#F4F0E8` (background), signal `#1E6B4C` (success). White card surfaces.
- Body text ≥ 14sp, tap targets ≥ 48dp, contrast ≥ 4.5:1 (NFR07 — these are graded).
- Cards for every selection option; `SingleChildScrollView` + `Column` for screen bodies.
- One `AppButton`, one `AppTextField`, one `StatusBadge`, one `EmptyState`, one `ErrorState` widget — reused everywhere. No one-off styling inside screens.

## Structure

Exactly as the khayson-flutter skill lays out (`app/`, `config/`, `core/`, `models/`, `services/`, `providers/`, `screens/`, `widgets/`).

```
providers/
├── auth_provider.dart      token, current user, login/register/logout
├── config_provider.dart    sand types, truck types, regions — cached
├── booking_provider.dart   the in-progress order draft
├── orders_provider.dart    history + the tracked order
└── issues_provider.dart

screens/
├── welcome/  auth/(login,register)  home/
├── booking/  truck_type · delivery_location · order_summary · payment
├── tracking/  orders/  issues/  chatbot/  profile/
```

## Non-negotiable rules

1. **All network traffic goes through `ApiClient`** (single Dio instance, auth interceptor, 401 handling). No bare `Dio()`, no `http`.
2. **Booking state lives in `BookingProvider`** as one draft object. Do not thread five screens' worth of arguments through `go_router` `extra` — going back must not lose the draft. `clearDraft()` after a successful order.
3. **The app never computes price.** Display `truck_type.price_ghs` from `/config` and the server's `total_ghs` on the order. No arithmetic on money in Dart.
4. **The app never owns the status→label/percent mapping** — it renders `status_label` and `progress_percent` from the API.
5. **Every screen handles loading / empty / error-with-retry.** No screen ships with only a happy path. This is the most common way FYP demos fall over.
6. **Server-side validation is authoritative.** Client validation is UX only; always surface the API's `errors` map onto the right fields.
7. Token in `flutter_secure_storage` only. Never `SharedPreferences`, never logged.

## Routing & auth guard

`go_router` with a `redirect` that reads `AuthProvider`: unauthenticated + protected route → `/welcome`; authenticated + `/welcome|/login|/register` → `/home`. On cold start show a splash while `GET /auth/me` validates the stored token — valid means straight to Home (FR03–05 auto-login), invalid means clear the token and go to Welcome.

## Screens (proposal §3.4.5 wireframes)

1. **Welcome** — truck icon, wordmark, tagline, Sign In (filled) + Create Account (outlined).
2. **Home** — "Hello, {firstName} 👋", avatar, orange "Book a Truck" banner, three full-width sand type cards, 4-column quick actions (Orders · Chat · Issues · Profile), bottom nav, offline banner when disconnected.
3. **Truck type** — selected-sand badge, three price cards, "Popular" star on Medium.
4. **Delivery location** — recipient name, phone (10 digits, starts with `0`), street, region dropdown (16 regions from `/config`), city, optional landmark + note, "Save this address" (local only), Continue.
5. **Order summary** — order details, price breakdown, total in 22sp orange, formatted delivery block, Proceed to Payment.
6. **Payment** — amount banner, recipient line, MoMo / Cash on Delivery radio, MoMo sub-form (name, phone, network) shown only for MoMo, Confirm & Place Order → `POST /orders` → tracking. **No PIN field.**
7. **Tracking** — order header, progress bar from `progress_percent`, three-step indicator, polling per BUILD_SPEC §5 (foreground only, back off to 30s after 5 min, stop on terminal status, cancel in `dispose()`), View History / New Order.
8. **Chatbot** — orange header, message list, quick-reply chips from the API, input + send, offline fallback rules clearly labelled.

Plus: order history (status badge + relative time, pull to refresh), issue report + list, profile (name, email, logout).

## Offline behaviour

`/config` and the last order-history page are cached in `SharedPreferences` and rendered stale-with-banner when the network is down. Actions that need the network (booking, chatbot, issue submit) are disabled with a clear message rather than failing after a 30-second timeout. This partly answers the offline regression the proposal flags in §1.6 — mention it in the write-up.

## Milestone gate

Stop after each milestone in `BUILD_SPEC.md` §6 and report what's done, what's stubbed, and anything the API contract got wrong. Do not roll into the next milestone.
