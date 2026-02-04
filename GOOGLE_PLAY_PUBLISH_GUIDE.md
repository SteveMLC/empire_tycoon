# Google Play Publish Guide – Empire Tycoon

Step-by-step guide to build and publish Empire Tycoon to Google Play.

---

## Before You Build (Required)

The release build **requires** `android/key.properties` and a keystore file. Without these, `flutter build appbundle` will fail with a signing error.

---

## Step 1: Signing Configuration (One-time setup)

Google Play needs a signed release build. You need `key.properties` and a keystore.

### 1a. Create or locate your upload keystore

**If you already have one** (e.g. from a previous upload or Play Console):
- Use that `.jks` or `.keystore` file.
- You have `old-upload-keystore.jks.backup` – if this is your real keystore, rename it to `upload-keystore.jks` and use it (and keep a backup elsewhere).

**If you need a new keystore:**
```powershell
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
- Place `upload-keystore.jks` in `android/` (and add it to `.gitignore` – it already ignores `**/*.jks`).
- Remember the passwords and alias; store them somewhere safe.

### 1b. Create `key.properties`

Create `android/key.properties` with:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

- Use the actual keystore file path: `upload-keystore.jks` if it’s in `android/`, or the full path.
- This file is gitignored – never commit it.

**Template:** Copy `android/key.properties.example` to `android/key.properties` and fill in your values.

---

## Step 2: Build the release AAB

Google Play uses **Android App Bundle (.aab)**, not APK.

```powershell
cd c:\Users\sgovo\Documents\GitHub\empire_tycoon
flutter clean
flutter pub get
flutter build appbundle --release
```

Output location:
```
build/app/outputs/bundle/release/app-release.aab
```

---

## Step 3: Open Google Play Console

1. Go to [Google Play Console](https://play.google.com/console/)
2. Sign in with your developer account.
3. **Create an app** or select **Empire Tycoon** if it already exists.

---

## Step 4: First-time app setup (if new app)

If this is a new app:

1. **Create app**
   - App name: Empire Tycoon  
   - Default language: English (US)  
   - App or game: Game  
   - Free or paid: Free  

2. **App access**
   - If you use Google Sign-In or similar: fill access and login details.
   - Optionally use “All functionality is available without restrictions”.

3. **Ads declaration**
   - Your app uses AdMob: select **Yes, my app contains ads**.

4. **Content rating**
   - Complete the questionnaire.
   - For a tycoon game, expect something like PEGI 3 / Everyone.

5. **Target audience**
   - Choose age groups.

6. **News app**
   - Select **No** (unless it’s a news app).

7. **COVID‑19 contact tracing**
   - Select **No**.

8. **Data safety**
   - Declare data you collect (e.g. account info, game progress).
   - See [Firebase data use](https://firebase.google.com/support/privacy) and AdMob docs.

---

## Step 5: Upload the AAB

1. In Play Console: **Production** → **Create new release** (or **Testing** → **Internal/Closed** first).
2. **Upload** `app-release.aab` from:
   ```
   build/app/outputs/bundle/release/app-release.aab
   ```
3. **Release name** (e.g.): `1.0.1 (130)`
4. **Release notes** (for users):
   ```
   • Initial release
   • Build your global business empire
   ```
5. **Review and roll out** (or **Save** if you’re just testing).

---

## Step 6: Store listing (required for Production)

1. **Main store listing**
   - Short description (up to 80 chars)
   - Full description (up to 4000 chars)
   - Screenshots (at least 2, max 8) – phone: min 320px, max 3840px
   - App icon: 512×512 PNG
   - Feature graphic: 1024×500

2. **Categorization**
   - Category: **Game** → **Simulation** (or similar)
   - Tags (optional)

---

## Step 7: Release

1. Finish all required sections (they will show as green).
2. For a new app, go to **Production** → **Create new release**.
3. Choose **Start rollout to Production** (or use Internal/Closed testing first).

---

## Quick reference – commands

| Task              | Command                          |
|-------------------|----------------------------------|
| Clean             | `flutter clean`                  |
| Get dependencies  | `flutter pub get`                |
| Build release AAB | `flutter build appbundle --release` |
| Build release APK | `flutter build apk --release`    |

---

## Current app info

- **Package:** `com.go7studio.empire_tycoon`
- **Version:** 1.0.1+130 (from pubspec.yaml)
- **AdMob:** Enabled (production IDs)
- **Firebase:** Configured
- **In-app purchase:** Premium subscription

---

## Troubleshooting

**Build fails: “Keystore not found”**  
- Confirm `key.properties` exists in `android/`.
- Ensure `storeFile` points to your `.jks` or `.keystore` file.

**Build fails: “JAVA_HOME not set”**  
- Set JAVA_HOME to your JDK (e.g. Android Studio’s `jbr`):
  `C:\Program Files\Android\Android Studio\jbr`

**Play Console needs SHA‑1**  
- See `docs/FIREBASE_SETUP_GUIDE.md` (Section 7: Production / Release Build Verification).
- Add release SHA‑1 in Firebase and Play Console if needed.
