# Empire Tycoon - Technical Architecture

## Application Architecture

### Component Structure
Empire Tycoon follows a simplified Model-View architecture with services:

1. **Models**: Core data structures that represent game entities
2. **Views/Screens**: UI components that display game information and accept user interaction
3. **Services**: Business logic layer that coordinates between models and persistence
4. **Widgets**: Reusable UI components used across different screens
5. **Utils**: Helper functions and utilities

### Dependency Flow
```
User Interaction → Screens/Widgets → GameService → GameState → Persistence
```

## Key Components

### Models

#### GameState (`models/game_state.dart`)
- Central state container for all core game data (money, businesses, investments, real estate, events, achievements, etc.).
- Implements `ChangeNotifier` for reactive state updates via the Provider pattern.
- Manages player resources (money), assets (businesses, investments, properties), and overall game progression (taps, levels, reincorporation).
- Tracks game time (start time, save/open times) and detailed financial metrics (total earned, passive income, investment gains, net worth history).
- Coordinates timers for periodic updates (passive income calculation, auto-save, investment price changes).
- Responsible for serialization/deserialization of the entire game state for persistence.
- **Note:** The extensive logic for `GameState` is modularized using Dart's `part` directive, splitting functionality into separate files (e.g., `business_logic.dart`, `investment_logic.dart`, `serialization_logic.dart`) located in `lib/models/game_state/`.
- Manages the game's event system (triggering, tracking, resolution) and achievement system (tracking progress, awarding, notifications).

#### Business (`models/business.dart`)
- Represents a player-owned business entity
- Contains business metadata (name, description, icon)
- Tracks level, cost, and income generation
- Implements upgrade mechanics through BusinessLevel objects
- Calculates return on investment and efficiency metrics

#### Investment (`models/investment.dart`)
- Models stock market-like investments
- Tracks current price, owned quantity, and purchase price
- Implements price volatility and trend mechanics
- Calculates profit/loss and portfolio metrics
- Maintains price history for market analysis

#### RealEstate (`models/real_estate.dart`)
- Contains RealEstateProperty and RealEstateLocale classes
- Manages property acquisition and income generation
- Organizes properties by geographical themes
- Tracks ROI and cash flow from properties

### Services

#### GameService (`services/game_service.dart`)
- Orchestrates game initialization, loading, and saving.
- Acts as the interface to the persistence layer (`SharedPreferences`), managing the serialization and deserialization of `GameState`.
- Calculates offline progression based on time elapsed since the last save.
- Initializes and manages the core `SoundManager` and related sound assets.
- Sets up and manages timers for background tasks like auto-saving.
- Handles game version checking and data migration/reset if necessary.

#### SoundManager (`utils/sounds.dart`)
- Loads and caches sound resources
- Plays appropriate sound effects for game events
- Manages audio settings and volume control

### Screens

#### MainScreen (`screens/main_screen.dart`)
- The primary UI container after initialization, hosting the main gameplay interface.
- Implements a `Scaffold` with a `BottomNavigationBar` and `TabBarView` to manage navigation between core game sections (Hustle, Businesses, Investments, Real Estate, Stats).
- Manages the `TabController` to synchronize the bottom navigation bar and the displayed screen.
- Displays persistent UI elements in the `AppBar`, such as the player's current money (`MoneyDisplay` widget).
- Uses a `Stack` to potentially overlay important notifications (e.g., Offline Income, Achievements, Events) on top of the current screen.

#### HustleScreen (`screens/hustle_screen.dart`)
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