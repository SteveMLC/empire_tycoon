# Empire Tycoon – Firebase Analytics DebugView Helper
# Run this script while your Android device is connected via USB.
# Package: com.go7studio.empire_tycoon

$pkg = "com.go7studio.empire_tycoon"

Write-Host "Firebase Analytics DebugView" -ForegroundColor Cyan
Write-Host ""

$choice = Read-Host "1) Enable DebugView  2) Disable DebugView  3) Get SHA-1 fingerprints  [1/2/3]"

switch ($choice) {
    "1" {
        Write-Host "Enabling DebugView for $pkg ..." -ForegroundColor Yellow
        adb shell setprop debug.firebase.analytics.app $pkg
        Write-Host "Done. Open Firebase Console > Analytics > DebugView and use your app." -ForegroundColor Green
    }
    "2" {
        Write-Host "Disabling DebugView ..." -ForegroundColor Yellow
        adb shell setprop debug.firebase.analytics.app .none.
        Write-Host "Done." -ForegroundColor Green
    }
    "3" {
        Write-Host "Running signing report ..." -ForegroundColor Yellow
        Set-Location -Path (Join-Path $PSScriptRoot "android")
        .\gradlew signingReport
        Set-Location $PSScriptRoot
    }
    default {
        Write-Host "Invalid choice." -ForegroundColor Red
    }
}
