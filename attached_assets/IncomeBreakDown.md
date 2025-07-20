Okay, Sherlock mode activated. Let's put on the deerstalker, grab the magnifying glass, and dive deep into the financial plumbing of Empire Tycoon. This requires tracing the flow of money from its sources, through all modifications, to its final accounting and display.
Based on the files provided and logical assumptions about the project structure, here is a comprehensive analysis of income accumulation and tracking:
I. Core Concepts & State Variables (GameState - defined in game_state.dart and its partial files)
The GameState acts as the central hub for all financial information.
Primary State:
money: (double) The player's current cash balance. This is the ultimate destination for most income.
totalEarned: (double) Tracks total money earned within the current prestige cycle. Used for display and potentially challenge goals.
Earnings Breakdown (for Stats):
manualEarnings: (double) Income generated specifically from player taps.
passiveEarnings: (double) Income generated automatically from Businesses.
investmentEarnings: (double) Net profit/loss realized from selling Investments. Does not include dividends.
investmentDividendEarnings: (double) Passive income generated from Investment dividends.
realEstateEarnings: (double) Passive income generated from Real Estate properties.
Base Income Sources:
clickValue: (double) Base cash earned per manual tap (influenced by clickLevel).
Business.baseIncome: (double) Base income per cycle for a business (defined in business_definitions.dart, likely scaled by level within Business.getCurrentIncome()).
Investment.dividendPerSecond: (double) Base dividend income per share per second (defined in investment_definitions.dart).
RealEstateProperty.baseIncomePerSecond: (double) Base income per second for a property (defined likely within RealEstateProperty, potentially influenced by base definitions).
Multipliers & Boosts (Flags and Values):
Global Prestige:
incomeMultiplier: (double) Set by reincorporate(). Based on compounding 1.2x per prestige level derived from networkWorth. Applied to all passive income sources (Business, RE, Dividends).
clickMultiplier: (double) Set by reincorporate(). Based on 1.0 + 0.1x per prestige level (min 1.2x). Applied to manual taps.
prestigeMultiplier: (double) Likely Legacy/Incorrectly Used. Applied alongside incomeMultiplier in _updateGameState and calculateTotalIncomePerSecond, but not set clearly by reincorporate and not used in the correct GameState.tap() function. Should likely be removed.
Platinum - Permanent Passive:
isPermanentIncomeBoostActive: (+5%) From perm_income_boost_5pct. Applied globally to Business, RE, Dividend income.
isPlatinumEfficiencyActive: (+5%) From platinum_efficiency. Applied specifically to Business base income.
isPlatinumPortfolioActive: (+25%) From platinum_portfolio. Applied specifically to Dividend base income.
Platinum - Permanent Active:
isPermanentClickBoostActive: (+10%) From perm_click_boost_10pct. Applied to manual taps.
Platinum - Conditional Passive:
platinumFoundationsApplied: (+5% per) From platinum_foundation. Applied to RE income for specific locales.
platinumYachtDockedLocaleId: (+5%) From platinum_yacht. Applied to RE income for the docked locale.
Platinum - Temporary Passive:
isIncomeSurgeActive: (2x) From platinum_surge. Applied globally to Business, RE, Dividend income. Has duration (incomeSurgeEndTime) and cooldown (incomeSurgeCooldownEnd).
Platinum - Temporary Active:
isClickFrenzyActive: (10x) From temp_boost_10x_5min. Applied to manual taps. Has duration (platinumClickFrenzyRemainingSeconds).
isSteadyBoostActive: (2x) From temp_boost_2x_10min. Applied to manual taps. Has duration (platinumSteadyBoostRemainingSeconds).
Ad Boost:
isAdBoostActive: (10x) From watching ads. Applied to manual taps. Has duration (adBoostRemainingSeconds).
Investment Specific:
calculateDiversificationBonus(): (+2% per unique owned category). Applied to Dividend income.
Penalties:
activeEvents: List of GameEvent objects.
hasActiveEventForBusiness() / hasActiveEventForLocale(): Check if an entity is affected.
GameStateEvents.NEGATIVE_EVENT_MULTIPLIER: (Constant, likely 0.75) Reduces income for affected Businesses/Real Estate locales. Requires confirmation of the constant's value.
II. Income Generation & Calculation Flow
The primary income generation happens in timed updates and manual actions:
Periodic Update (GameState._updateGameState in update_logic.dart - Runs every second):
Businesses:
Calculates income per business cycle completion.
Formula (per business): baseIncome * (isPlatinumEfficiencyActive ? 1.05 : 1.0) * incomeMultiplier * prestigeMultiplier * (isPermanentIncomeBoostActive ? 1.05 : 1.0) * (isIncomeSurgeActive ? 2.0 : 1.0) * (eventPenalty ? NEGATIVE_EVENT_MULTIPLIER : 1.0)
(Issue: prestigeMultiplier usage likely incorrect).
Adds to money, totalEarned, passiveEarnings, hourlyEarnings.
Real Estate:
Calculates total base income per second from all properties/upgrades via getRealEstateIncomePerSecond().
Formula (applied globally): baseIncomePerSecond * incomeMultiplier * prestigeMultiplier * (isPermanentIncomeBoostActive ? 1.05 : 1.0) * (isIncomeSurgeActive ? 2.0 : 1.0)
(Issue: prestigeMultiplier usage likely incorrect. Missing locale-specific Platinum Foundation/Yacht boosts and Event Penalties in this specific update loop).
Adds to money, totalEarned, realEstateEarnings, hourlyEarnings.
Dividends:
Calculates income per investment.
Formula (per investment): baseDivPerShare * (isPlatinumPortfolioActive ? 1.25 : 1.0) * (1 + diversificationBonus) * investment.owned * incomeMultiplier * prestigeMultiplier * (isPermanentIncomeBoostActive ? 1.05 : 1.0) * (isIncomeSurgeActive ? 2.0 : 1.0)
(Issue: prestigeMultiplier usage likely incorrect).
Adds to money, totalEarned, investmentDividendEarnings, hourlyEarnings.
Manual Tap (GameState.tap in game_state.dart - Correct Implementation):
Formula: clickValue * (isPermanentClickBoostActive ? 1.1 : 1.0) * (isAdBoostActive ? 10.0 : 1.0) * (platinumBoostMultiplier) * clickMultiplier
platinumBoostMultiplier is 10x for Frenzy, 2x for Steady, 1x otherwise.
(Issue: The clickMultiplier (from prestige) is missing from the current calculation in game_state.dart line 771).
Adds to money, totalEarned, manualEarnings, taps, lifetimeTaps, hourlyEarnings.
(Note: The tap() function in utility_logic.dart seems outdated/incorrect and likely unused).
Offline Progress (GameState._processOfflineProgress in serialization_logic.dart - Runs on game load):
Calculates earnings for the duration the game was closed (capped, e.g., 24h).
Uses logic very similar to _updateGameState but applied over the total cappedSeconds.
Crucially, it correctly includes the locale-specific Platinum Foundation/Yacht boosts and Event Penalties for Real Estate income, which are missing from the live _updateGameState RE calculation.
Adds totals to money, totalEarned, and respective categories (passiveEarnings, realEstateEarnings, investmentDividendEarnings).
Sets offlineEarningsAwarded, offlineDurationForNotification, and _shouldShowOfflineEarnings for the UI notification.
Instant Income Awards (Platinum Vault):
platinum_cache: Awards cash based on current passive income rate (calculateTotalIncomePerSecond). Adds to money, totalEarned.
platinum_warp: Awards 1 hour of offline income (calculateOfflineIncome, uses calculateTotalIncomePerSecond). Adds to money, totalEarned, passiveEarnings.
III. Supporting Calculations & Models
Business (Business.dart, business_definitions.dart): Defines baseIncome, incomeInterval. getCurrentIncome() likely calculates baseIncome * level * upgrade_multipliers. getIncomePerSecond() is getCurrentIncome() / incomeInterval. getCurrentValue() used for net worth.
Investment (Investment.dart, investment_definitions.dart): Defines dividendPerSecond, category. getDividendIncomePerSecond() returns the per-share rate. getCurrentValue() is currentPrice * owned. Market events (MarketEvent) modify currentPrice. calculateDiversificationBonus() implemented in GameState.
Real Estate (real_estate.dart, real_estate_data_loader.dart): Properties have baseIncomePerSecond. RealEstateUpgrades provide multipliers. RealEstateProperty.getTotalIncomePerSecond() aggregates property income considering owned count and upgrades. RealEstateLocale.getTotalIncomePerSecond() sums property income. getTotalValue() sums property values for net worth.
Net Worth (GameState.calculateNetWorth in utility_logic.dart): money + Sum(business.getCurrentValue()) + Sum(investment.getCurrentValue()) + Sum(locale.getTotalValue()). Used for prestige (reincorporate) thresholds.
Total Income Per Second (GameState.calculateTotalIncomePerSecond in utility_logic.dart): Used for display (StatsScreen), Platinum Cache/Warp calculations. Applies multipliers slightly differently than _updateGameState (globally after summing bases vs. per source). Includes correct RE locale boosts/penalties.
IV. Tracking & Storage
Live State: GameState object in memory.
Hourly History: hourlyEarnings (Map<String, double>) in GameState, keyed by YYYY-MM-DD-HH. Saved/loaded. Pruned to 7 days.
Persistent Net Worth History: persistentNetWorthHistory (Map<int, double>) in GameState, keyed by timestamp ms. Saved/loaded. Persists across reincorporation. Pruned to 7 days. Updated every 30 mins.
Serialization (serialization_logic.dart): GameState.toJson() saves all relevant fields (money, earnings, multipliers, flags, timers, history, offline state). GameState.fromJson() loads the state and triggers _processOfflineProgress.
V. UI Display
StatsScreen: Shows detailed breakdowns (manualEarnings, passiveEarnings, etc.), asset values, net worth, prestige multipliers (incomeMultiplier), hourly earnings chart (hourlyEarnings), net worth history chart (persistentNetWorthHistory). Uses NumberFormatter.
MoneyDisplay: Generic widget for disp laying formatted currency (NumberFormatter.formatCurrency).
MainScreen (Assumed): Displays current money. Likely shows tap value (needs calculation using clickValue and all relevant tap multipliers). May show income/sec using calculateTotalIncomePerSecond. Requires checking main_screen.dart.
VI. Summary of Issues & Inconsistencies (Verdict)
The income system is complex and functional but suffers from several key inconsistencies and potential bugs:
prestigeMultiplier Confusion: This field seems legacy or incorrectly used. It's applied to passive income in _updateGameState alongside the correct incomeMultiplier (from prestige), but isn't clearly set or used consistently, especially concerning tap income. ACTION: Remove prestigeMultiplier usage from passive income calculations. Standardize on incomeMultiplier for passive prestige boost and clickMultiplier for tap prestige boost.
Missing Tap Multiplier: The primary GameState.tap() function does not apply the clickMultiplier earned through reincorporation. ACTION: Add * clickMultiplier to the finalEarnings calculation in GameState.tap().
Incomplete Real Estate Update: The main _updateGameState loop fails to apply locale-specific Platinum Foundation/Yacht boosts and Event Penalties to real estate income. These are applied correctly in offline calculations (_processOfflineProgress) and total income calculations (calculateTotalIncomePerSecond). This leads to incorrect live RE income calculation under those conditions. ACTION: Refactor the RE income block within _updateGameState to iterate through locales/properties and apply these factors, mirroring the logic in _processOfflineProgress.
Calculation Order Differences: _updateGameState and _processOfflineProgress apply global multipliers per source/cycle, while calculateTotalIncomePerSecond applies them after summing base incomes. This isn't necessarily a bug but is inconsistent and could lead to minor discrepancies if used interchangeably for critical logic. ACTION: Consider standardizing the calculation order, preferably applying per source/cycle for robustness.
VII. Next Steps & Verification
File Check: Use list_dir . or similar to scan the entire lib/ directory to ensure no other relevant screens or logic files (especially main_screen.dart) were missed.
Constant Verification: Find the definition of GameStateEvents.NEGATIVE_EVENT_MULTIPLIER.
Function Verification: Read the exact implementation of Business.getCurrentIncome() to confirm level/upgrade scaling.
Address Issues: Implement the recommended actions to fix the identified inconsistencies (prestigeMultiplier, tap multiplier, RE update logic).
This analysis provides a deep understanding of the current income system's mechanics and its flaws. Addressing the identified issues is crucial for ensuring accurate and consistent financial calculations within the game.