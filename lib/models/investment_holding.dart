import 'package:flutter/foundation.dart';

// A class to track player's investment holdings with purchase info
class InvestmentHolding {
  final String investmentId;
  double purchasePrice; // Average purchase price
  int shares;

  InvestmentHolding({
    required this.investmentId,
    required this.purchasePrice,
    required this.shares,
  });

  // Calculate current value based on current market price
  double getCurrentValue(double currentPrice) {
    return currentPrice * shares;
  }

  // Calculate profit/loss
  double getProfitLoss(double currentPrice) {
    return (currentPrice - purchasePrice) * shares;
  }

  // Calculate profit/loss percentage
  double getProfitLossPercentage(double currentPrice) {
    if (purchasePrice <= 0) return 0.0;
    return ((currentPrice - purchasePrice) / purchasePrice) * 100;
  }
}
