# Tipper Truck App

A mobile-based tipper truck sand ordering system for Ghana's construction industry.

Final year project — BSc Information Technology, Faculty of Computing and Information Systems, Ghana Communication Technology University (GCTU).

| | |
|---|---|
| **Mobile** | Flutter 3.x · Dart 3.x · Material 3 · go_router · Provider · Dio |
| **API** | Laravel 13.x · PHP 8.4 · MySQL 8 · Sanctum · Filament v5 |
| **Docs** | [Build spec](docs/BUILD_SPEC.md) · [API contract](docs/API_CONTRACT.md) |

## What it does

Clients book tipper truck sand deliveries from their phone: pick a sand type, pick a truck size at a standardised price, enter a delivery location, pay by Mobile Money or cash on delivery, then track the order through *Confirmed → On The Way → Delivered*. A rule-based assistant answers common questions and clients can file structured issue reports. Administrators and truck operators manage orders, pricing and issues through a web panel.

## Repository layout

```
├── api/       Laravel 13 REST API + Filament admin panel
├── mobile/    Flutter client (Android + iOS)
├── docs/      Architecture, API contract, diagrams
└── .github/   CI workflows
```

## Getting started

Requires PHP 8.4+, Composer 2, MySQL 8, Flutter 3.x, Git.

On Windows, [Laragon](https://laragon.org/) or [Laravel Herd](https://herd.laravel.com/windows) gives you PHP, Composer and MySQL in one install.

**Windows (PowerShell)**

```powershell
.\tasks.ps1 setup
.\tasks.ps1 api                 # http://127.0.0.1:8000
.\tasks.ps1 mobile              # in a second terminal
```

**macOS / Linux**

```bash
make setup
make api
make mobile
```

The app reads its API URL from `--dart-define=API_BASE_URL`. The task runner
defaults to `http://10.0.2.2:8000/api/v1`, which is how the Android emulator
reaches your host machine. On a physical phone, pass your LAN IP instead:

```powershell
.\tasks.ps1 mobile -ApiUrl http://192.168.1.20:8000/api/v1
```

Seeded accounts (local only):

| Role | Email | Password |
|---|---|---|
| Admin | `admin@tippertruck.test` | `password` |
| Operator | `operator@tippertruck.test` | `password` |
| Client | `client@tippertruck.test` | `password` |

The admin panel is at `/admin`.

## Status

Pre-alpha, under active development. See [docs/BUILD_SPEC.md](docs/BUILD_SPEC.md) §6 for the milestone plan.

## Scope

This release covers the full client booking lifecycle plus admin and operator order management. Live payment processing (Paystack / MTN MoMo API), GPS map tracking, push notifications and a dedicated operator mobile app are out of scope — payments run through a simulated gateway behind a `PaymentGateway` interface so a real provider can be added without touching the ordering flow.

## Licence

MIT — see [LICENSE](LICENSE).
