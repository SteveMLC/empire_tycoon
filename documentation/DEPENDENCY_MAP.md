# Dependency Map

This document details the relationships and dependencies between major components of Empire Tycoon.

## Core Flutter Structure
- `lib/main.dart`: App entry point, initializes providers and navigation.
- `lib/models/`: Data models for game entities (businesses, investments, player state, etc).
- `lib/services/`: Business logic and state management (e.g., game_service.dart).
- `lib/screens/`: UI screens for player interaction.
- `lib/widgets/`: Reusable UI components.
- `lib/utils/`: Utility functions, helpers, and constants.
- `lib/data/`: Static and dynamic game data (e.g., asset lists, configs).
- `lib/providers/`: State management providers (if using Provider or Riverpod).
- `lib/themes/`: App themes and styling.
- `lib/painters/`: Custom painters for game visuals.

## Data Flow
- Models <-> Services: Services update and persist model data.
- Services <-> Providers: Providers expose service data to UI.
- Providers <-> Screens/Widgets: UI reacts to provider/state changes.

## Platform Integration
- Android: Google Play deployment, native plugins (if any)
- Web/Windows: Flutter web/desktop integration
- iOS: Planned, not yet implemented

## External Dependencies
- Flutter SDK
- Dart packages (see pubspec.yaml)
- Google Play Services (Android)

Refer to `TECHNICAL_ARCHITECTURE.md` for deeper code structure details.
