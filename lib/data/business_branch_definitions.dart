import 'package:flutter/material.dart';
import '../models/business.dart';
import '../models/business_branch.dart';

/// Defines the branch specializations for the Pop-Up Food Stall business
/// 
/// Branch Selection Level: 3
/// Pre-branch levels (1-2): Generic Pop-Up Food Stall
/// Post-branch levels (3-10): Specialized path based on selection
/// 
/// Three Paths:
/// 1. Taco Stand (Speed) - Fast upgrades, lower income
/// 2. Burger Bar (Balanced) - Baseline progression  
/// 3. Smoke BBQ (Premium) - Slow upgrades, high income

// ============================================================================
// TACO STAND PATH - Speed Specialist
// ============================================================================
// Theme: Fast Mexican street food, high volume, lower margins
// Economy: ~20% cheaper costs, ~20-25% lower income, ~25% faster timers

final BusinessBranch tacoStandBranch = BusinessBranch(
  id: 'taco_stand',
  name: 'Taco Stand',
  description: 'Fast Mexican street food with high volume and quick upgrades. Lower income ceiling but rapid progression.',
  icon: Icons.lunch_dining,
  type: BusinessBranchType.speed,
  themeColor: const Color(0xFFFF6B35), // Energetic orange
  costMultiplier: 0.8,
  incomeMultiplier: 0.78,
  speedMultiplier: 0.75,
  levels: [
    // Level 3 (branch index 0) - Branch selection level
    BusinessLevel(
      cost: 3200.0,      // 4000 * 0.8
      incomePerSecond: 8.78,  // 11.25 * 0.78
      description: 'Street Taco Cart',
      timerSeconds: 45,  // 60 * 0.75
    ),
    // Level 4 (branch index 1)
    BusinessLevel(
      cost: 6400.0,      // 8000 * 0.8
      incomePerSecond: 21.94, // 28.13 * 0.78
      description: 'Double Grill Setup',
      timerSeconds: 68,  // 90 * 0.75
    ),
    // Level 5 (branch index 2)
    BusinessLevel(
      cost: 12800.0,     // 16000 * 0.8
      incomePerSecond: 52.65, // 67.5 * 0.78
      description: 'Late Night Taco Hours',
      timerSeconds: 90,  // 120 * 0.75
    ),
    // Level 6 (branch index 3)
    BusinessLevel(
      cost: 25600.0,     // 32000 * 0.8
      incomePerSecond: 131.63, // 168.75 * 0.78
      description: 'Food Court Taco Stall',
      timerSeconds: 113, // 150 * 0.75
    ),
    // Level 7 (branch index 4)
    BusinessLevel(
      cost: 51200.0,     // 64000 * 0.8
      incomePerSecond: 329.07, // 421.88 * 0.78
      description: 'Multi-Cart Operation',
      timerSeconds: 135, // 180 * 0.75
    ),
    // Level 8 (branch index 5)
    BusinessLevel(
      cost: 102400.0,    // 128000 * 0.8
      incomePerSecond: 822.66, // 1054.69 * 0.78
      description: 'Citywide Taco Fleet',
      timerSeconds: 158, // 210 * 0.75
    ),
    // Level 9 (branch index 6)
    BusinessLevel(
      cost: 204800.0,    // 256000 * 0.8
      incomePerSecond: 2028.98, // 2601.25 * 0.78
      description: 'Taco Franchise Network',
      timerSeconds: 180, // 240 * 0.75
    ),
    // Level 10 (branch index 7)
    BusinessLevel(
      cost: 409600.0,    // 512000 * 0.8
      incomePerSecond: 4681.95, // 6002.5 * 0.78
      description: 'Taco Empire',
      timerSeconds: 225, // 300 * 0.75
    ),
  ],
);

// ============================================================================
// BURGER BAR PATH - Balanced (Baseline)
// ============================================================================
// Theme: Classic burger stall evolving into a neighborhood brand
// Economy: Mirrors existing Pop-Up Food Stall balance (1.0x multipliers)

final BusinessBranch burgerBarBranch = BusinessBranch(
  id: 'burger_bar',
  name: 'Burger Bar',
  description: 'Classic American burgers with balanced growth. Familiar progression with stable returns.',
  icon: Icons.fastfood,
  type: BusinessBranchType.balanced,
  themeColor: const Color(0xFFE53935), // Classic red
  costMultiplier: 1.0,
  incomeMultiplier: 1.0,
  speedMultiplier: 1.0,
  levels: [
    // Level 3 (branch index 0) - Branch selection level
    BusinessLevel(
      cost: 4000.0,
      incomePerSecond: 11.25,
      description: 'Burger Kiosk',
      timerSeconds: 60,
    ),
    // Level 4 (branch index 1)
    BusinessLevel(
      cost: 8000.0,
      incomePerSecond: 28.13,
      description: 'Classic Burger Stand',
      timerSeconds: 90,
    ),
    // Level 5 (branch index 2)
    BusinessLevel(
      cost: 16000.0,
      incomePerSecond: 67.5,
      description: 'Gourmet Add-Ons',
      timerSeconds: 120,
    ),
    // Level 6 (branch index 3)
    BusinessLevel(
      cost: 32000.0,
      incomePerSecond: 168.75,
      description: 'Burger Food Truck',
      timerSeconds: 150,
    ),
    // Level 7 (branch index 4)
    BusinessLevel(
      cost: 64000.0,
      incomePerSecond: 421.88,
      description: 'Downtown Burger Bar',
      timerSeconds: 180,
    ),
    // Level 8 (branch index 5)
    BusinessLevel(
      cost: 128000.0,
      incomePerSecond: 1054.69,
      description: 'Mini Burger Chain',
      timerSeconds: 210,
    ),
    // Level 9 (branch index 6)
    BusinessLevel(
      cost: 256000.0,
      incomePerSecond: 2601.25,
      description: 'Regional Burger Brand',
      timerSeconds: 240,
    ),
    // Level 10 (branch index 7)
    BusinessLevel(
      cost: 512000.0,
      incomePerSecond: 6002.5,
      description: 'Franchise-Ready Burger Brand',
      timerSeconds: 300,
    ),
  ],
);

// ============================================================================
// SMOKE BBQ PATH - Premium Route
// ============================================================================
// Theme: Artisanal slow-cooked BBQ with premium pricing and prestige
// Economy: ~30% more expensive, ~38% higher income, ~50% longer timers

final BusinessBranch smokeBbqBranch = BusinessBranch(
  id: 'smoke_bbq',
  name: 'Smoke BBQ',
  description: 'Artisanal slow-cooked BBQ with premium pricing. Slow upgrades but highest income potential.',
  icon: Icons.outdoor_grill,
  type: BusinessBranchType.premium,
  themeColor: const Color(0xFF8B4513), // Deep BBQ brown/gold
  costMultiplier: 1.3,
  incomeMultiplier: 1.38,
  speedMultiplier: 1.5,
  levels: [
    // Level 3 (branch index 0) - Branch selection level
    BusinessLevel(
      cost: 5200.0,      // 4000 * 1.3
      incomePerSecond: 15.53,  // 11.25 * 1.38
      description: 'Backyard Smoke Pit',
      timerSeconds: 90,  // 60 * 1.5
    ),
    // Level 4 (branch index 1)
    BusinessLevel(
      cost: 10400.0,     // 8000 * 1.3
      incomePerSecond: 38.82, // 28.13 * 1.38
      description: 'Street-Side Smoke Shack',
      timerSeconds: 135, // 90 * 1.5
    ),
    // Level 5 (branch index 2)
    BusinessLevel(
      cost: 20800.0,     // 16000 * 1.3
      incomePerSecond: 93.15, // 67.5 * 1.38
      description: 'Signature Smokers',
      timerSeconds: 180, // 120 * 1.5
    ),
    // Level 6 (branch index 3)
    BusinessLevel(
      cost: 41600.0,     // 32000 * 1.3
      incomePerSecond: 232.88, // 168.75 * 1.38
      description: 'Full BBQ Restaurant',
      timerSeconds: 225, // 150 * 1.5
    ),
    // Level 7 (branch index 4)
    BusinessLevel(
      cost: 83200.0,     // 64000 * 1.3
      incomePerSecond: 582.19, // 421.88 * 1.38
      description: 'BBQ Competition Circuit',
      timerSeconds: 270, // 180 * 1.5
    ),
    // Level 8 (branch index 5)
    BusinessLevel(
      cost: 166400.0,    // 128000 * 1.3
      incomePerSecond: 1455.47, // 1054.69 * 1.38
      description: 'Regional BBQ Brand',
      timerSeconds: 315, // 210 * 1.5
    ),
    // Level 9 (branch index 6)
    BusinessLevel(
      cost: 332800.0,    // 256000 * 1.3
      incomePerSecond: 3589.73, // 2601.25 * 1.38
      description: 'BBQ Empire Chain',
      timerSeconds: 360, // 240 * 1.5
    ),
    // Level 10 (branch index 7)
    BusinessLevel(
      cost: 665600.0,    // 512000 * 1.3
      incomePerSecond: 8283.45, // 6002.5 * 1.38
      description: 'Legendary BBQ Empire',
      timerSeconds: 450, // 300 * 1.5
    ),
  ],
);

/// List of all branches for the Pop-Up Food Stall business
final List<BusinessBranch> foodStallBranches = [
  tacoStandBranch,
  burgerBarBranch,
  smokeBbqBranch,
];

/// The level at which the Pop-Up Food Stall allows branch selection
const int foodStallBranchSelectionLevel = 3;
