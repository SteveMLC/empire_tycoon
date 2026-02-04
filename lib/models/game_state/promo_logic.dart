part of '../game_state.dart';

class PromoRewardConfig {
  final String name;
  final double cash;
  final int platinumPoints;
  final double clickBoostMultiplier;
  final Duration clickBoostDuration;

  const PromoRewardConfig({
    required this.name,
    required this.cash,
    required this.platinumPoints,
    required this.clickBoostMultiplier,
    required this.clickBoostDuration,
  });
}

class PromoRedemptionResult {
  final bool success;
  final String code;
  final String message;

  const PromoRedemptionResult({
    required this.success,
    required this.code,
    required this.message,
  });
}

extension PromoLogic on GameState {
  static const Map<String, PromoRewardConfig> _promoRewardCatalog = {
    'LAUNCH': PromoRewardConfig(
      name: 'Launch Pack',
      cash: 25000.0,
      platinumPoints: 250,
      clickBoostMultiplier: 2.0,
      clickBoostDuration: Duration(minutes: 15),
    ),
  };

  PromoRedemptionResult redeemPromoCode(String rawCode) {
    final String normalizedCode = rawCode.trim().toUpperCase();
    if (normalizedCode.isEmpty) {
      return const PromoRedemptionResult(
        success: false,
        code: '',
        message: 'Promo code missing.',
      );
    }

    if (redeemedPromoCodes.contains(normalizedCode)) {
      return PromoRedemptionResult(
        success: false,
        code: normalizedCode,
        message: 'Promo code $normalizedCode was already redeemed.',
      );
    }

    final PromoRewardConfig? reward = _promoRewardCatalog[normalizedCode];
    if (reward == null) {
      return PromoRedemptionResult(
        success: false,
        code: normalizedCode,
        message: 'Promo code $normalizedCode is invalid.',
      );
    }

    final DateTime now = DateTime.now();
    if (reward.cash > 0) {
      money += reward.cash;
      totalEarned += reward.cash;
      passiveEarnings += reward.cash;
    }

    if (reward.platinumPoints > 0) {
      awardPlatinumPoints(reward.platinumPoints);
    }

    if (reward.clickBoostMultiplier > 1.0 &&
        reward.clickBoostDuration != Duration.zero) {
      final DateTime promoBoostEnd = now.add(reward.clickBoostDuration);
      if (clickBoostEndTime == null || now.isAfter(clickBoostEndTime!)) {
        clickBoostEndTime = promoBoostEnd;
      } else if (promoBoostEnd.isAfter(clickBoostEndTime!)) {
        clickBoostEndTime = promoBoostEnd;
      }
      if (clickMultiplier < reward.clickBoostMultiplier) {
        clickMultiplier = reward.clickBoostMultiplier;
      }
    }

    redeemedPromoCodes.add(normalizedCode);
    notifyListeners();

    return PromoRedemptionResult(
      success: true,
      code: normalizedCode,
      message:
          '${reward.name} redeemed: +\$${NumberFormatter.formatCompact(reward.cash)}, +${reward.platinumPoints} PP, ${reward.clickBoostMultiplier.toStringAsFixed(0)}x taps for ${reward.clickBoostDuration.inMinutes}m.',
    );
  }
}
