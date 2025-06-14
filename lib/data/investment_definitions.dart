import 'dart:math';
import 'package:flutter/material.dart';
import '../models/investment.dart';

/// Defines the default list of investments available at the start of the game.
final List<Investment> defaultInvestments = [
  // STOCKS (More balanced trends)
  Investment(
    id: 'nxt', name: 'NexTech', description: 'A tech firm specializing in AI software.',
    currentPrice: 10.0, basePrice: 10.0, volatility: 0.15, trend: 0.01, owned: 0,
    icon: Icons.computer, color: Colors.blue, category: 'Technology', marketCap: 2.5,
    priceHistory: List.generate(30, (i) => 10.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'grv', name: 'GreenVolt', description: 'Renewable energy company with steady growth.',
    currentPrice: 25.0, basePrice: 25.0, volatility: 0.12, trend: 0.015, owned: 0,
    icon: Icons.eco, color: Colors.green, category: 'Energy', marketCap: 5.0,
    priceHistory: List.generate(30, (i) => 25.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'mft', name: 'MegaFreight', description: 'Logistics and shipping giant.',
    currentPrice: 50.0, basePrice: 50.0, volatility: 0.15, trend: -0.005, owned: 0,
    icon: Icons.local_shipping, color: Colors.blueGrey, category: 'Transportation', marketCap: 12.0,
    priceHistory: List.generate(30, (i) => 50.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'lxw', name: 'LuxWear', description: 'High-end fashion brand with trendy spikes.',
    currentPrice: 100.0, basePrice: 100.0, volatility: 0.20, trend: 0.005, owned: 0,
    icon: Icons.diamond_outlined, color: Colors.pink, category: 'Fashion', marketCap: 3.2,
    priceHistory: List.generate(30, (i) => 100.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'stf', name: 'StarForge', description: 'Space exploration company with high risk/reward.',
    currentPrice: 500.0, basePrice: 500.0, volatility: 0.25, trend: 0.02, owned: 0,
    icon: Icons.rocket_launch, color: Colors.deepPurple, category: 'Aerospace', marketCap: 20.0,
    priceHistory: List.generate(30, (i) => 500.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  // CRYPTOCURRENCIES (More volatile and balanced trends)
  Investment(
    id: 'bcl', name: 'BitCoinLite', description: 'A beginner-friendly crypto with moderate swings.',
    currentPrice: 50.0, basePrice: 50.0, volatility: 0.30, trend: 0.01, owned: 0,
    icon: Icons.currency_bitcoin, color: Colors.amber, category: 'Cryptocurrency', marketCap: 0.85,
    priceHistory: List.generate(30, (i) => 50.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'etc', name: 'EtherCore', description: 'A blockchain platform with growing adoption.',
    currentPrice: 200.0, basePrice: 200.0, volatility: 0.25, trend: 0.01, owned: 0,
    icon: Icons.hub, color: Colors.blue.shade800, category: 'Cryptocurrency', marketCap: 2.4,
    priceHistory: List.generate(30, (i) => 200.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'mtk', name: 'MoonToken', description: 'A meme coin with wild volatility.',
    currentPrice: 10.0, basePrice: 10.0, volatility: 0.50, trend: -0.02, owned: 0,
    icon: Icons.nightlight_round, color: Colors.purple.shade300, category: 'Cryptocurrency', marketCap: 0.25,
    priceHistory: List.generate(30, (i) => 10.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'sbx', name: 'StableX', description: 'A low-risk crypto pegged to real-world value.',
    currentPrice: 100.0, basePrice: 100.0, volatility: 0.03, trend: 0.0, owned: 0,
    icon: Icons.lock, color: Colors.teal, category: 'Cryptocurrency', marketCap: 5.7,
    priceHistory: List.generate(30, (i) => 100.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'qbt', name: 'QuantumBit', description: 'Cutting-edge crypto tied to quantum computing.',
    currentPrice: 1000.0, basePrice: 1000.0, volatility: 0.35, trend: 0.025, owned: 0,
    icon: Icons.pending, color: Colors.cyan.shade700, category: 'Cryptocurrency', marketCap: 3.2,
    priceHistory: List.generate(30, (i) => 1000.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  // DIVIDEND INVESTMENTS (Balanced trends)
  Investment(
    id: 'btf', name: 'BioTech Innovators Fund', description: 'Fund for biotech startups in gene therapy and vaccines.',
    currentPrice: 500.0, basePrice: 500.0, volatility: 0.20, trend: 0.01, owned: 0,
    icon: Icons.healing, color: Colors.lightBlue.shade700, category: 'Healthcare', dividendPerSecond: 0.95, marketCap: 12.5,
    priceHistory: List.generate(30, (i) => 500.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'sme', name: 'Streaming Media ETF', description: 'ETF of streaming platforms and content creators.',
    currentPrice: 2000.0, basePrice: 2000.0, volatility: 0.20, trend: 0.015, owned: 0,
    icon: Icons.live_tv, color: Colors.red.shade700, category: 'Entertainment', dividendPerSecond: 3.78, marketCap: 35.8,
    priceHistory: List.generate(30, (i) => 2000.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'sab', name: 'Sustainable Agriculture Bonds', description: 'Bonds for organic farming and sustainable food production.',
    currentPrice: 10000.0, basePrice: 10000.0, volatility: 0.10, trend: 0.005, owned: 0,
    icon: Icons.agriculture, color: Colors.green.shade800, category: 'Agriculture', dividendPerSecond: 19.5, marketCap: 22.7,
    priceHistory: List.generate(30, (i) => 10000.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'gti', name: 'Global Tourism Index', description: 'Index fund of major tourism companies.',
    currentPrice: 50000.0, basePrice: 50000.0, volatility: 0.20, trend: -0.01, owned: 0,
    icon: Icons.flight, color: Colors.amber.shade800, category: 'Tourism', dividendPerSecond: 95.5, marketCap: 86.5,
    priceHistory: List.generate(30, (i) => 50000.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'urt', name: 'Urban REIT', description: 'REIT for urban commercial properties.',
    currentPrice: 200000.0, basePrice: 200000.0, volatility: 0.10, trend: 0.01, owned: 0,
    icon: Icons.business, color: Colors.brown.shade600, category: 'REITs', dividendPerSecond: 381, marketCap: 125.8,
    priceHistory: List.generate(30, (i) => 200000.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'vrv', name: 'Virtual Reality Ventures', description: 'Stocks in VR gaming and entertainment companies.',
    currentPrice: 1000000.0, basePrice: 1000000.0, volatility: 0.30, trend: 0.02, owned: 0,
    icon: Icons.vrpano, color: Colors.deepPurple.shade600, category: 'Entertainment', dividendPerSecond: 1950, marketCap: 75.2,
    priceHistory: List.generate(30, (i) => 1000000.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'mrc', name: 'Medical Robotics Corp', description: 'Company producing robotic surgery and AI diagnostics.',
    currentPrice: 5000000.0, basePrice: 5000000.0, volatility: 0.20, trend: 0.015, owned: 0,
    icon: Icons.biotech, color: Colors.blue.shade800, category: 'Healthcare', dividendPerSecond: 9750.0, marketCap: 120.7,
    priceHistory: List.generate(30, (i) => 5000000.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'atf', name: 'AgroTech Futures', description: 'Futures on agrotech firms in vertical farming.',
    currentPrice: 20000000.0, basePrice: 20000000.0, volatility: 0.30, trend: 0.01, owned: 0,
    icon: Icons.eco, color: Colors.lightGreen.shade800, category: 'Agriculture', dividendPerSecond: 41500.0, marketCap: 195.3,
    priceHistory: List.generate(30, (i) => 20000000.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'lrr', name: 'Luxury Resort REIT', description: 'REIT for luxury resorts and vacation properties.',
    currentPrice: 100000000.0, basePrice: 100000000.0, volatility: 0.10, trend: 0.005, owned: 0,
    icon: Icons.beach_access, color: Colors.teal.shade600, category: 'REITs', dividendPerSecond: 96250.0, marketCap: 580.6,
    priceHistory: List.generate(30, (i) => 100000000.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'ath', name: 'Adventure Travel Holdings', description: 'Holdings in adventure travel and eco-tourism operators.',
    currentPrice: 500000000.0, basePrice: 500000000.0, volatility: 0.20, trend: -0.005, owned: 0,
    icon: Icons.terrain, color: Colors.orange.shade800, category: 'Tourism', dividendPerSecond: 475000.0, marketCap: 1250.0,
    priceHistory: List.generate(30, (i) => 500000000.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
]; 