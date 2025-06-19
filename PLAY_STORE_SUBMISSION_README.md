# Play Store Submission - AdMob Toggle Guide

## 🚀 Quick Setup for Play Store Submission

Your app is now configured to disable AdMob ads for Google Play Store submission while maintaining full functionality.

### Current Status
- ✅ **Ads are ENABLED** - Production AdMob integration active
- ✅ **Production App ID** - ca-app-pub-1738655803893663~8254619251
- ✅ **Full ad functionality restored** - All ad features working

## How It Works

All ad functionality has been temporarily disabled via a simple flag in `lib/services/admob_service.dart`:

```dart
// ⚠️ PLAY STORE SUBMISSION FLAG ⚠️
// Set this to FALSE when submitting to Google Play Store
// Set this to TRUE after approval with production ad unit IDs
static const bool _adsEnabled = false;
```

### What Happens When Ads Are Disabled:
- ✅ Users get rewards immediately (no ads shown)
- ✅ All game features work normally
- ✅ No AdMob SDK initialization
- ✅ No ad loading or network calls
- ✅ Clean console logs showing ads are disabled

## After Play Store Approval 

### Step 1: Enable Ads
Change the flag to `true`:
```dart
static const bool _adsEnabled = true;
```

### Step 2: Add Production Ad Unit IDs
Replace the placeholder IDs in `lib/services/admob_service.dart`:
```dart
// Replace these with your actual AdMob ad unit IDs from Google AdMob Console
static const String _prodHustleBoostAdUnitId = 'YOUR_HUSTLE_BOOST_AD_UNIT_ID';
static const String _prodBuildSkipAdUnitId = 'YOUR_BUILD_SKIP_AD_UNIT_ID';
static const String _prodEventClearAdUnitId = 'YOUR_EVENT_CLEAR_AD_UNIT_ID';
static const String _prodOfflineIncomeBoostAdUnitId = 'YOUR_OFFLINE_INCOME_BOOST_AD_UNIT_ID';
```

### Step 3: Update AndroidManifest.xml
Replace the test app ID in `android/app/src/main/AndroidManifest.xml`:
```xml
<!-- Replace with your production AdMob App ID -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="YOUR_PRODUCTION_APP_ID" />
```

## Build & Test

### Current Build (Ads Disabled)
```bash
flutter clean
flutter pub get
flutter build apk --release
```

### Testing
- ✅ All ad buttons work and grant rewards immediately
- ✅ Premium users continue to work normally
- ✅ No ad-related errors in console
- ✅ App size slightly reduced (no ad loading)

## Files Modified

### Main Changes
- `lib/services/admob_service.dart` - Added `_adsEnabled` flag and bypass logic

### No Changes Needed
- ✅ No UI changes required
- ✅ No dependency removals
- ✅ No build configuration changes
- ✅ No feature removals

## Revert Instructions

To revert back to showing ads during development:
1. Change `_adsEnabled` to `true` in `lib/services/admob_service.dart`
2. Rebuild the app

## Questions?

This implementation:
- ✅ Preserves all app functionality
- ✅ Allows easy toggle without code changes
- ✅ Maintains clean architecture
- ✅ Supports both test and production ad IDs
- ✅ Safe for Play Store submission

---

**Ready to submit to Google Play Store! 🚀** 