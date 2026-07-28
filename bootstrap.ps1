#Requires -Version 5.1
<#
.SYNOPSIS
    Tipper Truck — first-run scaffold (Windows / PowerShell).

.DESCRIPTION
    Creates the Laravel API and Flutter app inside this monorepo, wires up
    environment files, and makes the initial commit. Run once, from the
    repository root, on a clean checkout. Safe to re-run — it skips whatever
    already exists.

.EXAMPLE
    .\bootstrap.ps1
    Scaffold only.

.EXAMPLE
    .\bootstrap.ps1 -Remote git@github.com:you/tippertruck.git
    Scaffold, commit, and push.
#>

[CmdletBinding()]
param(
    [string] $Remote = '',
    [string] $OrgId  = 'com.khaystudios'
)

$ErrorActionPreference = 'Stop'

function Say  { param($m) Write-Host "`n> $m" -ForegroundColor Yellow }
function Note { param($m) Write-Host "  $m" -ForegroundColor DarkGray }
function Die  { param($m) Write-Host "`nX $m" -ForegroundColor Red; exit 1 }

# ── Preflight ────────────────────────────────────────────────────────────
Say 'Checking tooling'
foreach ($cmd in 'git', 'php', 'composer', 'flutter') {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Die "$cmd not found on PATH. Install it and reopen PowerShell."
    }
}

$phpVersion = (php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
php -r 'exit(version_compare(PHP_VERSION, "8.3.0", ">=") ? 0 : 1);'
if ($LASTEXITCODE -ne 0) { Die "PHP 8.3+ required, found $phpVersion" }

$flutterVersion = (flutter --version | Select-Object -First 1)
Note "php $phpVersion"
Note $flutterVersion

# Confirm we are at the repository root, and recover from the two common
# extraction mistakes rather than just failing.
$markers = @('CLAUDE.md', 'tasks.ps1', 'docs\BUILD_SPEC.md')

function Test-IsRoot {
    param([string] $Path)
    foreach ($m in $markers) {
        if (Test-Path (Join-Path $Path $m)) { return $true }
    }
    return $false
}

if (-not (Test-IsRoot '.')) {

    # Case 1: the archive extracted into a nested folder — flatten it.
    $nested = Get-ChildItem -Directory -Force |
        Where-Object { Test-IsRoot $_.FullName }

    if ($nested.Count -eq 1) {
        Say "Found the scaffold nested in $($nested.Name) — flattening"
        Get-ChildItem -Force -Path $nested.FullName |
            Move-Item -Destination (Get-Location) -Force
        Remove-Item $nested.FullName -Recurse -Force
        Note 'flattened'
    }
    else {
        # Case 2: something else. Show reality instead of guessing.
        Write-Host "`nX Not at the repository root — the scaffold files are missing." -ForegroundColor Red
        Write-Host "`n  $(Get-Location) contains:" -ForegroundColor DarkGray
        $items = Get-ChildItem -Force
        if ($items) {
            $items | ForEach-Object {
                $tag = if ($_.PSIsContainer) { 'DIR ' } else { '    ' }
                Write-Host "    $tag$($_.Name)" -ForegroundColor DarkGray
            }
        }
        else {
            Write-Host '    (empty)' -ForegroundColor DarkGray
        }
        Write-Host @"

  Expected at least: CLAUDE.md, tasks.ps1, docs\BUILD_SPEC.md

  Re-extract, then run this again:
    Expand-Archive `$HOME\Downloads\tippertruck-scaffold.zip -DestinationPath . -Force

"@ -ForegroundColor Yellow
        exit 1
    }
}

# Windows long-path guard — Laravel vendor/ and Flutter build/ both blow past
# 260 characters. Warn rather than fail; it needs an elevated shell to fix.
$longPaths = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' `
    -Name 'LongPathsEnabled' -ErrorAction SilentlyContinue).LongPathsEnabled
if ($longPaths -ne 1) {
    Write-Host '  ! Long paths are disabled. If composer or flutter fail with' -ForegroundColor Yellow
    Write-Host '    path-too-long errors, run this in an admin PowerShell:' -ForegroundColor Yellow
    Write-Host '    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" LongPathsEnabled 1' -ForegroundColor Yellow
}

# ── Clear placeholders ───────────────────────────────────────────────────
# composer create-project and flutter create both refuse a non-empty target.
foreach ($stub in 'api\.gitkeep', 'mobile\.gitkeep') {
    if (Test-Path $stub) { Remove-Item $stub -Force }
}

foreach ($dir in 'api', 'mobile') {
    if ((Test-Path $dir) -and -not (Test-Path "$dir\artisan") -and -not (Test-Path "$dir\pubspec.yaml")) {
        $leftovers = Get-ChildItem -Force -Path $dir
        if ($leftovers) {
            Write-Host "`nX $dir\ is not empty but holds no project:" -ForegroundColor Red
            $leftovers | ForEach-Object { Write-Host "    $($_.Name)" -ForegroundColor DarkGray }
            Die "Empty $dir\ (or delete it) and run this again."
        }
    }
}

# ── Laravel API ──────────────────────────────────────────────────────────
if (Test-Path 'api\artisan') {
    Say 'api\ already scaffolded — skipping'
} else {
    Say 'Creating Laravel 13 API in api\'

    # Do NOT use a caret constraint here. composer.bat runs through cmd.exe,
    # where ^ is the escape character — it is stripped even inside PowerShell
    # quotes, so ^13.0 silently becomes an exact 13.0 pin. 13.* means the same
    # thing as ^13.0 and survives the trip.
    composer create-project laravel/laravel api '13.*' --no-interaction
    if ($LASTEXITCODE -ne 0) { Die 'composer create-project failed' }

    Push-Location api
    try {
        Say 'Installing API scaffolding (Sanctum + routes/api.php)'
        php artisan install:api --no-interaction

        Say 'Installing Filament v5'
        composer require 'filament/filament:5.*' --no-interaction
        php artisan filament:install --panels --no-interaction

        Say 'Configuring environment'
        (Get-Content '.env.example') `
            -replace '^DB_DATABASE=.*', 'DB_DATABASE=tipper_truck' |
            Set-Content '.env.example' -Encoding UTF8

        if (-not (Test-Path '.env')) { Copy-Item '.env.example' '.env' }
        php artisan key:generate
    }
    finally { Pop-Location }
}

# ── Flutter app ──────────────────────────────────────────────────────────
if (Test-Path 'mobile\pubspec.yaml') {
    Say 'mobile\ already scaffolded — skipping'
} else {
    Say 'Creating Flutter app in mobile\'
    flutter create `
        --org $OrgId `
        --project-name tippertruck `
        --platforms android,ios `
        --description "Tipper truck sand ordering for Ghana's construction industry" `
        mobile
    if ($LASTEXITCODE -ne 0) { Die 'flutter create failed' }

    Push-Location mobile
    try {
        Say 'Adding dependencies'
        flutter pub add go_router provider dio flutter_secure_storage `
            shared_preferences connectivity_plus intl
        flutter pub add --dev mocktail
    }
    finally { Pop-Location }
}

# ── Place the working guides ─────────────────────────────────────────────
Say 'Placing CLAUDE.md guides'
if (Test-Path 'docs\backend-CLAUDE.md') { Move-Item -Force 'docs\backend-CLAUDE.md' 'api\CLAUDE.md' }
if (Test-Path 'docs\mobile-CLAUDE.md')  { Move-Item -Force 'docs\mobile-CLAUDE.md'  'mobile\CLAUDE.md' }
Remove-Item 'api\.gitkeep', 'mobile\.gitkeep' -ErrorAction SilentlyContinue
Note 'api\CLAUDE.md · mobile\CLAUDE.md · CLAUDE.md (root)'

# ── Git ──────────────────────────────────────────────────────────────────
if (Test-Path '.git') {
    Say 'Git repository already initialised — skipping init'
} else {
    Say 'Initialising repository'
    git init -q
    git branch -M main
}

# ── Sanity check: secrets must be ignored before anything is staged ──────
Say 'Checking for secrets'
git check-ignore -q 'api/.env'
if ($LASTEXITCODE -ne 0) { Die 'api\.env is NOT ignored. Fix .gitignore before committing.' }
Note 'api\.env is ignored'

git add -A
git diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
    Say 'Nothing to commit'
} else {
    $msg = @'
chore: scaffold monorepo with Laravel 13 API and Flutter app

- api/     Laravel 13 + Sanctum + Filament v5
- mobile/  Flutter 3.x with go_router, Provider, Dio
- docs/    build spec and frozen API contract
- CI       separate path-filtered workflows per side
'@
    git commit -q -m $msg
    Note 'committed'
}

if ($Remote) {
    Say "Pushing to $Remote"
    git remote get-url origin *> $null
    if ($LASTEXITCODE -ne 0) { git remote add origin $Remote }
    git push -u origin main
} else {
    Write-Host @'

Next:
  gh repo create tippertruck --public --source=. --remote=origin --push
  # or
  git remote add origin git@github.com:<you>/tippertruck.git
  git push -u origin main
'@ -ForegroundColor Cyan
}

Say 'Done. Start Claude Code on milestone M1 (docs/BUILD_SPEC.md section 6).'
