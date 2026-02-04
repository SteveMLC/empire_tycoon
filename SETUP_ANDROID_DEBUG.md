# Empire Tycoon – Flutter & Android Debug Setup

This project uses **Flutter stable** (Dart SDK >=3.0.0). Follow these steps to run the app on your Android device in debug mode.

---

## 1. Flutter SDK (already installed)

Flutter has been installed at:

- **Path:** `C:\src\flutter`

### Add Flutter to your PATH (do this once)

So that `flutter` works in any terminal:

**Option A – PowerShell (run as your user):**
```powershell
[Environment]::SetEnvironmentVariable("Path", "C:\src\flutter\bin;" + [Environment]::GetEnvironmentVariable("Path", "User"), "User")
```
Then **close and reopen** your terminal (and Cursor/VS Code).

**Option B – GUI:**
1. Press `Win + R`, type `sysdm.cpl`, Enter.
2. **Advanced** → **Environment Variables**.
3. Under **User variables**, select **Path** → **Edit** → **New** → add `C:\src\flutter\bin` → OK.

Verify in a **new** terminal:
```bash
flutter --version
```

---

## 2. Android SDK (required for Android device)

To run on a physical Android device, you need the Android SDK.

1. **Install Android Studio** (easiest): https://developer.android.com/studio  
2. Open Android Studio → **More Actions** → **SDK Manager**.  
3. Install:
   - **Android SDK Platform** (e.g. latest or API 34)
   - **Android SDK Command-line Tools**
   - **Android SDK Build-Tools**
4. Note the **Android SDK location** (e.g. `C:\Users\<You>\AppData\Local\Android\Sdk`).

If Flutter doesn’t find it automatically:
```bash
flutter config --android-sdk C:\Users\<YourUsername>\AppData\Local\Android\Sdk
```
Replace `<YourUsername>` with your Windows username.

Check:
```bash
flutter doctor -v
```
**Android toolchain** should show a checkmark.

---

## 3. Run on your Android device (debug)

### On the phone/tablet

1. **Enable Developer options:** Settings → About phone → tap **Build number** 7 times.  
2. **Enable USB debugging:** Settings → System → Developer options → **USB debugging** ON.  
3. Connect the device with a **USB cable**.  
4. When prompted, allow **USB debugging** from this computer.

### On your PC

1. Open a terminal in the project folder (e.g. `c:\Users\sgovo\Documents\GitHub\empire_tycoon`).  
2. Ensure PATH includes Flutter (see step 1).  
3. Get dependencies and run in debug on the connected Android device:

```bash
flutter pub get
flutter run -d android
```

If you have multiple devices, list them and pick the Android device:

```bash
flutter devices
flutter run -d <device-id>
```

Example: `flutter run -d 1234567890ABCDEF` (use the id from `flutter devices`).

The app will build, install, and launch on your device in **debug mode** (hot reload, DevTools, etc.).

---

## Quick reference

| Step              | Command / action |
|-------------------|-------------------|
| Check environment | `flutter doctor -v` |
| List devices      | `flutter devices` |
| Get dependencies  | `flutter pub get` |
| Run on Android    | `flutter run -d android` |
| Run on specific   | `flutter run -d <device-id>` |

---

## Windows: Developer Mode (for plugins/symlinks)

If `flutter pub get` warns that "Building with plugins requires symlink support", enable Developer Mode:

1. Press `Win + I` → **Privacy & security** → **For developers** (or run `ms-settings:developers`).
2. Turn **Developer Mode** **On**.

---

## Troubleshooting

- **“flutter” not found**  
  Add `C:\src\flutter\bin` to your user PATH and open a new terminal.

- **No Android devices found**  
  - Confirm USB debugging is on and the cable allows data.  
  - Run `adb devices` (after Android SDK is installed).  
  - Try another USB port or cable.

- **Android toolchain / SDK errors**  
  Install Android Studio and the SDK components above, then run `flutter doctor -v` again.

- **Build errors**  
  In the project folder: `flutter clean` then `flutter pub get` and `flutter run -d android` again.
