#!/usr/bin/env bash
#
# Tipper Truck — first-run scaffold.
#
# Creates the Laravel API and Flutter app inside this monorepo, wires up
# environment files, and makes the initial commit. Run it once, from the
# repository root, on a clean checkout.
#
#   ./bootstrap.sh                                  # scaffold only
#   ./bootstrap.sh git@github.com:you/tippertruck.git   # scaffold + first push
#
set -euo pipefail

REMOTE="${1:-}"
ORG_ID="com.khaystudios"

say()  { printf '\n\033[1;33m▸ %s\033[0m\n' "$1"; }
die()  { printf '\n\033[1;31m✗ %s\033[0m\n' "$1" >&2; exit 1; }

# ── Preflight ────────────────────────────────────────────────────────────
say "Checking tooling"
for cmd in git php composer flutter; do
  command -v "$cmd" >/dev/null 2>&1 || die "$cmd not found on PATH"
done

PHP_VERSION="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"
php -r 'exit(version_compare(PHP_VERSION, "8.4.0", ">=") ? 0 : 1);' \
  || die "PHP 8.4+ required, found $PHP_VERSION"

printf '  php %s · composer %s · flutter %s\n' \
  "$PHP_VERSION" \
  "$(composer --version --no-ansi | awk '{print $3}')" \
  "$(flutter --version | head -1 | awk '{print $2}')"

[ -f CLAUDE.md ] || die "Run this from the repository root"

# ── Laravel API ──────────────────────────────────────────────────────────
if [ -f api/artisan ]; then
  say "api/ already scaffolded — skipping"
else
  say "Creating Laravel 13 API in api/"
  composer create-project laravel/laravel:^13.0 api --no-interaction

  pushd api >/dev/null
    say "Installing API scaffolding (Sanctum + routes/api.php)"
    php artisan install:api --no-interaction

    say "Installing Filament v5"
    composer require filament/filament:"^5.0" --no-interaction
    php artisan filament:install --panels --no-interaction

    say "Configuring environment"
    # bcrypt cost 12 (NFR04) and a 7-day Sanctum token expiry are set in
    # config/hashing.php and config/sanctum.php by milestone M2.
    sed -i.bak 's/^DB_DATABASE=.*/DB_DATABASE=tipper_truck/' .env.example && rm -f .env.example.bak
    cp -n .env.example .env
    php artisan key:generate
  popd >/dev/null
fi

# ── Flutter app ──────────────────────────────────────────────────────────
if [ -f mobile/pubspec.yaml ]; then
  say "mobile/ already scaffolded — skipping"
else
  say "Creating Flutter app in mobile/"
  flutter create \
    --org "$ORG_ID" \
    --project-name tippertruck \
    --platforms android,ios \
    --description "Tipper truck sand ordering for Ghana's construction industry" \
    mobile

  pushd mobile >/dev/null
    say "Adding dependencies"
    flutter pub add go_router provider dio flutter_secure_storage \
      shared_preferences connectivity_plus intl
    flutter pub add --dev flutter_lints mocktail
  popd >/dev/null
fi

# ── Place the working guides ─────────────────────────────────────────────
say "Placing CLAUDE.md guides"
[ -f docs/backend-CLAUDE.md ] && mv -f docs/backend-CLAUDE.md api/CLAUDE.md
[ -f docs/mobile-CLAUDE.md ]  && mv -f docs/mobile-CLAUDE.md mobile/CLAUDE.md
printf '  api/CLAUDE.md · mobile/CLAUDE.md · CLAUDE.md (root)\n'

# ── Sanity check: no secrets staged ──────────────────────────────────────
say "Checking for secrets"
if git check-ignore -q api/.env 2>/dev/null; then
  printf '  api/.env is ignored ✓\n'
else
  die "api/.env is NOT ignored — fix .gitignore before committing"
fi

# ── First commit ─────────────────────────────────────────────────────────
if [ -d .git ]; then
  say "Git repository already initialised — skipping init"
else
  say "Initialising repository"
  git init -q
  git branch -M main
fi

git add -A
if git diff --cached --quiet; then
  say "Nothing to commit"
else
  git commit -q -m "chore: scaffold monorepo with Laravel 13 API and Flutter app

- api/     Laravel 13 + Sanctum + Filament v5
- mobile/  Flutter 3.x with go_router, Provider, Dio
- docs/    build spec and frozen API contract
- CI       separate path-filtered workflows per side"
  printf '  committed\n'
fi

if [ -n "$REMOTE" ]; then
  say "Pushing to $REMOTE"
  git remote get-url origin >/dev/null 2>&1 || git remote add origin "$REMOTE"
  git push -u origin main
else
  cat <<'EOF'

Next:
  gh repo create tippertruck --public --source=. --remote=origin --push
  # or
  git remote add origin git@github.com:<you>/tippertruck.git && git push -u origin main
EOF
fi

say "Done. Start Claude Code on milestone M1 (docs/BUILD_SPEC.md §6)."
