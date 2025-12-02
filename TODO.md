# Empire Tycoon – Cleanup & Refactor TODOs

## 1. Timer & Income Architecture Hardening

- [ ] **Centralize all timers in `TimerService`**
  - **Files**:
    - `lib/services/components/timer_service.dart`
    - `lib/models/game_state.dart` (timer fields)
  - **Tasks**:
    - Audit all `Timer` usages in `GameState` (e.g. `_boostTimer`, `_adBoostTimer`, `_platinumClickFrenzyTimer`, `_platinumSteadyBoostTimer`, `_achievementNotificationTimer`, offline timers).
    - For each timer, replace direct `Timer` usage with callbacks registered via `TimerService.registerUpdateCallback` or a new dedicated scheduler in `TimerService`.
    - Ensure `GameState.cancelAllTimers()` becomes a no‑op or a very small wrapper that delegates to `TimerService`.

- [ ] **Wire `IncomeService` properly into `TimerService`**
  - **Files**:
    - `lib/services/components/timer_service.dart`
    - `lib/services/income_service.dart`
    - `lib/services/game_service.dart` (constructor)
  - **Tasks**:
    - In `GameService` constructor, after creating `_incomeService`, call `_timerService.registerIncomeService(_incomeService);`.
    - In `TimerService.registerIncomeService`, inside the callback added by `registerUpdateCallback`, actually call:
      - `incomeService.calculateIncomePerSecond(_gameState);`  
      - (or a dedicated method to update cached income if you add one).
    - Make `DiagnosticService` and the UI use the same `IncomeService` data (see section 10).

- [ ] **Tighten `_isUpdatingGameState` usage**
  - **Files**:
    - `lib/services/components/timer_service.dart`
  - **Tasks**:
    - Review all branches guarded by `_isUpdatingGameState` (`gameUpdateTimer`, `autoSaveTimer`, `investmentUpdateTimer`).
    - Make sure every path that sets `_isUpdatingGameState = true` has a `try/finally` that always clears it.
    - Add a small diagnostic (`if (_isUpdatingGameState && kDebugMode)`) to log when updates get skipped too often.

## 2. GameState Decomposition (De‑Godify)

- [ ] **Extract core economy domain service**
  - **Files**:
    - `lib/models/game_state.dart`
    - `lib/models/game_state/income_logic.dart`
    - `lib/models/game_state/update_logic.dart`
  - **Tasks**:
    - Identify pure, deterministic economy functions (no Flutter, no Ads, no notifications).
    - Move them into a new service, e.g. `lib/domain/economy_service.dart`.
    - Have `GameState` delegate to this service instead of embedding all income and update logic.

- [ ] **Isolate platinum / boosters / cosmetics**
  - **Files**:
    - `lib/models/game_state.dart` (platinum & booster fields)
    - `lib/models/game_state/platinum_logic.dart`
    - `lib/models/game_state/booster_logic.dart`
  - **Tasks**:
    - Create `lib/domain/platinum_service.dart` that knows about:
      - `platinumPoints`, vault items, permanent boosts, daily cooldowns.
    - Replace direct field manipulation in `GameState` with calls into this service.
    - Keep all UI‑related flags (like `showPPAnimation`) in `GameState`; pure business rules go in the domain service.

- [ ] **Remove infrastructure dependencies from `GameState`**
  - **Files**:
    - `lib/models/game_state.dart`
  - **Tasks**:
    - Remove `AdMobService? _adMobService;` and any direct references to services.
    - Pass ad‑relevant information as plain data (e.g. via `GameService` calling `AdMobService.updateGameState(...)`) instead of giving `GameState` a reference to ad services.

## 3. Dependency Injection & Service Boundaries

- [ ] **Normalize `AdMobService` usage**
  - **Files**:
    - `lib/main.dart`
    - `lib/services/game_service.dart`
    - `lib/services/app_lifecycle_service.dart`
    - `lib/services/admob_service.dart`
  - **Tasks**:
    - Decide: singleton (factory) vs injected instance, then pick one style:
      - If singleton: stop passing `AdMobService()` into `AppLifecycleService.initialize` and `Provider<AdMobService>.value` in `main.dart`; just call `AdMobService()` where needed.
      - If injected: remove `factory`/singleton pattern and pass an instance from `main.dart` into `GameService` and `AppLifecycleService`.
    - Ensure there is a single source of truth for AdMob configuration and lifecycle.

- [ ] **Remove redundant `IncomeService` providers**
  - **Files**:
    - `lib/main.dart` (MultiProvider)
    - `lib/services/game_service.dart`
  - **Tasks**:
    - You currently have both:
      - `ChangeNotifierProvider(create: (context) => IncomeService())` in `main.dart`.
      - `_incomeService = IncomeService();` in `GameService`.
    - Decide which is canonical:
      - Prefer: `IncomeService` owned by `GameService` and exposed via `gameService.incomeService`.
    - Remove the extra Provider in `main.dart` and update UI widgets (like `TopPanel`) to access `IncomeService` only through `GameService`.

## 4. Lifecycle & Offline Income

- [ ] **Clarify “no background start time recorded” cases**
  - **Files**:
    - `lib/services/app_lifecycle_service.dart` → `_handleAppReturningToForeground`
  - **Tasks**:
    - Add explicit logging of `_backgroundStartTime` and `_gameState` presence when hitting:
      - `debugPrint('ℹ️ No background start time recorded or game state unavailable');`
    - Confirm whether `WidgetsBinding.instance.addObserver(this)` is executed early enough in app startup.
    - If necessary, move `AppLifecycleService.initialize(...)` earlier in `GameService.init()` or into `MyApp` init.

- [ ] **Document separation of “offline since last save” vs “background offline”**
  - **Files**:
    - `lib/models/game_state/offline_income_logic.dart`
    - `lib/services/app_lifecycle_service.dart`
  - **Tasks**:
    - Add inline docs (no behaviour change) describing:
      - Long‑term offline income handled on load using `lastSaved` and `lastOpened`.
      - Short‑term background offline handled by `AppLifecycleService` using `_backgroundStartTime`.
    - This prevents future refactors that may double count offline income.

## 5. AdMob & Rewarded Ads

- [ ] **Guard predictive loading with nicer batching**
  - **Files**:
    - `lib/services/admob_service.dart` → `updateGameState`, `_performPredictiveLoading`
  - **Tasks**:
    - Replace the naive `Future.delayed(const Duration(milliseconds: 500), () { _performPredictiveLoading(); });` with:
      - A debounced mechanism (store a `Timer? _predictiveLoadingTimer`), cancelling/restarting within that 500ms window.
    - Ensure `_performPredictiveLoading` is idempotent and cheap for repeated state updates.

- [ ] **Explicit state machine for HustleBoost & offline 2x ads**
  - **Files**:
    - `lib/services/admob_service.dart`
    - `lib/widgets/hustle/boost_dialog.dart` (if present)
    - `lib/widgets/offline_income_notification.dart`
  - **Tasks**:
    - Introduce clear states per ad type: `idle`, `loading`, `ready`, `showing`, `cooldown`.
    - Ensure UI checks this state before calling `show...Ad(...)` to avoid hammering the API.
    - Log state transitions minimally in debug builds.

## 6. Google Play Games Login & Auth UX

- [ ] **Verify & wire `AuthService.signIn()` from UI**
  - **Files**:
    - `lib/services/auth_service.dart`
    - `lib/screens/user_profile_screen.dart`
    - Any “Connect Google Play” / “Sign In” button handlers
  - **Tasks**:
    - Find all places where the Google Play sign‑in button is rendered; make sure each one calls `Provider.of<AuthService>(context, listen:false).signIn()`.
    - Add subtle UI feedback:
      - Loading state while sign‑in in progress.
      - Error display using `authService.lastError`.

- [ ] **Add an in‑game auth diagnostics panel**
  - **Files**:
    - `lib/screens/user_profile_screen.dart`
  - **Tasks**:
    - Create a small collapsible section that shows `authService.getDiagnosticInfo()`:
      - `isSignedIn`, `playerId`, `playerName`, `hasGamesPermission`, `lastError`.
    - Only visible in debug or behind a long‑press on a debug icon.

- [ ] **Handle `GameAuth.player` being cleared more intelligently**
  - **Files**:
    - `lib/services/auth_service.dart` → `GameAuth.player.listen`
  - **Tasks**:
    - When `player == null` but `_isSignedIn == true` and `_firebaseUser != null`:
      - Log a clear “Play Games stream cleared while Firebase still signed in” message.
      - Optionally attempt a silent `GameAuth.signIn()` and log the result.
    - Avoid flipping `_isSignedIn` to `false` purely on Play Games stream `null`—leave Firebase sign‑in status authoritative.

## 7. Dialog / Overlay Safety

- [ ] **Create centralized dialog/overlay manager**
  - **Files**:
    - New: `lib/services/dialog_service.dart` (or similar)
    - `lib/screens/user_profile_screen.dart` (overlay processing dialogs)
    - `lib/widgets/premium_avatar_selector.dart` (purchase dialogs)
  - **Tasks**:
    - Implement a `DialogService` with:
      - `showProcessingDialog(id, ...)`
      - `hideDialog(id)`
    - Replace manual `OverlayEntry` management and multi‑step force closes (`Navigator.popUntil(isFirst)`) with a single well‑tested path.

- [ ] **Remove aggressive `Navigator.popUntil((route) => route.isFirst)` usage from widgets**
  - **Files**:
    - `lib/screens/user_profile_screen.dart` → `_forceClosePurchaseDialog`
    - `lib/widgets/premium_avatar_selector.dart` → `_forceClosePurchaseDialog`
  - **Tasks**:
    - Route closing should be initiated by higher‑level navigation logic, not deeply nested widgets.
    - Limit usage of `popUntil(isFirst)` to one known safe location (e.g., a dedicated “Return to Main Menu” action).

## 8. UI Simplification & File Splits

- [ ] **Split `UserProfileScreen` into smaller widgets**
  - **Files**:
    - `lib/screens/user_profile_screen.dart`
  - **Tasks**:
    - Extract:
      - Avatar section → `UserAvatarSection` widget.
      - Premium / purchase section → `PremiumSection` widget.
      - Settings/toggles → `SettingsSection` widget.
    - Keep business logic calls (GameService, BillingService, AuthService) in a small number of methods; UI widgets become mostly declarative.

- [ ] **Refactor `StatsScreen` into modular components**
  - **Files**:
    - `lib/screens/stats_screen.dart`
  - **Tasks**:
    - Move scrolling/section navigation logic into a `StatsPageLayout` widget.
    - Keep each card widget as is (`OverviewCard`, `EarningsBreakdownCard`, etc.) but ensure they are independent and reusable from other screens.

## 9. Onboarding & Explainability

- [ ] **Introduce a first‑session onboarding system**
  - **Files**:
    - `lib/models/game_state.dart` (flags for “tutorials shown”)
    - `lib/screens/hustle_screen.dart`
    - `lib/screens/business_screen.dart`
    - `lib/screens/investment_screen.dart`
    - `lib/screens/real_estate_screen.dart`
  - **Tasks**:
    - Add simple flags to GameState: `hasSeenHustleIntro`, `hasSeenBusinessIntro`, etc.
    - On first relevant action (first tap, first business purchase, etc.), show a short, skippable tutorial dialog and set the flag.
    - Make sure these tutorials are idempotent and survive app restarts.

- [ ] **Make income breakdown discoverable**
  - **Files**:
    - `lib/widgets/main_screen/top_panel.dart`
    - `lib/screens/stats_screen.dart`
  - **Tasks**:
    - Add `onTap` on the income rate display to open a bottom sheet or panel summarizing:
      - Business, Real Estate, Dividends, Boosts contributions.
    - Reuse logic from `EarningsBreakdownCard` in Stats.

## 10. Diagnostics & Logging Modes

- [ ] **Gate diagnostics and noisy logs behind a debug flag**
  - **Files**:
    - `lib/services/components/diagnostic_service.dart`
    - `lib/services/components/timer_service.dart`
    - `lib/services/admob_service.dart`
    - `lib/services/auth_service.dart`
    - `lib/services/app_lifecycle_service.dart`
  - **Tasks**:
    - Introduce a global `bool kEnableDiagnostics = kDebugMode;` (or a `DiagnosticConfig` class).
    - Wrap noisy prints (especially `[DIAGNOSTICS]`, timer skips, predictive loading details) in `if (kEnableDiagnostics)`.
    - Keep critical error logs unconditional.

- [ ] **Unify income diagnostics path**
  - **Files**:
    - `lib/services/components/diagnostic_service.dart`
    - `lib/services/income_service.dart`
  - **Tasks**:
    - Have `DiagnosticService` get its income rate via `IncomeService.calculateIncomePerSecond(gameState)` instead of `gameState.calculateTotalIncomePerSecond()`.
    - This ensures diagnostics and UI use the same formula.

## 11. Code Hygiene & Backups

- [ ] **Remove or relocate backup/original screens from `lib/`**
  - **Files**:
    - `lib/screens/*.bak`, `*backup.dart`, `*.original.dart`:
      - `business_screen_copy.dart.bak`
      - `investment_detail_screen_backup.dart`
      - `real_estate_screen_backup.dart`
      - `real_estate_screen.original.dart`
  - **Tasks**:
    - Move these to a `legacy/` or `archive/` folder outside `lib/` or delete if no longer needed.
    - Ensure they are not importable by the main app.

## 12. Testing & Tooling

- [ ] **Create regression tests for timers/offline income**
  - **Files**:
    - `test/timers_test.dart` (new)
    - `test/offline_income_test.dart` (new)
  - **Tasks**:
    - Simulate:
      - Several init/dispose cycles of `GameService` + `TimerService`.
      - Long background periods and multiple resume events.
      - Verify no duplicated income and correct offline income calculation.

- [ ] **Add a simple automated auth test stub (where feasible)**
  - **Files**:
    - `test/auth_service_test.dart` (new)
  - **Tasks**:
    - At minimum, test:
      - `_checkExistingAuthState()` behaviour with mocked Firebase user vs none.
      - `getAuthStatus()` mapping.
