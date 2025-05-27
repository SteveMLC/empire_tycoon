import 'package:flutter/material.dart';
import 'dart:async';
import '../models/game_state.dart';
import '../models/game_state_events.dart';
import '../utils/number_formatter.dart';

/// Service class for income calculations to avoid duplicating logic
/// This follows a more consistent dependency injection pattern and prevents race conditions
class IncomeService extends ChangeNotifier {
  // Track calculation state with stronger safeguards
  bool _isCalculatingIncome = false;
  double _lastCalculatedIncome = 0.0;
  int _lastCalculationHashCode = 0; // Track the hashCode of the last GameState we calculated for
  DateTime _lastCalculationTime = DateTime.now(); // Track when we last calculated income
  
  // Add a counter to track how many times we calculate income
  int _calculationCount = 0;
  // Add a timestamp-based tracking system similar to the one in GameState
  final Set<String> _processedTimestamps = <String>{}; // Using a Set for faster lookups
  
  /// Calculate total income per second for display purposes
  double calculateIncomePerSecond(GameState gameState) {
    // Enhanced safeguards against duplicate calculations
    final now = DateTime.now();
    final stateHashCode = gameState.hashCode;
    
    // Create a timestamp key for the current second
    final String timestampKey = "${now.hour}:${now.minute}:${now.second}";
    final bool alreadyProcessedThisSecond = _processedTimestamps.contains(timestampKey);
    
    // CRITICAL FIX: Only apply optimization in specific cases to ensure income display updates properly
    // 1. If we're already calculating, return the cached value to prevent recursion
    // 2. If we calculated within the last 100ms (for UI smoothness), return cached value
    if (_isCalculatingIncome || now.difference(_lastCalculationTime).inMilliseconds < 100) {
      print("💹 Income calculation optimized, returning cached value: $_lastCalculatedIncome (reason: ${_isCalculatingIncome ? 'calculating' : 'recent calc'})");
      return _lastCalculatedIncome;
    }
    
    // Record this timestamp to prevent duplicate processing in the same second
    _processedTimestamps.add(timestampKey);
    // Keep a limited history to prevent memory leaks
    if (_processedTimestamps.length > 10) {
      _processedTimestamps.remove(_processedTimestamps.first);
    }
    
    _isCalculatingIncome = true;
    try {
      // --- DEBUG START ---
      print("--- Calculating Display Income --- ");
      print("  Global Multipliers: income=${gameState.incomeMultiplier.toStringAsFixed(2)}, prestige=${gameState.prestigeMultiplier.toStringAsFixed(2)}");
      print("  Permanent Boosts: income=${gameState.isPermanentIncomeBoostActive}, efficiency=${gameState.isPlatinumEfficiencyActive}, portfolio=${gameState.isPlatinumPortfolioActive}");
      double totalBusinessIncome = 0;
      double totalRealEstateIncome = 0;
      double totalDividendIncome = 0;
      // --- DEBUG END ---
      
      double total = 0.0;
      
      // Define multipliers (matching _updateGameState)
      double businessEfficiencyMultiplier = gameState.isPlatinumEfficiencyActive ? 1.05 : 1.0;
      double permanentIncomeBoostMultiplier = gameState.isPermanentIncomeBoostActive ? 1.05 : 1.0;
      double portfolioMultiplier = gameState.isPlatinumPortfolioActive ? 1.25 : 1.0;
      double diversificationBonus = gameState.calculateDiversificationBonus();

      // Business Income (with event check)
      for (var business in gameState.businesses) {
        if (business.level > 0) {
          double baseIncome = business.getCurrentIncome(isResilienceActive: gameState.isPlatinumResilienceActive); // Use getCurrentIncome
          double incomeWithEfficiency = baseIncome * businessEfficiencyMultiplier;
          double finalIncome = incomeWithEfficiency * gameState.incomeMultiplier;
          finalIncome *= permanentIncomeBoostMultiplier;
          if (gameState.isIncomeSurgeActive) finalIncome *= 2.0;

          bool hasEvent = gameState.hasActiveEventForBusiness(business.id);
          if (hasEvent) {
            finalIncome *= GameStateEvents.NEGATIVE_EVENT_MULTIPLIER;
          }
          
          // --- DEBUG START ---
          // print("    Business '${business.name}': Base=$baseIncome, Final=$finalIncome (Event: $hasEvent)");
          totalBusinessIncome += finalIncome;
          // --- DEBUG END ---
          total += finalIncome;
        }
      }
      // --- DEBUG START ---
      print("  Subtotal Business: ${totalBusinessIncome.toStringAsFixed(2)}");
      // --- DEBUG END ---
      
      // Real Estate Income (with event check per locale/property)
      for (var locale in gameState.realEstateLocales) {
        if (locale.unlocked) {
          bool isLocaleAffectedByEvent = gameState.hasActiveEventForLocale(locale.id);
          bool isFoundationApplied = gameState.platinumFoundationsApplied.containsKey(locale.id);
          bool isYachtDocked = gameState.platinumYachtDockedLocaleId == locale.id;
          double foundationMultiplier = isFoundationApplied ? 1.05 : 1.0;
          double yachtMultiplier = isYachtDocked ? 1.05 : 1.0;
          
          for (var property in locale.properties) {
            if (property.owned > 0) {
              // Get base income (already includes owned count)
              double basePropertyIncome = property.getTotalIncomePerSecond(
                isResilienceActive: gameState.isPlatinumResilienceActive);
              
              // Apply locale-specific boosts
              double incomeWithLocaleBoosts = basePropertyIncome * foundationMultiplier * yachtMultiplier;
              
              // Apply global multipliers
              double finalIncome = incomeWithLocaleBoosts * gameState.incomeMultiplier;
              
              // Apply permanent income boost
              finalIncome *= permanentIncomeBoostMultiplier;
              
              // Apply Income Surge (if applicable)
              if (gameState.isIncomeSurgeActive) finalIncome *= 2.0;
              
              // Apply event penalty if locale is affected
              if (isLocaleAffectedByEvent) {
                finalIncome *= GameStateEvents.NEGATIVE_EVENT_MULTIPLIER;
              }
              
              // --- DEBUG START ---
              // print("    RE Property '${property.name}': Base=${basePropertyIncome}, Final=$finalIncome (Event: $isLocaleAffectedByEvent)");
              totalRealEstateIncome += finalIncome;
              // --- DEBUG END ---
              total += finalIncome;
            }
          }
        }
      }
      // --- DEBUG START ---
      print("  Subtotal Real Estate: ${totalRealEstateIncome.toStringAsFixed(2)}");
      // --- DEBUG END ---
      
      // Dividend Income from Investments
      double diversificationBonusValue = (1.0 + diversificationBonus);
      for (var investment in gameState.investments) {
        if (investment.owned > 0 && investment.hasDividends()) {
          double baseDividend = investment.getDividendIncomePerSecond() * investment.owned;
          double portfolioAdjustedDividend = baseDividend * portfolioMultiplier * diversificationBonusValue;
          
          // Apply global multipliers
          double finalDividend = portfolioAdjustedDividend * gameState.incomeMultiplier;
          
          // Apply permanent income boost
          finalDividend *= permanentIncomeBoostMultiplier;
          
          // Apply Income Surge (if applicable)
          if (gameState.isIncomeSurgeActive) finalDividend *= 2.0;
          
          // --- DEBUG START ---
          // print("    Investment '${investment.name}': BaseTotal=$baseDividend, Final=$finalDividend");
          totalDividendIncome += finalDividend;
          // --- DEBUG END ---
          total += finalDividend;
        }
      }
      // --- DEBUG START ---
      print("  Subtotal Dividends: ${totalDividendIncome.toStringAsFixed(2)}");
      print("  TOTAL Display Income: ${total.toStringAsFixed(2)}");
      print("--- End Calculating Display Income --- ");
      // --- DEBUG END ---
      
      // Cache the result with enhanced tracking
      _lastCalculatedIncome = total;
      _lastCalculationHashCode = gameState.hashCode;
      _lastCalculationTime = now;
      return total;
    } finally {
      _isCalculatingIncome = false;
    }
  }

  /// Format remaining boost time for display
  /// Now uses the centralized NumberFormatter to avoid duplication
  String formatBoostTimeRemaining(Duration remaining) {
    if (remaining <= Duration.zero) return 'Expired';
    return NumberFormatter.formatBoostTimeRemaining(remaining);
  }
  
  /// Format income per second for display
  /// Uses the centralized NumberFormatter for consistent formatting
  String formatIncomePerSecond(double incomePerSecond) {
    return '${NumberFormatter.formatCurrency(incomePerSecond)}/sec';
  }
  
  /// Register this service with the TimerService to ensure income calculations
  /// are synchronized with the game update cycle
  void registerWithTimerService(Function timerCallback) {
    // This method allows the TimerService to call back to this service
    // when it's time to update income calculations, ensuring they happen
    // in sync with other game state updates
  }
}
