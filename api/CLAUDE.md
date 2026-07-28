# CLAUDE.md — tippertruck-api

Laravel 13.x REST API + Filament v5 admin panel for the Tipper Truck sand ordering app (GCTU final year project).

**Read `BUILD_SPEC.md` and `API_CONTRACT.md` before writing code. The contract is frozen — if something in it looks wrong, stop and say so rather than changing it.**

## Stack

PHP 8.4+ · Laravel 13.x · MySQL 8 · Sanctum (`php artisan install:api`) · Filament v5 · Pest · Pint

## Setup

```bash
composer create-project laravel/laravel:^13.0 tippertruck-api
php artisan install:api          # routes/api.php + Sanctum + personal_access_tokens
composer require filament/filament:"^5.0"
php artisan filament:install --panels
```

`config/sanctum.php` → `'expiration' => 10080` (7 days).
`config/hashing.php` → `'bcrypt' => ['rounds' => 12]`.

## Non-negotiable rules

1. **Controllers are thin.** Form Request in → Service call → API Resource out. No business logic, no queries in controllers.
2. **`orders.status` is written only by `OrderStatusService::transition()`.** Nowhere else. Every transition validates against the state machine, writes an `order_status_log` row, and stamps the timestamp column — all in one DB transaction.
3. **Price never comes from the client.** Read `truck_types.price_ghs` server-side, snapshot onto the order, never recalculate afterwards.
4. **One response envelope** for everything, including validation errors and unhandled exceptions. Override the exception handler in `bootstrap/app.php` so a `ValidationException` on an API route renders the same shape as a success.
5. **API Resources for every response object.** No models serialised directly.
6. **Never store a MoMo PIN.** No column, no request field, no log line.
7. **Pest tests in the same milestone as the code.** A milestone with no tests is not done.
8. `declare(strict_types=1)` in `app/`. Run `./vendor/bin/pint` before finishing a milestone.

## Structure

```
app/
├── Http/
│   ├── Controllers/Api/V1/    AuthController, ConfigController, OrderController,
│   │                          IssueController, ChatbotController
│   ├── Requests/Api/V1/       RegisterRequest, LoginRequest, StoreOrderRequest, ...
│   ├── Resources/             UserResource, OrderResource, IssueResource, ...
│   └── Middleware/
├── Models/                    User, Order, Issue, SandType, TruckType, OrderStatusLog
├── Services/
│   ├── OrderService.php           creation, order_ref generation
│   ├── OrderStatusService.php     the state machine — single writer of status
│   ├── ChatbotService.php         12 rules, live price interpolation
│   └── Payments/                  PaymentGateway interface + SimulatedGateway
├── Enums/                     OrderStatus, PaymentMethod, PaymentStatus, IssueType, UserRole
└── Filament/Resources/        OrderResource, UserResource, IssueResource,
                               SandTypeResource, TruckTypeResource
```

Use **PHP backed enums** for every status/type column and cast them on the models — that's where `status_label` and `progress_percent` live.

`order_ref` format `TT-YYYYMMDD-XXXX` where XXXX is a zero-padded daily sequence; generate inside the creation transaction and let the unique index be the backstop with one retry.

## Routes (`routes/api.php`, prefix `v1`)

```php
Route::prefix('v1')->group(function () {
    Route::post('auth/register', ...)->middleware('throttle:5,1');
    Route::post('auth/login', ...)->middleware('throttle:5,1');
    Route::get('config', ...);

    Route::middleware(['auth:sanctum', 'throttle:60,1'])->group(function () {
        Route::post('auth/logout', ...);
        Route::get('auth/me', ...);
        Route::apiResource('orders', OrderController::class)->only(['index','store','show']);
        Route::post('orders/{order}/cancel', ...);
        Route::apiResource('issues', IssueController::class)->only(['index','store']);
        Route::post('chatbot/message', ...);
    });
});
```

Authorisation on `orders.show` via a Policy: owner, admin, or assigned operator. Return `403`, not `404`.

## Filament panel

Path `/admin`, session auth. `User::canAccessPanel()` → `role` is `admin` or `operator`.

- **Orders:** table with status badge, filters by status/date, row actions "Mark On The Way" / "Mark Delivered" / "Cancel" that call `OrderStatusService` (never a raw update), an infolist showing full delivery details, and a Status Log relation manager. Operators see only `assigned_operator_id = auth()->id()` and get only the two status actions.
- **Users:** list, role change, no password display. Admin-only.
- **Issues:** list, filter by status, admin response + resolve action. Admin-only.
- **Sand/Truck types:** full CRUD including price editing — this is FR07–08's "admin-managed pricing". Admin-only.

## Seeders

3 sand types, 3 truck types (250/450/700, Medium flagged popular), 1 admin, 1 operator, 1 demo client, and ~8 demo orders spread across statuses so the panel and the app both have something to show in the demo. `migrate:fresh --seed` must always produce a demo-ready system.

## Milestone gate

Stop after each milestone in `BUILD_SPEC.md` §6 and report: what was built, tests passing, anything in the spec or contract that turned out wrong. Do not roll into the next milestone.
