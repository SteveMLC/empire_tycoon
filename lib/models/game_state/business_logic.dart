part of '../game_state.dart';

// Contains methods related to Business management
extension BusinessLogic on GameState {

  // Buy/Start Upgrade for a business
  bool buyBusiness(String businessId) {
    int index = businesses.indexWhere((b) => b.id == businessId);
    if (index == -1) return false;

    Business business = businesses[index];

    // Check if it's already at max level or currently upgrading
    if (business.isMaxLevel() || business.isUpgrading) {
        print("Cannot upgrade business ${business.id}: Max level or already upgrading.");
        return false;
    }

    double cost = business.getNextUpgradeCost();
    int timerSeconds = business.getNextUpgradeTimerSeconds();

    if (money >= cost) {
      money -= cost;

      // Unlock if it was level 0
      if (business.level == 0) {
        business.unlocked = true;
      }

      // If timer is 0, complete instantly (like original behavior)
      if (timerSeconds <= 0) {
        print("Instant upgrade for ${business.name} (Level ${business.level + 1})");
        business.level++; // Direct level up
        _updateBusinessUnlocks(); // Update unlocks based on new level
      } else {
        // Start the timer
        print("Starting upgrade for ${business.name} (to Level ${business.level + 1}) - Duration: ${timerSeconds}s");
        business.startUpgrade(timerSeconds);
        // Note: Level increase happens in completeBusinessUpgrade
      }

      notifyListeners();
      return true;
    }

    return false;
  }

  // ADDED: Method to complete a finished business upgrade
  void completeBusinessUpgrade(String businessId) {
    int index = businesses.indexWhere((b) => b.id == businessId);
    if (index == -1) return;

    Business business = businesses[index];

    // Check if it was upgrading and the time is up
    if (business.isUpgrading && (business.upgradeEndTime == null || business.upgradeEndTime!.isBefore(DateTime.now()))) {
      print("✅ Completing upgrade for ${business.name} (Level ${business.level + 1})");
      int previousLevel = business.level;
      business.completeUpgrade(); // This increments the level internally

      // Play sound only if the upgrade wasn't completed instantly offline during load
      // (We might need a more robust way to track if sound should play)
      if (previousLevel < business.level) { 
         // TODO: Integrate sound playing here based on GameService - requires context or a different approach
         // Example placeholder:
         // Provider.of<GameService>(context, listen: false).soundManager.playBusinessUpgradeSound();
         print("🔊 (Placeholder) Play upgrade completion sound for ${business.name}");
      }

      _updateBusinessUnlocks(); // Check if new unlocks are triggered
      notifyListeners();
    } else {
      print("⚠️ Attempted to complete upgrade for ${business.name}, but not ready.");
    }
  }

  // ADDED: Method to speed up an upgrade using an Ad reward
  void speedUpUpgradeWithAd(String businessId) {
    int index = businesses.indexWhere((b) => b.id == businessId);
    if (index == -1) return;

    Business business = businesses[index];

    if (business.isUpgrading) {
      Duration reduction = const Duration(minutes: 15);
      print("⏩ Speeding up upgrade for ${business.name} by ${reduction.inMinutes} minutes.");

      // --- TODO: Placeholder for actual Ad logic ---
      // 1. Trigger Ad display using an Ad service
      // 2. On successful ad completion (callback): 
      business.reduceUpgradeTime(reduction);
      // Check if the upgrade is now complete after reduction
      if (business.getRemainingUpgradeTime() <= Duration.zero) {
        completeBusinessUpgrade(businessId);
      } else {
        notifyListeners(); // Notify UI about the reduced time
      }
      // --- End Placeholder ---

    } else {
       print("⚠️ Cannot speed up upgrade for ${business.name}: Not currently upgrading.");
    }
  }

  // Update which businesses are unlocked based on money
  void _updateBusinessUnlocks() {
    // Count businesses owned for event system
    businessesOwnedCount = businesses.where((b) => b.level > 0).length;

    for (var business in businesses) {
      if (!business.unlocked) {
        if (business.id == 'fitness_studio' && money >= 10000.0) {
          business.unlocked = true;
        } else if (business.id == 'ecommerce_store' && money >= 50000.0) {
          business.unlocked = true;
        } else if (business.id == 'craft_brewery' && money >= 250000.0) {
          business.unlocked = true;
        } else if (business.id == 'boutique_hotel' && money >= 1000000.0) {
          business.unlocked = true;
        } else if (business.id == 'film_studio' && money >= 5000000.0) {
          business.unlocked = true;
        } else if (business.id == 'logistics_company' && money >= 25000000.0) {
          business.unlocked = true;
        } else if (business.id == 'real_estate_developer' && money >= 100000000.0) {
          business.unlocked = true;
        } else if (business.id == 'platinum_venture' && isPlatinumVentureUnlocked && money >= 500000000.0) {
          business.unlocked = true;
        }
      }
    }
     // No notifyListeners() here, often called within loops or by parent methods
  }

  // Calculate the total business income per second (with multipliers)
  double getBusinessIncomePerSecond() {
    double total = 0.0;
    for (var business in businesses) {
      if (business.level > 0) {
        // Check if business is affected by an event
        bool hasEvent = hasActiveEventForBusiness(business.id);
        // Apply multipliers
        total += business.getCurrentIncome() * incomeMultiplier * prestigeMultiplier;
      }
    }
    return total;
  }

} 