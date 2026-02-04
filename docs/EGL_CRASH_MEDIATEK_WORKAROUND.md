# EGL / IMGeglMakeCurrent Crash on MediaTek Devices

## Issue Summary

**Crash signature (production):**
- `SIGSEGV` in `IMGeglMakeCurrent` (vendor EGL/OpenGL stack)
- Stack: `libGLESv2_mtk.so` → `libIMGegl.so` → `libEGL.so` → `libhwui.so` (Android UI renderer)
- **Visibility:** Foreground
- **Device:** Redmi dandelion (MediaTek/PowerVR GPU)
- **Android:** 10 (SDK 29)
- **App version:** 1.0.1 (130)

This is a **perceived crash** (app appears to crash) caused by a **device/vendor GPU driver bug**, not by application logic.

## Root Cause

- The crash occurs inside **vendor GPU libraries** (MediaTek/PowerVR) when Android’s HWUI/Skia pipeline calls `eglMakeCurrent()` to bind the EGL/OpenGL context.
- It is a known class of issues on **MediaTek + PowerVR/IMG** devices (e.g. Redmi dandelion, MT6762/MT6765) and has been reported in Flutter and Android issues (e.g. Flutter #166248, #61158).
- It often happens during **lifecycle transitions** (e.g. app resume, surface (re)creation) when the render thread tries to make the context current while the surface or driver state is invalid.

## What We Cannot Fix in App Code

- The fault is in **closed-source vendor GPU drivers** (`libGLESv2_mtk.so`, `libIMGegl.so`). We cannot patch or fix the driver from the app.
- We cannot reliably “pause” or “skip” the exact frame where the system calls `eglMakeCurrent` from the Flutter/Dart side.

## Mitigations Implemented

1. **Deferred work on resume**  
   When the app returns to the foreground, we delay non-essential work (e.g. offline income, AdMob updates) by a short interval (~300 ms). This reduces load and rendering pressure during the critical resume/surface transition and may lower the chance of hitting the driver bug at that moment.

2. **Documentation**  
   This file and any linked docs explain the issue and workarounds for support and future reference.

## Optional User-Side Workaround (Affected Devices)

Users on Redmi dandelion or similar MediaTek/PowerVR devices who see repeated crashes can try:

- **Developer options → Disable HW overlays**  
  Forces the GPU to use a different composition path and can sometimes avoid this class of EGL crash (at a possible cost in battery/performance).

This is optional and only for affected users; we do not prompt all users to change this.

## Optional App-Level Workaround (Heavy-Handed)

If the crash rate on a specific device/model is unacceptable:

- **Disable hardware acceleration** for the main Activity in `AndroidManifest.xml`:
  - Set `android:hardwareAccelerated="false"` on the activity.
- Effect: the activity uses software rendering, avoiding the buggy GPU path. This can reduce performance and battery life, so it should only be considered as a last resort or for a dedicated “compatibility” build if we ever ship one.

We are **not** enabling this by default; it is documented here for reference.

## Monitoring

- Track this crash in your crash reporting (e.g. Play Console Vitals) by:
  - Signal: `SIGSEGV`
  - Stack: `IMGeglMakeCurrent` / `libhwui.so` / `libEGL.so`
  - Device/model: Redmi dandelion, other MediaTek/PowerVR devices
- If Flutter or the engine adds a more targeted fix (e.g. engine flag or device-specific workaround), consider upgrading and re-evaluating.

## References

- Flutter issue #166248 (MediaTek EGL crashes)
- Flutter issue #61158 (EGL_BAD_ACCESS / make context current)
- Flutter issue #87937 (OpenGL ES “no current context” / EGL usage)
- Crash stack: `libhwui.so` → `EglManager::makeCurrent` → `SkiaOpenGLPipeline::makeCurrent` → vendor `IMGeglMakeCurrent` → SIGSEGV
