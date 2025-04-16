part of '../game_state.dart';

extension RealEstateLogic on GameState {
  // Initialize real estate locales
  void _initializeRealEstateLocales() {
    realEstateLocales = [
      // Beachfront
      RealEstateLocale(
        id: 'beachfront',
        name: 'Beachfront',
        unlocked: true, // Initially unlocked
        theme: 'Prime properties with ocean views.',
        icon: Icons.beach_access,
        properties: [
          // Beach House
          RealEstateProperty(
            id: 'beach_house',
            name: 'Beach House',
            purchasePrice: 150000.0,
            baseCashFlowPerSecond: 250.0,
            owned: 0,
            upgrades: [], // Upgrades will be loaded from CSV
          ),
          // Luxury Villa
          RealEstateProperty(
            id: 'luxury_villa',
            name: 'Luxury Villa',
            purchasePrice: 750000.0,
            baseCashFlowPerSecond: 1200.0,
            owned: 0,
            upgrades: [], // Upgrades will be loaded from CSV
          ),
        ],
      ),

      // Downtown
      RealEstateLocale(
        id: 'downtown',
        name: 'Downtown',
        unlocked: false, // Initially locked
        theme: 'Commercial and residential properties in the city center.',
        icon: Icons.location_city,
        properties: [
          // Loft Apartment
          RealEstateProperty(
            id: 'loft_apartment',
            name: 'Loft Apartment',
            purchasePrice: 300000.0,
            baseCashFlowPerSecond: 450.0,
            owned: 0,
            upgrades: [], // Upgrades will be loaded from CSV
          ),
          // Office Space
          RealEstateProperty(
            id: 'office_space',
            name: 'Office Space',
            purchasePrice: 1000000.0,
            baseCashFlowPerSecond: 1500.0,
            owned: 0,
            upgrades: [], // Upgrades will be loaded from CSV
          ),
        ],
      ),

      // Suburbs
      RealEstateLocale(
        id: 'suburbs',
        name: 'Suburbs',
        unlocked: false,
        theme: 'Family homes and community spaces.',
        icon: Icons.home_work,
        properties: [
          // Family Home
          RealEstateProperty(
            id: 'family_home',
            name: 'Family Home',
            purchasePrice: 400000.0,
            baseCashFlowPerSecond: 600.0,
            owned: 0,
            upgrades: [], // Upgrades will be loaded from CSV
          ),
          // Community Center
          RealEstateProperty(
            id: 'community_center',
            name: 'Community Center',
            purchasePrice: 1500000.0,
            baseCashFlowPerSecond: 2000.0,
            owned: 0,
            upgrades: [], // Upgrades will be loaded from CSV
          ),
        ],
      ),

      // Mountain Retreat
      RealEstateLocale(
        id: 'mountain_retreat',
        name: 'Mountain Retreat',
        unlocked: false,
        theme: 'Secluded properties with scenic mountain views.',
        icon: Icons.terrain,
        properties: [
          // Cozy Cabin
          RealEstateProperty(
            id: 'cozy_cabin',
            name: 'Cozy Cabin',
            purchasePrice: 250000.0,
            baseCashFlowPerSecond: 350.0,
            owned: 0,
            upgrades: [], // Upgrades will be loaded from CSV
          ),
          // Ski Lodge
          RealEstateProperty(
            id: 'ski_lodge',
            name: 'Ski Lodge',
            purchasePrice: 5000000.0,
            baseCashFlowPerSecond: 6000.0,
            owned: 0,
            upgrades: [], // Upgrades will be loaded from CSV
          ),
        ],
      ),

      // Private Island
      RealEstateLocale(
        id: 'private_island',
        name: 'Private Island',
        unlocked: false,
        theme: 'The ultimate luxury real estate investment.',
        icon: Icons.terrain,
        properties: [
          // Island Bungalow
          RealEstateProperty(
            id: 'island_bungalow',
            name: 'Island Bungalow',
            purchasePrice: 25000000.0,
            baseCashFlowPerSecond: 30000.0,
            owned: 0,
            upgrades: [], // Upgrades will be loaded from CSV
          ),
          // Mega Resort
          RealEstateProperty(
            id: 'mega_resort',
            name: 'Mega Resort',
            purchasePrice: 500000000.0,
            baseCashFlowPerSecond: 500000.0,
            owned: 0,
            upgrades: [], // Upgrades will be loaded from CSV
          ),
        ],
      ),
    ];
    print("🏘️ Default Real Estate Locales Initialized.");
  }

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
  }

  // Get total income per second from all owned real estate properties
  double getRealEstateIncomePerSecond() {
    double total = 0.0;
    bool hasEvent; // Declare outside loop for efficiency

    for (var locale in realEstateLocales) {
      // Check if the entire locale is affected by an event
      hasEvent = hasActiveEventForLocale(locale.id);

      for (var property in locale.properties) {
        if (property.owned > 0) {
          total += property.getTotalIncomePerSecond(affectedByEvent: hasEvent);
        }
      }
    }
    return total;
  }

  // Buy a real estate property
  bool buyRealEstateProperty(String localeId, String propertyId) {
    RealEstateLocale? locale = realEstateLocales.firstWhere(
          (l) => l.id == localeId,
      orElse: () => null as RealEstateLocale, // Explicit cast to expected type
    );

    if (locale == null || !locale.unlocked) {
      print("DEBUG: Locale not found or locked ($localeId)");
      return false;
    }

    RealEstateProperty? property = locale.properties.firstWhere(
          (p) => p.id == propertyId,
      orElse: () => null as RealEstateProperty, // Explicit cast
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
      orElse: () => null as RealEstateLocale, // Cast
    );

    if (locale == null) return false;

    RealEstateProperty? property = locale.properties.firstWhere(
          (p) => p.id == propertyId,
      orElse: () => null as RealEstateProperty, // Cast
    );

    if (property == null) return false;

    RealEstateUpgrade? upgrade = property.upgrades.firstWhere(
          (u) => u.id == upgradeId,
      orElse: () => null as RealEstateUpgrade, // Cast
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
      orElse: () => null as RealEstateLocale, // Cast
    );

    if (locale == null) return false;

    RealEstateProperty? property = locale.properties.firstWhere(
          (p) => p.id == propertyId,
      orElse: () => null as RealEstateProperty, // Cast
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
}