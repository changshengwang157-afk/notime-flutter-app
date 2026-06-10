# Reliable APK build on Windows (avoids asset file-lock errno 32).
# Staging copy is ON by default — raw `flutter build` often fails while Cursor has the project open.
# Usage:
#   .\scripts\build-apk.ps1 -ApiBase "https://heynotime.com" -UseMockData $false
#   .\scripts\build-apk.ps1 -Release -ApiBase "https://heynotime.com" -UseMockData $false
#   .\scripts\build-apk.ps1 -NoStagingCopy   # only if IDE/emulator are closed
param(
    [string]$ApiBase = "",
    [bool]$UseMockData = $false,
    [switch]$Release,
    [switch]$NoStagingCopy
)
$UseStagingCopy = -not $NoStagingCopy

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
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

function Stop-BuildProcesses {
    if (Test-Path "android\gradlew.bat") {
        Push-Location android
        & .\gradlew.bat --stop *> $null
        Pop-Location
    }
    foreach ($name in @("dart", "java")) {
        Get-Process $name -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Seconds 3
}

function Setup-BuildEnvironment {
    $tempDir = "E:\temp"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    $env:TEMP = $tempDir
    $env:TMP = $tempDir

    foreach ($path in @($ProjectRoot, "E:\flutter", $tempDir, "E:\dev")) {
        Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue
    }
}

function Refresh-AssetFiles {
    param([string]$Root)

    $assetsDir = Join-Path $Root "assets"
    if (-not (Test-Path $assetsDir)) { return }

    Write-Host "Refreshing asset files (breaks Windows file locks)..."
    Get-ChildItem -Path $assetsDir -Recurse -File | ForEach-Object {
        $path = $_.FullName
        for ($i = 1; $i -le 5; $i++) {
            try {
                $bytes = [System.IO.File]::ReadAllBytes($path)
                $temp = "$path.refresh"
                [System.IO.File]::WriteAllBytes($temp, $bytes)
                if (Test-Path $path) {
                    [System.IO.File]::Delete($path)
                }
                [System.IO.File]::Move($temp, $path)
                break
            } catch {
                if ($i -eq 5) { throw }
                Write-Host "  Retry asset $($_.Name) ($i/5)..."
                Start-Sleep -Seconds 2
            }
        }
    }
}

function Invoke-FlutterBuild {
    param([string]$WorkDir)

    Push-Location $WorkDir
    try {
        Stop-BuildProcesses
        Refresh-AssetFiles -Root $WorkDir

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
                Stop-BuildProcesses
                Refresh-AssetFiles -Root $WorkDir
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

function New-StagingCopy {
    $stamp = Get-Date -Format "yyyyMMddHHmmss"
    $stagingRoot = "E:\dev\notime-build-$stamp"
    New-Item -ItemType Directory -Path (Split-Path $stagingRoot) -Force | Out-Null

    Write-Host "Staging copy -> $stagingRoot"
    Stop-BuildProcesses

    robocopy $ProjectRoot $stagingRoot /MIR /XD build .dart_tool .git /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
    if ($LASTEXITCODE -ge 8) {
        Write-Host "robocopy failed with exit code $LASTEXITCODE"
        exit 1
    }

    Add-MpPreference -ExclusionPath $stagingRoot -ErrorAction SilentlyContinue
    Refresh-AssetFiles -Root $stagingRoot
    return , $stagingRoot
}

Setup-BuildEnvironment
Set-Location $ProjectRoot

if ($UseStagingCopy) {
    Write-Host "Staging copy build ($BuildMode) - avoids Cursor/IDE locks on project folder..."
    $stagingRoot = New-StagingCopy

    if (-not (Invoke-FlutterBuild -WorkDir $stagingRoot)) {
        Write-Host "Staging build failed. Staging folder kept at: $stagingRoot"
        exit 1
    }
    Finish-Build -WorkDir $stagingRoot
}

if (Invoke-FlutterBuild -WorkDir $ProjectRoot) {
    Finish-Build -WorkDir $ProjectRoot
}

Write-Host ""
Write-Host "Do NOT use raw 'flutter build apk' while Cursor has this project open."
Write-Host "Use this script instead:"
Write-Host "  .\scripts\build-apk.ps1 -ApiBase `"https://heynotime.com`" -UseMockData `$false"
Write-Host ""
Write-Host "Also close: emulator, flutter run, Android Studio, PNG preview tabs."
exit 1
