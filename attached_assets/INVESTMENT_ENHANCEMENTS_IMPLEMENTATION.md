# Investment Enhancements Implementation

## Overview
This document outlines proposed enhancements for the investment system in Empire Tycoon. These improvements build upon the existing system with clean, focused additions that enhance player engagement and strategic depth without major refactoring of the codebase.

## Proposed Enhancements

### 1. Investment Detail Screen
Add a detailed screen that shows expanded information about an investment when tapped.

```dart
// New screen: lib/screens/investment_detail_screen.dart
// Accessed by tapping on an investment in the investment screen
// Shows expanded price history with proper chart visualization
// Includes investment news and events that affect prices
// Displays performance metrics and detailed stats
```

### 2. Investment Categories and Filtering
Organize investments into categories with filtering options.

```dart
// Add to Investment model
final String category; // e.g., 'Technology', 'Energy', 'Real Estate', etc.

// Add to InvestmentScreen
List<String> categories = ['All', 'Technology', 'Energy', 'Finance', 'Consumer']; 
String selectedCategory = 'All';

// Add category chips to InvestmentScreen
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: categories.map((category) => 
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FilterChip(
          label: Text(category),
          selected: selectedCategory == category,
          onSelected: (selected) {
            setState(() {
              selectedCategory = category;
            });
          },
        ),
      )
    ).toList(),
  ),
)
```

### 3. Diversification Bonus
Implement a bonus system that rewards portfolio diversification.

```dart
// Add to GameState
double calculateDiversificationBonus() {
  // Count investments owned across different categories
  Set<String> categories = {};
  for (var investment in investments) {
    if (investment.owned > 0) {
      categories.add(investment.category);
    }
  }
  
  // Calculate bonus (e.g., 2% per category)
  return categories.length * 0.02; // Return as decimal, e.g., 0.06 for 6%
}

// Apply this bonus to investment earnings in the daily update function
```

### 4. Market Events System
Implement special market events that temporarily affect prices.

```dart
// Add to GameState
class MarketEvent {
  final String name;
  final String description;
  final Map<String, double> categoryImpacts; // Map of category to impact multiplier
  final int durationDays;
  int remainingDays;
  
  MarketEvent({
    required this.name,
    required this.description,
    required this.categoryImpacts,
    required this.durationDays,
    this.remainingDays = 0,
  });
}

List<MarketEvent> activeMarketEvents = [];

// Add market event creation to the daily update
void _generateMarketEvents() {
  // Small chance to generate a new market event
  if (Random().nextDouble() < 0.15) { // 15% chance per day
    // Create a random market event
    MarketEvent newEvent = _createRandomMarketEvent();
    activeMarketEvents.add(newEvent);
  }
  
  // Apply effects of active events
  for (var event in activeMarketEvents) {
    for (var investment in investments) {
      // Apply impact if the investment's category is affected
      if (event.categoryImpacts.containsKey(investment.category)) {
        double impact = event.categoryImpacts[investment.category]!;
        investment.currentPrice *= impact;
      }
    }
    
    // Decrease remaining days
    event.remainingDays--;
  }
  
  // Remove expired events
  activeMarketEvents.removeWhere((event) => event.remainingDays <= 0);
}

// Display active market events in the Market Overview section
```

### 5. Investment Forecasting
Add simple forecasting indicators to help guide investment decisions.

```dart
// Add to Investment model
String getForecast() {
  // Analyze price history and trend to predict future movement
  // Simple algorithm based on current trend, volatility, and recent history
  
  double recentTrend = 0;
  if (priceHistory.length >= 3) {
    int lastIndex = priceHistory.length - 1;
    recentTrend = (priceHistory[lastIndex] - priceHistory[lastIndex - 2]) / priceHistory[lastIndex - 2];
  }
  
  double projectedTrend = (trend + recentTrend) / 2;
  
  if (projectedTrend > 0.03) return "Strong Buy";
  if (projectedTrend > 0.01) return "Buy";
  if (projectedTrend > -0.01) return "Hold";
  if (projectedTrend > -0.03) return "Sell";
  return "Strong Sell";
}

// Display forecast in the investment item with appropriate color coding
```

### 6. Dollar-Cost Averaging
Add an auto-invest feature that allows players to set up recurring investments.

```dart
// Add to Investment model
bool autoInvestEnabled = false;
double autoInvestAmount = 0;

// Add to GameState
void processAutoInvestments() {
  for (var investment in investments) {
    if (investment.autoInvestEnabled && investment.autoInvestAmount > 0) {
      // Calculate how many shares can be purchased
      int quantity = (investment.autoInvestAmount / investment.currentPrice).floor();
      
      // Purchase if possible
      if (quantity > 0 && money >= investment.autoInvestAmount) {
        buyInvestment(investment.id, quantity);
      }
    }
  }
}

// Add toggle switch and amount selector to InvestmentItem
```

## Implementation Notes

### UI Changes
1. **InvestmentItem**: Update to include category badges and forecast indicators
2. **InvestmentScreen**: Add category filtering controls and market event notifications
3. **New InvestmentDetailScreen**: Create for expanded analysis and controls

### Data Model Changes
1. **Investment**: Add category field, forecast calculation, auto-invest properties
2. **GameState**: Add market events list, diversification bonus calculation

### Business Logic Additions
1. **Market Events**: Generation and application logic
2. **Auto-Invest**: Processing during daily updates
3. **Diversification**: Bonus calculation and application

## Expected Result
When implementation is complete, the investment system will offer:

1. More strategic depth through diversification incentives
2. Greater immersion with market events and news
3. Additional guidance through forecasting
4. More automation options with auto-investing
5. Better organization with categories and filtering
6. Detailed analysis through the investment detail screen

## Phase 1 Priority Features
For initial implementation, the following features will provide the most value with minimal code changes:

1. **Categories and Filtering**: Improves organization and UI immediately
2. **Forecasting Indicators**: Adds strategic depth with minimal back-end changes
3. **Market Events**: Creates dynamic gameplay with high engagement value

Features to consider for Phase 2:
- Investment Detail Screen (requires more complex charting)
- Auto-Invest (requires additional UI controls)
- Diversification Bonus (requires balancing with other game mechanics)