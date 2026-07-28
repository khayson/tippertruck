#Requires -Version 5.1
<#
.SYNOPSIS
    Task runner for the Tipper Truck monorepo (Windows replacement for make).

.EXAMPLE
    .\tasks.ps1 setup
    .\tasks.ps1 api
    .\tasks.ps1 mobile
    .\tasks.ps1 test
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('help', 'setup', 'api', 'mobile', 'test', 'lint', 'fresh', 'apk')]
    [string] $Task = 'help',

    # Override the API the app talks to, e.g. -ApiUrl https://staging.example.com/api/v1
    [string] $ApiUrl = 'http://10.0.2.2:8000/api/v1'
)

$ErrorActionPreference = 'Stop'

function Invoke-In {
    param([string] $Dir, [scriptblock] $Block)
    Push-Location $Dir
    try { & $Block } finally { Pop-Location }
}

switch ($Task) {

    'help' {
        Write-Host @'
Tasks:
  setup    Install dependencies for both sides
  api      Serve the Laravel API on :8000
  mobile   Run the Flutter app on a connected device or emulator
  test     Run Pest + Flutter tests
  lint     Run Pint + dart format + flutter analyze
  fresh    Rebuild and reseed the database (destroys local data)
  apk      Build a release APK  (-ApiUrl https://your-api/api/v1)

Note: 10.0.2.2 is how the Android emulator reaches this machine.
On a physical device pass your LAN IP:
  .\tasks.ps1 mobile -ApiUrl http://192.168.1.20:8000/api/v1
'@
    }

    'setup' {
        Invoke-In 'api' {
            composer install
            if (-not (Test-Path '.env')) { Copy-Item '.env.example' '.env' }
            php artisan key:generate
        }
        Invoke-In 'mobile' { flutter pub get }
    }

    'api' {
        # --host 0.0.0.0 so a physical phone on the same Wi-Fi can reach it
        Invoke-In 'api' { php artisan serve --host 0.0.0.0 --port 8000 }
    }

    'mobile' {
        Invoke-In 'mobile' { flutter run --dart-define=API_BASE_URL=$ApiUrl }
    }

    'test' {
        Invoke-In 'api'    { php artisan test }
        Invoke-In 'mobile' { flutter test }
    }

    'lint' {
        Invoke-In 'api'    { .\vendor\bin\pint }
        Invoke-In 'mobile' { dart format .; flutter analyze }
    }

    'fresh' {
        Write-Host 'This destroys all local data in tipper_truck.' -ForegroundColor Yellow
        if ((Read-Host 'Continue? (y/N)') -ne 'y') { return }
        Invoke-In 'api' { php artisan migrate:fresh --seed }
    }

    'apk' {
        Invoke-In 'mobile' {
            flutter build apk --release --dart-define=API_BASE_URL=$ApiUrl
            Write-Host "`nAPK: mobile\build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
        }
    }
}
