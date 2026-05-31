# Reliable debug APK build on Windows (avoids asset file-lock errno 32).
# Usage:
#   .\scripts\build-debug-apk.ps1
#   .\scripts\build-debug-apk.ps1 -ApiBase "https://heynotime.com" -UseMockData $false
#   .\scripts\build-debug-apk.ps1 -UseStagingCopy   # recommended when E: drive builds fail with errno 32
param(
    [string]$ApiBase = "",
    [bool]$UseMockData = $false,
    [switch]$UseStagingCopy
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$StagingRoot = "C:\dev\notime-app-build"

function Remove-TreeRetry {
    param([string]$Path, [int]$Retries = 5)
    if (-not (Test-Path $Path)) { return }
    for ($i = 1; $i -le $Retries; $i++) {
        try {
            Remove-Item -Recurse -Force $Path -ErrorAction Stop
            return
        } catch {
            if ($i -eq $Retries) { throw }
            Write-Host "  Could not delete $Path (attempt $i/$Retries). Waiting 3s..."
            Start-Sleep -Seconds 3
        }
    }
}

function Stop-Gradle {
    if (Test-Path "android\gradlew.bat") {
        Push-Location android
        & .\gradlew.bat --stop 2>$null
        Pop-Location
    }
    Get-Process dart -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

function Invoke-FlutterBuild {
    param([string]$WorkDir)

    Push-Location $WorkDir
    try {
        Stop-Gradle

        Write-Host "Cleaning build caches in $WorkDir ..."
        flutter clean | Out-Null
        Remove-TreeRetry "build"
        Remove-TreeRetry ".dart_tool\flutter_build"
        Start-Sleep -Seconds 3

        flutter pub get | Out-Null

        $dartDefines = @("--dart-define=USE_MOCK_DATA=$UseMockData")
        if ($ApiBase) {
            $dartDefines += "--dart-define=NOTIME_API_BASE=$ApiBase"
        }

        $maxAttempts = 3
        for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
            Write-Host "Build attempt $attempt of $maxAttempts..."
            flutter build apk --debug @dartDefines
            if ($LASTEXITCODE -eq 0) {
                return $true
            }
            if ($attempt -lt $maxAttempts) {
                Write-Host "Build failed (often a file lock). Cleaning intermediates..."
                Stop-Gradle
                Remove-TreeRetry "build\app\intermediates\flutter"
                Remove-TreeRetry ".dart_tool\flutter_build"
                Start-Sleep -Seconds 5
            }
        }
        return $false
    } finally {
        Pop-Location
    }
}

if ($UseStagingCopy) {
    Write-Host "Staging copy build (avoids Cursor/IDE locks on E: project folder)..."
    New-Item -ItemType Directory -Path (Split-Path $StagingRoot) -Force | Out-Null
    robocopy $ProjectRoot $StagingRoot /MIR /XD build .dart_tool .git /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
    if ($LASTEXITCODE -ge 8) {
        Write-Host "robocopy failed with exit code $LASTEXITCODE"
        exit 1
    }

    Add-MpPreference -ExclusionPath $StagingRoot -ErrorAction SilentlyContinue

    if (-not (Invoke-FlutterBuild -WorkDir $StagingRoot)) {
        Write-Host "Staging build failed."
        exit 1
    }

    $apk = Join-Path $StagingRoot "build\app\outputs\flutter-apk\app-debug.apk"
    $destDir = Join-Path $ProjectRoot "build\app\outputs\flutter-apk"
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    Copy-Item -Force $apk (Join-Path $destDir "app-debug.apk")
    Write-Host ""
    Write-Host "OK: $ProjectRoot\build\app\outputs\flutter-apk\app-debug.apk"
    exit 0
}

Set-Location $ProjectRoot
Add-MpPreference -ExclusionPath $ProjectRoot -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionPath "E:\flutter" -ErrorAction SilentlyContinue

if (Invoke-FlutterBuild -WorkDir $ProjectRoot) {
    Write-Host ""
    Write-Host "OK: build\app\outputs\flutter-apk\app-debug.apk"
    exit 0
}

Write-Host ""
Write-Host "Build still failing. Try staging copy (works when IDE locks E: drive files):"
Write-Host "  .\scripts\build-debug-apk.ps1 -UseStagingCopy -ApiBase `"https://heynotime.com`" -UseMockData `$false"
Write-Host ""
Write-Host "Also:"
Write-Host "  1. Close Nox/emulator and any 'flutter run' terminal"
Write-Host "  2. Close Android Studio and PNG tabs in Cursor"
Write-Host "  3. Windows Security -> Exclusions -> add project folder + E:\flutter"
exit 1
