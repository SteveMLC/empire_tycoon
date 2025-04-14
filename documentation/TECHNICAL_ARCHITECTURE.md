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
- Central state container for all game data
- Implements `ChangeNotifier` for the Provider pattern
- Manages player resources, assets, and game progression
- Tracks game time and financial metrics
- Coordinates timers for passive income and auto-save
- Responsible for serialization/deserialization of game data

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
- Coordinates between persistence layer and game state
- Manages saving/loading game data
- Handles offline progression calculations
- Coordinates sound effects and game events
- Initializes game systems and dependencies

#### SoundManager (`assets/sounds.dart`)
- Loads and caches sound resources
- Plays appropriate sound effects for game events
- Manages audio settings and volume control

### Screens

#### MainScreen (`screens/main_screen.dart`)
- Root UI container with tabbed navigation
- Manages tab controller and navigation state
- Displays persistent UI elements (money display)
- Coordinates between different gameplay screens

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
- Displays investment opportunities and owned assets
- Shows market data and price trends
- Implements buy/sell mechanics
- Visualizes portfolio performance

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
- Shows current player balance with formatting
- Animates value changes
- Provides visual hierarchy for currency display

#### BusinessItem (`widgets/business_item.dart`)
- List item for business display
- Shows business state, level, and income
- Contains upgrade button and progress indicators

#### InvestmentItem (`widgets/investment_item.dart`)
- Displays individual investment assets
- Shows price trends and ownership information
- Contains buy/sell controls

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
- Handles time-based calculations
- Formats timestamps
- Calculates offline progression

## State Management

The application uses the Provider pattern for state management:

1. `GameState` class extends `ChangeNotifier`
2. `MultiProvider` in `main.dart` provides:
   - `GameService` as a straight Provider
   - `GameState` as a ChangeNotifierProvider
3. Screens and widgets consume state using `Consumer<GameState>` or `Provider.of<GameState>(context)`
4. State changes trigger UI rebuilds through the notifier pattern

## Persistence

Game persistence is implemented through:

1. `SharedPreferences` for local storage
2. JSON serialization/deserialization of game state
3. Regular auto-saving on state changes
4. Offline progression calculation based on timestamps

## Initialization Flow

1. Show loading screen first (`LoadingApp`)
2. Initialize core systems in the background:
   - Set device orientation to portrait
   - Handle web-specific initialization
   - Initialize SharedPreferences
   - Create GameState instance
   - Initialize GameService
   - Load saved game data if available
3. Calculate offline progress if applicable
4. Switch to main game UI (`EmpireTycoonApp`)
5. Start passive income timers and auto-save timer

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

## Code Organization

```
lib/
├── assets/
│   └── sounds.dart
├── models/
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