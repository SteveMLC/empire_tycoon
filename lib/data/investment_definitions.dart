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
    icon: Icons.healing, color: Colors.lightBlue.shade700, category: 'Healthcare', dividendPerSecond: 0.475, marketCap: 12.5,
    priceHistory: List.generate(30, (i) => 500.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'sme', name: 'Streaming Media ETF', description: 'ETF of streaming platforms and content creators.',
    currentPrice: 2000.0, basePrice: 2000.0, volatility: 0.20, trend: 0.015, owned: 0,
    icon: Icons.live_tv, color: Colors.red.shade700, category: 'Entertainment', dividendPerSecond: 1.89, marketCap: 35.8,
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
    icon: Icons.flight, color: Colors.amber.shade800, category: 'Tourism', dividendPerSecond: 47.75, marketCap: 86.5,
    priceHistory: List.generate(30, (i) => 50000.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'urt', name: 'Urban REIT', description: 'REIT for urban commercial properties.',
    currentPrice: 200000.0, basePrice: 200000.0, volatility: 0.10, trend: 0.01, owned: 0,
    icon: Icons.business, color: Colors.brown.shade600, category: 'REITs', dividendPerSecond: 190.5, marketCap: 125.8,
    priceHistory: List.generate(30, (i) => 200000.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'vrv', name: 'Virtual Reality Ventures', description: 'Stocks in VR gaming and entertainment companies.',
    currentPrice: 1000000.0, basePrice: 1000000.0, volatility: 0.30, trend: 0.02, owned: 0,
    icon: Icons.vrpano, color: Colors.deepPurple.shade600, category: 'Entertainment', dividendPerSecond: 975, marketCap: 75.2,
    priceHistory: List.generate(30, (i) => 1000000.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'mrc', name: 'Medical Robotics Corp', description: 'Company producing robotic surgery and AI diagnostics.',
    currentPrice: 5000000.0, basePrice: 5000000.0, volatility: 0.20, trend: 0.015, owned: 0,
    icon: Icons.biotech, color: Colors.blue.shade800, category: 'Healthcare', dividendPerSecond: 4875.0, marketCap: 120.7,
    priceHistory: List.generate(30, (i) => 5000000.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'atf', name: 'AgroTech Futures', description: 'Futures on agrotech firms in vertical farming.',
    currentPrice: 20000000.0, basePrice: 20000000.0, volatility: 0.30, trend: 0.01, owned: 0,
    icon: Icons.eco, color: Colors.lightGreen.shade800, category: 'Agriculture', dividendPerSecond: 20750.0, marketCap: 195.3,
    priceHistory: List.generate(30, (i) => 20000000.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'lrr', name: 'Luxury Resort REIT', description: 'REIT for luxury resorts and vacation properties.',
    currentPrice: 100000000.0, basePrice: 100000000.0, volatility: 0.10, trend: 0.005, owned: 0,
    icon: Icons.beach_access, color: Colors.teal.shade600, category: 'REITs', dividendPerSecond: 48125.0, marketCap: 580.6,
    priceHistory: List.generate(30, (i) => 100000000.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'ath', name: 'Adventure Travel Holdings', description: 'Holdings in adventure travel and eco-tourism operators.',
    currentPrice: 500000000.0, basePrice: 500000000.0, volatility: 0.20, trend: -0.005, owned: 0,
    icon: Icons.terrain, color: Colors.orange.shade800, category: 'Tourism', dividendPerSecond: 237500.0, marketCap: 1250.0,
    priceHistory: List.generate(30, (i) => 500000000.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),

  // MEME CRYPTOCURRENCIES (Extremely volatile, low market cap)
  Investment(
    id: 'frg', name: 'Froge', description: 'The frog that never stops croaking. To the moon! 🐸',
    currentPrice: 0.001, basePrice: 0.001, volatility: 0.80, trend: 0.0, owned: 0,
    icon: Icons.catching_pokemon, color: Colors.green.shade400, category: 'Meme', marketCap: 0.1,
    priceHistory: List.generate(30, (i) => 0.001 * (0.95 + (Random().nextDouble() * 0.10))),
  ),
  Investment(
    id: 'gga', name: 'Giga', description: 'Chad energy in token form. Only for the strongest holders.',
    currentPrice: 0.05, basePrice: 0.05, volatility: 0.75, trend: 0.01, owned: 0,
    icon: Icons.fitness_center, color: Colors.orange.shade600, category: 'Meme', marketCap: 0.05,
    priceHistory: List.generate(30, (i) => 0.05 * (0.95 + (Random().nextDouble() * 0.10))),
  ),
  Investment(
    id: 'lfi', name: 'Lofi', description: 'Chill beats to trade crypto to. Very relaxed, very volatile.',
    currentPrice: 0.002, basePrice: 0.002, volatility: 0.85, trend: -0.01, owned: 0,
    icon: Icons.headphones, color: Colors.purple.shade300, category: 'Meme', marketCap: 0.02,
    priceHistory: List.generate(30, (i) => 0.002 * (0.95 + (Random().nextDouble() * 0.10))),
  ),
  Investment(
    id: 'shv', name: 'Shiv', description: 'Sharp gains, sharper losses. Not for the faint of heart.',
    currentPrice: 0.008, basePrice: 0.008, volatility: 0.90, trend: 0.005, owned: 0,
    icon: Icons.flash_on, color: Colors.red.shade400, category: 'Meme', marketCap: 0.015,
    priceHistory: List.generate(30, (i) => 0.008 * (0.95 + (Random().nextDouble() * 0.10))),
  ),
  Investment(
    id: 'dge', name: 'DogeCoin Elite', description: 'Much wow, such gains, very meme. The elite version.',
    currentPrice: 0.12, basePrice: 0.12, volatility: 0.70, trend: 0.02, owned: 0,
    icon: Icons.pets, color: Colors.yellow.shade600, category: 'Meme', marketCap: 0.08,
    priceHistory: List.generate(30, (i) => 0.12 * (0.95 + (Random().nextDouble() * 0.10))),
  ),
  Investment(
    id: 'ppe', name: 'Pepe Elite', description: 'Rare Pepe energy concentrated into pure trading power.',
    currentPrice: 0.003, basePrice: 0.003, volatility: 0.88, trend: -0.005, owned: 0,
    icon: Icons.emoji_emotions, color: Colors.green.shade300, category: 'Meme', marketCap: 0.025,
    priceHistory: List.generate(30, (i) => 0.003 * (0.95 + (Random().nextDouble() * 0.10))),
  ),

  // STABLE YIELD ASSETS (Low volatility, stable income)
  Investment(
    id: 'use', name: 'USD.E', description: 'Digital dollar equivalent. Stable value with minimal yield.',
    currentPrice: 1.0, basePrice: 1.0, volatility: 0.005, trend: 0.0, owned: 0,
    icon: Icons.account_balance, color: Colors.green.shade700, category: 'StableYield', 
    dividendPerSecond: 0.00008, marketCap: 50000.0,
    priceHistory: List.generate(30, (i) => 1.0 * (0.999 + (Random().nextDouble() * 0.002))),
  ),
  Investment(
    id: 'trs', name: 'Treasuries', description: 'Government-backed bonds. Ultra-safe with guaranteed returns.',
    currentPrice: 10000.0, basePrice: 10000.0, volatility: 0.02, trend: 0.002, owned: 0,
    icon: Icons.security, color: Colors.blue.shade800, category: 'StableYield', 
    dividendPerSecond: 0.75, marketCap: 400000.0,
    priceHistory: List.generate(30, (i) => 10000.0 * (0.998 + (Random().nextDouble() * 0.004))),
  ),
  Investment(
    id: 'mms', name: 'Money Market Stable', description: 'Conservative money market fund with steady, low returns.',
    currentPrice: 100.0, basePrice: 100.0, volatility: 0.01, trend: 0.001, owned: 0,
    icon: Icons.savings, color: Colors.teal.shade700, category: 'StableYield', 
    dividendPerSecond: 0.00078, marketCap: 15000.0,
    priceHistory: List.generate(30, (i) => 100.0 * (0.999 + (Random().nextDouble() * 0.002))),
  ),

  // ADDITIONAL TECHNOLOGY INVESTMENTS
  Investment(
    id: 'nrl', name: 'NeuralLink Systems', description: 'Brain-computer interface technology leader.',
    currentPrice: 750.0, basePrice: 750.0, volatility: 0.28, trend: 0.018, owned: 0,
    icon: Icons.psychology, color: Colors.indigo.shade600, category: 'Technology', marketCap: 18.5,
    priceHistory: List.generate(30, (i) => 750.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'qcs', name: 'Quantum Computing Solutions', description: 'Next-gen quantum processors and algorithms.',
    currentPrice: 1200.0, basePrice: 1200.0, volatility: 0.32, trend: 0.022, owned: 0,
    icon: Icons.memory, color: Colors.deepPurple.shade700, category: 'Technology', marketCap: 25.8,
    priceHistory: List.generate(30, (i) => 1200.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),

  // ADDITIONAL ENERGY INVESTMENTS
  Investment(
    id: 'fsc', name: 'Fusion Solar Corp', description: 'Revolutionary fusion-solar hybrid technology.',
    currentPrice: 180.0, basePrice: 180.0, volatility: 0.22, trend: 0.012, owned: 0,
    icon: Icons.wb_sunny, color: Colors.yellow.shade700, category: 'Energy', marketCap: 8.2,
    priceHistory: List.generate(30, (i) => 180.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'hyd', name: 'HydroGen Power', description: 'Clean hydrogen fuel cell technology company.',
    currentPrice: 95.0, basePrice: 95.0, volatility: 0.18, trend: 0.008, owned: 0,
    icon: Icons.water_drop, color: Colors.cyan.shade600, category: 'Energy', marketCap: 4.7,
    priceHistory: List.generate(30, (i) => 95.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),

  // ADDITIONAL HEALTHCARE INVESTMENTS
  Investment(
    id: 'gnm', name: 'GenomeMax Therapeutics', description: 'Personalized medicine through genomic analysis.',
    currentPrice: 320.0, basePrice: 320.0, volatility: 0.25, trend: 0.016, owned: 0,
    icon: Icons.biotech, color: Colors.lightBlue.shade600, category: 'Healthcare', marketCap: 12.8,
    priceHistory: List.generate(30, (i) => 320.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'nnt', name: 'NanoTech Medical', description: 'Nanotechnology for targeted drug delivery systems.',
    currentPrice: 450.0, basePrice: 450.0, volatility: 0.30, trend: 0.020, owned: 0,
    icon: Icons.science, color: Colors.green.shade600, category: 'Healthcare', marketCap: 9.5,
    priceHistory: List.generate(30, (i) => 450.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),

  // ADDITIONAL ENTERTAINMENT INVESTMENTS  
  Investment(
    id: 'mvr', name: 'Metaverse Studios', description: 'Virtual world creation and immersive experiences.',
    currentPrice: 85.0, basePrice: 85.0, volatility: 0.35, trend: 0.014, owned: 0,
    icon: Icons.view_in_ar, color: Colors.purple.shade500, category: 'Entertainment', marketCap: 6.2,
    priceHistory: List.generate(30, (i) => 85.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'gms', name: 'GameStream Interactive', description: 'Cloud gaming and interactive streaming platform.',
    currentPrice: 125.0, basePrice: 125.0, volatility: 0.28, trend: 0.011, owned: 0,
    icon: Icons.videogame_asset, color: Colors.red.shade500, category: 'Entertainment', marketCap: 7.8,
    priceHistory: List.generate(30, (i) => 125.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),

  // ADDITIONAL TRANSPORTATION INVESTMENTS
  Investment(
    id: 'avt', name: 'AeroVert Transport', description: 'Vertical takeoff aircraft for urban transport.',
    currentPrice: 280.0, basePrice: 280.0, volatility: 0.24, trend: 0.013, owned: 0,
    icon: Icons.flight_takeoff, color: Colors.blue.shade600, category: 'Transportation', marketCap: 11.2,
    priceHistory: List.generate(30, (i) => 280.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
  Investment(
    id: 'hpr', name: 'HyperLoop Rail', description: 'Ultra-high-speed vacuum tube transportation.',
    currentPrice: 650.0, basePrice: 650.0, volatility: 0.26, trend: 0.017, owned: 0,
    icon: Icons.train, color: Colors.grey.shade700, category: 'Transportation', marketCap: 15.6,
    priceHistory: List.generate(30, (i) => 650.0 * (0.98 + (Random().nextDouble() * 0.04))),
  ),
];