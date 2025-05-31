# Dependency Map

This document details the comprehensive relationships and dependencies between major components of Empire Tycoon, a sophisticated cross-platform Flutter game with modular architecture and advanced feature systems.

## Core Flutter Structure

### Application Entry Point
- **`lib/main.dart`**: Application entry point with multi-provider setup and initialization flow
  - Initializes SharedPreferences and Flutter bindings
  - Sets up MaterialApp with theming and routing
  - Configures Provider architecture for state management
  - Handles GameInitializer widget for startup flow

### Modular GameState Architecture (`lib/models/game_state/`)
The GameState is decomposed into 16 specialized part files for maximum maintainability:

#### Core Logic Modules
- **`initialization_logic.dart`** (1,826 lines): Complete game setup and data loading
- **`serialization_logic.dart`** (700 lines): JSON save/load with error handling
- **`investment_logic.dart`** (628 lines): Market simulation and portfolio management
- **`platinum_logic.dart`** (577 lines): Premium currency system and vault purchases
- **`update_logic.dart`** (508 lines): Game loop management and timer coordination

#### Feature-Specific Modules
- **`real_estate_logic.dart`** (360 lines): Property management and cash flow
- **`prestige_logic.dart`** (321 lines): Reincorporation system with state preservation
- **`utility_logic.dart`** (255 lines): Helper functions and cross-module utilities
- **`event_logic.dart`** (174 lines): Negative event system with resolution mechanics
- **`business_logic.dart`** (170 lines): Business management and ROI calculations
- **`offline_income_logic.dart`** (147 lines): Sophisticated offline progression

#### Supporting Modules
- **`notification_logic.dart`** (103 lines): Multi-layered notification system
- **`booster_logic.dart`** (99 lines): Temporary boost management with cooldowns
- **`challenge_logic.dart`** (82 lines): Dynamic challenge system with rewards
- **`income_logic.dart`** (63 lines): Real-time income calculations
- **`achievement_logic.dart`** (55 lines): Achievement progression tracking

### Model Layer (`lib/models/`)
- **`game_state.dart`**: Central state management with ChangeNotifier
- **`business.dart`**: Business entity definitions and calculations
- **`investment.dart`**: Investment asset models and market behavior
- **`real_estate.dart`**: Property and locale definitions
- **`event.dart`**: Event system models and resolution types
- **`achievement.dart`**: Achievement definitions and progress tracking
- **`challenge.dart`**: Challenge system models
- **`premium_avatar.dart`**: Premium avatar system
- **`mogul_avatar.dart`**: Mogul avatar unlocking system

### Service Layer (`lib/services/`)
- **`game_service.dart`** (243 lines): Core game initialization and management
- **`income_service.dart`** (195 lines): Income calculation and offline progression
- **`components/persistence_service.dart`**: Data persistence and serialization

### Screen Architecture (`lib/screens/`)
#### Main Navigation Screens (11 total)
- **`main_screen.dart`** (226 lines): Tabbed navigation hub with notifications
- **`hustle_screen.dart`** (670 lines): Enhanced tapping mechanics
- **`business_screen.dart`** (145 lines): Business management interface
- **`investment_screen.dart`** (276 lines): Portfolio overview
- **`investment_detail_screen.dart`** (802 lines): Detailed investment analysis
- **`real_estate_screen.dart`** (1,245 lines): Property management across 20 locales
- **`stats_screen.dart`** (1,659 lines): Advanced analytics dashboard
- **`platinum_vault_screen.dart`** (79 lines): Premium currency marketplace
- **`user_profile_screen.dart`** (1,528 lines): Avatar customization
- **`splash_screen.dart`** (158 lines): Initialization and loading

### Widget Ecosystem (`lib/widgets/`)
#### Premium/Platinum Widgets (40+ components)
- **`platinum_crest_avatar.dart`** (325 lines): Premium avatar display
- **`platinum_spire_trophy.dart`** (532 lines): Trophy system with effects
- **`platinum_facade_selector.dart`** (187 lines): Business facade customization
- **`vault_item_card.dart`** (884 lines): Complex purchase interface

#### Notification Widgets
- **`achievement_notification.dart`** (570 lines): Multi-tier achievement display
- **`event_notification.dart`** (557 lines): Crisis management interface
- **`challenge_notification.dart`** (328 lines): Challenge progress display
- **`offline_income_notification.dart`** (453 lines): Offline earnings summary

#### Core Game Widgets
- **`business_item.dart`** (919 lines): Business management interface
- **`investment_item.dart`** (396 lines): Investment trading interface
- **`real_estate_property_item.dart`** (244 lines): Property purchase interface
- **`money_display.dart`** (86 lines): Currency formatting and display

### Data Layer (`lib/data/`)
- **`business_definitions.dart`** (271 lines): Business configurations
- **`investment_definitions.dart`** (130 lines): Investment asset definitions
- **`real_estate_data_loader.dart`** (168 lines): 20 locales with properties
- **`achievement_definitions.dart`** (229 lines): 29 achievements with tracking
- **`platinum_vault_items.dart`** (323 lines): Vault item configurations

### Utility Layer (`lib/utils/`)
- **`number_formatter.dart`**: Currency and large number formatting
- **`time_utils.dart`**: Time-related operations and formatting
- **Sound management**: Categorized audio system integration

### Theming & Visual (`lib/painters/`, `lib/themes/`)
- **Custom painters**: Premium visual effects and animations
- **Theme system**: Material Design with adaptive theming
- **Visual effects**: Platinum gradients, glow effects, and particles

## Data Flow Architecture

### Primary Data Flow
```
User Interaction → Screens/Widgets → Services → GameState (16 modules) → Persistence
                                         ↓
                    Reactive UI Updates ← Provider/ChangeNotifier ← State Changes
```

### Detailed Component Interactions

#### State Management Flow
1. **User Actions**: UI interactions trigger method calls on GameState
2. **Business Logic**: Appropriate part file handles the logic (e.g., platinum_logic.dart)
3. **State Updates**: Changes are made to GameState properties
4. **Notification**: ChangeNotifier triggers UI rebuilds
5. **Persistence**: Auto-save system persists changes to SharedPreferences

#### Service Dependencies
- **GameService** depends on:
  - GameState (for state management)
  - SharedPreferences (for persistence)
  - Sound system (for audio feedback)
- **IncomeService** depends on:
  - GameState (for income calculations)
  - Event system (for income modifiers)
  - Platinum system (for boost effects)

#### Widget Dependencies
- **Screens** depend on:
  - GameState (via Provider.of or Consumer)
  - GameService (for actions and sound)
  - Theme system (for consistent styling)
- **Custom Widgets** depend on:
  - Specific GameState properties
  - Callback functions for user actions
  - Theme and styling systems

## Platform Integration

### Cross-Platform Support
- **Android**: Google Play deployment with native optimizations
- **Web**: Browser compatibility with responsive design
- **Windows**: Desktop integration with platform-specific features
- **iOS**: Planned deployment with platform adaptations

### Platform-Specific Dependencies
- **SharedPreferences**: Local storage across all platforms
- **Flutter framework**: Core UI and platform abstraction
- **Platform channels**: Native feature integration where needed
- **Audio system**: Platform-specific audio implementation

## External Dependencies

### Core Flutter Dependencies
```yaml
flutter: sdk
provider: ^6.1.4          # State management
shared_preferences: ^2.2.2 # Local storage
intl: ^0.18.1             # Internationalization
```

### UI & Visual Dependencies
```yaml
fl_chart: ^0.62.0         # Chart rendering
font_awesome_flutter: ^10.6.0 # Icon library
google_fonts: ^4.0.4     # Typography
flutter_svg: ^2.0.9      # SVG support
```

### Audio & Interaction Dependencies
```yaml
audioplayers: ^5.2.1     # Sound system
flutter_vibrate: git     # Haptic feedback
```

### Utility Dependencies
```yaml
uuid: ^3.0.7             # Unique ID generation
vector_math: 2.1.4       # Mathematical operations
collection: 1.19.1       # Collection utilities
```

## Dependency Relationships

### Circular Dependency Prevention
- **Modular GameState**: Part files prevent circular dependencies
- **Service Layer**: Clear separation between services and state
- **Widget Composition**: Widgets depend on state, not each other
- **Data Layer**: Static configurations have no runtime dependencies

### Dependency Injection
- **Provider Pattern**: Dependency injection at application root
- **Service Locator**: GameService provides access to other services
- **Context-Based Access**: Widgets access dependencies via BuildContext
- **Lazy Loading**: Services initialized only when needed

## Extension Points

### Adding New Features
1. **New Business Types**: Add to business_definitions.dart and business_logic.dart
2. **Investment Categories**: Extend investment_definitions.dart and investment_logic.dart
3. **Real Estate Locales**: Add to real_estate_data_loader.dart and real_estate_logic.dart
4. **Achievements**: Extend achievement_definitions.dart and achievement_logic.dart
5. **Platinum Items**: Add to platinum_vault_items.dart and platinum_logic.dart

### System Integration Points
- **Event System**: Integrates with all income-generating systems
- **Achievement System**: Monitors progress across all game systems
- **Platinum System**: Provides enhancements to all game mechanics
- **Statistics System**: Aggregates data from all game components

## Performance Considerations

### Dependency Optimization
- **Lazy Loading**: Services and data loaded only when needed
- **Targeted Updates**: ChangeNotifier updates only affected UI components
- **Memory Management**: Limited historical data with rolling windows
- **Calculation Caching**: Smart caching for expensive operations

### Scalability Design
- **Modular Architecture**: Easy addition of new systems and features
- **Configuration-Driven**: Static data enables rapid content expansion
- **Service Abstraction**: Clear interfaces for system interactions
- **Platform Abstraction**: Consistent behavior across platforms

## Security & Data Integrity

### Data Protection
- **Local Storage**: Secure SharedPreferences implementation
- **State Validation**: Input validation and sanitization
- **Error Handling**: Comprehensive error recovery mechanisms
- **Data Migration**: Version-safe data structure evolution

### Dependency Security
- **Package Auditing**: Regular review of external dependencies
- **Version Pinning**: Specific versions to prevent compatibility issues
- **Security Updates**: Timely updates for security vulnerabilities
- **Platform Compliance**: Adherence to platform security requirements

This comprehensive dependency map reflects the sophisticated architecture of Empire Tycoon, with clear separation of concerns, modular design, and robust dependency management enabling scalable development and maintenance.
