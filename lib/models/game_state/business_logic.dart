part of '../game_state.dart';

// Contains methods related to Business management
extension BusinessLogic on GameState {

  // Buy a business
  bool buyBusiness(String businessId) {
    int index = businesses.indexWhere((b) => b.id == businessId);
    if (index == -1) return false;

    Business business = businesses[index];

    // Check if it's already at max level
    if (business.isMaxLevel()) return false;

    double cost = business.getNextUpgradeCost();

    if (money >= cost) {
      money -= cost;

      // Level up instead of increasing owned count
      business.level++;
      business.unlocked = true;

      // Update unlocking of higher businesses
      _updateBusinessUnlocks();

      notifyListeners();
      return true;
    }

    return false;
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