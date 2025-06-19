# 🧪 Production Ad Testing Guide - Empire Tycoon

## 🎯 **Testing Production Ads Locally**

You can test production ads WITHOUT submitting to Play Store using these methods:

## **Method 1: Local Release APK (Recommended)**

### Step 1: Build Release APK
```bash
flutter build apk --release
```
✅ **Built:** `build\app\outputs\flutter-apk\app-release.apk` (120.3MB)

### Step 2: Install on Test Device
1. Enable "Unknown Sources" in Android Settings → Security
2. Transfer APK to your device:
   - USB file transfer
   - Email attachment
   - Google Drive/Dropbox
3. Install the APK directly
4. **Result:** Shows REAL production ads

### Step 3: Test All 4 Ad Types
- **HustleBoost**: Hustle screen → "Start Ad Boost"
- **BuildingUpgradeBoost**: Start upgrade → "Speed Up"
- **EventAdSkip**: Wait for event → "Watch AD"
- **OfflineIncomeBoost**: Return offline → "Watch Ad"

---

## **Method 2: Test Device Registration**

### Step 1: Get Your Device ID
Add this code temporarily to get your device's advertising ID:

```dart
// Add to main.dart temporarily for testing
import 'package:google_mobile_ads/google_mobile_ads.dart';

// In initState or main():
MobileAds.instance.getRequestConfiguration().then((config) {
  print("🎯 Test Device ID: ${config.testDeviceIds}");
});
```

### Step 2: Add Device ID to AdMob Service
Update `lib/services/admob_service.dart`:

```dart
// Test device IDs for development
static const List<String> _testDeviceIds = [
  'YOUR_ACTUAL_DEVICE_ID_HERE', // Replace with ID from Step 1
  // Add more test device IDs as needed
];
```

### Step 3: Build and Test
- Device will show test ads even with production ad unit IDs
- Useful for development without affecting production metrics

---

## **Method 3: Debug Build with Production IDs**

### Temporarily Switch to Production in Debug Mode
In `lib/services/admob_service.dart`, modify the `_getAdUnitId` method:

```dart
String _getAdUnitId(AdType adType) {
  // Temporarily use production IDs even in debug mode
  // if (kDebugMode) {
  //   return _testRewardedAdUnitId;
  // }
  
  switch (adType) {
    case AdType.hustleBoost:
      return _prodHustleBoostAdUnitId;
    // ... rest of production IDs
  }
}
```

**⚠️ Remember to revert this before final submission!**

---

## **Method 4: Internal Testing Track**

### Use Google Play Console Internal Testing
1. Upload APK to Play Console
2. Add yourself as internal tester
3. Install via Play Store internal testing link
4. Test with real production environment

---

## **🔍 Testing Checklist**

### Before Testing:
- [ ] AdMob app is approved and active
- [ ] All 4 ad units created in AdMob console
- [ ] App uses production App ID: `ca-app-pub-1738655803893663~8254619251`
- [ ] Release APK built successfully

### During Testing:
- [ ] HustleBoost ad loads and shows
- [ ] BuildingUpgradeBoost ad loads and shows  
- [ ] EventAdSkip ad loads and shows
- [ ] OfflineIncomeBoost ad loads and shows
- [ ] Rewards are granted correctly after watching ads
- [ ] Premium users can skip ads successfully

### Ad Loading Issues:
If ads don't load in production:
1. **Check AdMob Console**: Ensure ad units are active
2. **Wait 24-48 hours**: New ad units may take time to activate
3. **Check logs**: Look for AdMob error messages in console
4. **Verify IDs**: Double-check all ad unit IDs are correct

---

## **🚨 Important Notes**

### Production Ad Guidelines:
- **Don't click your own ads repeatedly** - This can get your AdMob account suspended
- **Test functionality, not revenue** - Use test mode for extensive testing
- **Production testing should be minimal** - Just verify ads load and work

### AdMob Account Safety:
- Use test device IDs for development
- Only test production ads briefly to verify they work
- Never try to generate fake revenue

### Debugging Tips:
- Check `flutter logs` for AdMob error messages
- Ensure internet connection is stable
- Test on multiple devices if possible
- Check AdMob account for any warnings or issues

---

## **✅ Recommended Testing Flow**

1. **Development**: Use Method 2 (Test Device Registration)
2. **Pre-Production**: Use Method 1 (Local Release APK)
3. **Final Verification**: Use Method 4 (Internal Testing Track)

This ensures thorough testing without risking your AdMob account or affecting production metrics. 