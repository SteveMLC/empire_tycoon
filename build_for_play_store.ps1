# Empire Tycoon - Build for Google Play Store
# Run this script from the project root to prepare and build the release AAB

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$androidDir = Join-Path $projectRoot "android"
$keyProps = Join-Path $androidDir "key.properties"

Write-Host ""
Write-Host "=== Empire Tycoon - Google Play Build ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check key.properties
if (-not (Test-Path $keyProps)) {
    Write-Host "REQUIRED: key.properties not found." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Create it before building:" -ForegroundColor White
    Write-Host "  1. Copy: android\key.properties.example  ->  android\key.properties" -ForegroundColor Gray
    Write-Host "  2. Edit android\key.properties with your keystore password, key password, alias, and store file path" -ForegroundColor Gray
    Write-Host ""
    Write-Host "If you don't have a keystore yet, create one:" -ForegroundColor White
    Write-Host "  keytool -genkey -v -keystore android\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload" -ForegroundColor Gray
    Write-Host ""
    Write-Host "See GOOGLE_PLAY_PUBLISH_GUIDE.md for full instructions." -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

Write-Host "[OK] key.properties found" -ForegroundColor Green

# Step 2: Clean and build
Write-Host ""
Write-Host "Cleaning..." -ForegroundColor Cyan
Set-Location $projectRoot
flutter clean

Write-Host ""
Write-Host "Getting dependencies..." -ForegroundColor Cyan
flutter pub get

Write-Host ""
Write-Host "Building release AAB..." -ForegroundColor Cyan
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
# Use Gradle directly to avoid Flutter's "failed to strip debug symbols" step on some Windows setups
Set-Location $androidDir
& .\gradlew bundleRelease
$buildExit = $LASTEXITCODE
Set-Location $projectRoot

if ($buildExit -eq 0) {
    $aabPath = Join-Path $projectRoot "build\app\outputs\bundle\release\app-release.aab"
    Write-Host ""
    Write-Host "=== BUILD SUCCESS ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "AAB location: $aabPath" -ForegroundColor White
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Go to https://play.google.com/console/" -ForegroundColor Gray
    Write-Host "  2. Select Empire Tycoon (or create new app)" -ForegroundColor Gray
    Write-Host "  3. Production -> Create new release" -ForegroundColor Gray
    Write-Host "  4. Upload the AAB file" -ForegroundColor Gray
    Write-Host ""
    Write-Host "See GOOGLE_PLAY_PUBLISH_GUIDE.md for full submission steps." -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "Build failed. Check the output above." -ForegroundColor Red
    exit 1
}
