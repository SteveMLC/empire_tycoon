import 'package:flutter/material.dart';

/// Categories for premium avatars to organize them in the UI
enum PremiumAvatarCategory {
  investment,
  realestate,
  business,
  lifestyle,
  technology,
  industry,
}

/// Extension to get display names for premium avatar categories
extension PremiumAvatarCategoryExtension on PremiumAvatarCategory {
  String get displayName {
    switch (this) {
      case PremiumAvatarCategory.investment:
        return 'Investment';
      case PremiumAvatarCategory.realestate:
        return 'Real Estate';
      case PremiumAvatarCategory.business:
        return 'Business';
      case PremiumAvatarCategory.lifestyle:
        return 'Lifestyle';
      case PremiumAvatarCategory.technology:
        return 'Technology';
      case PremiumAvatarCategory.industry:
        return 'Industry';
    }
  }

  Color get color {
    switch (this) {
      case PremiumAvatarCategory.investment:
        return Colors.green.shade700;
      case PremiumAvatarCategory.realestate:
        return Colors.blue.shade700;
      case PremiumAvatarCategory.business:
        return Colors.amber.shade700;
      case PremiumAvatarCategory.lifestyle:
        return Colors.purple.shade700;
      case PremiumAvatarCategory.technology:
        return Colors.cyan.shade700;
      case PremiumAvatarCategory.industry:
        return Colors.brown.shade700;
    }
  }
}

/// Model class for premium avatars
class PremiumAvatar {
  final String id;
  final String imagePath;
  final String name;
  final String description;
  final PremiumAvatarCategory category;
  final String emoji;

  PremiumAvatar({
    required this.id,
    required this.imagePath,
    required this.name,
    required this.description,
    required this.category,
    required this.emoji,
  });
}

/// Get the list of all premium avatars
List<PremiumAvatar> getPremiumAvatars() {
  return [
    // Investment
    PremiumAvatar(
      id: 'investment_tycoon',
      imagePath: 'assets/images/premium_avatars/Investment_Tycoon_Avatar.png',
      name: 'Investment Tycoon',
      description: 'Master of financial markets and investment strategies.',
      category: PremiumAvatarCategory.investment,
      emoji: '📈',
    ),
    
    // Agriculture
    PremiumAvatar(
      id: 'agriculture_baron',
      imagePath: 'assets/images/premium_avatars/Agriculture_Baron_Avatar.png',
      name: 'Agriculture Baron',
      description: 'Controls vast agricultural empires across continents.',
      category: PremiumAvatarCategory.business,
      emoji: '🌾',
    ),
    
    // Casino
    PremiumAvatar(
      id: 'casino_king',
      imagePath: 'assets/images/premium_avatars/Casino_King_Avatar.png',
      name: 'Casino King',
      description: 'Rules the world of high-stakes gambling and entertainment.',
      category: PremiumAvatarCategory.lifestyle,
      emoji: '♠️',
    ),
    
    // Crypto
    PremiumAvatar(
      id: 'crypto_visionary',
      imagePath: 'assets/images/premium_avatars/Crypto_Visionary_Avatar.png',
      name: 'Crypto Visionary',
      description: 'Pioneer of blockchain technology and digital currencies.',
      category: PremiumAvatarCategory.technology,
      emoji: '🔐',
    ),
    
    // Real Estate
    PremiumAvatar(
      id: 'estate_baroness',
      imagePath: 'assets/images/premium_avatars/Estate_Baroness_Avatar.png',
      name: 'Estate Baroness',
      description: 'Queen of luxury real estate and property development.',
      category: PremiumAvatarCategory.realestate,
      emoji: '🏘️',
    ),
    
    // Fashion
    PremiumAvatar(
      id: 'fashion_mogul',
      imagePath: 'assets/images/premium_avatars/Fashion_Mogul_Avatar.png',
      name: 'Fashion Mogul',
      description: 'Trendsetter in the global fashion industry.',
      category: PremiumAvatarCategory.lifestyle,
      emoji: '👔',
    ),
    
    // Hotel
    PremiumAvatar(
      id: 'hotel_queen',
      imagePath: 'assets/images/premium_avatars/Hotel_Queen_Avatar.png',
      name: 'Hotel Queen',
      description: 'Reigns over a global empire of luxury hotels and resorts.',
      category: PremiumAvatarCategory.realestate,
      emoji: '🏨',
    ),
    
    // Industry
    PremiumAvatar(
      id: 'industrial_magnate',
      imagePath: 'assets/images/premium_avatars/Industrial_Magnate_Avatar.png',
      name: 'Industrial Magnate',
      description: 'Commands vast industrial complexes and manufacturing empires.',
      category: PremiumAvatarCategory.industry,
      emoji: '🏭',
    ),
    
    // Shipping
    PremiumAvatar(
      id: 'shipping_tycoon',
      imagePath: 'assets/images/premium_avatars/Shipping_Tycoon_Avatar.png',
      name: 'Shipping Tycoon',
      description: 'Controls global shipping routes and maritime commerce.',
      category: PremiumAvatarCategory.industry,
      emoji: '🚢',
    ),
  ];
}
