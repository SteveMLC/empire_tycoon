/// Central configuration for tap boost (click) leveling in the Hustle screen.
///
/// Defines tap requirements per level, click value scaling, and migration
/// logic for existing users (Option A: recompute level from taps).
class TapBoostConfig {
  TapBoostConfig._();

  static const int maxClickLevel = 60;

  /// Taps required to complete the transition from level [level] to level+1.
  /// Tiered formula: early levels fast, gradual ramp, end-game substantial.
  static int getTapsRequiredForLevel(int level) {
    if (level < 1) return 0;
    if (level <= 10) {
      return 35 + 8 * level;
    } else if (level <= 25) {
      return 80 + 12 * (level - 10);
    } else if (level <= 40) {
      return 200 + 18 * (level - 25);
    } else if (level <= 60) {
      return 350 + 25 * (level - 40);
    }
    return 0;
  }

  /// Cumulative taps required to reach [level] (sum of getTapsRequiredForLevel(1) through level-1).
  /// Level 1 requires 0 cumulative (start). Level 2 requires getTapsRequiredForLevel(1), etc.
  static int getCumulativeTapsForLevel(int level) {
    if (level <= 1) return 0;
    int sum = 0;
    for (int i = 1; i < level; i++) {
      sum += getTapsRequiredForLevel(i);
    }
    return sum;
  }

  /// Base click value ($ per tap) at [level], before prestige multiplier.
  /// L1: ~$1.50, L20: ~$8.00, L60: ~$51.70.
  /// Early ramp (1-20) gentler; late ramp (21-60) steeper.
  static double getClickBaseValueForLevel(int level) {
    if (level < 1) return 1.5;
    if (level <= 20) {
      return 1.5 + (level - 1) * 0.342;
    } else if (level <= 60) {
      return 8.0 + (level - 20) * 1.09;
    }
    return 8.0 + 40 * 1.09; // cap at L60 value
  }

  /// Option A: Derive click level from taps (taps is source of truth).
  /// Returns the highest level where cumulative taps to reach it <= [taps].
  /// Used on load to migrate existing users to the new leveling system.
  static int getLevelFromTaps(int taps) {
    if (taps <= 0) return 1;
    for (int level = maxClickLevel; level >= 1; level--) {
      if (taps >= getCumulativeTapsForLevel(level)) {
        return level;
      }
    }
    return 1;
  }
}
