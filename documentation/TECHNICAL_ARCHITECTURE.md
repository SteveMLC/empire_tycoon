# Empire Tycoon - Technical Architecture

## Application Architecture

Empire Tycoon is a modular, cross-platform Flutter game following a highly maintainable Model-View-Service architecture. The codebase is organized for scalability, DRYness, and extensibility, with a strong focus on premium features and a robust platinum points system.

### Component Structure

1. **Models**: Core data structures for all game entities and resources.
2. **GameState (Modularized)**: Central state, split into part files for each domain (e.g., business, investment, platinum, events, serialization, etc.). See `lib/models/game_state/`.
3. **Views/Screens**: UI containers for each major game section (hustle, business, investment, real estate, stats, platinum vault, user profile, etc.).
4. **Widgets**: Highly reusable UI components, including premium/platinum-specific widgets (e.g., platinum vault, crest, spire, selectors, notifications).
5. **Services**: Business logic and persistence orchestration (e.g., `GameService`).
6. **Utils**: Formatting, time, sound, and other helpers.
7. **Painters/Themes**: Custom painters and theming for premium/polished UI.

### Dependency/Data Flow

```
User Interaction → Screens/Widgets → GameService → GameState (part files) → Persistence
```

- State changes propagate via Provider (`ChangeNotifier`), with all screens and widgets consuming `GameState` reactively.
- All persistent data is serialized/deserialized using real APIs (`SharedPreferences`) and robust error handling.

---

## Key Features & Systems

### Modular GameState (lib/models/game_state/)
- **GameState** is split into focused part files:
  - `achievement_logic.dart`, `booster_logic.dart`, `business_logic.dart`, `challenge_logic.dart`, `event_logic.dart`, `income_logic.dart`, `initialization_logic.dart`, `investment_logic.dart`, `notification_logic.dart`, `offline_income_logic.dart`, `platinum_logic.dart`, `prestige_logic.dart`, `real_estate_logic.dart`, `serialization_logic.dart`, `update_logic.dart`, `utility_logic.dart`.
- Each part encapsulates domain logic, ensuring zero duplication and DRY code.
- All state changes, calculations, and event handling are performed in these part files for optimal maintainability and efficiency.

### Platinum Points System
- **Platinum Points (PP):** Premium currency earned via achievements, events, or premium actions.
- **Logic:** All platinum logic is in `platinum_logic.dart` and integrated with all relevant flows (awards, purchases, vault, UI updates).
- **UI:** Dedicated platinum widgets (`platinum_vault_screen.dart`, `platinum_facade_selector.dart`, `platinum_crest_avatar.dart`, `platinum_spire_trophy.dart`, widgets/platinum_vault/*, etc.).
- **Vault:** The platinum vault allows players to spend PP on upgrades, boosters, cosmetics, and unlockables.
- **Achievements:** Achievement definitions in `data/achievement_definitions.dart` include platinum rewards.
- **Edge Cases:** Handles insufficient PP, concurrent transactions, and all error scenarios with user feedback.

### Enhanced Feature Structure
- **Business, Investment, Real Estate:** Each has its own model, logic part, and screen. All calculations (ROI, upgrades, volatility, etc.) are handled in their respective part files.
- **Achievements & Challenges:** Modular tracking, progress, and notification logic.
- **Premium UI:** Custom painters, animated avatars, premium themes, and visual effects for platinum features.
- **Data Loading:** Static data loaded from `lib/data/` (e.g., `platinum_vault_items.dart`, `achievement_definitions.dart`).

### State Management, Persistence & Initialization
- **Provider** is used for all state propagation. All widgets and screens are reactive to `GameState` changes.
- **Persistence** uses real APIs (`SharedPreferences`), with JSON serialization for all state. No mocks or placeholders.
- **Initialization flow:**
  1. **Entry Point (`main` function):** Ensures Flutter bindings are ready and initializes `SharedPreferences`.
  2. **Root Widget (`MyApp`):** Sets up `MaterialApp` and the core `MultiProvider` with `GameState` and `GameService`.
  3. **Initializer Widget (`GameInitializer`):** Loads and initializes the game, showing loading/error states.
  4. **GameService:** Handles version checking, sound initialization, loading/saving game state, offline progression, and auto-save timers.
  5. **Transition to Main UI:** Once initialization completes, the main screen is shown and periodic updates continue in the background.

### Error Handling & Edge Cases
- Try/catch for all critical flows (save/load, purchases, upgrades, platinum transactions).
- User-facing feedback for all errors (e.g., insufficient funds/PP, network issues).
- Fallback to default values if loading fails, with error screens and restart options.
- All edge cases explicitly handled (no placeholders, no silent failures).

---

## Code Organization

The project is organized into clear directories for models, modularized game state logic, data, screens, widgets, services, painters, themes, providers, and utilities. For details, see the "Component Structure" section above or refer to the root `lib/` directory in your editor for the latest file organization.

---

## Platinum Points & Vault System

- **Earning:** Platinum points are awarded for major achievements, special events, and certain premium actions (see `achievement_definitions.dart`, `platinum_logic.dart`).
- **Spending:** PP can be spent in the Platinum Vault on:
  - Permanent upgrades
  - Boosters
  - Cosmetics
  - Unlockable features
- **UI:** All platinum-related UI is visually distinct, animated, and uses custom painters and effects.
- **Edge Cases:** All scenarios (insufficient PP, concurrent actions, transaction errors) are explicitly handled with user feedback.
- **Integration:** Platinum logic is tightly integrated with achievements, vault, and premium UI. No placeholder code is used; all flows are fully functional and robust.

---

## State Management & Persistence

- **Provider** is used for all state propagation. All widgets and screens are reactive to `GameState` changes.
- **Persistence** uses real APIs (`SharedPreferences`), with JSON serialization for all state. No mocks or placeholders.
- **Initialization** is robust, with error handling, fallback defaults, and full system readiness before UI loads.

---

## Error Handling & Edge Cases

- All critical flows are wrapped in try/catch with user feedback and error screens as needed.
- Fallbacks and recovery for loading failures, transaction errors, and network issues.
- No silent failures or unhandled exceptions.
- All edge cases are explicitly handled in logic and UI.

---

## Performance & Scalability

- Targeted state updates minimize rebuilds.
- Timers are consolidated for efficiency.
- Efficient JSON parsing and serialization for persistence.
- Animation and rendering optimizations for smooth framerates.
- Architecture is extensible for new features, business types, investments, real estate, and premium content.

---

## Extension Points

- **New Business Types:** Add to business logic part file and definitions.
- **New Investments:** Add to investment logic and data.
- **New Real Estate:** Extend real estate logic and data.
- **Premium Features:** Add new platinum vault items, achievements, and UI components.
- **UI Customization:** Extend themes, painters, and widgets for new visual styles.
- **Game Mechanics:** Add new part files or extend existing ones for new features.

---

## Standards & Best Practices

- No placeholder code or comments. All features are fully implemented and functional.
- DRY, idiomatic Dart/Flutter code throughout.
- All edge cases handled. No duplicated files or functions.
- Only real APIs and data flows. No mocks or stubs.
- Documentation is always up-to-date, accurate, and portable.

- Implements manual income generation mechanics
- Manages tap animations and feedback
- Handles click boost mechanics
- Displays tap value and multiplier information

#### BusinessScreen (`screens/business_screen.dart`)
- Shows list of available and locked businesses
- Handles business purchase and upgrade interactions
- Displays ROI and efficiency metrics
- Shows income generation rates

#### InvestmentScreen (`screens/investment_screen.dart`)
- Displays a filterable and sortable list of available investment opportunities using `InvestmentListItem` widgets.
- Includes filters for investment category and owned status.
- Shows a high-level market overview (`MarketOverviewWidget`) and provides access to a detailed portfolio summary (`PortfolioWidget`) overlay.
- Tapping an `InvestmentListItem` navigates to `InvestmentDetailScreen` where detailed information, price trends, and buy/sell actions (likely using an `InvestmentItem` widget) are handled.
- Provides sorting options based on price, volatility, performance, and dividend yield.

#### RealEstateScreen (`screens/real_estate_screen.dart`)
- Organizes properties by locale
- Shows property acquisition options
- Displays cash flow and ROI metrics
- Handles property purchase interactions

#### StatsScreen (`screens/stats_screen.dart`)
- Visualizes player statistics and progress
- Shows financial metrics and history
- Displays income breakdown by source
- Contains achievement and milestone information

### Widgets

#### MoneyDisplay (`widgets/money_display.dart`)
- A reusable widget for displaying currency values.
- Shows the provided balance formatted using `NumberFormatter.formatCurrency`.
- Allows customization of text style (color, size, weight) for visual hierarchy.

#### BusinessItem (`widgets/business_item.dart`)
- List item for business display
- Shows business state, level, and income
- Contains upgrade button and progress indicators

#### InvestmentItem (`widgets/investment_item.dart`)
- A detailed widget (likely used on `InvestmentDetailScreen`) for a single investment.
- Displays investment details: name, icon, price, price change, owned quantity, description, category, forecast, dividend info.
- Shows a simple price history chart.
- Includes controls for selecting quantity and triggering buy/sell actions via callbacks (`onBuy`, `onSell`).

#### RealEstatePropertyItem (`widgets/real_estate_property_item.dart`)
- Displays property information
- Shows cash flow and ROI metrics
- Contains purchase controls

### Utilities

#### NumberFormatter (`utils/number_formatter.dart`)
- Formats large numbers in readable format
- Handles currency display
- Implements short notation for large values

#### TimeUtils (`utils/time_utils.dart`)
- Provides helper functions for time-related operations.
- Formats `DateTime` objects into various string representations (time, date, date+time, relative time ago, remaining time).
- Generates standardized string keys based on date/hour for data storage.

## State Management

The application uses the Provider package for state management:

1. `GameState` (`models/game_state.dart`) extends `ChangeNotifier` to hold and notify about changes in the core game state.
2. `GameService` (`services/game_service.dart`) manages initialization, persistence, and background tasks.
3. `MultiProvider` in `main.dart` (`MyApp` widget) sets up the providers at the root:
   - `GameState` is provided via `ChangeNotifierProvider`.
   - `GameService` is provided via a standard `Provider`, taking the `GameState` instance and `SharedPreferences`.
4. Screens and widgets access state and services primarily using `Provider.of<T>(context)` or `context.read<T>()` / `context.watch<T>()`, and react to `GameState` changes using `Consumer<GameState>` or `context.watch<GameState>()`.

## Persistence

Game persistence is implemented through:

1. `SharedPreferences` for local storage
2. JSON serialization/deserialization of game state
3. Regular auto-saving on state changes
4. Offline progression calculation based on timestamps

## Initialization Flow

1. **Entry Point (`main` function):** Ensures Flutter bindings are ready and initializes `SharedPreferences`.
2. **Root Widget (`MyApp`):** Sets up `MaterialApp` and the core `MultiProvider` with `GameState` and `GameService`.
3. **Initializer Widget (`GameInitializer`):** 
   - Shown initially as the home route.
   - Displays a loading indicator or an error message.
   - Fetches the `GameService` instance from the provider.
   - Calls `gameService.init()` to perform the main initialization tasks.
4. **Service Initialization (`GameService.init()`):**
   - Handles game version checking.
   - Initializes sound systems.
   - Loads the saved `GameState` from `SharedPreferences` (`_loadGame`).
   - Calculates offline progress based on timestamps (`_calculateOfflineIncome`).
   - Performs an initial save (`saveGame`).
   - Sets up the auto-save timer.
   - Sets `GameState.isInitialized` to true.
5. **Transition to Main UI:** Once `gameService.init()` completes successfully, `GameInitializer` rebuilds and displays the `MainScreen` (`screens/main_screen.dart`).
6. **Background Timers:** Auto-save and other periodic updates (like investment changes within `GameState`) continue running in the background.

## Error Handling

The application implements error handling through:

1. Try/catch blocks for critical operations
2. Fallback to default values when loading fails
3. Error screen display (`ErrorApp`) with restart option
4. Console logging for debugging purposes

## Performance Considerations

1. Targeted state updates to minimize full rebuilds
2. Timer consolidation to reduce update frequency
3. Efficient JSON parsing for save/load operations
4. Animation optimizations to maintain smooth framerates

## Data Loading

Static game data, such as achievement definitions and real estate details, is loaded from:
1. Hardcoded definitions within the `lib/data/` directory (e.g., `achievement_definitions.dart`).
2. External files (e.g., CSVs) located in the root `attached_assets/` directory, parsed by loaders in `lib/data/` (e.g., `real_estate_data_loader.dart`).

## Code Organization

```
lib/
├── data/
│   ├── achievement_definitions.dart
│   └── real_estate_data_loader.dart
├── models/
│   ├── achievement_data.dart # (Implicitly exists based on achievement_definitions.dart import)
│   ├── business.dart
│   ├── game_state.dart
│   ├── investment.dart
│   └── real_estate.dart
├── screens/
│   ├── business_screen.dart
│   ├── hustle_screen.dart
│   ├── investment_screen.dart
│   ├── main_screen.dart
│   ├── real_estate_screen.dart
│   └── stats_screen.dart
├── services/
│   └── game_service.dart
├── utils/
│   ├── number_formatter.dart
│   ├── sounds.dart           
│   └── time_utils.dart
├── widgets/
│   ├── business_item.dart
│   ├── investment_item.dart
│   ├── money_display.dart
│   └── real_estate_property_item.dart
└── main.dart
```

## Extension Points

The architecture is designed to be extensible in these key areas:

1. **New Business Types**: Add to the business array in GameState
2. **Additional Investment Assets**: Add to the investments array in GameState
3. **New Real Estate Options**: Add to the realEstateLocales array in GameState
4. **UI Customization**: Theme can be modified in the main.dart file
5. **Game Mechanics**: Core logic in GameState can be extended with new features