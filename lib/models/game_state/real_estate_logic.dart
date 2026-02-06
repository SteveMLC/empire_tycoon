part of '../game_state.dart';

extension RealEstateLogic on GameState {
  // Update which real estate locales are unlocked
  void _updateRealEstateUnlocks() {
    int count = 0;
    bool changed = false;
    for (var locale in realEstateLocales) {
      // Determine if locale *should* be unlocked based on money or flags
      bool shouldBeUnlocked = false;
      
      if (locale.unlocked) {
        shouldBeUnlocked = true; // Already unlocked, skip checks
      } 
      // Platinum Islands Check (Independent of money)
      else if (locale.id == 'platinum_islands' && isPlatinumIslandsUnlocked) {
          shouldBeUnlocked = true;
      } 
      // Money Threshold Checks (Based on real_estate_screen.dart)
      else if (money >= 10000.0 && ['lagos_nigeria', 'rural_thailand', 'rural_mexico'].contains(locale.id)) {
        shouldBeUnlocked = true;
      } else if (money >= 50000.0 && ['cape_town_sa', 'mumbai_india', 'ho_chi_minh_city', 'bucharest_romania', 'lima_peru', 'sao_paulo_brazil'].contains(locale.id)) {
        shouldBeUnlocked = true;
      } else if (money >= 250000.0 && ['lisbon_portugal', 'berlin_germany', 'mexico_city'].contains(locale.id)) {
        shouldBeUnlocked = true;
      } else if (money >= 1000000.0 && ['singapore', 'london_uk', 'miami_florida', 'new_york_city', 'los_angeles'].contains(locale.id)) {
        shouldBeUnlocked = true;
      } else if (money >= 5000000.0 && ['hong_kong', 'dubai_uae'].contains(locale.id)) {
        shouldBeUnlocked = true;
      }
      // Note: 'rural_kenya' should start unlocked in initialization logic.

      // Update if state needs to change
      if (!locale.unlocked && shouldBeUnlocked) {
        locale.unlocked = true;
        changed = true;
        print("🔓 Locale Unlocked: ${locale.name} (Money: $money)");
        // Potentially add a notification or event here
      }

      // Count locales with properties
      if (locale.properties.any((p) => p.owned > 0)) {
        count++;
      }
    }
    localesWithPropertiesCount = count;
    if (changed) {
        notifyListeners(); // Notify only if an unlock happened
    }
    
    // Explicit Platinum Item Unlocks (Keep this logic)
    if (isPlatinumTowerUnlocked) {
      var dubaiLocale = realEstateLocales.firstWhere((l) => l.id == 'dubai_uae', orElse: () => RealEstateLocale(id: '', name: '', theme: '', unlocked: false, icon: Icons.error, properties: []));
      if (dubaiLocale.id.isNotEmpty) {
          var towerProperty = dubaiLocale.properties.firstWhere((p) => p.id == 'platinum_tower', orElse: () => RealEstateProperty(id: '', name: '', purchasePrice: 0, baseCashFlowPerSecond: 0));
          if (towerProperty.id.isNotEmpty && !towerProperty.unlocked) {
             towerProperty.unlocked = true;
          }
      }
    }
    if (isPlatinumIslandUnlocked) {
        var islandsLocale = realEstateLocales.firstWhere((l) => l.id == 'platinum_islands', orElse: () => RealEstateLocale(id: '', name: '', theme: '', unlocked: false, icon: Icons.error, properties: []));
        if (islandsLocale.id.isNotEmpty && islandsLocale.unlocked) {
             var islandProperty = islandsLocale.properties.firstWhere((p) => p.id == 'platinum_island', orElse: () => RealEstateProperty(id: '', name: '', purchasePrice: 0, baseCashFlowPerSecond: 0));
             if (islandProperty.id.isNotEmpty && !islandProperty.unlocked) {
                islandProperty.unlocked = true; 
             }
        }
    }
  }

  // Get total income per second from all owned real estate properties
  double getRealEstateIncomePerSecond() {
    double total = 0.0;
    for (var locale in realEstateLocales) {
      if (locale.unlocked) {
        // Get locale-specific multipliers
        bool isFoundationApplied = platinumFoundationsApplied.containsKey(locale.id);
        bool isYachtDocked = platinumYachtDockedLocaleId == locale.id;
        double foundationMultiplier = isFoundationApplied ? 1.05 : 1.0;
        double yachtMultiplier = isYachtDocked ? 1.05 : 1.0;
        
        // CRITICAL FIX: Check for active events affecting this locale
        bool hasActiveEvent = hasActiveEventForLocale(locale.id);
        
        // Process each property in the locale
        for (var property in locale.properties) {
          if (property.owned > 0) {
            // Get base income per property
            double basePropertyIncome = property.getTotalIncomePerSecond(isResilienceActive: isPlatinumResilienceActive);
            
            // Apply locale-specific multipliers
            double incomeWithLocaleBoosts = basePropertyIncome * foundationMultiplier * yachtMultiplier;
            
            // Apply global income multiplier
            double incomeWithGlobalMultiplier = incomeWithLocaleBoosts * incomeMultiplier;
            
            // Apply permanent income boost if active
            if (isPermanentIncomeBoostActive) {
              incomeWithGlobalMultiplier *= 1.05;
            }
            
            // Apply income surge if active
            if (isIncomeSurgeActive) {
              incomeWithGlobalMultiplier *= 2.0;
            }
            
            // CRITICAL FIX: Apply event penalty if locale is affected
            if (hasActiveEvent) {
              incomeWithGlobalMultiplier *= GameStateEvents.NEGATIVE_EVENT_MULTIPLIER;
            }
            
            total += incomeWithGlobalMultiplier;
          }
        }
      }
    }
    return total;
  }

  /// Paced cost to purchase one unit of this property (for display and affordability).
  double getEffectivePropertyPurchaseCost(String localeId, String propertyId) {
    for (var locale in realEstateLocales) {
      if (locale.id != localeId) continue;
      final propertyIndex = locale.properties.indexWhere((p) => p.id == propertyId);
      if (propertyIndex < 0) return 0.0;
      final property = locale.properties[propertyIndex];
      final int tier = PacingConfig.realEstateTierFromPropertyIndex(propertyIndex);
      return property.purchasePrice * PacingConfig.realEstateCostMultiplierForTier(tier);
    }
    return 0.0;
  }

  /// Paced cost for a property upgrade (for display and affordability).
  double getEffectiveUpgradeCost(String localeId, String propertyId, String upgradeId) {
    for (var locale in realEstateLocales) {
      if (locale.id != localeId) continue;
      final propertyIndex = locale.properties.indexWhere((p) => p.id == propertyId);
      if (propertyIndex < 0) return 0.0;
      final property = locale.properties[propertyIndex];
      final upgradeIndex = property.upgrades.indexWhere((u) => u.id == upgradeId);
      if (upgradeIndex < 0) return 0.0;
      final upgrade = property.upgrades[upgradeIndex];
      final int tier = PacingConfig.realEstateTierFromPropertyIndex(propertyIndex);
      return upgrade.cost * PacingConfig.realEstateCostMultiplierForTier(tier);
    }
    return 0.0;
  }

  // Buy a real estate property
  bool buyRealEstateProperty(String localeId, String propertyId) {
    RealEstateLocale? locale = realEstateLocales.firstWhere(
      (l) => l.id == localeId,
      orElse: () => null as RealEstateLocale, 
    );

    if (locale == null || !locale.unlocked) {
      print("DEBUG: Locale not found or locked ($localeId)");
      return false;
    }

    RealEstateProperty? property = locale.properties.firstWhere(
      (p) => p.id == propertyId,
      orElse: () => null as RealEstateProperty, 
    );

    if (property == null) {
      print("DEBUG: Property not found ($propertyId in $localeId)");
      return false;
    }

    final int propertyIndex = locale.properties.indexOf(property);
    final int tier = PacingConfig.realEstateTierFromPropertyIndex(propertyIndex);
    final double cost = property.purchasePrice * PacingConfig.realEstateCostMultiplierForTier(tier);
    print("DEBUG: Attempting to buy $propertyId. Cost: $cost, Money: $money");

    if (money >= cost) {
      money -= cost;
      property.owned++;

      // >> START: Add Achievement Tracking Update <<
      _updatePropertyOwnershipAchievements(property);
      // >> END: Add Achievement Tracking Update <<

      // Update unlocks after purchase might enable new tiers
      _updateRealEstateUnlocks(); // Ensure unlocks reflect new state

      notifyListeners();
      print("DEBUG: Purchase successful for $propertyId. Owned: ${property.owned}");
      return true;
    } else {
      print("DEBUG: Insufficient funds for $propertyId");
    }

    return false;
  }

  // Purchase a specific upgrade for a property
  bool purchasePropertyUpgrade(String localeId, String propertyId, String upgradeId) {
    RealEstateLocale? locale = realEstateLocales.firstWhere(
      (l) => l.id == localeId,
      orElse: () => null as RealEstateLocale, 
    );

    if (locale == null) return false;

    RealEstateProperty? property = locale.properties.firstWhere(
      (p) => p.id == propertyId,
      orElse: () => null as RealEstateProperty, 
    );

    if (property == null) return false;

    RealEstateUpgrade? upgrade = property.upgrades.firstWhere(
      (u) => u.id == upgradeId,
      orElse: () => null as RealEstateUpgrade, 
    );

    if (upgrade == null || upgrade.purchased) return false;

    final int propertyIndex = locale.properties.indexOf(property);
    final int tier = PacingConfig.realEstateTierFromPropertyIndex(propertyIndex);
    final double effectiveUpgradeCost = upgrade.cost * PacingConfig.realEstateCostMultiplierForTier(tier);

    if (money >= effectiveUpgradeCost) {
      money -= effectiveUpgradeCost;
      upgrade.purchased = true;
      totalRealEstateUpgradesPurchased++; // Increment total count

      // >> START: Add Achievement Tracking Update <<
      _updateUpgradePurchaseAchievements(property, upgrade);
      // >> END: Add Achievement Tracking Update <<

      notifyListeners();
      return true;
    }

    return false;
  }

  // Sell a real estate property
  bool sellRealEstateProperty(String localeId, String propertyId) {
    RealEstateLocale? locale = realEstateLocales.firstWhere(
      (l) => l.id == localeId,
      orElse: () => null as RealEstateLocale, 
    );

    if (locale == null) return false;

    RealEstateProperty? property = locale.properties.firstWhere(
      (p) => p.id == propertyId,
      orElse: () => null as RealEstateProperty, 
    );

    if (property == null || property.owned <= 0) return false;

    // Sell at current base price (potential for dynamic pricing later)
    double salePrice = property.purchasePrice * 0.8; // Sell for 80% of purchase price
    money += salePrice;
    property.owned--;

    // >> START: Add Achievement Tracking Update <<
    // Update relevant achievements when selling might affect counts
    _updatePropertyOwnershipAchievements(property); // Re-evaluate after selling
    // >> END: Add Achievement Tracking Update <<

    // Update unlocks after selling might disable tiers
    _updateRealEstateUnlocks();

    notifyListeners();
    return true;
  }

  // Helper to update achievements related to property ownership counts
  void _updatePropertyOwnershipAchievements(RealEstateProperty property) {
    // Re-evaluate counts related to this property's locale
    String localeId = realEstateLocales
        .firstWhere((loc) => loc.properties.contains(property))
        .id;
    fullyUpgradedPropertiesPerLocale[localeId] = realEstateLocales
        .firstWhere((loc) => loc.id == localeId)
        .properties
        .where((p) => p.allUpgradesPurchased)
        .length;

    // Check if this locale now has at least one fully upgraded property
    if (fullyUpgradedPropertiesPerLocale[localeId]! > 0) {
      localesWithOneFullyUpgradedProperty.add(localeId);
    } else {
      localesWithOneFullyUpgradedProperty.remove(localeId);
    }

    // Check if the locale is now fully upgraded
    bool localeFullyUpgraded = realEstateLocales
        .firstWhere((loc) => loc.id == localeId)
        .properties
        .every((p) => p.allUpgradesPurchased);
    if (localeFullyUpgraded) {
      fullyUpgradedLocales.add(localeId);
    } else {
      fullyUpgradedLocales.remove(localeId);
    }

    // Update overall count
    localesWithPropertiesCount = realEstateLocales.where((l) => l.properties.any((p) => p.owned > 0)).length;
  }

  // Helper to update achievements related to upgrade purchases
  void _updateUpgradePurchaseAchievements(RealEstateProperty property, RealEstateUpgrade upgrade) {
    totalUpgradeSpending += upgrade.cost;
    if (property.allUpgradesPurchased) {
      fullyUpgradedPropertyIds.add(property.id);
      // Trigger locale-based achievement updates as well
      _updatePropertyOwnershipAchievements(property);
    }
  }

  void _unlockLocalesById(List<String> localeIds) {
    // Implementation of _unlockLocalesById method
  }

  // Method to check if Platinum Stock should be unlocked
  void _checkPlatinumStockUnlock() {
    if (!isPlatinumStockUnlocked && ownsAllProperties()) {
        isPlatinumStockUnlocked = true;
        print("Platinum Stock Unlocked!");
        notifyListeners();
    }
  }

  // Method to reset real estate state for reincorporation
  void _resetRealEstateForReincorporation() {
    for (var locale in realEstateLocales) {
      locale.unlocked = (locale.id == 'rural_kenya'); // Keep starter locale unlocked
      for (var property in locale.properties) {
        property.owned = 0; 
        property.unlocked = false; 
        for (var upgrade in property.upgrades) {
          upgrade.purchased = false; 
        }
      }
    }
    _updateRealEstateUnlocks();
    notifyListeners(); 
  }

  // Method to calculate the total number of properties owned across all locales
  int getTotalOwnedProperties() {
    int total = 0;
    for (var locale in realEstateLocales) {
      if (locale.unlocked) {
        for (var property in locale.properties) {
          total += property.owned;
        }
      }
    }
    return total;
  }

  // Method to check if all properties in all *unlocked* locales are owned
  bool ownsAllProperties() {
    for (var locale in realEstateLocales) {
      if (locale.unlocked) {
        for (var property in locale.properties) {
          if (property.owned <= 0) {
            return false;
          }
        }
      }
    }
    return realEstateLocales.any((locale) => locale.unlocked);
  }

  // Method to get details of all owned properties
  List<Map<String, dynamic>> getAllOwnedPropertiesWithDetails() {
    List<Map<String, dynamic>> ownedProperties = [];
    for (var locale in realEstateLocales) {
      if (locale.unlocked) {
        for (var property in locale.properties) {
          if (property.owned > 0) {
            ownedProperties.add({
              'localeId': locale.id,
              'propertyId': property.id,
              'propertyName': property.name,
              'localeName': locale.name,
              'owned': property.owned,
              'currentIncomePerSecond': property.getTotalIncomePerSecond(),
            });
          }
        }
      }
    }
    return ownedProperties;
  }
}