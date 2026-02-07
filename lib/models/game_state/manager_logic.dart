part of '../game_state.dart';

/// Contains methods related to the Real Estate Manager system
/// Managers persist through reincorporation and provide automation for property purchases
extension ManagerLogic on GameState {
  
  // ============================================================================
  // LOCALE COMPLETION CHECKS
  // ============================================================================
  
  /// Check if a locale is fully complete (all properties owned + all upgrades purchased)
  bool isLocaleComplete(String localeId) {
    final locale = realEstateLocales.firstWhere(
      (l) => l.id == localeId,
      orElse: () => RealEstateLocale(
        id: '', 
        name: '', 
        theme: '', 
        unlocked: false, 
        icon: Icons.error, 
        properties: []
      ),
    );
    
    if (locale.id.isEmpty) return false;
    if (!locale.unlocked) return false;
    if (locale.properties.isEmpty) return false;
    
    // Check all properties are owned
    for (var property in locale.properties) {
      if (property.owned <= 0) return false;
      // Check all upgrades are purchased
      for (var upgrade in property.upgrades) {
        if (!upgrade.purchased) return false;
      }
    }
    
    return true;
  }
  
  /// Calculate the total investment in a locale (properties + upgrades)
  double calculateLocaleTotalInvestment(String localeId) {
    final locale = realEstateLocales.firstWhere(
      (l) => l.id == localeId,
      orElse: () => RealEstateLocale(
        id: '', 
        name: '', 
        theme: '', 
        unlocked: false, 
        icon: Icons.error, 
        properties: []
      ),
    );
    
    if (locale.id.isEmpty) return 0.0;
    
    double total = 0.0;
    for (int i = 0; i < locale.properties.length; i++) {
      final property = locale.properties[i];
      final int tier = PacingConfig.realEstateTierFromPropertyIndex(i);
      final double costMultiplier = PacingConfig.realEstateCostMultiplierForTier(tier);
      
      // Property cost (paced)
      total += property.purchasePrice * costMultiplier;
      
      // Upgrade costs (paced)
      for (var upgrade in property.upgrades) {
        total += upgrade.cost * costMultiplier;
      }
    }
    
    return total;
  }
  
  /// Calculate the cost to unlock a locale manager (30% of total investment)
  double calculateLocaleManagerCost(String localeId) {
    return calculateLocaleTotalInvestment(localeId) * 0.30;
  }
  
  // ============================================================================
  // MANAGER UNLOCK CHECKS
  // ============================================================================
  
  /// Check if a locale manager can be unlocked
  /// Requirements: locale is complete AND manager not already owned
  bool canUnlockLocaleManager(String localeId) {
    // Already have manager?
    if (unlockedLocaleManagerIds.contains(localeId)) return false;
    
    // Check if a regional manager covers this locale
    final tier = LocaleTierConfig.getTierForLocale(localeId);
    if (tier >= 0 && unlockedRegionalManagerTiers.contains(tier)) return false;
    
    // Check if locale is complete
    return isLocaleComplete(localeId);
  }
  
  /// Check if player has a manager for a specific locale (locale or regional)
  bool hasManagerForLocale(String localeId) {
    // Check locale manager
    if (unlockedLocaleManagerIds.contains(localeId)) return true;
    
    // Check regional manager
    final tier = LocaleTierConfig.getTierForLocale(localeId);
    if (tier >= 0 && unlockedRegionalManagerTiers.contains(tier)) return true;
    
    return false;
  }
  
  /// Check if player has a regional manager for a tier
  bool hasRegionalManager(int tier) {
    return unlockedRegionalManagerTiers.contains(tier);
  }
  
  // ============================================================================
  // MANAGER PURCHASE/UNLOCK
  // ============================================================================
  
  /// Purchase a locale manager (requires locale completion + sufficient funds)
  bool purchaseLocaleManager(String localeId) {
    if (!canUnlockLocaleManager(localeId)) {
      print("❌ Cannot unlock manager for $localeId: requirements not met");
      return false;
    }
    
    final cost = calculateLocaleManagerCost(localeId);
    if (money < cost) {
      print("❌ Cannot afford manager for $localeId: need $cost, have $money");
      return false;
    }
    
    // Deduct cost
    money -= cost;
    
    // Add to unlocked managers
    unlockedLocaleManagerIds.add(localeId);
    
    // Create and store manager record
    final manager = RealEstateManager.forLocale(localeId);
    manager.unlocked = true;
    manager.unlockedAt = DateTime.now();
    realEstateManagers.add(manager);
    
    print("✅ Unlocked locale manager for $localeId (cost: $cost)");
    notifyListeners();
    return true;
  }
  
  /// Unlock a regional manager (typically via IAP, so no cost deduction here)
  /// Call this after successful IAP verification
  bool unlockRegionalManager(int tier) {
    if (unlockedRegionalManagerTiers.contains(tier)) {
      print("⚠️ Regional manager for tier $tier already unlocked");
      return false;
    }
    
    // Add to unlocked tiers
    unlockedRegionalManagerTiers.add(tier);
    
    // Create and store manager record
    final manager = RealEstateManager.forTier(tier);
    manager.unlocked = true;
    manager.unlockedAt = DateTime.now();
    realEstateManagers.add(manager);
    
    print("✅ Unlocked regional manager for tier $tier");
    notifyListeners();
    return true;
  }
  
  // ============================================================================
  // MANAGER ACTIONS (Buy All, Buy with Upgrades)
  // ============================================================================
  
  /// Calculate cost to buy all unowned properties in a locale
  double calculateBuyAllCost(String localeId) {
    final locale = realEstateLocales.firstWhere(
      (l) => l.id == localeId,
      orElse: () => RealEstateLocale(
        id: '', 
        name: '', 
        theme: '', 
        unlocked: false, 
        icon: Icons.error, 
        properties: []
      ),
    );
    
    if (locale.id.isEmpty || !locale.unlocked) return 0.0;
    
    double total = 0.0;
    for (var property in locale.properties) {
      if (property.owned <= 0) {
        total += getEffectivePropertyPurchaseCost(localeId, property.id);
      }
    }
    
    return total;
  }
  
  /// Calculate cost to buy all unpurchased upgrades in a locale
  double calculateBuyAllUpgradesCost(String localeId) {
    final locale = realEstateLocales.firstWhere(
      (l) => l.id == localeId,
      orElse: () => RealEstateLocale(
        id: '', 
        name: '', 
        theme: '', 
        unlocked: false, 
        icon: Icons.error, 
        properties: []
      ),
    );
    
    if (locale.id.isEmpty || !locale.unlocked) return 0.0;
    
    double total = 0.0;
    for (var property in locale.properties) {
      if (property.owned > 0) {
        for (var upgrade in property.upgrades) {
          if (!upgrade.purchased) {
            total += getEffectiveUpgradeCost(localeId, property.id, upgrade.id);
          }
        }
      }
    }
    
    return total;
  }
  
  /// Buy all unowned properties in a managed locale (manager feature)
  /// Returns number of properties purchased, or -1 if failed
  int buyAllInLocale(String localeId) {
    if (!hasManagerForLocale(localeId)) {
      print("❌ No manager for $localeId");
      return -1;
    }
    
    final locale = realEstateLocales.firstWhere(
      (l) => l.id == localeId,
      orElse: () => RealEstateLocale(
        id: '', 
        name: '', 
        theme: '', 
        unlocked: false, 
        icon: Icons.error, 
        properties: []
      ),
    );
    
    if (locale.id.isEmpty || !locale.unlocked) {
      print("❌ Locale $localeId not found or not unlocked");
      return -1;
    }
    
    // Calculate total cost first
    final totalCost = calculateBuyAllCost(localeId);
    if (money < totalCost) {
      print("❌ Cannot afford bulk purchase: need $totalCost, have $money");
      return -1;
    }
    
    // Buy all unowned properties
    int purchased = 0;
    for (var property in locale.properties) {
      if (property.owned <= 0) {
        if (buyRealEstateProperty(localeId, property.id)) {
          purchased++;
        }
      }
    }
    
    print("✅ Bought $purchased properties in $localeId");
    return purchased;
  }
  
  /// Buy a property with all its upgrades in one action (manager feature)
  /// Returns true if successful
  bool buyPropertyWithUpgrades(String localeId, String propertyId) {
    if (!hasManagerForLocale(localeId)) {
      print("❌ No manager for $localeId");
      return false;
    }
    
    final locale = realEstateLocales.firstWhere(
      (l) => l.id == localeId,
      orElse: () => RealEstateLocale(
        id: '', 
        name: '', 
        theme: '', 
        unlocked: false, 
        icon: Icons.error, 
        properties: []
      ),
    );
    
    if (locale.id.isEmpty || !locale.unlocked) return false;
    
    final property = locale.properties.firstWhere(
      (p) => p.id == propertyId,
      orElse: () => RealEstateProperty(
        id: '', 
        name: '', 
        purchasePrice: 0, 
        baseCashFlowPerSecond: 0
      ),
    );
    
    if (property.id.isEmpty) return false;
    
    // Calculate total cost
    double totalCost = 0.0;
    if (property.owned <= 0) {
      totalCost += getEffectivePropertyPurchaseCost(localeId, propertyId);
    }
    for (var upgrade in property.upgrades) {
      if (!upgrade.purchased) {
        totalCost += getEffectiveUpgradeCost(localeId, propertyId, upgrade.id);
      }
    }
    
    if (money < totalCost) {
      print("❌ Cannot afford property + upgrades: need $totalCost, have $money");
      return false;
    }
    
    // Execute purchases
    if (property.owned <= 0) {
      buyRealEstateProperty(localeId, propertyId);
    }
    
    for (var upgrade in property.upgrades) {
      if (!upgrade.purchased) {
        purchasePropertyUpgrade(localeId, propertyId, upgrade.id);
      }
    }
    
    print("✅ Bought property $propertyId with all upgrades");
    return true;
  }
  
  /// Buy all unpurchased upgrades in a managed locale (manager feature)
  /// Returns number of upgrades purchased, or -1 if failed
  int buyAllUpgradesInLocale(String localeId) {
    if (!hasManagerForLocale(localeId)) {
      print("❌ No manager for $localeId");
      return -1;
    }
    
    final locale = realEstateLocales.firstWhere(
      (l) => l.id == localeId,
      orElse: () => RealEstateLocale(
        id: '', 
        name: '', 
        theme: '', 
        unlocked: false, 
        icon: Icons.error, 
        properties: []
      ),
    );
    
    if (locale.id.isEmpty || !locale.unlocked) return -1;
    
    // Calculate total cost first
    final totalCost = calculateBuyAllUpgradesCost(localeId);
    if (money < totalCost) {
      print("❌ Cannot afford all upgrades: need $totalCost, have $money");
      return -1;
    }
    
    // Buy all unpurchased upgrades for owned properties
    int purchased = 0;
    for (var property in locale.properties) {
      if (property.owned > 0) {
        for (var upgrade in property.upgrades) {
          if (!upgrade.purchased) {
            if (purchasePropertyUpgrade(localeId, property.id, upgrade.id)) {
              purchased++;
            }
          }
        }
      }
    }
    
    print("✅ Bought $purchased upgrades in $localeId");
    return purchased;
  }
  
  // ============================================================================
  // UTILITY METHODS
  // ============================================================================
  
  /// Get list of locales that are eligible for manager unlock
  List<String> getLocalesEligibleForManager() {
    final eligible = <String>[];
    for (var locale in realEstateLocales) {
      if (canUnlockLocaleManager(locale.id)) {
        eligible.add(locale.id);
      }
    }
    return eligible;
  }
  
  /// Get count of managers owned (locale + regional)
  int getTotalManagerCount() {
    return unlockedLocaleManagerIds.length + unlockedRegionalManagerTiers.length;
  }
  
  /// Get all locale IDs that have a manager (either locale or regional)
  Set<String> getManagedLocaleIds() {
    final managed = <String>{};
    
    // Add directly managed locales
    managed.addAll(unlockedLocaleManagerIds);
    
    // Add locales covered by regional managers
    for (var tier in unlockedRegionalManagerTiers) {
      managed.addAll(LocaleTierConfig.getLocalesInTier(tier));
    }
    
    return managed;
  }
}
