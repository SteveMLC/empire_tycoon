# Firebase & Google Sign-In Setup Guide

This guide addresses common "gotchas" when Firebase Analytics shows "No data" and Google Sign-In fails (e.g., error 12500 / Developer Error).

---

## 1. SHA-1 Fingerprints (Critical for Google Sign-In)

Google Sign-In requires your app's SHA-1 certificate fingerprint in Firebase. You need **both** debug and release fingerprints.

### Get SHA-1 for Debug Build

**Option A – Gradle (recommended)**  
In the project root, run:

```bash
cd android && ./gradlew signingReport
```

Or on Windows (PowerShell):

```powershell
cd android; .\gradlew signingReport
```

In the output, find the **SHA-1** under `Variant: debug` (or similar). It looks like:
`AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD`.

**Option B – Android Studio**  
1. Open **Gradle** tab (right side)  
2. **app → Tasks → android → signingReport**  
3. Double-click to run  
4. Copy the SHA-1 from the **Run** output

### Get SHA-1 for Release Build

Your release build uses `key.properties` and a keystore file.

**Using keytool** (replace paths with yours):

```bash
keytool -list -v -keystore C:\path\to\your\upload-keystore.jks -alias upload
```

You'll be prompted for the keystore password. The output includes **SHA1**.

**Using Gradle** (if `key.properties` exists and release signing is configured):

```bash
cd android && ./gradlew signingReport
```

Find the SHA-1 under the **release** variant.

### Add Fingerprints in Firebase

1. Open [Firebase Console](https://console.firebase.google.com/) → your project  
2. **Project Settings** (gear icon)  
3. **Your apps** → select Android app `com.go7studio.empire_tycoon`  
4. **Add fingerprint**  
5. Paste each SHA-1 (debug and release)  
6. Save

---

## 2. Your Current google-services.json

Your `google-services.json` already has **two** OAuth client entries with certificate hashes:

| Hash (SHA-1) | Purpose |
|--------------|---------|
| `ce7c41572e9d2231904cc9fcea2d7f73a1785168` | Usually debug keystore |
| `7fa7454938bc4a0e75c152c84e828866124aca5e` | Usually release/upload keystore |

**Important:** After adding or changing SHA-1 fingerprints in Firebase:

1. Download a **new** `google-services.json` from Project Settings  
2. Replace the file in `android/app/google-services.json`  
3. Rebuild the app: `flutter clean && flutter pub get && flutter run -d android`

---

## 3. Verify Firebase Analytics (DebugView)

Firebase Analytics can take 24–48 hours to show data in the main dashboard. You can verify it immediately with **DebugView**.

### Enable Debug Mode on Device

With your Android device connected via USB:

```bash
adb shell setprop debug.firebase.analytics.app com.go7studio.empire_tycoon
```

To disable:

```bash
adb shell setprop debug.firebase.analytics.app .none.
```

### View Events

1. Open [Firebase Console](https://console.firebase.google.com/) → your project  
2. **Analytics** → **DebugView** (left sidebar)  
3. Select your device in the dropdown  
4. Use the app; events should appear within seconds

If nothing appears, the Firebase SDK may not be initialized correctly or the device may not be linked to your debug build.

---

## 4. Support Email (Required for Google Sign-In)

If these fields are missing, Google Sign-In can fail with error **12500** or "Developer Error":

1. Firebase Console → **Project Settings** → **General**  
2. **Public-facing name**: your app’s public name  
3. **Support email**: a valid email address  

Both must be filled in.

---

## 5. Quick Checklist

- [ ] Debug SHA-1 added to Firebase  
- [ ] Release SHA-1 added to Firebase (if using Play Store)  
- [ ] Fresh `google-services.json` downloaded after adding SHA-1s  
- [ ] `google-services.json` placed in `android/app/`  
- [ ] Public-facing name and Support email set in Project Settings  
- [ ] Google Sign-In enabled in **Authentication → Sign-in method**  
- [ ] DebugView tested for Analytics (optional)

---

## 6. Useful Commands

| Task | Command |
|------|---------|
| Get all SHA-1/SHA-256 | `cd android && .\gradlew signingReport` |
| Enable Analytics DebugView | `adb shell setprop debug.firebase.analytics.app com.go7studio.empire_tycoon` |
| Disable Analytics DebugView | `adb shell setprop debug.firebase.analytics.app .none.` |
| Full rebuild | `flutter clean && flutter pub get && flutter run -d android` |

---

## 7. Production / Release Build Verification

**Important:** Before publishing to the Play Store, verify your **release** SHA-1 is in Firebase. Otherwise Google Sign-In will work in debug but fail for real users.

### Where Release SHA-1s Come From

1. **Upload keystore** – The `.jks` or `.keystore` you use to sign your first AAB/APK upload  
2. **Google Play App Signing** – If you use Play App Signing, Google re-signs your app. You must add **both** your upload key SHA-1 and the **Play Console's app signing key** SHA-1.

### Get Your Release SHA-1s

**Your upload keystore** (using `key.properties` paths):

```bash
keytool -list -v -keystore C:\path\to\upload-keystore.jks -alias upload
```

**Play Console app signing key** (after enabling Play App Signing):

1. [Google Play Console](https://play.google.com/console/) → Your app  
2. **Setup** → **App signing**  
3. Under **App signing key certificate**, copy **SHA-1 certificate fingerprint**

Add both SHA-1s to Firebase Project Settings → Your apps → Add fingerprint, then download a fresh `google-services.json`.
