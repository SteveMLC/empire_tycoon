# Net Worth Ticker Widget

## Overview

The Net Worth Ticker is a draggable floating widget that displays the player's lifetime earnings in real-time. It provides an eye-catching, always-visible indicator of financial progress throughout the game.

## Features

### Visual Design
- **Crown Icon**: Gold/yellow crown emoji (👑) as the primary visual element
- **Semi-transparent background**: Dark gradient with amber border and subtle glow
- **Gold gradient text**: Animated dollar amount with multi-tone gold gradient shader
- **Rounded corners**: Modern, polished appearance
- **Smooth animations**: Entrance, number transitions, and expand/collapse animations

### States

#### Collapsed State (Default)
- Small circular widget showing only the crown icon
- Dimensions: 60x60 pixels
- Position: Persists between sessions (default top-right)
- **Interaction**: Tap to expand

#### Expanded State
- Shows "LIFETIME NET WORTH" label
- Large animated dollar amount displaying `totalEarned` from GameState
- Numbers smoothly animate when earnings increase
- Dimensions: ~280x100 pixels
- **Interaction**: Tap crown icon to collapse

### Draggable Behavior
- User can drag the widget anywhere on screen in both states
- Position is constrained to screen bounds with padding
- Position persists in GameState and across sessions
- Visual feedback during drag (enhanced glow)
- Smooth position updates

### Real-time Animation
- Updates every second to check for earnings changes
- Smooth number animation using `AnimatedBuilder`
- Animates from previous value to new value over 800ms
- Uses cubic easing curve for natural feel
- Only triggers animation for changes > $1 (performance optimization)

## Technical Implementation

### Files Modified

#### 1. `lib/widgets/net_worth_ticker.dart` (NEW)
- Stateful widget with `TickerProviderStateMixin` for animations
- `AnimationController` for smooth number transitions
- `Timer` for periodic updates
- `Draggable` widget for drag behavior
- `Consumer<GameState>` for reactive state management

#### 2. `lib/models/game_state.dart`
Added state fields:
```dart
Offset? netWorthTickerPosition;
bool isNetWorthTickerExpanded = false;
```

Added methods:
```dart
void toggleNetWorthTicker()
void setNetWorthTickerPosition(Offset position)
```

#### 3. `lib/screens/main_screen.dart`
- Added import: `import '../widgets/net_worth_ticker.dart';`
- Added widget to Stack: `const NetWorthTicker()`
- Positioned after `EventCornerBadge` for proper z-index

#### 4. `lib/models/game_state/serialization_logic.dart`
Added to `toJson()`:
```dart
'netWorthTickerPosition': netWorthTickerPosition != null ? {
  'dx': netWorthTickerPosition!.dx,
  'dy': netWorthTickerPosition!.dy,
} : null,
'isNetWorthTickerExpanded': isNetWorthTickerExpanded,
```

Added to `fromJson()`:
```dart
if (json['netWorthTickerPosition'] != null) {
  final posData = json['netWorthTickerPosition'] as Map;
  netWorthTickerPosition = Offset(
    (posData['dx'] as num).toDouble(),
    (posData['dy'] as num).toDouble(),
  );
}
isNetWorthTickerExpanded = json['isNetWorthTickerExpanded'] ?? false;
```

## Architecture Patterns Used

### 1. Event Notification Pattern
Referenced the existing `EventNotification` widget for draggable behavior patterns, though simplified for this use case.

### 2. State Persistence
Follows the pattern used by other UI widgets (like real estate locale selection) for persisting position and state.

### 3. Animation Best Practices
- Uses `TickerProviderStateMixin` for animation lifecycle
- Proper disposal of controllers and timers
- Debouncing with change threshold to reduce unnecessary animations

### 4. Provider Pattern
Uses `Consumer<GameState>` for reactive updates when position or expanded state changes.

## Performance Considerations

1. **Timer Management**: Single 1-second timer for updates (not per-frame)
2. **Animation Threshold**: Only animates for changes > $1
3. **Selective Rebuilds**: Only rebuilds when relevant state changes
4. **Proper Cleanup**: Disposes controllers and timers in `dispose()`

## User Experience

### Discovery
- Widget is visible by default in collapsed state
- Crown icon is distinctive and inviting to tap
- Position defaults to non-intrusive top-right area

### Interaction
- Simple tap to expand/collapse
- Intuitive drag-and-drop positioning
- Visual feedback (glow) during interaction
- Position persists, so users can set it once

### Visual Appeal
- Eye-catching gold gradient matches game's wealth theme
- Smooth animations provide satisfying feedback
- Semi-transparent to not obstruct gameplay
- High z-index ensures visibility

## Future Enhancement Ideas

1. **Additional Stats**: Click to cycle through different lifetime stats
2. **Sparkle Effects**: Add particle effects when large earnings occur
3. **Milestones**: Visual celebration when crossing major thresholds
4. **Sound Effects**: Optional audio feedback on expand/large earnings
5. **Theme Customization**: Allow color/style changes (Platinum Vault item?)
6. **Compact Mode**: Even smaller collapsed state for minimalists

## Testing Checklist

- [ ] Widget appears on screen at default position
- [ ] Tap toggles between collapsed and expanded states
- [ ] Drag repositions the widget smoothly
- [ ] Position persists after app restart
- [ ] Numbers animate smoothly as earnings increase
- [ ] Widget stays within screen bounds when dragged
- [ ] No performance issues (check with profiler)
- [ ] Works on different screen sizes
- [ ] State saves/loads correctly
- [ ] No memory leaks (timers/controllers disposed)

## Known Issues

None currently identified.

## Version History

- **v1.0** (2025-02-05): Initial implementation
  - Draggable crown icon
  - Expand/collapse toggle
  - Real-time earnings display
  - Smooth number animations
  - Position persistence
