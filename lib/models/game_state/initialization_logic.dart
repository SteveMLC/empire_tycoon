part of '../game_state.dart';

// Contains methods related to initializing the game state

extension InitializationLogic on GameState {
  Future<void> initializeRealEstateUpgrades() async {
    try {
      final upgradesByPropertyId = await RealEstateDataLoader.loadUpgradesFromCSV();
      RealEstateDataLoader.applyUpgradesToProperties(realEstateLocales, upgradesByPropertyId);
      notifyListeners();
    } catch (e) {
      print('Failed to initialize real estate upgrades: $e');
      // Consider how to handle this error more gracefully in the UI
    }
  }

  void _initializeDefaultBusinesses() {
    businesses = defaultBusinesses; // Use the imported list from business_definitions.dart
  }

  void _initializeDefaultInvestments() {
    investments = [
      // STOCKS
      Investment(
        id: 'nxt',
        name: 'NexTech',
        description: 'A tech firm specializing in AI software.',
        currentPrice: 10.0,
        basePrice: 10.0,
        volatility: 0.15,
        trend: 0.02,
        owned: 0,
        icon: Icons.computer,
        color: Colors.blue,
        priceHistory: List.generate(30, (i) {
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04);
          return 10.0 * randomFactor;
        }),
        category: 'Technology',
        marketCap: 2.5,
      ),
      Investment(
        id: 'grv',
        name: 'GreenVolt',
        description: 'Renewable energy company with steady growth.',
        currentPrice: 25.0,
        basePrice: 25.0,
        volatility: 0.12,
        trend: 0.03,
        owned: 0,
        icon: Icons.eco,
        color: Colors.green,
        priceHistory: List.generate(30, (i) {
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04);
          return 25.0 * randomFactor;
        }),
        category: 'Energy',
        marketCap: 5.0,
      ),
      Investment(
        id: 'mft',
        name: 'MegaFreight',
        description: 'Logistics and shipping giant.',
        currentPrice: 50.0,
        basePrice: 50.0,
        volatility: 0.15,
        trend: 0.01,
        owned: 0,
        icon: Icons.local_shipping,
        color: Colors.blueGrey,
        priceHistory: List.generate(30, (i) {
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04);
          return 50.0 * randomFactor;
        }),
        category: 'Transportation',
        marketCap: 12.0,
      ),
      Investment(
        id: 'lxw',
        name: 'LuxWear',
        description: 'High-end fashion brand with trendy spikes.',
        currentPrice: 100.0,
        basePrice: 100.0,
        volatility: 0.20,
        trend: 0.02,
        owned: 0,
        icon: Icons.diamond_outlined,
        color: Colors.pink,
        priceHistory: List.generate(30, (i) {
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04);
          return 100.0 * randomFactor;
        }),
        category: 'Fashion',
        marketCap: 3.2,
      ),
      Investment(
        id: 'stf',
        name: 'StarForge',
        description: 'Space exploration company with high risk/reward.',
        currentPrice: 500.0,
        basePrice: 500.0,
        volatility: 0.25,
        trend: 0.04,
        owned: 0,
        icon: Icons.rocket_launch,
        color: Colors.deepPurple,
        priceHistory: List.generate(30, (i) {
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04);
          return 500.0 * randomFactor;
        }),
        category: 'Aerospace',
        marketCap: 20.0,
      ),
      // CRYPTOCURRENCIES
      Investment(
        id: 'bcl',
        name: 'BitCoinLite',
        description: 'A beginner-friendly crypto with moderate swings.',
        currentPrice: 50.0,
        basePrice: 50.0,
        volatility: 0.30,
        trend: 0.02,
        owned: 0,
        icon: Icons.currency_bitcoin,
        color: Colors.amber,
        priceHistory: List.generate(30, (i) {
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04);
          return 50.0 * randomFactor;
        }),
        category: 'Cryptocurrency',
        marketCap: 0.85,
      ),
      Investment(
        id: 'etc',
        name: 'EtherCore',
        description: 'A blockchain platform with growing adoption.',
        currentPrice: 200.0,
        basePrice: 200.0,
        volatility: 0.25,
        trend: 0.03,
        owned: 0,
        icon: Icons.hub,
        color: Colors.blue.shade800,
        priceHistory: List.generate(30, (i) {
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04);
          return 200.0 * randomFactor;
        }),
        category: 'Cryptocurrency',
        marketCap: 2.4,
      ),
      Investment(
        id: 'mtk',
        name: 'MoonToken',
        description: 'A meme coin with wild volatility.',
        currentPrice: 10.0,
        basePrice: 10.0,
        volatility: 0.50,
        trend: -0.01,
        owned: 0,
        icon: Icons.nightlight_round,
        color: Colors.purple.shade300,
        priceHistory: List.generate(30, (i) {
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04);
          return 10.0 * randomFactor;
        }),
        category: 'Cryptocurrency',
        marketCap: 0.25,
      ),
      Investment(
        id: 'sbx',
        name: 'StableX',
        description: 'A low-risk crypto pegged to real-world value.',
        currentPrice: 100.0,
        basePrice: 100.0,
        volatility: 0.03,
        trend: 0.001,
        owned: 0,
        icon: Icons.lock,
        color: Colors.teal,
        priceHistory: List.generate(30, (i) {
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04);
          return 100.0 * randomFactor;
        }),
        category: 'Cryptocurrency',
        marketCap: 5.7,
      ),
      Investment(
        id: 'qbt',
        name: 'QuantumBit',
        description: 'Cutting-edge crypto tied to quantum computing.',
        currentPrice: 1000.0,
        basePrice: 1000.0,
        volatility: 0.35,
        trend: 0.05,
        owned: 0,
        icon: Icons.pending,
        color: Colors.cyan.shade700,
        priceHistory: List.generate(30, (i) {
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04);
          return 1000.0 * randomFactor;
        }),
        category: 'Cryptocurrency',
        marketCap: 3.2,
      ),
      // DIVIDEND INVESTMENTS
      Investment(
        id: 'btf',
        name: 'BioTech Innovators Fund',
        description: 'Fund for biotech startups in gene therapy and vaccines.',
        currentPrice: 500.0,
        basePrice: 500.0,
        volatility: 0.20,
        trend: 0.03,
        owned: 0,
        icon: Icons.healing,
        color: Colors.lightBlue.shade700,
        priceHistory: List.generate(30, (i) {
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04);
          return 500.0 * randomFactor;
        }),
        category: 'Healthcare',
        dividendPerSecond: 1.89, // Income per second per share
        marketCap: 12.5,
      ),
      Investment(
        id: 'sme',
        name: 'Streaming Media ETF',
        description: 'ETF of streaming platforms and content creators.',
        currentPrice: 2000.0,
        basePrice: 2000.0,
        volatility: 0.20,
        trend: 0.04,
        owned: 0,
        icon: Icons.live_tv,
        color: Colors.red.shade700,
        priceHistory: List.generate(30, (i) {
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04);
          return 2000.0 * randomFactor;
        }),
        category: 'Entertainment',
        dividendPerSecond: 7.56,
        marketCap: 35.8,
      ),
      Investment(
        id: 'sab',
        name: 'Sustainable Agriculture Bonds',
        description: 'Bonds for organic farming and sustainable food production.',
        currentPrice: 10000.0,
        basePrice: 10000.0,
        volatility: 0.10,
        trend: 0.02,
        owned: 0,
        icon: Icons.agriculture,
        color: Colors.green.shade800,
        priceHistory: List.generate(30, (i) {
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04);
          return 10000.0 * randomFactor;
        }),
        category: 'Agriculture',
        dividendPerSecond: 39,
        marketCap: 22.7,
      ),
      Investment(
        id: 'gti',
        name: 'Global Tourism Index',
        description: 'Index fund of major tourism companies.',
        currentPrice: 50000.0,
        basePrice: 50000.0,
        volatility: 0.20,
        trend: 0.03,
        owned: 0,
        icon: Icons.flight,
        color: Colors.amber.shade800,
        priceHistory: List.generate(30, (i) {
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04);
          return 50000.0 * randomFactor;
        }),
        category: 'Tourism',
        dividendPerSecond: 191,
        marketCap: 86.5,
      ),
      Investment(
        id: 'urt',
        name: 'Urban REIT',
        description: 'REIT for urban commercial properties.',
        currentPrice: 200000.0,
        basePrice: 200000.0,
        volatility: 0.10,
        trend: 0.02,
        owned: 0,
        icon: Icons.business,
        color: Colors.brown.shade600,
        priceHistory: List.generate(30, (i) {
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04);
          return 200000.0 * randomFactor;
        }),
        category: 'REITs',
        dividendPerSecond: 762,
        marketCap: 125.8,
      ),
      Investment(
        id: 'vrv',
        name: 'Virtual Reality Ventures',
        description: 'Stocks in VR gaming and entertainment companies.',
        currentPrice: 1000000.0,
        basePrice: 1000000.0,
        volatility: 0.30,
        trend: 0.05,
        owned: 0,
        icon: Icons.vrpano,
        color: Colors.deepPurple.shade600,
        priceHistory: List.generate(30, (i) {
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04);
          return 1000000.0 * randomFactor;
        }),
        category: 'Entertainment',
        dividendPerSecond: 3900,
        marketCap: 75.2,
      ),
      Investment(
        id: 'mrc',
        name: 'Medical Robotics Corp',
        description: 'Company producing robotic surgery and AI diagnostics.',
        currentPrice: 5000000.0,
        basePrice: 5000000.0,
        volatility: 0.20,
        trend: 0.04,
        owned: 0,
        icon: Icons.biotech,
        color: Colors.blue.shade800,
        priceHistory: List.generate(30, (i) {
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04);
          return 5000000.0 * randomFactor;
        }),
        category: 'Healthcare',
        dividendPerSecond: 19500.0,
        marketCap: 120.7,
      ),
      Investment(
        id: 'atf',
        name: 'AgroTech Futures',
        description: 'Futures on agrotech firms in vertical farming.',
        currentPrice: 20000000.0,
        basePrice: 20000000.0,
        volatility: 0.30,
        trend: 0.03,
        owned: 0,
        icon: Icons.eco,
        color: Colors.lightGreen.shade800,
        priceHistory: List.generate(30, (i) {
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04);
          return 20000000.0 * randomFactor;
        }),
        category: 'Agriculture',
        dividendPerSecond: 83000,
        marketCap: 195.3,
      ),
      Investment(
        id: 'lrr',
        name: 'Luxury Resort REIT',
        description: 'REIT for luxury resorts and vacation properties.',
        currentPrice: 100000000.0,
        basePrice: 100000000.0,
        volatility: 0.10,
        trend: 0.02,
        owned: 0,
        icon: Icons.beach_access,
        color: Colors.teal.shade600,
        priceHistory: List.generate(30, (i) {
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04);
          return 100000000.0 * randomFactor;
        }),
        category: 'REITs',
        dividendPerSecond: 385000,
        marketCap: 580.6,
      ),
      Investment(
        id: 'ath',
        name: 'Adventure Travel Holdings',
        description: 'Holdings in adventure travel and eco-tourism operators.',
        currentPrice: 500000000.0,
        basePrice: 500000000.0,
        volatility: 0.20,
        trend: 0.03,
        owned: 0,
        icon: Icons.terrain,
        color: Colors.orange.shade800,
        priceHistory: List.generate(30, (i) {
          final randomFactor = 0.98 + (Random().nextDouble() * 0.04);
          return 500000000.0 * randomFactor;
        }),
        category: 'Tourism',
        dividendPerSecond: 1900000,
        marketCap: 1250.0,
      ),
    ];
  }

  void _initializeRealEstateLocales() {
    realEstateLocales = [
      RealEstateLocale(
        id: 'rural_kenya',
        name: 'Rural Kenya',
        theme: 'Traditional and rural African homes',
        unlocked: true, // Always unlocked from the start
        icon: Icons.cabin,
        properties: [
          RealEstateProperty(
            id: 'mud_hut',
            name: 'Mud Hut',
            purchasePrice: 500.0,
            baseCashFlowPerSecond: 0.5 * 1.15,
          ),
          RealEstateProperty(
            id: 'thatched_cottage',
            name: 'Thatched Cottage',
            purchasePrice: 1000.0,
            baseCashFlowPerSecond: 1.0 * 1.25,
          ),
          RealEstateProperty(
            id: 'brick_shack',
            name: 'Brick Shack',
            purchasePrice: 2500.0,
            baseCashFlowPerSecond: 2.5 * 1.35,
          ),
          RealEstateProperty(
            id: 'solar_powered_hut',
            name: 'Solar-Powered Hut',
            purchasePrice: 5000.0,
            baseCashFlowPerSecond: 5.0 * 1.45,
          ),
          RealEstateProperty(
            id: 'village_compound',
            name: 'Village Compound',
            purchasePrice: 10000.0,
            baseCashFlowPerSecond: 10.0 * 1.55,
          ),
          RealEstateProperty(
            id: 'eco_lodge',
            name: 'Eco-Lodge',
            purchasePrice: 25000.0,
            baseCashFlowPerSecond: 25.0 * 1.65,
          ),
          RealEstateProperty(
            id: 'farmhouse',
            name: 'Farmhouse',
            purchasePrice: 50000.0,
            baseCashFlowPerSecond: 50.0 * 1.75,
          ),
          RealEstateProperty(
            id: 'safari_retreat',
            name: 'Safari Retreat',
            purchasePrice: 100000.0,
            baseCashFlowPerSecond: 100.0 * 1.85,
          ),
          RealEstateProperty(
            id: 'rural_estate',
            name: 'Rural Estate',
            purchasePrice: 250000.0,
            baseCashFlowPerSecond: 250.0 * 1.95,
          ),
          RealEstateProperty(
            id: 'conservation_villa',
            name: 'Conservation Villa',
            purchasePrice: 500000.0,
            baseCashFlowPerSecond: 500.0 * 2.05,
          ),
        ],
      ),
      RealEstateLocale(
        id: 'lagos_nigeria',
        name: 'Lagos, Nigeria',
        theme: 'Urban growth and modern apartments',
        unlocked: false,
        icon: Icons.apartment,
        properties: [
          RealEstateProperty(
            id: 'tin_roof_shack',
            name: 'Tin-Roof Shack',
            purchasePrice: 1000.0,
            baseCashFlowPerSecond: 1.0 * 1.15,
          ),
          RealEstateProperty(
            id: 'concrete_flat',
            name: 'Concrete Flat',
            purchasePrice: 2000.0,
            baseCashFlowPerSecond: 2.0 * 1.25,
          ),
          RealEstateProperty(
            id: 'small_apartment',
            name: 'Small Apartment',
            purchasePrice: 5000.0,
            baseCashFlowPerSecond: 5.0 * 1.35,
          ),
          RealEstateProperty(
            id: 'duplex',
            name: 'Duplex',
            purchasePrice: 10000.0,
            baseCashFlowPerSecond: 10.0 * 1.45,
          ),
          RealEstateProperty(
            id: 'mid_rise_block',
            name: 'Mid-Rise Block',
            purchasePrice: 25000.0,
            baseCashFlowPerSecond: 25.0 * 1.55,
          ),
          RealEstateProperty(
            id: 'gated_complex',
            name: 'Gated Complex',
            purchasePrice: 50000.0,
            baseCashFlowPerSecond: 50.0 * 1.65,
          ),
          RealEstateProperty(
            id: 'high_rise_tower',
            name: 'High-Rise Tower',
            purchasePrice: 100000.0,
            baseCashFlowPerSecond: 100.0 * 1.75,
          ),
          RealEstateProperty(
            id: 'luxury_condo',
            name: 'Luxury Condo',
            purchasePrice: 250000.0,
            baseCashFlowPerSecond: 250.0 * 1.85,
          ),
          RealEstateProperty(
            id: 'business_loft',
            name: 'Business Loft',
            purchasePrice: 500000.0,
            baseCashFlowPerSecond: 500.0 * 1.95,
          ),
          RealEstateProperty(
            id: 'skyline_penthouse',
            name: 'Skyline Penthouse',
            purchasePrice: 1000000.0,
            baseCashFlowPerSecond: 1000.0 * 2.05,
          ),
        ],
      ),
      RealEstateLocale(
        id: 'cape_town_sa',
        name: 'Cape Town, South Africa',
        theme: 'Coastal and scenic properties',
        unlocked: false,
        icon: Icons.beach_access,
        properties: [
          RealEstateProperty(
            id: 'beach_shack',
            name: 'Beach Shack',
            purchasePrice: 5000.0,
            baseCashFlowPerSecond: 5.0 * 1.15,
          ),
          RealEstateProperty(
            id: 'wooden_bungalow',
            name: 'Wooden Bungalow',
            purchasePrice: 10000.0,
            baseCashFlowPerSecond: 10.0 * 1.25,
          ),
          RealEstateProperty(
            id: 'cliffside_cottage',
            name: 'Cliffside Cottage',
            purchasePrice: 25000.0,
            baseCashFlowPerSecond: 25.0 * 1.35,
          ),
          RealEstateProperty(
            id: 'seaview_villa',
            name: 'Seaview Villa',
            purchasePrice: 50000.0,
            baseCashFlowPerSecond: 50.0 * 1.45,
          ),
          RealEstateProperty(
            id: 'modern_beach_house',
            name: 'Modern Beach House',
            purchasePrice: 100000.0,
            baseCashFlowPerSecond: 100.0 * 1.55,
          ),
          RealEstateProperty(
            id: 'coastal_estate',
            name: 'Coastal Estate',
            purchasePrice: 250000.0,
            baseCashFlowPerSecond: 250.0 * 1.65,
          ),
          RealEstateProperty(
            id: 'luxury_retreat',
            name: 'Luxury Retreat',
            purchasePrice: 500000.0,
            baseCashFlowPerSecond: 500.0 * 1.75,
          ),
          RealEstateProperty(
            id: 'oceanfront_mansion',
            name: 'Oceanfront Mansion',
            purchasePrice: 1000000.0,
            baseCashFlowPerSecond: 1000.0 * 1.85,
          ),
          RealEstateProperty(
            id: 'vineyard_manor',
            name: 'Vineyard Manor',
            purchasePrice: 2500000.0,
            baseCashFlowPerSecond: 2500.0 * 1.95,
          ),
          RealEstateProperty(
            id: 'cape_peninsula_chateau',
            name: 'Cape Peninsula Chateau',
            purchasePrice: 5000000.0,
            baseCashFlowPerSecond: 5000.0 * 2.05,
          ),
        ],
      ),
      RealEstateLocale(
        id: 'rural_thailand',
        name: 'Rural Thailand',
        theme: 'Tropical and bamboo-based homes',
        unlocked: false,
        icon: Icons.holiday_village,
        properties: [
          RealEstateProperty(
            id: 'bamboo_hut',
            name: 'Bamboo Hut',
            purchasePrice: 750.0,
            baseCashFlowPerSecond: 0.75 * 1.15,
          ),
          RealEstateProperty(
            id: 'stilt_house',
            name: 'Stilt House',
            purchasePrice: 1500.0,
            baseCashFlowPerSecond: 1.5 * 1.25,
          ),
          RealEstateProperty(
            id: 'teak_cabin',
            name: 'Teak Cabin',
            purchasePrice: 3000.0,
            baseCashFlowPerSecond: 3.0 * 1.35,
          ),
          RealEstateProperty(
            id: 'rice_farmhouse',
            name: 'Rice Farmhouse',
            purchasePrice: 7500.0,
            baseCashFlowPerSecond: 7.5 * 1.45,
          ),
          RealEstateProperty(
            id: 'jungle_bungalow',
            name: 'Jungle Bungalow',
            purchasePrice: 15000.0,
            baseCashFlowPerSecond: 15.0 * 1.55,
          ),
          RealEstateProperty(
            id: 'riverside_villa',
            name: 'Riverside Villa',
            purchasePrice: 30000.0,
            baseCashFlowPerSecond: 30.0 * 1.65,
          ),
          RealEstateProperty(
            id: 'eco_resort',
            name: 'Eco-Resort',
            purchasePrice: 75000.0,
            baseCashFlowPerSecond: 75.0 * 1.75,
          ),
          RealEstateProperty(
            id: 'hilltop_retreat',
            name: 'Hilltop Retreat',
            purchasePrice: 150000.0,
            baseCashFlowPerSecond: 150.0 * 1.85,
          ),
          RealEstateProperty(
            id: 'teak_mansion',
            name: 'Teak Mansion',
            purchasePrice: 300000.0,
            baseCashFlowPerSecond: 300.0 * 1.95,
          ),
          RealEstateProperty(
            id: 'tropical_estate',
            name: 'Tropical Estate',
            purchasePrice: 750000.0,
            baseCashFlowPerSecond: 750.0 * 2.05,
          ),
        ],
      ),
      RealEstateLocale(
        id: 'mumbai_india',
        name: 'Mumbai, India',
        theme: 'Dense urban housing with cultural flair',
        unlocked: false,
        icon: Icons.location_city,
        properties: [
          RealEstateProperty(
            id: 'slum_tenement',
            name: 'Slum Tenement',
            purchasePrice: 2000.0,
            baseCashFlowPerSecond: 2.0 * 1.15,
          ),
          RealEstateProperty(
            id: 'concrete_flat_mumbai',
            name: 'Concrete Flat',
            purchasePrice: 4000.0,
            baseCashFlowPerSecond: 4.0 * 1.25,
          ),
          RealEstateProperty(
            id: 'small_apartment_mumbai',
            name: 'Small Apartment',
            purchasePrice: 10000.0,
            baseCashFlowPerSecond: 10.0 * 1.35,
          ),
          RealEstateProperty(
            id: 'mid_tier_condo',
            name: 'Mid-Tier Condo',
            purchasePrice: 20000.0,
            baseCashFlowPerSecond: 20.0 * 1.45,
          ),
          RealEstateProperty(
            id: 'bollywood_loft',
            name: 'Bollywood Loft',
            purchasePrice: 50000.0,
            baseCashFlowPerSecond: 50.0 * 1.55,
          ),
          RealEstateProperty(
            id: 'high_rise_unit_mumbai',
            name: 'High-Rise Unit',
            purchasePrice: 100000.0,
            baseCashFlowPerSecond: 100.0 * 1.65,
          ),
          RealEstateProperty(
            id: 'gated_tower',
            name: 'Gated Tower',
            purchasePrice: 250000.0,
            baseCashFlowPerSecond: 250.0 * 1.75,
          ),
          RealEstateProperty(
            id: 'luxury_flat_mumbai',
            name: 'Luxury Flat',
            purchasePrice: 500000.0,
            baseCashFlowPerSecond: 500.0 * 1.85,
          ),
          RealEstateProperty(
            id: 'seafront_penthouse',
            name: 'Seafront Penthouse',
            purchasePrice: 1000000.0,
            baseCashFlowPerSecond: 1000.0 * 1.95,
          ),
          RealEstateProperty(
            id: 'mumbai_skyscraper',
            name: 'Mumbai Skyscraper',
            purchasePrice: 2000000.0,
            baseCashFlowPerSecond: 2000.0 * 2.05,
          ),
        ],
      ),
      RealEstateLocale(
        id: 'ho_chi_minh_city',
        name: 'Ho Chi Minh City, Vietnam',
        theme: 'Emerging urban and riverfront homes',
        unlocked: false,
        icon: Icons.house_siding,
        properties: [
          RealEstateProperty(
            id: 'shophouse',
            name: 'Shophouse',
            purchasePrice: 3000.0,
            baseCashFlowPerSecond: 3.0 * 1.15,
          ),
          RealEstateProperty(
            id: 'narrow_flat',
            name: 'Narrow Flat',
            purchasePrice: 6000.0,
            baseCashFlowPerSecond: 6.0 * 1.25,
          ),
          RealEstateProperty(
            id: 'riverside_hut',
            name: 'Riverside Hut',
            purchasePrice: 15000.0,
            baseCashFlowPerSecond: 15.0 * 1.35,
          ),
          RealEstateProperty(
            id: 'modern_apartment_hcmc',
            name: 'Modern Apartment',
            purchasePrice: 30000.0,
            baseCashFlowPerSecond: 30.0 * 1.45,
          ),
          RealEstateProperty(
            id: 'condo_unit_hcmc',
            name: 'Condo Unit',
            purchasePrice: 75000.0,
            baseCashFlowPerSecond: 75.0 * 1.55,
          ),
          RealEstateProperty(
            id: 'riverfront_villa',
            name: 'Riverfront Villa',
            purchasePrice: 150000.0,
            baseCashFlowPerSecond: 150.0 * 1.65,
          ),
          RealEstateProperty(
            id: 'high_rise_suite_hcmc',
            name: 'High-Rise Suite',
            purchasePrice: 300000.0,
            baseCashFlowPerSecond: 300.0 * 1.75,
          ),
          RealEstateProperty(
            id: 'luxury_tower_hcmc',
            name: 'Luxury Tower',
            purchasePrice: 750000.0,
            baseCashFlowPerSecond: 750.0 * 1.85,
          ),
          RealEstateProperty(
            id: 'business_loft_hcmc',
            name: 'Business Loft',
            purchasePrice: 1500000.0,
            baseCashFlowPerSecond: 1500.0 * 1.95,
          ),
          RealEstateProperty(
            id: 'saigon_skyline_estate',
            name: 'Saigon Skyline Estate',
            purchasePrice: 3000000.0,
            baseCashFlowPerSecond: 3000.0 * 2.05,
          ),
        ],
      ),
      RealEstateLocale(
        id: 'singapore',
        name: 'Singapore',
        theme: 'Ultra-modern, high-density urban living',
        unlocked: false,
        icon: Icons.apartment,
        properties: [
          RealEstateProperty(
            id: 'hdb_flat',
            name: 'HDB Flat',
            purchasePrice: 50000.0,
            baseCashFlowPerSecond: 50.0 * 1.15,
          ),
          RealEstateProperty(
            id: 'condo_unit_singapore',
            name: 'Condo Unit',
            purchasePrice: 100000.0,
            baseCashFlowPerSecond: 100.0 * 1.25,
          ),
          RealEstateProperty(
            id: 'executive_apartment',
            name: 'Executive Apartment',
            purchasePrice: 250000.0,
            baseCashFlowPerSecond: 250.0 * 1.35,
          ),
          RealEstateProperty(
            id: 'sky_terrace',
            name: 'Sky Terrace',
            purchasePrice: 500000.0,
            baseCashFlowPerSecond: 500.0 * 1.45,
          ),
          RealEstateProperty(
            id: 'luxury_condo_singapore',
            name: 'Luxury Condo',
            purchasePrice: 1000000.0,
            baseCashFlowPerSecond: 1000.0 * 1.55,
          ),
          RealEstateProperty(
            id: 'marina_view_suite',
            name: 'Marina View Suite',
            purchasePrice: 2500000.0,
            baseCashFlowPerSecond: 2500.0 * 1.65,
          ),
          RealEstateProperty(
            id: 'penthouse_tower_singapore',
            name: 'Penthouse Tower',
            purchasePrice: 5000000.0,
            baseCashFlowPerSecond: 5000.0 * 1.75,
          ),
          RealEstateProperty(
            id: 'sky_villa',
            name: 'Sky Villa',
            purchasePrice: 10000000.0,
            baseCashFlowPerSecond: 10000.0 * 1.85,
          ),
          RealEstateProperty(
            id: 'billionaire_loft_singapore',
            name: 'Billionaire Loft',
            purchasePrice: 25000000.0,
            baseCashFlowPerSecond: 25000.0 * 1.95,
          ),
          RealEstateProperty(
            id: 'iconic_skyscraper_singapore',
            name: 'Iconic Skyscraper',
            purchasePrice: 50000000.0,
            baseCashFlowPerSecond: 50000.0 * 2.05,
          ),
        ],
      ),
      RealEstateLocale(
        id: 'hong_kong',
        name: 'Hong Kong',
        theme: 'Compact, premium urban properties',
        unlocked: false,
        icon: Icons.location_city,
        properties: [
          RealEstateProperty(
            id: 'micro_flat',
            name: 'Micro-Flat',
            purchasePrice: 75000.0,
            baseCashFlowPerSecond: 75.0 * 1.15,
          ),
          RealEstateProperty(
            id: 'small_apartment_hk',
            name: 'Small Apartment',
            purchasePrice: 150000.0,
            baseCashFlowPerSecond: 150.0 * 1.25,
          ),
          RealEstateProperty(
            id: 'mid_rise_unit',
            name: 'Mid-Rise Unit',
            purchasePrice: 300000.0,
            baseCashFlowPerSecond: 300.0 * 1.35,
          ),
          RealEstateProperty(
            id: 'harbor_view_flat',
            name: 'Harbor View Flat',
            purchasePrice: 750000.0,
            baseCashFlowPerSecond: 750.0 * 1.45,
          ),
          RealEstateProperty(
            id: 'luxury_condo_hk',
            name: 'Luxury Condo',
            purchasePrice: 1500000.0,
            baseCashFlowPerSecond: 1500.0 * 1.55,
          ),
          RealEstateProperty(
            id: 'peak_villa',
            name: 'Peak Villa',
            purchasePrice: 3000000.0,
            baseCashFlowPerSecond: 3000.0 * 1.65,
          ),
          RealEstateProperty(
            id: 'skyline_suite_hk',
            name: 'Skyline Suite',
            purchasePrice: 7500000.0,
            baseCashFlowPerSecond: 7500.0 * 1.75,
          ),
          RealEstateProperty(
            id: 'penthouse_tower_hk',
            name: 'Penthouse Tower',
            purchasePrice: 15000000.0,
            baseCashFlowPerSecond: 15000.0 * 1.85,
          ),
          RealEstateProperty(
            id: 'billionaire_mansion',
            name: 'Billionaire Mansion',
            purchasePrice: 30000000.0,
            baseCashFlowPerSecond: 30000.0 * 1.95,
          ),
          RealEstateProperty(
            id: 'victoria_peak_estate',
            name: 'Victoria Peak Estate',
            purchasePrice: 75000000.0,
            baseCashFlowPerSecond: 75000.0 * 2.05,
          ),
        ],
      ),
      RealEstateLocale(
        id: 'lisbon_portugal',
        name: 'Lisbon, Portugal',
        theme: 'Historic and coastal European homes',
        unlocked: false,
        icon: Icons.villa,
        properties: [
          RealEstateProperty(
            id: 'stone_cottage',
            name: 'Stone Cottage',
            purchasePrice: 10000.0,
            baseCashFlowPerSecond: 10.0 * 1.15,
          ),
          RealEstateProperty(
            id: 'townhouse',
            name: 'Townhouse',
            purchasePrice: 20000.0,
            baseCashFlowPerSecond: 20.0 * 1.25,
          ),
          RealEstateProperty(
            id: 'riverside_flat',
            name: 'Riverside Flat',
            purchasePrice: 50000.0,
            baseCashFlowPerSecond: 50.0 * 1.35,
          ),
          RealEstateProperty(
            id: 'renovated_villa',
            name: 'Renovated Villa',
            purchasePrice: 100000.0,
            baseCashFlowPerSecond: 100.0 * 1.45,
          ),
          RealEstateProperty(
            id: 'coastal_bungalow',
            name: 'Coastal Bungalow',
            purchasePrice: 250000.0,
            baseCashFlowPerSecond: 250.0 * 1.55,
          ),
          RealEstateProperty(
            id: 'luxury_apartment_lisbon',
            name: 'Luxury Apartment',
            purchasePrice: 500000.0,
            baseCashFlowPerSecond: 500.0 * 1.65,
          ),
          RealEstateProperty(
            id: 'historic_manor',
            name: 'Historic Manor',
            purchasePrice: 1000000.0,
            baseCashFlowPerSecond: 1000.0 * 1.75,
          ),
          RealEstateProperty(
            id: 'seaside_mansion',
            name: 'Seaside Mansion',
            purchasePrice: 2500000.0,
            baseCashFlowPerSecond: 2500.0 * 1.85,
          ),
          RealEstateProperty(
            id: 'cliffside_estate',
            name: 'Cliffside Estate',
            purchasePrice: 5000000.0,
            baseCashFlowPerSecond: 5000.0 * 1.95,
          ),
          RealEstateProperty(
            id: 'lisbon_palace',
            name: 'Lisbon Palace',
            purchasePrice: 10000000.0,
            baseCashFlowPerSecond: 10000.0 * 2.05,
          ),
        ],
      ),
      RealEstateLocale(
        id: 'bucharest_romania',
        name: 'Bucharest, Romania',
        theme: 'Affordable Eastern European urban growth',
        unlocked: false,
        icon: Icons.apartment,
        properties: [
          RealEstateProperty(
            id: 'panel_flat',
            name: 'Panel Flat',
            purchasePrice: 7500.0,
            baseCashFlowPerSecond: 7.5 * 1.15,
          ),
          RealEstateProperty(
            id: 'brick_apartment',
            name: 'Brick Apartment',
            purchasePrice: 15000.0,
            baseCashFlowPerSecond: 15.0 * 1.25,
          ),
          RealEstateProperty(
            id: 'modern_condo_bucharest',
            name: 'Modern Condo',
            purchasePrice: 30000.0,
            baseCashFlowPerSecond: 30.0 * 1.35,
          ),
          RealEstateProperty(
            id: 'renovated_loft',
            name: 'Renovated Loft',
            purchasePrice: 75000.0,
            baseCashFlowPerSecond: 75.0 * 1.45,
          ),
          RealEstateProperty(
            id: 'gated_unit',
            name: 'Gated Unit',
            purchasePrice: 150000.0,
            baseCashFlowPerSecond: 150.0 * 1.55,
          ),
          RealEstateProperty(
            id: 'high_rise_suite_bucharest',
            name: 'High-Rise Suite',
            purchasePrice: 300000.0,
            baseCashFlowPerSecond: 300.0 * 1.65,
          ),
          RealEstateProperty(
            id: 'luxury_flat_bucharest',
            name: 'Luxury Flat',
            purchasePrice: 750000.0,
            baseCashFlowPerSecond: 750.0 * 1.75,
          ),
          RealEstateProperty(
            id: 'urban_villa',
            name: 'Urban Villa',
            purchasePrice: 1500000.0,
            baseCashFlowPerSecond: 1500.0 * 1.85,
          ),
          RealEstateProperty(
            id: 'city_penthouse',
            name: 'City Penthouse',
            purchasePrice: 3000000.0,
            baseCashFlowPerSecond: 3000.0 * 1.95,
          ),
          RealEstateProperty(
            id: 'bucharest_tower',
            name: 'Bucharest Tower',
            purchasePrice: 7500000.0,
            baseCashFlowPerSecond: 7500.0 * 2.05,
          ),
        ],
      ),
      RealEstateLocale(
        id: 'berlin_germany',
        name: 'Berlin, Germany',
        theme: 'Creative and industrial-chic properties',
        unlocked: false,
        icon: Icons.house_siding,
        properties: [
          RealEstateProperty(
            id: 'studio_flat',
            name: 'Studio Flat',
            purchasePrice: 25000.0,
            baseCashFlowPerSecond: 25.0 * 1.15,
          ),
          RealEstateProperty(
            id: 'loft_space',
            name: 'Loft Space',
            purchasePrice: 50000.0,
            baseCashFlowPerSecond: 50.0 * 1.25,
          ),
          RealEstateProperty(
            id: 'renovated_warehouse',
            name: 'Renovated Warehouse',
            purchasePrice: 100000.0,
            baseCashFlowPerSecond: 100.0 * 1.35,
          ),
          RealEstateProperty(
            id: 'modern_apartment_berlin',
            name: 'Modern Apartment',
            purchasePrice: 250000.0,
            baseCashFlowPerSecond: 250.0 * 1.45,
          ),
          RealEstateProperty(
            id: 'artist_condo',
            name: 'Artist Condo',
            purchasePrice: 500000.0,
            baseCashFlowPerSecond: 500.0 * 1.55,
          ),
          RealEstateProperty(
            id: 'riverfront_suite',
            name: 'Riverfront Suite',
            purchasePrice: 1000000.0,
            baseCashFlowPerSecond: 1000.0 * 1.65,
          ),
          RealEstateProperty(
            id: 'luxury_loft',
            name: 'Luxury Loft',
            purchasePrice: 2500000.0,
            baseCashFlowPerSecond: 2500.0 * 1.75,
          ),
          RealEstateProperty(
            id: 'high_rise_tower_berlin',
            name: 'High-Rise Tower',
            purchasePrice: 5000000.0,
            baseCashFlowPerSecond: 5000.0 * 1.85,
          ),
          RealEstateProperty(
            id: 'tech_villa',
            name: 'Tech Villa',
            purchasePrice: 10000000.0,
            baseCashFlowPerSecond: 10000.0 * 1.95,
          ),
          RealEstateProperty(
            id: 'berlin_skyline_estate',
            name: 'Berlin Skyline Estate',
            purchasePrice: 25000000.0,
            baseCashFlowPerSecond: 25000.0 * 2.05,
          ),
        ],
      ),
      RealEstateLocale(
        id: 'london_uk',
        name: 'London, UK',
        theme: 'Historic and ultra-premium urban homes',
        unlocked: false,
        icon: Icons.location_city,
        properties: [
          RealEstateProperty(
            id: 'council_flat',
            name: 'Council Flat',
            purchasePrice: 40000.0,
            baseCashFlowPerSecond: 40.0 * 1.15,
          ),
          RealEstateProperty(
            id: 'terraced_house',
            name: 'Terraced House',
            purchasePrice: 80000.0,
            baseCashFlowPerSecond: 80.0 * 1.25,
          ),
          RealEstateProperty(
            id: 'georgian_townhouse',
            name: 'Georgian Townhouse',
            purchasePrice: 200000.0,
            baseCashFlowPerSecond: 200.0 * 1.35,
          ),
          RealEstateProperty(
            id: 'modern_condo_london',
            name: 'Modern Condo',
            purchasePrice: 400000.0,
            baseCashFlowPerSecond: 400.0 * 1.45,
          ),
          RealEstateProperty(
            id: 'riverside_apartment',
            name: 'Riverside Apartment',
            purchasePrice: 1000000.0,
            baseCashFlowPerSecond: 1000.0 * 1.55,
          ),
          RealEstateProperty(
            id: 'luxury_flat_london',
            name: 'Luxury Flat',
            purchasePrice: 2000000.0,
            baseCashFlowPerSecond: 2000.0 * 1.65,
          ),
          RealEstateProperty(
            id: 'mayfair_mansion',
            name: 'Mayfair Mansion',
            purchasePrice: 5000000.0,
            baseCashFlowPerSecond: 5000.0 * 1.75,
          ),
          RealEstateProperty(
            id: 'skyline_penthouse_london',
            name: 'Skyline Penthouse',
            purchasePrice: 10000000.0,
            baseCashFlowPerSecond: 10000.0 * 1.85,
          ),
          RealEstateProperty(
            id: 'historic_estate',
            name: 'Historic Estate',
            purchasePrice: 25000000.0,
            baseCashFlowPerSecond: 25000.0 * 1.95,
          ),
          RealEstateProperty(
            id: 'london_iconic_tower',
            name: 'London Iconic Tower',
            purchasePrice: 50000000.0,
            baseCashFlowPerSecond: 50000.0 * 2.05,
          ),
        ],
      ),
      RealEstateLocale(
        id: 'rural_mexico',
        name: 'Rural Mexico',
        theme: 'Rustic and affordable Latin American homes',
        unlocked: false,
        icon: Icons.holiday_village,
        properties: [
          RealEstateProperty(
            id: 'adobe_hut',
            name: 'Adobe Hut',
            purchasePrice: 600.0,
            baseCashFlowPerSecond: 0.6 * 1.15,
          ),
          RealEstateProperty(
            id: 'clay_house',
            name: 'Clay House',
            purchasePrice: 1200.0,
            baseCashFlowPerSecond: 1.2 * 1.25,
          ),
          RealEstateProperty(
            id: 'brick_cottage_mexico',
            name: 'Brick Cottage',
            purchasePrice: 3000.0,
            baseCashFlowPerSecond: 3.0 * 1.35,
          ),
          RealEstateProperty(
            id: 'hacienda_bungalow',
            name: 'Hacienda Bungalow',
            purchasePrice: 6000.0,
            baseCashFlowPerSecond: 6.0 * 1.45,
          ),
          RealEstateProperty(
            id: 'village_flat',
            name: 'Village Flat',
            purchasePrice: 15000.0,
            baseCashFlowPerSecond: 15.0 * 1.55,
          ),
          RealEstateProperty(
            id: 'rural_villa',
            name: 'Rural Villa',
            purchasePrice: 30000.0,
            baseCashFlowPerSecond: 30.0 * 1.65,
          ),
          RealEstateProperty(
            id: 'eco_casa',
            name: 'Eco-Casa',
            purchasePrice: 75000.0,
            baseCashFlowPerSecond: 75.0 * 1.75,
          ),
          RealEstateProperty(
            id: 'farmstead',
            name: 'Farmstead',
            purchasePrice: 150000.0,
            baseCashFlowPerSecond: 150.0 * 1.85,
          ),
          RealEstateProperty(
            id: 'countryside_estate',
            name: 'Countryside Estate',
            purchasePrice: 300000.0,
            baseCashFlowPerSecond: 300.0 * 1.95,
          ),
          RealEstateProperty(
            id: 'hacienda_grande',
            name: 'Hacienda Grande',
            purchasePrice: 600000.0,
            baseCashFlowPerSecond: 600.0 * 2.05,
          ),
        ],
      ),
      RealEstateLocale(
        id: 'mexico_city',
        name: 'Mexico City, Mexico',
        theme: 'Urban sprawl with colonial charm',
        unlocked: false,
        icon: Icons.location_city,
        properties: [
          RealEstateProperty(
            id: 'barrio_flat',
            name: 'Barrio Flat',
            purchasePrice: 4000.0,
            baseCashFlowPerSecond: 4.0 * 1.15,
          ),
          RealEstateProperty(
            id: 'concrete_unit_mexico',
            name: 'Concrete Unit',
            purchasePrice: 8000.0,
            baseCashFlowPerSecond: 8.0 * 1.25,
          ),
          RealEstateProperty(
            id: 'colonial_house',
            name: 'Colonial House',
            purchasePrice: 20000.0,
            baseCashFlowPerSecond: 20.0 * 1.35,
          ),
          RealEstateProperty(
            id: 'mid_rise_apartment',
            name: 'Mid-Rise Apartment',
            purchasePrice: 40000.0,
            baseCashFlowPerSecond: 40.0 * 1.45,
          ),
          RealEstateProperty(
            id: 'gated_condo',
            name: 'Gated Condo',
            purchasePrice: 100000.0,
            baseCashFlowPerSecond: 100.0 * 1.55,
          ),
          RealEstateProperty(
            id: 'modern_loft_mexico',
            name: 'Modern Loft',
            purchasePrice: 200000.0,
            baseCashFlowPerSecond: 200.0 * 1.65,
          ),
          RealEstateProperty(
            id: 'luxury_suite_mexico',
            name: 'Luxury Suite',
            purchasePrice: 500000.0,
            baseCashFlowPerSecond: 500.0 * 1.75,
          ),
          RealEstateProperty(
            id: 'high_rise_tower_mexico',
            name: 'High-Rise Tower',
            purchasePrice: 1000000.0,
            baseCashFlowPerSecond: 1000.0 * 1.85,
          ),
          RealEstateProperty(
            id: 'historic_penthouse',
            name: 'Historic Penthouse',
            purchasePrice: 2000000.0,
            baseCashFlowPerSecond: 2000.0 * 1.95,
          ),
          RealEstateProperty(
            id: 'mexico_city_skyline',
            name: 'Mexico City Skyline',
            purchasePrice: 4000000.0,
            baseCashFlowPerSecond: 4000.0 * 2.05,
          ),
        ],
      ),
      RealEstateLocale(
        id: 'miami_florida',
        name: 'Miami, Florida',
        theme: 'Coastal and flashy U.S. properties',
        unlocked: false,
        icon: Icons.beach_access,
        properties: [
          RealEstateProperty(
            id: 'beach_condo',
            name: 'Beach Condo',
            purchasePrice: 30000.0,
            baseCashFlowPerSecond: 30.0 * 1.15,
          ),
          RealEstateProperty(
            id: 'bungalow',
            name: 'Bungalow',
            purchasePrice: 60000.0,
            baseCashFlowPerSecond: 60.0 * 1.25,
          ),
          RealEstateProperty(
            id: 'oceanfront_flat',
            name: 'Oceanfront Flat',
            purchasePrice: 150000.0,
            baseCashFlowPerSecond: 150.0 * 1.35,
          ),
          RealEstateProperty(
            id: 'modern_villa_miami',
            name: 'Modern Villa',
            purchasePrice: 300000.0,
            baseCashFlowPerSecond: 300.0 * 1.45,
          ),
          RealEstateProperty(
            id: 'luxury_condo_miami',
            name: 'Luxury Condo',
            purchasePrice: 750000.0,
            baseCashFlowPerSecond: 750.0 * 1.55,
          ),
          RealEstateProperty(
            id: 'miami_beach_house',
            name: 'Miami Beach House',
            purchasePrice: 1500000.0,
            baseCashFlowPerSecond: 1500.0 * 1.65,
          ),
          RealEstateProperty(
            id: 'high_rise_suite_miami',
            name: 'High-Rise Suite',
            purchasePrice: 3000000.0,
            baseCashFlowPerSecond: 3000.0 * 1.75,
          ),
          RealEstateProperty(
            id: 'skyline_penthouse_miami',
            name: 'Skyline Penthouse',
            purchasePrice: 7500000.0,
            baseCashFlowPerSecond: 7500.0 * 1.85,
          ),
          RealEstateProperty(
            id: 'waterfront_mansion',
            name: 'Waterfront Mansion',
            purchasePrice: 15000000.0,
            baseCashFlowPerSecond: 15000.0 * 1.95,
          ),
          RealEstateProperty(
            id: 'miami_iconic_estate',
            name: 'Miami Iconic Estate',
            purchasePrice: 30000000.0,
            baseCashFlowPerSecond: 30000.0 * 2.05,
          ),
        ],
      ),
      RealEstateLocale(
        id: 'new_york_city',
        name: 'New York City, NY',
        theme: 'Iconic U.S. urban real estate',
        unlocked: false,
        icon: Icons.location_city,
        properties: [
          RealEstateProperty(
            id: 'studio_apartment',
            name: 'Studio Apartment',
            purchasePrice: 60000.0,
            baseCashFlowPerSecond: 60.0 * 1.15,
          ),
          RealEstateProperty(
            id: 'brownstone_flat',
            name: 'Brownstone Flat',
            purchasePrice: 120000.0,
            baseCashFlowPerSecond: 120.0 * 1.25,
          ),
          RealEstateProperty(
            id: 'midtown_condo',
            name: 'Midtown Condo',
            purchasePrice: 300000.0,
            baseCashFlowPerSecond: 300.0 * 1.35,
          ),
          RealEstateProperty(
            id: 'luxury_loft_nyc',
            name: 'Luxury Loft',
            purchasePrice: 600000.0,
            baseCashFlowPerSecond: 600.0 * 1.45,
          ),
          RealEstateProperty(
            id: 'high_rise_unit_nyc',
            name: 'High-Rise Unit',
            purchasePrice: 1500000.0,
            baseCashFlowPerSecond: 1500.0 * 1.55,
          ),
          RealEstateProperty(
            id: 'manhattan_suite',
            name: 'Manhattan Suite',
            purchasePrice: 3000000.0,
            baseCashFlowPerSecond: 3000.0 * 1.65,
          ),
          RealEstateProperty(
            id: 'skyline_penthouse_nyc',
            name: 'Skyline Penthouse',
            purchasePrice: 7500000.0,
            baseCashFlowPerSecond: 7500.0 * 1.75,
          ),
          RealEstateProperty(
            id: 'central_park_view',
            name: 'Central Park View',
            purchasePrice: 15000000.0,
            baseCashFlowPerSecond: 15000.0 * 1.85,
          ),
          RealEstateProperty(
            id: 'billionaire_tower',
            name: 'Billionaire Tower',
            purchasePrice: 30000000.0,
            baseCashFlowPerSecond: 30000.0 * 1.95,
          ),
          RealEstateProperty(
            id: 'nyc_landmark_estate',
            name: 'NYC Landmark Estate',
            purchasePrice: 60000000.0,
            baseCashFlowPerSecond: 60000.0 * 2.05,
          ),
        ],
      ),
      RealEstateLocale(
        id: 'los_angeles',
        name: 'Los Angeles, CA',
        theme: 'Hollywood and luxury U.S. homes',
        unlocked: false,
        icon: Icons.villa,
        properties: [
          RealEstateProperty(
            id: 'studio_bungalow',
            name: 'Studio Bungalow',
            purchasePrice: 50000.0,
            baseCashFlowPerSecond: 50.0 * 1.15,
          ),
          RealEstateProperty(
            id: 'hillside_flat',
            name: 'Hillside Flat',
            purchasePrice: 100000.0,
            baseCashFlowPerSecond: 100.0 * 1.25,
          ),
          RealEstateProperty(
            id: 'modern_condo_la',
            name: 'Modern Condo',
            purchasePrice: 250000.0,
            baseCashFlowPerSecond: 250.0 * 1.35,
          ),
          RealEstateProperty(
            id: 'hollywood_villa',
            name: 'Hollywood Villa',
            purchasePrice: 500000.0,
            baseCashFlowPerSecond: 500.0 * 1.45,
          ),
          RealEstateProperty(
            id: 'luxury_loft_la',
            name: 'Luxury Loft',
            purchasePrice: 1000000.0,
            baseCashFlowPerSecond: 1000.0 * 1.55,
          ),
          RealEstateProperty(
            id: 'beverly_hills_house',
            name: 'Beverly Hills House',
            purchasePrice: 2500000.0,
            baseCashFlowPerSecond: 2500.0 * 1.65,
          ),
          RealEstateProperty(
            id: 'celebrity_mansion',
            name: 'Celebrity Mansion',
            purchasePrice: 5000000.0,
            baseCashFlowPerSecond: 5000.0 * 1.75,
          ),
          RealEstateProperty(
            id: 'skyline_penthouse_la',
            name: 'Skyline Penthouse',
            purchasePrice: 10000000.0,
            baseCashFlowPerSecond: 10000.0 * 1.85,
          ),
          RealEstateProperty(
            id: 'oceanfront_estate',
            name: 'Oceanfront Estate',
            purchasePrice: 25000000.0,
            baseCashFlowPerSecond: 25000.0 * 1.95,
          ),
          RealEstateProperty(
            id: 'la_iconic_compound',
            name: 'LA Iconic Compound',
            purchasePrice: 50000000.0,
            baseCashFlowPerSecond: 50000.0 * 2.05,
          ),
        ],
      ),
      RealEstateLocale(
        id: 'lima_peru',
        name: 'Lima, Peru',
        theme: 'Andean urban and coastal homes',
        unlocked: false,
        icon: Icons.house_siding,
        properties: [
          RealEstateProperty(
            id: 'adobe_flat',
            name: 'Adobe Flat',
            purchasePrice: 2500.0,
            baseCashFlowPerSecond: 2.5 * 1.15,
          ),
          RealEstateProperty(
            id: 'brick_house_lima',
            name: 'Brick House',
            purchasePrice: 5000.0,
            baseCashFlowPerSecond: 5.0 * 1.25,
          ),
          RealEstateProperty(
            id: 'coastal_shack',
            name: 'Coastal Shack',
            purchasePrice: 12500.0,
            baseCashFlowPerSecond: 12.5 * 1.35,
          ),
          RealEstateProperty(
            id: 'modern_apartment_lima',
            name: 'Modern Apartment',
            purchasePrice: 25000.0,
            baseCashFlowPerSecond: 25.0 * 1.45,
          ),
          RealEstateProperty(
            id: 'gated_unit_lima',
            name: 'Gated Unit',
            purchasePrice: 50000.0,
            baseCashFlowPerSecond: 50.0 * 1.55,
          ),
          RealEstateProperty(
            id: 'andean_villa',
            name: 'Andean Villa',
            purchasePrice: 125000.0,
            baseCashFlowPerSecond: 125.0 * 1.65,
          ),
          RealEstateProperty(
            id: 'luxury_condo_lima',
            name: 'Luxury Condo',
            purchasePrice: 250000.0,
            baseCashFlowPerSecond: 250.0 * 1.75,
          ),
          RealEstateProperty(
            id: 'high_rise_suite_lima',
            name: 'High-Rise Suite',
            purchasePrice: 500000.0,
            baseCashFlowPerSecond: 500.0 * 1.85,
          ),
          RealEstateProperty(
            id: 'oceanfront_loft',
            name: 'Oceanfront Loft',
            purchasePrice: 1000000.0,
            baseCashFlowPerSecond: 1000.0 * 1.95,
          ),
          RealEstateProperty(
            id: 'lima_skyline_estate',
            name: 'Lima Skyline Estate',
            purchasePrice: 2500000.0,
            baseCashFlowPerSecond: 2500.0 * 2.05,
          ),
        ],
      ),
      RealEstateLocale(
        id: 'sao_paulo_brazil',
        name: 'Sao Paulo, Brazil',
        theme: 'Sprawling South American metropolis',
        unlocked: false,
        icon: Icons.location_city,
        properties: [
          RealEstateProperty(
            id: 'favela_hut',
            name: 'Favela Hut',
            purchasePrice: 3500.0,
            baseCashFlowPerSecond: 3.5 * 1.15,
          ),
          RealEstateProperty(
            id: 'concrete_flat_sao_paulo',
            name: 'Concrete Flat',
            purchasePrice: 7000.0,
            baseCashFlowPerSecond: 7.0 * 1.25,
          ),
          RealEstateProperty(
            id: 'small_apartment_sao_paulo',
            name: 'Small Apartment',
            purchasePrice: 17500.0,
            baseCashFlowPerSecond: 17.5 * 1.35,
          ),
          RealEstateProperty(
            id: 'mid_rise_condo',
            name: 'Mid-Rise Condo',
            purchasePrice: 35000.0,
            baseCashFlowPerSecond: 35.0 * 1.45,
          ),
          RealEstateProperty(
            id: 'gated_tower_sao_paulo',
            name: 'Gated Tower',
            purchasePrice: 75000.0,
            baseCashFlowPerSecond: 75.0 * 1.55,
          ),
          RealEstateProperty(
            id: 'luxury_unit',
            name: 'Luxury Unit',
            purchasePrice: 150000.0,
            baseCashFlowPerSecond: 150.0 * 1.65,
          ),
          RealEstateProperty(
            id: 'high_rise_suite_sao_paulo',
            name: 'High-Rise Suite',
            purchasePrice: 375000.0,
            baseCashFlowPerSecond: 375.0 * 1.75,
          ),
          RealEstateProperty(
            id: 'skyline_penthouse_sao_paulo',
            name: 'Skyline Penthouse',
            purchasePrice: 750000.0,
            baseCashFlowPerSecond: 750.0 * 1.85,
          ),
          RealEstateProperty(
            id: 'business_loft_sao_paulo',
            name: 'Business Loft',
            purchasePrice: 1500000.0,
            baseCashFlowPerSecond: 1500.0 * 1.95,
          ),
          RealEstateProperty(
            id: 'sao_paulo_iconic_tower',
            name: 'Sao Paulo Iconic Tower',
            purchasePrice: 3000000.0,
            baseCashFlowPerSecond: 3000.0 * 2.05,
          ),
        ],
      ),
      RealEstateLocale(
        id: 'dubai_uae',
        name: 'Dubai, UAE',
        theme: 'Flashy desert luxury properties',
        unlocked: false,
        icon: Icons.location_city,
        properties: [
          RealEstateProperty(
            id: 'desert_apartment',
            name: 'Desert Apartment',
            purchasePrice: 35000.0,
            baseCashFlowPerSecond: 35.0 * 1.15,
          ),
          RealEstateProperty(
            id: 'modern_condo_dubai',
            name: 'Modern Condo',
            purchasePrice: 70000.0,
            baseCashFlowPerSecond: 70.0 * 1.25,
          ),
          RealEstateProperty(
            id: 'palm_villa',
            name: 'Palm Villa',
            purchasePrice: 175000.0,
            baseCashFlowPerSecond: 175.0 * 1.35,
          ),
          RealEstateProperty(
            id: 'luxury_flat_dubai',
            name: 'Luxury Flat',
            purchasePrice: 350000.0,
            baseCashFlowPerSecond: 350.0 * 1.45,
          ),
          RealEstateProperty(
            id: 'high_rise_suite_dubai',
            name: 'High-Rise Suite',
            purchasePrice: 750000.0,
            baseCashFlowPerSecond: 750.0 * 1.55,
          ),
          RealEstateProperty(
            id: 'burj_tower_unit',
            name: 'Burj Tower Unit',
            purchasePrice: 1500000.0,
            baseCashFlowPerSecond: 1500.0 * 1.65,
          ),
          RealEstateProperty(
            id: 'skyline_mansion',
            name: 'Skyline Mansion',
            purchasePrice: 3750000.0,
            baseCashFlowPerSecond: 3750.0 * 1.75,
          ),
          RealEstateProperty(
            id: 'island_retreat',
            name: 'Island Retreat',
            purchasePrice: 7500000.0,
            baseCashFlowPerSecond: 7500.0 * 1.85,
          ),
          RealEstateProperty(
            id: 'billionaire_penthouse_dubai',
            name: 'Billionaire Penthouse',
            purchasePrice: 15000000.0,
            baseCashFlowPerSecond: 15000.0 * 1.95,
          ),
          RealEstateProperty(
            id: 'dubai_iconic_skyscraper',
            name: 'Dubai Iconic Skyscraper',
            purchasePrice: 35000000.0,
            baseCashFlowPerSecond: 35000.0 * 2.05,
          ),
          // ADDED: Platinum Tower Property
          RealEstateProperty(
            id: 'platinum_tower', 
            name: 'Platinum Tower', 
            purchasePrice: 1000000000.0, // Example Price
            baseCashFlowPerSecond: 1200000.0, // Example Income
            unlocked: false, // Initially locked by default, unlocked via PP purchase flag 
            upgrades: [ // Example Upgrades
               RealEstateUpgrade(id: 'pt_vip_lounge', description: 'VIP Lounge Access', cost: 10000000.0, newIncomePerSecond: 130000.0),
               RealEstateUpgrade(id: 'pt_helipad', description: 'Rooftop Helipad', cost: 30000000.0, newIncomePerSecond: 390000.0),
               RealEstateUpgrade(id: 'pt_global_comm', description: 'Global Communications Hub', cost: 120000000.0, newIncomePerSecond: 780000.0),
            ]
          ),
        ],
      ),
      RealEstateLocale(
        id: 'platinum_islands', 
        name: 'Platinum Islands', 
        theme: 'Exclusive tropical paradise resorts and villas.', 
        unlocked: false, // Requires PP unlock flag + achievement
        icon: Icons.scuba_diving, // Placeholder icon
        properties: [
          // 10 unique properties for Platinum Islands
          RealEstateProperty(id: 'pi_beach_bungalow', name: 'Coral Beach Bungalow', purchasePrice: 1.0e8, baseCashFlowPerSecond: 1.2e5), // 100M, 120K/s
          RealEstateProperty(id: 'pi_marina_slip', name: 'Private Marina Slip', purchasePrice: 2.5e8, baseCashFlowPerSecond: 3.0e5),   // 250M, 300K/s
          RealEstateProperty(id: 'pi_overwater_villa', name: 'Overwater Luxury Villa', purchasePrice: 5.0e8, baseCashFlowPerSecond: 6.5e5), // 500M, 650K/s
          RealEstateProperty(id: 'pi_jungle_retreat', name: 'Secluded Jungle Retreat', purchasePrice: 8.0e8, baseCashFlowPerSecond: 1.0e6),  // 800M, 1M/s
          RealEstateProperty(id: 'pi_cliffside_estate', name: 'Cliffside Panoramic Estate', purchasePrice: 1.2e9, baseCashFlowPerSecond: 1.5e6), // 1.2B, 1.5M/s
          RealEstateProperty(id: 'pi_eco_resort', name: 'Sustainable Eco-Resort', purchasePrice: 2.0e9, baseCashFlowPerSecond: 2.5e6),   // 2B, 2.5M/s
          RealEstateProperty(id: 'pi_volcano_lair', name: 'Extinct Volcano Lair', purchasePrice: 3.5e9, baseCashFlowPerSecond: 4.5e6), // 3.5B, 4.5M/s
          RealEstateProperty(id: 'pi_underwater_hotel', name: 'Underwater Hotel Suite', purchasePrice: 6.0e9, baseCashFlowPerSecond: 7.5e6), // 6B, 7.5M/s
          RealEstateProperty(id: 'pi_yacht_club', name: 'Platinum Yacht Club HQ', purchasePrice: 1.0e10, baseCashFlowPerSecond: 1.2e7), // 10B, 12M/s
          RealEstateProperty(id: 'pi_sovereign_island', name: 'Sovereign Island Compound', purchasePrice: 2.5e10, baseCashFlowPerSecond: 3.0e7),// 25B, 30M/s
          // ADDED: Platinum Island Property (within Platinum Islands locale)
          RealEstateProperty(
            id: 'platinum_island',
            name: "The Sovereign's Platinum Isle", // Use double quotes to avoid escaping issues
            purchasePrice: 1.0e12, // Example high cost
            baseCashFlowPerSecond: 5.0e8, // Example high income
            unlocked: false, // Initially locked, unlocked via Platinum Points
            upgrades: [], // No upgrades initially
             // Ensure all required named parameters are provided if the constructor demands them
          ),
        ]
      ),
    ];
  }
}