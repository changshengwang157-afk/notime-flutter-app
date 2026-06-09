# Reliable APK build on Windows (avoids asset file-lock errno 32).
# Usage:
#   .\scripts\build-apk.ps1 -UseStagingCopy -ApiBase "https://heynotime.com" -UseMockData $false
#   .\scripts\build-apk.ps1 -UseStagingCopy -Release -ApiBase "https://heynotime.com" -UseMockData $false
param(
    [string]$ApiBase = "",
    [bool]$UseMockData = $false,
    [switch]$Release,
    [switch]$UseStagingCopy
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$StagingRoot = "C:\dev\notime-app-build"
$BuildMode = if ($Release) { "release" } else { "debug" }
$ApkName = if ($Release) { "app-release.apk" } else { "app-debug.apk" }

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

        Write-Host "Cleaning build caches ($BuildMode) in $WorkDir ..."
        flutter clean | Out-Null
        Remove-TreeRetry "build"
        Remove-TreeRetry ".dart_tool\flutter_build"
        Start-Sleep -Seconds 3

        flutter pub get | Out-Null

        $dartDefines = @("--dart-define=USE_MOCK_DATA=$UseMockData")
        if ($ApiBase) {
            $dartDefines += "--dart-define=NOTIME_API_BASE=$ApiBase"
        }

        $buildArgs = @("build", "apk")
        if ($Release) { $buildArgs += "--release" } else { $buildArgs += "--debug" }
        $buildArgs += $dartDefines

        $maxAttempts = 3
        for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
            Write-Host "Build attempt $attempt of $maxAttempts ($BuildMode)..."
            & flutter @buildArgs
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

function Finish-Build {
    param([string]$WorkDir)

    $apk = Join-Path $WorkDir "build\app\outputs\flutter-apk\$ApkName"
    if (-not (Test-Path $apk)) {
        Write-Host "Expected APK not found: $apk"
        exit 1
    }

    if ($WorkDir -ne $ProjectRoot) {
        $destDir = Join-Path $ProjectRoot "build\app\outputs\flutter-apk"
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        Copy-Item -Force $apk (Join-Path $destDir $ApkName)
        $apk = Join-Path $destDir $ApkName
    }

    Write-Host ""
    Write-Host "OK: $apk"
    exit 0
}

if ($UseStagingCopy) {
    Write-Host "Staging copy build ($BuildMode) — avoids Cursor/IDE locks on E: project folder..."
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
    Finish-Build -WorkDir $StagingRoot
}

Set-Location $ProjectRoot
Add-MpPreference -ExclusionPath $ProjectRoot -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionPath "E:\flutter" -ErrorAction SilentlyContinue

if (Invoke-FlutterBuild -WorkDir $ProjectRoot) {
    Finish-Build -WorkDir $ProjectRoot
}

Write-Host ""
Write-Host "Build still failing (errno 32 = file locked). Use staging copy:"
Write-Host "  .\scripts\build-apk.ps1 -UseStagingCopy -Release -ApiBase `"https://heynotime.com`" -UseMockData `$false"
Write-Host ""
Write-Host "Before building: close emulator, flutter run, Android Studio, PNG tabs in Cursor."
exit 1
