# Reliable debug APK build on Windows (avoids asset file-lock errno 32).
# Usage: .\scripts\build-debug-apk.ps1
# Tip: close Nox / stop "flutter run" before building.

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

Write-Host "Stopping Gradle daemons..."
if (Test-Path "android\gradlew.bat") {
    Push-Location android
    & .\gradlew.bat --stop 2>$null
    Pop-Location
}

Write-Host "Cleaning..."
flutter clean | Out-Null
if (Test-Path "build") {
    Remove-Item -Recurse -Force "build" -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

flutter pub get | Out-Null

$maxAttempts = 3
for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
    Write-Host "Build attempt $attempt of $maxAttempts..."
    flutter build apk --debug
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "OK: build\app\outputs\flutter-apk\app-debug.apk"
        exit 0
    }
    if ($attempt -lt $maxAttempts) {
        Write-Host "Build failed (often a file lock). Waiting 5s..."
        Start-Sleep -Seconds 5
        if (Test-Path "build\app\intermediates\flutter") {
            Remove-Item -Recurse -Force "build\app\intermediates\flutter" -ErrorAction SilentlyContinue
        }
    }
}

Write-Host ""
Write-Host "Build still failing. Try:"
Write-Host "  1. Close Nox emulator and any 'flutter run' terminal"
Write-Host "  2. Close PNG previews in the editor (assets/images/*.png)"
Write-Host "  3. Add a Windows Defender exclusion for this project folder"
Write-Host "  4. Run this script again"
exit 1
