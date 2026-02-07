/// Real Estate Manager System for Empire Tycoon
/// 
/// Managers unlock after completing a locale (all properties + all upgrades)
/// and persist through reincorporation, providing:
/// - One-tap "Buy All" for properties in managed locales
/// - One-tap "Buy with Upgrades" for individual properties
/// 
/// Two types:
/// - Locale Manager: Earned in-game by maxing a locale (30% of locale investment cost)
/// - Regional Manager: Premium IAP covering entire unlock tiers
library real_estate_manager;

enum ManagerType { locale, regional }

class RealEstateManager {
  final String id;
  final ManagerType type;
  final String? localeId;        // For locale managers - which locale they manage
  final int? tier;               // For regional managers - which tier (0-5) they cover
  bool unlocked;
  DateTime? unlockedAt;
  
  RealEstateManager({
    required this.id,
    required this.type,
    this.localeId,
    this.tier,
    this.unlocked = false,
    this.unlockedAt,
  });
  
  /// Create a locale manager for a specific locale
  factory RealEstateManager.forLocale(String localeId) {
    return RealEstateManager(
      id: 'locale_$localeId',
      type: ManagerType.locale,
      localeId: localeId,
      unlocked: false,
    );
  }
  
  /// Create a regional manager for a specific tier
  factory RealEstateManager.forTier(int tier) {
    return RealEstateManager(
      id: 'regional_tier_$tier',
      type: ManagerType.regional,
      tier: tier,
      unlocked: false,
    );
  }
  
  /// Serialization to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'localeId': localeId,
    'tier': tier,
    'unlocked': unlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
  };
  
  /// Deserialization from JSON
  factory RealEstateManager.fromJson(Map<String, dynamic> json) => RealEstateManager(
    id: json['id'] as String,
    type: ManagerType.values.byName(json['type'] as String),
    localeId: json['localeId'] as String?,
    tier: json['tier'] as int?,
    unlocked: json['unlocked'] as bool? ?? false,
    unlockedAt: json['unlockedAt'] != null 
      ? DateTime.parse(json['unlockedAt'] as String) 
      : null,
  );
  
  @override
  String toString() => 'RealEstateManager(id: $id, type: $type, unlocked: $unlocked)';
}

/// Configuration for locale tiers and their money unlock thresholds
class LocaleTierConfig {
  LocaleTierConfig._();
  
  /// Maps tier number to list of locale IDs in that tier
  static const Map<int, List<String>> tierToLocales = {
    0: ['rural_kenya'],
    1: ['lagos_nigeria', 'rural_thailand', 'rural_mexico'],
    2: ['cape_town_sa', 'mumbai_india', 'ho_chi_minh_city', 
        'bucharest_romania', 'lima_peru', 'sao_paulo_brazil'],
    3: ['lisbon_portugal', 'berlin_germany', 'mexico_city'],
    4: ['singapore', 'london_uk', 'miami_florida', 
        'new_york_city', 'los_angeles'],
    5: ['hong_kong', 'dubai_uae'],
  };
  
  /// Money thresholds to unlock each tier
  static const Map<int, double> tierUnlockThresholds = {
    0: 0.0,           // Always unlocked
    1: 10000.0,       // $10K
    2: 50000.0,       // $50K
    3: 250000.0,      // $250K
    4: 1000000.0,     // $1M
    5: 5000000.0,     // $5M
  };
  
  /// Get the tier for a given locale ID
  static int getTierForLocale(String localeId) {
    for (var entry in tierToLocales.entries) {
      if (entry.value.contains(localeId)) {
        return entry.key;
      }
    }
    return -1; // Unknown locale (e.g., platinum_islands)
  }
  
  /// Get all locales in a given tier
  static List<String> getLocalesInTier(int tier) {
    return tierToLocales[tier] ?? [];
  }
  
  /// Get the money threshold for a tier
  static double getThresholdForTier(int tier) {
    return tierUnlockThresholds[tier] ?? double.infinity;
  }
  
  /// Get total number of tiers (0-5)
  static int get totalTiers => tierToLocales.length;
}
