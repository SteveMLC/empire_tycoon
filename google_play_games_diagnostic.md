# Google Play Games Services Diagnostic Checklist

## Current Configuration ✅
- **Package Name**: `com.go7studio.empire_tycoon`
- **App Name**: "Empire Tycoon"  
- **Google Play Games App ID**: `400590136347`
- **Google Cloud Project**: `empiretycoon-ab85c`
- **SHA-1 Fingerprint**: `CE:7C:41:57:2E:9D:22:31:90:4C:C9:FC:EA:2D:7F:73:A1:78:51:68` (✅ MATCHES)

## Diagnostic Steps

### 1. Check Google Cloud Console APIs
Go to: https://console.cloud.google.com/apis/library?project=empiretycoon-ab85c

**Required APIs to ENABLE**:
- [ ] Google Play Games Services API
- [ ] Google Play Developer API  
- [ ] Android Device Verification API (optional but recommended)

### 2. Check OAuth Consent Screen
Go to: https://console.cloud.google.com/apis/credentials/consent?project=empiretycoon-ab85c

**Verify**:
- [ ] Publishing status: "In production" OR "Testing" 
- [ ] Your email added as test user (if in Testing mode)
- [ ] Required scopes configured

### 3. Set Up Play Games Services in Google Play Console
Go to: https://play.google.com/console/

Navigate to: **Grow → Play Games Services → Setup and management → Configuration**

**Action Required**:
- [ ] Click "Set up Play Games Services" (if not done)
- [ ] Choose "Yes, my game already uses Google APIs"
- [ ] Select project: `empiretycoon-ab85c`
- [ ] Add Android app with package: `com.go7studio.empire_tycoon`

### 4. Add Test Users
Go to: **Grow → Play Games Services → Setup and management → Testers**

**Action Required**:
- [ ] Click "Add testers"
- [ ] Add your Google account email
- [ ] Save configuration

### 5. Test Authentication
After completing above steps:
- [ ] Clean build app: `flutter clean && flutter pub get`
- [ ] Test sign-in functionality
- [ ] Check debug logs for success

## Expected Result After Fix
```
🎮 AuthService: Starting sign-in process
🎮 AuthService: Calling GameAuth.signIn()
✅ AuthService: User signed in - ID: G:1234567890, Name: [Your Name]
```

## If Still Failing
1. Wait 15-30 minutes for changes to propagate
2. Ensure you're testing with the same Google account added as tester
3. Check if Google Play Games app is installed and up to date on test device
4. Verify OAuth consent screen is published and accessible 