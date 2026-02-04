# Run Empire Tycoon on Android device (debug)
# Usage: .\run_android_debug.ps1
# Ensure: Flutter on PATH (or installed at C:\src\flutter), Android SDK installed, device connected with USB debugging on

$flutterBin = "C:\src\flutter\bin"
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    $env:PATH = "$flutterBin;$env:PATH"
}

Set-Location $PSScriptRoot
Write-Host "Getting dependencies..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "Running on Android (debug)..." -ForegroundColor Cyan
flutter run -d android
