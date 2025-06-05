# AdMob Production Deployment Guide

## Overview
This document outlines the exact locations where test AdMob IDs need to be replaced with production IDs when deploying Empire Tycoon to production.

**⚠️ CRITICAL: All test IDs MUST be replaced before production release**

## Pre-Production Setup Required

### 1. AdMob Console Setup
Before making code changes, you must complete these steps in Google AdMob Console:

1. **Create Production AdMob App**
   - Log into [AdMob Console](https://admob.google.com)
   - Create new app for "Empire Tycoon"
   - Note the Production App ID (format: `ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX`)

2. **Create Ad Units**
   You need to create **4 Rewarded Ad Units**:
   - **Hustle Boost Ad Unit** (for 10x earnings boost)
   - **Build Skip Ad Unit** (for upgrade time reduction)
   - **Event Clear Ad Unit** (for instant event resolution)
   - **Offline Income Boost Ad Unit** (for 2x offline income boost)
   
   Each will generate an Ad Unit ID (format: `ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX`)

## Code Changes Required

### File 1: `android/app/src/main/AndroidManifest.xml`

**Location:** Lines 19-22
```xml
<!-- CURRENT (TEST): -->
<!-- TEST APP ID: ca-app-pub-1738655803893663~7413442778 -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-1738655803893663~7413442778" />

<!-- REPLACE WITH: -->
<!-- PRODUCTION APP ID: YOUR_PRODUCTION_APP_ID -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="YOUR_PRODUCTION_APP_ID" />
```

**Action Required:**
- Replace `ca-app-pub-1738655803893663~7413442778` with your production App ID
- Update the comment to reflect production status

### File 2: `lib/services/admob_service.dart`

**Location:** Lines 22-25
```dart
// CURRENT (TEST):
static const String _prodHustleBoostAdUnitId = 'ca-app-pub-1738655803893663/HUSTLE_BOOST_AD_UNIT';
static const String _prodBuildSkipAdUnitId = 'ca-app-pub-1738655803893663/BUILD_SKIP_AD_UNIT';
static const String _prodEventClearAdUnitId = 'ca-app-pub-1738655803893663/EVENT_CLEAR_AD_UNIT';
static const String _prodOfflineIncomeBoostAdUnitId = 'ca-app-pub-1738655803893663/OFFLINE_INCOME_BOOST_AD_UNIT';

// REPLACE WITH:
static const String _prodHustleBoostAdUnitId = 'YOUR_HUSTLE_BOOST_AD_UNIT_ID';
static const String _prodBuildSkipAdUnitId = 'YOUR_BUILD_SKIP_AD_UNIT_ID';
static const String _prodEventClearAdUnitId = 'YOUR_EVENT_CLEAR_AD_UNIT_ID';
static const String _prodOfflineIncomeBoostAdUnitId = 'YOUR_OFFLINE_INCOME_BOOST_AD_UNIT_ID';
```

**Action Required:**
- Replace `YOUR_HUSTLE_BOOST_AD_UNIT_ID` with the actual Hustle Boost ad unit ID from AdMob
- Replace `YOUR_BUILD_SKIP_AD_UNIT_ID` with the actual Build Skip ad unit ID from AdMob  
- Replace `YOUR_EVENT_CLEAR_AD_UNIT_ID` with the actual Event Clear ad unit ID from AdMob
- Replace `YOUR_OFFLINE_INCOME_BOOST_AD_UNIT_ID` with the actual Offline Income Boost ad unit ID from AdMob

### File 3: Debug Mode Configuration (Optional)

**Location:** Line 18 in `lib/services/admob_service.dart`
```dart
// CURRENT (Google's Test ID):
static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
```

**Action:** Leave unchanged - this is Google's official test ad unit ID and is used only in debug mode.

## Production Checklist

### Before Release:
- [ ] Created production AdMob app in console
- [ ] Created 4 rewarded ad units in AdMob console
- [ ] Updated `AndroidManifest.xml` with production App ID
- [ ] Updated `AdMobService` with 4 production ad unit IDs
- [ ] Verified app builds successfully with new IDs
- [ ] Tested ads work in release mode with production IDs

### Testing:
- [ ] Build app in release mode: `flutter build apk --release`
- [ ] Test each ad placement:
  - [ ] Hustle Boost ads load and show correctly
  - [ ] Build Skip ads load and show correctly  
  - [ ] Event Clear ads load and show correctly
  - [ ] Offline Income Boost ads load and show correctly
- [ ] Verify premium users can skip ads
- [ ] Test ad failure scenarios

### Post-Release:
- [ ] Monitor AdMob console for ad performance
- [ ] Check app logs for any ad-related errors
- [ ] Monitor user feedback for ad experience

## File Summary

**Files to modify:**
1. `android/app/src/main/AndroidManifest.xml` - App ID replacement
2. `lib/services/admob_service.dart` - 4 ad unit ID replacements

**Total changes:** 5 ID replacements across 2 files

## ID Format Reference

| Type | Format | Example |
|------|--------|---------|
| App ID | `ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX` | `ca-app-pub-1234567890123456~1234567890` |
| Ad Unit ID | `ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX` | `ca-app-pub-1234567890123456/1234567890` |

## Troubleshooting

### Common Issues:
1. **Ads not loading**: Verify ad unit IDs are correct and active in AdMob console
2. **App crashes**: Check that App ID in AndroidManifest.xml is correct
3. **Revenue not tracking**: Ensure AdMob app is properly linked to your account
4. **MinSdkVersion compatibility error**: Google Mobile Ads SDK requires minSdk 23 minimum

### MinSdkVersion Fix:
If you encounter the error:
```
uses-sdk:minSdkVersion 21 cannot be smaller than version 23 declared in library [com.google.android.gms:play-services-ads:24.2.0]
```

**Solution:** Update `android/app/build.gradle.kts`:
```kotlin
defaultConfig {
    // Change from: minSdk = flutter.minSdkVersion (21)
    // To: minSdk = 23 (required by Google Mobile Ads SDK)
    minSdk = 23
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
}
```

**Impact:** This change raises the minimum Android version from API 21 (Android 5.0) to API 23 (Android 6.0). Android 6.0+ represents 99.8%+ of active Android devices, so this is a safe change.

### Kotlin Version Compatibility Fix:
If you encounter the error:
```
Kotlin binary version 2.1.0, expected version is 1.8.0
```

**Solution:** Update `android/settings.gradle.kts`:
```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.0" apply false
    // Change from: version "1.8.22"
    // To: version "2.1.0" (required by Google Mobile Ads SDK 24.2.0)
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}
```

**Impact:** Google Mobile Ads SDK 24.2.0 requires Kotlin 2.1.0 minimum for compatibility.

### Java Version Update:
If you see warnings about Java 8 being obsolete:
```
warning: [options] source value 8 is obsolete and will be removed in a future release
```

**Solution:** Update `android/app/build.gradle.kts`:
```kotlin
compileOptions {
    // Change from: JavaVersion.VERSION_1_8
    // To: JavaVersion.VERSION_11 (modern standard)
    sourceCompatibility = JavaVersion.VERSION_11
    targetCompatibility = JavaVersion.VERSION_11
}

kotlinOptions {
    // Change from: jvmTarget = "1.8"
    // To: jvmTarget = "11" (match Java version)
    jvmTarget = "11"
}
```

**Impact:** Updates from obsolete Java 8 to modern Java 11 standard, eliminates deprecation warnings.

### Debug Commands:
```bash
# Test build with production IDs
flutter build apk --release

# Check for compilation errors
flutter analyze

# View logs during testing
flutter logs
```

## Important Notes

- **Never commit test IDs to production branch**
- **Test thoroughly with production IDs before release**
- **Keep a backup of all production IDs in secure location**
- **AdMob console changes can take up to 1 hour to propagate**

---

**Last Updated:** [Current Date]
**Author:** Development Team
**Status:** Ready for Production Deployment 