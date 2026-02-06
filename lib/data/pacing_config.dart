/// Central pacing configuration for progression scaling.
///
/// Applies cost/income multipliers at use sites to slow mid-game (~30%) and
/// late-game (~50%) progression. Reincorporation and other existing multipliers
/// apply on top of these paced bases.
class PacingConfig {
  PacingConfig._();

  /// When false, all multipliers return 1.0 (pacing disabled). Toggle for testing or rollout.
  static const bool pacingEnabled = true;

  // ---------------------------------------------------------------------------
  // Real Estate (cost-only; tier from property index within locale)
  // Raised so late-game properties (e.g. Sao Paulo Iconic Tower) are meaningfully more expensive.
  // Tier 1 = index 0,1 → 1.0; Tier 2 = 2,3 → 1.35; Tier 3 = 4,5 → 1.7; Tier 4 = 6,7 → 2.2; Tier 5 = 8,9 → 3.0
  // e.g. base $3M tier-5 property → $9M (was $6M at 2.0x)
  // ---------------------------------------------------------------------------

  static const List<double> _realEstateCostMultipliers = [1.0, 1.35, 1.7, 2.2, 3.0];

  /// Real estate cost multiplier for tier 1–5. Tier is derived from property index:
  /// tier = (propertyIndex ~/ 2).clamp(0, 4) + 1
  static double realEstateCostMultiplierForTier(int tier) {
    if (!pacingEnabled) return 1.0;
    final index = (tier - 1).clamp(0, _realEstateCostMultipliers.length - 1);
    return _realEstateCostMultipliers[index];
  }

  /// Derive tier 1–5 from property index within locale (0–9).
  static int realEstateTierFromPropertyIndex(int propertyIndex) {
    return ((propertyIndex ~/ 2).clamp(0, 4)) + 1;
  }

  // ---------------------------------------------------------------------------
  // Businesses (cost up, income down by index in businesses list)
  // Index 0,1 → cost 1.0, income 1.0; 2,3 → 1.2 / 0.85; 4,5 → 1.4 / 0.75; 6,7 → 1.6 / 0.65; 8+ → 2.0 / 0.5
  // ---------------------------------------------------------------------------

  static const List<double> _businessCostMultipliers = [
    1.0, 1.0, 1.2, 1.2, 1.4, 1.4, 1.6, 1.6, 2.0, 2.0, 2.0, 2.0,
  ];
  static const List<double> _businessIncomeMultipliers = [
    1.0, 1.0, 0.85, 0.85, 0.75, 0.75, 0.65, 0.65, 0.5, 0.5, 0.5, 0.5,
  ];

  static double _businessMultiplierForIndex(int index, List<double> multipliers) {
    if (!pacingEnabled) return 1.0;
    if (index < 0) return 1.0;
    if (index >= multipliers.length) return multipliers.last;
    return multipliers[index];
  }

  /// Business upgrade/buy cost multiplier by 0-based business index.
  static double businessCostMultiplierForIndex(int businessIndex) {
    return _businessMultiplierForIndex(businessIndex, _businessCostMultipliers);
  }

  /// Business income multiplier by 0-based business index (applied to base income before other multipliers).
  static double businessIncomeMultiplierForIndex(int businessIndex) {
    return _businessMultiplierForIndex(businessIndex, _businessIncomeMultipliers);
  }

  // ---------------------------------------------------------------------------
  // Investments (dividend only; scale by market cap in billions)
  // Lower cap → more reduction. Brackets: <1, 1-10, 10-50, 50-200, 200-500, 500+
  // ---------------------------------------------------------------------------

  /// Dividend income multiplier by market cap (in billions). Only applied when adding dividend to income.
  static double dividendMultiplierByMarketCap(double marketCap) {
    if (!pacingEnabled) return 1.0;
    if (marketCap < 1) return 0.5;
    if (marketCap < 10) return 0.6;
    if (marketCap < 50) return 0.65;
    if (marketCap < 200) return 0.7;
    if (marketCap < 500) return 0.75;
    return 0.8;
  }
}
