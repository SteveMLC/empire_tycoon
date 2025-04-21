part of '../game_state.dart';

extension RealEstateLogic on GameState {
  // Update which real estate locales are unlocked
  void _updateRealEstateUnlocks() {
    int count = 0;
    bool changed = false;
    for (var locale in realEstateLocales) {
      // Determine if locale *should* be unlocked based on money
      bool shouldBeUnlocked = false;
      if (locale.id == 'beachfront') {
        shouldBeUnlocked = true;
      } else if (locale.id == 'downtown' && money >= 500000) {
        shouldBeUnlocked = true;
      } else if (locale.id == 'suburbs' && money >= 2000000) {
        shouldBeUnlocked = true;
      } else if (locale.id == 'mountain_retreat' && money >= 10000000) {
        shouldBeUnlocked = true;
      } else if (locale.id == 'private_island' && money >= 100000000) {
        shouldBeUnlocked = true;
      }
      
      // ADDED: Check for Platinum Islands unlock flag
      else if (locale.id == 'platinum_islands' && isPlatinumIslandsUnlocked) {
          shouldBeUnlocked = true;
      }

      // Update if state needs to change
      if (!locale.unlocked && shouldBeUnlocked) {
        locale.unlocked = true;
        changed = true;
        print("🔓 Locale Unlocked: ${locale.name}");
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
    
    // ADDED: Explicitly unlock Platinum Tower if the flag is set
    if (isPlatinumTowerUnlocked) {
      var dubaiLocale = realEstateLocales.firstWhere((l) => l.id == 'dubai_uae', orElse: () => RealEstateLocale(id: '', name: '', theme: '', unlocked: false, icon: Icons.error, properties: []));
      if (dubaiLocale.id.isNotEmpty) {
          var towerProperty = dubaiLocale.properties.firstWhere((p) => p.id == 'platinum_tower', orElse: () => RealEstateProperty(id: '', name: '', purchasePrice: 0, baseCashFlowPerSecond: 0));
          if (towerProperty.id.isNotEmpty && !towerProperty.unlocked) {
             towerProperty.unlocked = true;
             // Don't notify here, rely on the standard unlock notification above if changes occurred.
          }
      }
    }
    // --- End Platinum Tower Unlock ---
    
    // ADDED: Explicitly unlock Platinum Island property if the flag is set
    if (isPlatinumIslandUnlocked) {
        var islandsLocale = realEstateLocales.firstWhere((l) => l.id == 'platinum_islands', orElse: () => RealEstateLocale(id: '', name: '', theme: '', unlocked: false, icon: Icons.error, properties: []));
        if (islandsLocale.id.isNotEmpty && islandsLocale.unlocked) { // Check if locale itself is unlocked first
             var islandProperty = islandsLocale.properties.firstWhere((p) => p.id == 'platinum_island', orElse: () => RealEstateProperty(id: '', name: '', purchasePrice: 0, baseCashFlowPerSecond: 0));
             if (islandProperty.id.isNotEmpty && !islandProperty.unlocked) {
                islandProperty.unlocked = true; 
             }
        }
    }
    // --- End Platinum Island Unlock ---
  }

  // Get total income per second from all owned real estate properties
  double getRealEstateIncomePerSecond() {
    double total = 0.0;
    for (var locale in realEstateLocales) {
      bool hasLocaleEvent = hasActiveEventForLocale(locale.id);
      // Pass isResilienceActive down to the property calculation within the locale method
      // This requires modifying RealEstateLocale.getTotalIncomePerSecond as well.
      // Let's adjust RealEstateLocale.getTotalIncomePerSecond first.
      // Assuming RealEstateLocale.getTotalIncomePerSecond is modified to accept the flag:
      // double localeBaseIncome = locale.getTotalIncomePerSecond(
      //   affectedByEvent: hasLocaleEvent, 
      //   isResilienceActive: isPlatinumResilienceActive // Pass flag here
      // );

      // --- Alternative Approach: Apply resilience within the locale loop --- 
      double localeBaseIncome = 0.0;
      for (var property in locale.properties) {
          // Pass the flag to the property's income calculation
          localeBaseIncome += property.getTotalIncomePerSecond(
              affectedByEvent: hasLocaleEvent, // Use locale-wide event status for simplicity
              isResilienceActive: isPlatinumResilienceActive 
          );
      }
      // --- End Alternative Approach ---
      
      // Apply Platinum Tower regional boost (applies to Dubai locale's base income)
      if (locale.id == 'dubai_uae') {
        // Check if the tower property exists and is owned
        var towerProperty = locale.properties.firstWhere((p) => p.id == 'platinum_tower', orElse: () => RealEstateProperty(id: '', name: '', purchasePrice: 0, baseCashFlowPerSecond: 0));
        if (towerProperty.id.isNotEmpty && towerProperty.owned > 0) {
          localeBaseIncome *= 1.10; // Apply +10% boost
        }
      }
      
      // Apply Platinum Yacht regional boost
      if (isPlatinumYachtPurchased && platinumYachtDockedLocaleId == locale.id) {
          // Check if boost amplifier upgrade is purchased
          bool boostAmplified = platinumYachtUpgrades.any((u) => u.id == 'py_boost_amp' && u.purchased);
          double yachtBoost = boostAmplified ? 1.075 : 1.05; // 7.5% if amplified, else 5%
          localeBaseIncome *= yachtBoost;
          print("DEBUG: Applying Yacht Boost (${(yachtBoost-1)*100}%) to locale ${locale.id}");
      }
      
      // Apply Platinum Island regional boost (applies only to Platinum Islands locale)
      if (locale.id == 'platinum_islands') {
          var islandProperty = locale.properties.firstWhere((p) => p.id == 'platinum_island', orElse: () => RealEstateProperty(id: '', name: '', purchasePrice: 0, baseCashFlowPerSecond: 0));
          if (islandProperty.id.isNotEmpty && islandProperty.owned > 0) {
             localeBaseIncome *= 1.08; // Apply +8% boost
          }
      }
      
      // Apply Platinum Foundation bonus if applicable to this locale
      if (platinumFoundationsApplied.containsKey(locale.id)) {
        // Assuming count is always 1 for now, based on _applyVaultItemEffect logic
        localeBaseIncome *= 1.05; 
      }
      
      total += localeBaseIncome;
    }
    // ADDED: Apply Income Surge
    if (isIncomeSurgeActive) total *= 2.0;
    return total;
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

    double cost = property.purchasePrice;
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

    if (money >= upgrade.cost) {
      money -= upgrade.cost;
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
              'name': property.name,
              'locale': locale.name,
              'ownedCount': property.owned,
              'currentIncomePerSecond': property.getTotalIncomePerSecond(),
            });
          }
        }
      }
    }
    return ownedProperties;
  }
}