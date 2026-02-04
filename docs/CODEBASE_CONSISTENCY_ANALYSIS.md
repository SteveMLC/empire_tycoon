# Codebase consistency analysis (post-merge)

**Date:** 2026-02-04  
**Context:** Recent merge *"promo deep links + smart rate-us dialog (resolved conflict, kept main's timer methods)"* (commit `bec6701`).  
**Scope:** Inconsistencies, duplicate logic, version/docs, and dead/backup files.

---

## 1. Critical: Duplicate game update timers

**Issue:** Two separate systems drive the 1-second game update and the 30-second investment update. Both run at once, so `_updateGameState()` can run **twice per second** and investment updates can run twice per 30 seconds.

**Details:**

- **TimerService** (used by `GameService.init()`):
  - 1-second timer → `_gameState.updateGameState()` → `GameState._updateGameState()` (the implementation in **game_state.dart**).
  - 30-second timer → `_gameState.updateInvestmentPrices()`.
- **GameState._setupTimers()** (in **game_state.dart**, lines 437–452):
  - Called when `isInitialized = true` (after real estate init).
  - Creates **another** 1-second `_updateTimer` that calls `_updateGameState()`.
  - Creates an **anonymous** 30-second `Timer.periodic` for investment updates (never cancelled).

When `GameService.init()` runs, it calls `_gameState.cancelAllTimers()`, which delegates to **UpdateLogic._cancelAllTimers()** (a no-op in **update_logic.dart**). So **GameState’s own** `_updateTimer` and the anonymous 30s timer are **never cancelled**. Result:

- Two 1-second tick sources.
- Two 30-second investment update sources.
- Extra CPU and risk of double income/state updates.

**Recommendation:**

- Make **GameState._setupTimers()** a no-op (same as **UpdateLogic._setupTimers()**), so only **TimerService** starts timers.
- Implement **GameState.cancelAllTimers()** so it cancels and nulls **GameState’s** `_updateTimer` and any 30s timer (or store the 30s timer in a field and cancel it there). Ensure **GameState** does not create new timers after moving to the centralized **TimerService**.

---

## 2. Two different `_updateGameState()` implementations

**Issue:** There are two implementations of the game tick; only one is used.

- **game_state.dart** (lines 472–638): Full implementation using `_lastIncomeApplicationTime`, interval-based business income (`business.secondsSinceLastIncome`), `_updateHourlyEarnings`, etc. This is the one **actually used** by both the **TimerService** and **GameState._updateTimer** (because `updateGameState()` calls `_updateGameState()`, and the instance method on **GameState** wins).
- **update_logic.dart** (extension **UpdateLogic**): Different implementation with debounce, `_lastProcessedUpdateId`, `_processedIncomeTimestamps`, per-second income formulas, `_checkTimedEffects`, and many `DEBUG` prints. This extension method is **never invoked** (Dart resolves the instance method on **GameState** first).

So the more advanced logic in **update_logic.dart** is effectively dead code, and the live path is the older implementation in **game_state.dart**.

**Recommendation:**

- Either:
  - Migrate to a single update path: have **GameState.updateGameState()** call the **UpdateLogic** implementation (e.g. by renaming/removing the body in **game_state.dart** and ensuring the extension’s `_updateGameState` is the one used), and remove the duplicate logic; or
  - Clearly document that the “main” loop is in **game_state.dart** and trim or remove the unused implementation in **update_logic.dart** to avoid confusion and drift.

---

## 3. Missing part and field for promo feature

**Issue:** **promo_logic.dart** is written as `part of '../game_state.dart'`, but **game_state.dart** does **not** declare:

- `part 'game_state/promo_logic.dart';`
- A field `Set<String> redeemedPromoCodes = {};` on **GameState**.

**game_state/serialization_logic.dart** and **game_state/promo_logic.dart** both use `redeemedPromoCodes`. **main_screen.dart** uses `PromoRedemptionResult` and `gameState.redeemPromoCode()`. Without the part and the field, the project would fail to compile when building from a clean state. If it compiles locally, the part/field may exist in another branch or local edit.

**Recommendation:**

- Add to **game_state.dart**:
  - `part 'game_state/promo_logic.dart';`
  - In the Platinum Points / persistence section: `Set<String> redeemedPromoCodes = {};`

---

## 4. Version and documentation mismatch

**Issue:** Version references are inconsistent.

- **pubspec.yaml:** `version: 1.0.1+134`
- **documentation/DEVELOPMENT_ROADMAP.md:** “Current Release Status (v1.0.1+130)” and “Version: 1.0.1+130”
- **documentation/DOCUMENTATION_INDEX.md:** “v1.0.1+130”
- **VERSION_HISTORY.md:** “1.0.1+130 (Current)”
- **GOOGLE_PLAY_PUBLISH_GUIDE.md:** “Version: 1.0.1+130”

**Recommendation:** Bump all documented “current” version references to **1.0.1+134** (or the next release) so they match **pubspec.yaml**.

---

## 5. Excessive DEBUG logging in update path

**Issue:** **update_logic.dart** (the unused implementation) contains many `print("DEBUG: ...")` calls (dozens in the income/update block). The **game_state.dart** update path also has some debug-style prints. Leaving these in the main loop can hurt performance and clutter logs in production.

**Recommendation:** Guard all such logs with `kDebugMode` or remove them from the hot path; consider a small logging helper that no-ops in release.

---

## 6. Backup and copy files in `lib/`

**Issue:** The following look like temporary/backup files and are easy to confuse with the real screens:

- `lib/screens/business_screen_copy.dart.bak`
- `lib/screens/investment_detail_screen_backup.dart`
- `lib/screens/real_estate_screen_backup.dart`
- `lib/screens/real_estate_screen.original.dart`

**Recommendation:** Remove them from the repo (or move to a `/backup` or `/archive` folder outside `lib/`) and rely on version control for history.

---

## 7. Comment in GameState init

**Issue:** In **game_state.dart** (e.g. around line 386), the comment says `_setupTimers(); // From update_logic.dart`, but the method actually called is the **instance** method **GameState._setupTimers()** (the one that creates the real timers), not the no-op in **UpdateLogic**.

**Recommendation:** Fix the comment (e.g. “GameState’s own _setupTimers” or “no-op in UpdateLogic; this is the instance implementation”) or remove it once **GameState._setupTimers()** is turned into a no-op.

---

## 8. Summary table

| Area                    | Severity   | Summary                                                                 |
|-------------------------|-----------|-------------------------------------------------------------------------|
| Duplicate timers        | Critical  | Two 1s + two 30s timers; GameState timers never cancelled               |
| Two update implementations | High   | UpdateLogic implementation unused; possible drift and confusion         |
| Promo part/field        | Critical* | Missing `part` and `redeemedPromoCodes` if building from clean state    |
| Version in docs         | Low       | Docs say 130, pubspec 134                                                |
| DEBUG prints            | Low       | Many in update_logic (and some in game_state) hot path                   |
| Backup/copy files       | Low       | Four backup/copy screen files in lib/screens                             |
| Misleading comment      | Low       | _setupTimers comment says “From update_logic” but it’s the main impl    |

\* Critical for a clean build if part/field are indeed missing in your tree.

---

## Suggested fix order

1. Add **promo_logic** part and **redeemedPromoCodes** to **game_state.dart** (if missing).
2. Make **GameState._setupTimers()** a no-op and ensure **GameState.cancelAllTimers()** cancels **GameState’s** own timers so only **TimerService** drives updates.
3. Align version in all docs with **pubspec.yaml** (e.g. 1.0.1+134).
4. Remove or guard DEBUG prints in the update path; optionally remove or refactor the dead **UpdateLogic._updateGameState**.
5. Remove or relocate backup/copy screen files and fix the **GameState._setupTimers** comment.
