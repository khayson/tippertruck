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
    [string] $ApiUrl = 'http://10.0.2.2:8000/api/v1',

    # Physical phone on the same Wi-Fi: detect this PC's LAN IPv4 and pass it to Flutter.
    [switch] $Lan
)

$ErrorActionPreference = 'Stop'

function Invoke-In {
    param([string] $Dir, [scriptblock] $Block)
    Push-Location $Dir
    try { & $Block } finally { Pop-Location }
}

function Get-LanIPv4 {
    $candidates = @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object {
            $_.IPAddress -notmatch '^(127\.|169\.254\.)' -and
            $_.PrefixOrigin -in @('Dhcp', 'Manual')
        })
    $preferred = $candidates | Where-Object { $_.IPAddress -like '192.168.*' } | Select-Object -First 1
    if ($preferred) { return $preferred.IPAddress }
    $first = $candidates | Select-Object -First 1
    if ($first) { return $first.IPAddress }
    throw 'No LAN IPv4 found. Connect the laptop to Wi-Fi (same network as the phone).'
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
On a physical phone (same Wi-Fi, never the router/gateway .1):
  .\tasks.ps1 api
  .\tasks.ps1 mobile -Lan
Or pass the laptop IPv4 yourself:
  .\tasks.ps1 mobile -ApiUrl http://192.168.0.156:8000/api/v1
Sanity-check from the phone browser: http://<laptop-ip>:8000/up
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
        try {
            $LanIp = Get-LanIPv4
            Write-Host "Laravel is bound to every interface. Do not open http://0.0.0.0:8000 in a browser." -ForegroundColor Yellow
            Write-Host "This PC api test point:             http://127.0.0.1:8000/up"
            Write-Host "This PC api admin:                  http://127.0.0.1:8000/admin"
            Write-Host "Phone (same Wi-Fi):                 http://${LanIp}:8000/up"
            Write-Host "Flutter (physical):                 .\tasks.ps1 mobile -Lan"
            Write-Host "If the phone cannot open that URL, allow TCP 8000 in Windows Firewall."
        } catch {
            Write-Host $_ -ForegroundColor Yellow
        }
        Invoke-In 'api' { php artisan serve --host 0.0.0.0 --port 8000 }
    }

    'mobile' {
        if ($Lan) {
            $LanIp = Get-LanIPv4
            $ApiUrl = "http://${LanIp}:8000/api/v1"
        }
        Write-Host "API_BASE_URL=$ApiUrl" -ForegroundColor Green
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
        if ($Lan) {
            $LanIp = Get-LanIPv4
            $ApiUrl = "http://${LanIp}:8000/api/v1"
        }
        Write-Host "API_BASE_URL=$ApiUrl" -ForegroundColor Green
        Invoke-In 'mobile' {
            flutter build apk --release --dart-define=API_BASE_URL=$ApiUrl
            Write-Host "`nAPK: mobile\build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
        }
    }
}
