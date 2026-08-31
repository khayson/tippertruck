# Proposal Amendments

Every place the built system differs from the submitted proposal, with the replacement text to apply before final submission.

**How to use this file.** Add an entry the moment a decision diverges from the proposal — same commit as the code, never "later". Each entry names the proposal section, what it currently says, what it should say, and why. At the end, one editing pass through the `.docx` applies them all. Do not commit the proposal `.docx` to this repository; it carries student index numbers.

**Status key:** `PENDING` = not yet applied to the document · `APPLIED` = written into the .docx

---

## 1. Backend framework

**Sections:** §1.1, §2.1, §3.4.1 · **Status:** PENDING

Proposal says the backend is "PHP". Built on Laravel 13.

> The backend is implemented as a RESTful API in PHP using the Laravel 13 framework. Laravel was selected for its mature Eloquent ORM, which parameterises all database queries by default; its first-party token authentication; and its ability to generate a secure administrative interface, all of which reduce the attack surface relative to a hand-written implementation.

---

## 2. Authentication mechanism

**Sections:** §1.3 (objective 4), §2.1, §3.3.3 (FR03–FR05), §3.3.6, §3.4.1, §3.4.6, NFR04 · **Status:** PENDING

Proposal specifies JWT signed with HS256. Built with Laravel Sanctum personal access tokens. Search the document for "JWT" — roughly nine occurrences.

> Authentication uses Laravel Sanctum bearer tokens with a seven-day expiry. Unlike self-contained JWTs, Sanctum tokens are server-side records, which allows a token to be revoked immediately on logout. Logging out of one device does not affect sessions on other devices.

---

## 3. Enumerated columns stored as VARCHAR

**Sections:** §3.4.2 (data dictionary), ERD · **Status:** PENDING

Proposal specifies SQL `ENUM` for status, role, payment and issue-type columns. Implemented as `VARCHAR` with application-level PHP backed enums.

> Columns with a fixed set of permitted values are stored as VARCHAR and constrained in the application layer using PHP backed enumerations. MySQL's native ENUM type requires an ALTER TABLE statement to add or change a permitted value, which complicates future migrations; application-level enumerations provide equivalent validation with a cleaner upgrade path.

---

## 4. Price snapshotting

**Section:** §3.4.2 · **Status:** PENDING

Not addressed in the proposal. Add to the orders table discussion.

> The unit price is copied onto the order record at the time of creation rather than being read from the truck type on each retrieval. Because administrators can revise pricing, a referenced price would retroactively alter the value of completed orders and invalidate the audit trail. The stored price is therefore the price the customer agreed to pay.

---

## 5. Rate limiting moved from future work to implemented

**Sections:** §3.4.6, NFR04 · **Status:** PENDING

> Rate limiting is implemented rather than deferred. Registration is limited to five attempts per minute per address. Login applies two limits: five attempts per minute keyed on the combination of email address and IP address, and twenty per minute per IP address. Keying on the email address as well as the IP address prevents subscribers sharing a carrier-grade NAT address — common on Ghanaian mobile networks — from locking one another out, while still constraining an attacker targeting a single account.

---

## 6. Timing-safe authentication

**Section:** §3.4.6 · **Status:** PENDING

Not in the proposal. Worth including; it demonstrates threat modelling.

> When a login attempt supplies an unregistered email address, the system still performs a bcrypt comparison against a fixed dummy hash. Without this, a missing account would return in under a millisecond while a valid account with a wrong password would take approximately 200 milliseconds, allowing an attacker to enumerate registered email addresses by measuring response time.

---

## 7. Concurrency controls

**Section:** §3.4.2 or §3.4.3 · **Status:** PENDING

Not in the proposal.

> Order status transitions acquire a row-level lock and re-validate the current status inside the database transaction, preventing two administrators — or an administrator and a customer cancelling simultaneously — from both writing a status change based on the same stale value. Order reference generation retries on a unique-constraint violation so that two orders created in the same second receive distinct references.

---

## 8. Real-time tracking wording

**Sections:** §1.4, §2.1, FR15 · **Status:** PENDING

GPS is excluded from scope elsewhere in the document, so "real-time tracking" overstates what is built.

> Real-time order status tracking. The application polls the server while the tracking screen is open and reflects status changes within ten seconds. Map-based GPS tracking of the vehicle is outside the scope of this release.

---

## 9. Operator access

**Sections:** §1.4, §3.3.5 (use case diagram) · **Status:** PENDING

**Proposal / earlier amendment said:** Operators are served only through the web administration panel; a dedicated operator mobile app is future work.

**Implementation:** Operators (drivers) use the Flutter app. After login, `role = operator` routes to **Driver Home** (`/driver`): assigned deliveries, order detail, and Mark On The Way / Mark Delivered via `POST /operator/orders/{id}/dispatch|deliver`. Public signup remains clients only — driver accounts are created by an admin. Admins continue to use Filament at `/admin`; signing in as admin on mobile shows a staff portal hint. Filament may still allow operator panel access as a fallback.

> Truck operators use the Tipper Truck mobile application’s driver home to view orders assigned to them and advance those orders through On The Way and Delivered. Operator accounts are provisioned by an administrator (no public driver registration). System administration (users, pricing, issues) remains on the Filament web panel. GPS tracking remains outside the scope of this release.

---

## 10. Payment network naming

**Section:** §3.4.5 (wireframes) · **Status:** PENDING

Wireframes show Vodafone Cash. The network rebranded to Telecel Cash.

---

## 11. Offline behaviour

**Section:** §1.6 · **Status:** PENDING

The proposal flags loss of offline capability as a limitation. Partial mitigation was built.

> Configuration data and the most recent order history are cached on the device and displayed with a clear offline indicator when connectivity is lost. Actions requiring the network are disabled with an explanatory message rather than failing after a timeout. Full offline order placement remains outside the scope of this release.

---

## 12. Chatbot architecture

**Sections:** §3.3.3 (FR16–FR17), §3.4.4 · **Status:** PENDING

The proposal describes a rule-based assistant matching twelve keyword rules. What was built is substantially more capable and needs a fuller description.

> The assistant is rule-based and operates entirely on the server without external language-model services, ensuring deterministic responses, no per-query cost, and no dependence on third-party availability. Incoming messages are normalised — lowercased, stripped of punctuation, with contractions and colloquial abbreviations expanded and synonyms mapped to canonical terms. Each rule then scores the normalised input against a set of weighted patterns matched on word boundaries, and the highest-scoring rule responds; matching on whole words rather than substrings prevents short keywords from matching inside unrelated words. Approximate matching tolerates single-character errors in longer words. Where the message names a specific truck or sand type, the reply is scoped to that item. Where the customer asks about their own delivery, the assistant reads their most recent active order and reports its reference, status and progress. Below a confidence threshold the assistant states that it is unsure and offers the closest matching topics, and after repeated failures offers to open a support issue. All prices, capacities and product names are read from the database at request time, so administrative price changes are reflected immediately without an application update.

---

## 13. New table: chatbot_unmatched_logs

**Sections:** §3.4.2 (data dictionary), ERD · **Status:** PENDING

The proposal's schema has six tables; there are now seven. **The ERD must be redrawn.**

> `chatbot_unmatched_logs` — records messages the assistant could not confidently answer, together with the highest-scoring candidate intent and its confidence value. This provides empirical data for evaluating and extending the rule set.

---

## 14. Chatbot rule count: twelve becomes sixteen

**Section:** §3.4.4 · **Status:** PENDING

Twelve rules become sixteen. The original twelve plus:
- **order_status** — looks up the authenticated user's most recent non-terminal order and reports its reference, status, and progress percentage.
- **order_cancellation** — explains the cancel flow (orders cancellable while Confirmed) and directs dispatched-order cancellations to the issue reporting flow.
- **delivery_coverage** — lists served regions read from config; resolves named cities (Accra, Kumasi, Takoradi, Tamale, Cape Coast, Koforidua, Sunyani, Ho, Wa, Bolgatanga) to their region.
- **human_handoff** — routes "can I speak to someone" to the issue reporting flow rather than dead-ending in fallback.

Update any count of "twelve rules" or "thirteen rules" in the document to "sixteen rules".

---

## 15. Platform versions

**Sections:** §3.4.1, §4 (implementation environment) · **Status:** PENDING

State the versions actually used: PHP 8.4, Laravel 13, MySQL 8, Flutter 3.44, Filament 5 for the administration panel, Pest for automated testing, GitHub Actions for continuous integration.

---

## 16. Testing and continuous integration

**Section:** §4 · **Status:** PENDING

Not in the proposal. A defensible strength worth claiming.

> The API is covered by an automated test suite executed against MySQL on every pull request via GitHub Actions, alongside an automated code-style check. Tests run against the same database engine used in production rather than an in-memory substitute, so that constraint and type behaviour is exercised faithfully.

---

## 17. Complaint routing with suggested_issue_type

**Section:** §3.4.4 · **Status:** PENDING

The proposal describes a single "report issue" intent. The implementation detects complaint vocabulary (late, damaged, paid but, wrong sand, etc.) and maps it to `issue_type` enum values.

> When the report-issue intent wins, the engine scans the normalised input for complaint vocabulary mapped to the seven issue-type categories. If a match is found, the response carries a `suggested_issue_type` field and the first quick reply includes an `issue_type` value so the mobile application can open the issue form pre-filled with the correct category. This reduces friction and improves issue categorisation accuracy.

---

## 18. Entity bonus typing in scoring engine

**Section:** §3.4.4 · **Status:** PENDING

The original scoring engine applied entity bonuses uniformly. This caused false positives where entity detection pulled unrelated intents (e.g. "quarry or river which is better" triggered pricing because a sand entity was detected).

> Entity bonuses are typed. A detected sand entity boosts only sand-related intents. A detected truck entity boosts truck and pricing intents only when price vocabulary is also present in the input. This prevents entity detection from pulling unrelated intents.

---

## 19. Sand × Truck price matrix

**Sections:** §3.4.2 (data dictionary), ERD · **Status:** PENDING

**Proposal said:** Single price per truck type.

**Implementation:** A `sand_truck_prices` table stores the cross-product of 3 sand types × 3 truck types = 9 distinct base prices. `truck_types.price_ghs` is retained but deprecated.

> Different sand types have different quarry costs, so a single truck-based price under-represents reality. A matrix lets the admin set granular pricing without code changes.

---

## 20. Delivery zones with regional surcharges

**Sections:** §3.4.2 (data dictionary), ERD · **Status:** PENDING

**Proposal said:** Free-text region field validated against a static list of all 16 Ghana regions.

**Implementation:** A `delivery_zones` table with `region`, `surcharge_ghs`, and `is_active`. Only active zones are orderable. Initial scope: Greater Accra (surcharge GHS 0) and Central (surcharge GHS 400).

> A startup cannot serve all 16 regions at launch. Delivery zones let the admin control service areas and apply distance-based surcharges without redeploying. The `is_active` flag enables gradual rollout.

---

## 21. Schema: 9 tables instead of 7

**Sections:** §3.4.2 (data dictionary), ERD · **Status:** PENDING

**Proposal said:** 7 tables. With `chatbot_unmatched_logs` (amendment 13) the count was 8; with `sand_truck_prices` and `delivery_zones` it is now 10. **The ERD must be redrawn.**

---

## 22. Data dictionary additions

**Section:** §3.4.2 · **Status:** PENDING

New columns / tables added to the data dictionary:

| Table | Column | Type | Notes |
|---|---|---|---|
| `sand_truck_prices` | `id` | bigint PK | |
| `sand_truck_prices` | `sand_type_id` | FK → sand_types | RESTRICT |
| `sand_truck_prices` | `truck_type_id` | FK → truck_types | RESTRICT |
| `sand_truck_prices` | `price_ghs` | decimal(10,2) | Base price for this combination |
| `delivery_zones` | `id` | bigint PK | |
| `delivery_zones` | `region` | string, unique | Ghana region name |
| `delivery_zones` | `surcharge_ghs` | decimal(10,2) | Default 0 |
| `delivery_zones` | `is_active` | boolean | Default true |
| `users` | `password` | string, nullable | Null for social-only accounts |
| `users` | `provider` | string, nullable | `google` or `facebook` |
| `users` | `provider_id` | string, nullable | Unique with `provider` |

---

## 23. Delivery fee is now real

**Section:** §3.4.2 · **Status:** PENDING

**Proposal said:** `delivery_fee_ghs` existed on the order but was always 0.

> `delivery_fee_ghs` is now the surcharge from the delivery zone, snapshotted at order creation. `total_ghs = price_ghs + delivery_fee_ghs`. Regional surcharges make delivery fees meaningful. The snapshot rule is unchanged — price at order time is final. Delivery is bundled into the trip price with a regional surcharge, not billed separately.

---

## 24. Pricing rationale and launch coverage

**Section:** §3.4.2 · **Status:** PENDING

Seed prices (GHS) for the initial deployment:

| Sand Type | Small | Medium | Large |
|---|---|---|---|
| Filling Sand | 900 | 1,600 | 2,400 |
| Quarry Sand | 1,100 | 1,900 | 2,800 |
| River Sand | 1,300 | 2,300 | 3,100 |

Surcharges: Greater Accra GHS 0, Central GHS 400.

> Prices are based on typical Accra-area market rates for tipper truck sand delivery as of mid-2026. They are admin-editable via the Filament panel and the `sand_truck_prices` table. Launch coverage is Greater Accra and Central Region only; additional regions are activated by inserting rows into `delivery_zones` — no code change required.

---

## 25. Social sign-in (Google, Facebook)

**Sections:** §3.3.3 (FR03–FR05), §3.4.5 (wireframes), §3.4.6 · **Status:** PENDING

**Proposal said:** Email and password registration / login only.

**Implementation:** Optional Google and Facebook sign-in on the login and register screens. `POST /auth/social` verifies a provider token and returns the same Sanctum `{ user, token }` envelope as password login. Mode is hybrid: when OAuth credentials are configured the API verifies real Google ID tokens and Facebook access tokens; otherwise it accepts HMAC-signed demo tokens so local and FYP demos work without third-party developer apps. Effective mode and enabled providers are published on `GET /config` as `social_auth`. Social-only accounts store a nullable `password` with `provider` / `provider_id` on `users`. Apple Sign In is deferred.

> Customers may sign in with Google or Facebook in addition to email and password. The API issues the same Sanctum bearer token in either case. Where third-party OAuth credentials are not configured, a simulated token path supports demonstration and automated testing without depending on external identity providers. Apple Sign In is identified as future work.

---

## 26. Sand type images (admin-managed)

**Sections:** §3.4.5 (Home wireframe / sand cards), FR07–08 · **Status:** APPLIED

**Proposal said:** Sand types were catalogue rows with name/description; Home sand cards used static client artwork.

**Implementation:** Admins upload a sand image when creating/editing a sand type in Filament (`sand_types.image` on the public disk). `GET /config` exposes `sand_types[].image_url` (absolute URL or `null`). The Flutter Home cards prefer `image_url` and fall back to bundled assets by slug when null.

> Sand type imagery is admin-managed. The API publishes an optional `image_url` on each active sand type so the mobile Home cards stay in sync with the catalogue without shipping new app builds for artwork changes.

---

## Awaiting decision

*No outstanding items.*
