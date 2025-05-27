part of '../game_state.dart';

// Extension for handling offline income logic
extension GameStateOfflineIncome on GameState {
  // Constants
  static const int MAX_OFFLINE_SECONDS = 4 * 60 * 60; // 4 hours maximum

  // Getters for offline income state (now read from GameState)
  double get offlineIncome => this.offlineIncome;
  DateTime? get offlineIncomeStartTime => this.offlineIncomeStartTime;
  DateTime? get offlineIncomeEndTime => this.offlineIncomeEndTime;
  bool get showOfflineIncomeNotification => this.showOfflineIncomeNotification;



  // Process offline income based on last saved time
  // CRITICAL FIX: Added incomeService parameter to ensure consistent income calculation
  void processOfflineIncome(DateTime lastSavedTime, {dynamic incomeService}) {
    print("🕒 Calculating offline income...");
    
    final DateTime now = DateTime.now();
    
    // Ensure lastOpened is after lastSaved (handle clock tampering)
    if (!lastSavedTime.isBefore(now)) {
      print("⚠️ Last saved time is in the future. Skipping offline income calculation.");
      return;
    }

    // Calculate time difference in seconds
    final Duration offlineDuration = now.difference(lastSavedTime);
    final int offlineSeconds = offlineDuration.inSeconds;
    
    // Skip if offline for less than 30 seconds
    if (offlineSeconds < 30) {
      print("🕒 Offline for only $offlineSeconds seconds. Not applying offline income.");
      return;
    }

    // Get income rate per second at the time of last save
    // CRITICAL FIX: Use the IncomeService if provided, otherwise fall back to direct calculation
    // This ensures we use the exact same calculation as the UI display
    double incomePerSecond;
    if (incomeService != null) {
      // Use the same income calculation as the top panel
      incomePerSecond = incomeService.calculateIncomePerSecond(this);
      print("💰 Using IncomeService for offline income calculation");
    } else {
      // Fall back to direct calculation if service not provided
      incomePerSecond = calculateTotalIncomePerSecond();
      print("⚠️ Falling back to direct income calculation (not using IncomeService)");
    }
    
    print("🔍 DEBUG: Income breakdown for offline calculation:");
    double businessIncome = getBusinessIncomePerSecond();
    double realEstateIncome = getRealEstateIncomePerSecond();
    double dividendIncome = getDividendIncomePerSecond();
    print("   - Business income: ${NumberFormatter.formatCompact(businessIncome)}/sec");
    print("   - Real Estate income: ${NumberFormatter.formatCompact(realEstateIncome)}/sec");
    print("   - Dividend income: ${NumberFormatter.formatCompact(dividendIncome)}/sec");
    print("   - Total income with all multipliers: ${NumberFormatter.formatCompact(incomePerSecond)}/sec");
    
    // Cap offline time at 4 hours (14400 seconds)
    final int cappedOfflineSeconds = min(offlineSeconds, MAX_OFFLINE_SECONDS);
    
    // Calculate total offline income - make sure it's a simple multiplication
    // without any additional hidden multipliers
    final double calculatedOfflineIncome = incomePerSecond * cappedOfflineSeconds;
    
    // Debug logs for income calculation
    print("🔍 DEBUG: Offline income calculation:");
    print("   - Income per second: ${NumberFormatter.formatCompact(incomePerSecond)}/sec");
    print("   - Offline duration: $offlineSeconds seconds (capped at $cappedOfflineSeconds)");
    print("   - Raw calculation: $incomePerSecond × $cappedOfflineSeconds = $calculatedOfflineIncome");
    
    // Store times for notification display
    this.offlineIncomeStartTime = lastSavedTime;
    this.offlineIncomeEndTime = now;
    
    // Format time periods for logging
    String formattedOfflineTime = '';
    if (cappedOfflineSeconds < 60) {
      formattedOfflineTime = '$cappedOfflineSeconds seconds';
    } else if (cappedOfflineSeconds < 3600) {
      formattedOfflineTime = '${(cappedOfflineSeconds / 60).floor()} minutes';
    } else if (cappedOfflineSeconds < 86400) {
      formattedOfflineTime = '${(cappedOfflineSeconds / 3600).floor()} hours ${((cappedOfflineSeconds % 3600) / 60).floor()} minutes';
    } else {
      formattedOfflineTime = '24 hours (capped)';
    }
    
    // Apply the calculated income
    if (calculatedOfflineIncome > 0) {
      // Store calculated values in GameState fields
      this.offlineIncome = calculatedOfflineIncome;
      this.offlineIncomeStartTime = lastSavedTime;
      this.offlineIncomeEndTime = now;
      this.setOfflineIncomeAdWatched(false); // Reset ad-watched flag on new offline session

      // Set flag to show notification
      this.showOfflineIncomeNotification = true;

      print(
          "💰 Calculated offline income: ${NumberFormatter.formatCompact(calculatedOfflineIncome)} (from $cappedOfflineSeconds seconds offline at ${NumberFormatter.formatCompact(incomePerSecond)}/sec)");
    } else {
      // Ensure notification isn't shown if no income earned
      this.offlineIncome = 0.0;
      this.offlineIncomeStartTime = null;
      this.offlineIncomeEndTime = null;
      this.showOfflineIncomeNotification = false;
      print("🕒 Offline time: ${formattedOfflineTime}. No significant income generated.");
    }

    // Update last opened time
    this.lastOpened = now;
    notifyListeners(); // Notify after processing
  }

  /// Collect offline income - applies 2x if ad was watched
  void collectOfflineIncome() {
    if (!showOfflineIncomeNotification) return;
    double payout = offlineIncome;
    if (offlineIncomeAdWatched) {
      payout *= 2;
    }
    // Add to totals
    money += payout;
    totalEarned += payout;
    passiveEarnings += payout;
    // Dismiss and reset
    dismissOfflineIncomeNotification();
    _offlineIncomeAdWatched = false;
    notifyListeners();
  }

  // Dismiss the offline income notification
  void dismissOfflineIncomeNotification() {
    if (showOfflineIncomeNotification) {
      this.showOfflineIncomeNotification = false;
      // Reset income value after dismissal to prevent re-showing with old value
      this.offlineIncome = 0.0;
      this.offlineIncomeStartTime = null;
      this.offlineIncomeEndTime = null;
      setOfflineIncomeAdWatched(false);
      notifyListeners();
    }
  }
} 