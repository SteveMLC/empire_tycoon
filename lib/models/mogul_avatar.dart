// Models premium mogul avatars unlocked via the Platinum Vault
class MogulAvatar {
  final String id;
  final String imagePath;
  final String name;
  final String description;
  final MogulAvatarCategory category;
  final String emoji;

  MogulAvatar({
    required this.id,
    required this.imagePath,
    required this.name, 
    required this.description,
    required this.category,
    required this.emoji,
  });
}

// Categorize the mogul avatars
enum MogulAvatarCategory {
  business,
  royalty,
  corporate,
  tycoon,
  elite,
  futuristic,
  luxury,
  mystic,
  mythic,
  lifestyle,
  visionary,
  science
}

// List of available mogul avatars
List<MogulAvatar> getMogulAvatars() {
  return [
    // Elite Moguls
    MogulAvatar(
      id: 'apex_mogul',
      imagePath: 'assets/images/mogul_avatars/apex_mogul.jpg',
      name: 'The Apex Mogul',
      description: 'Commands empires. Feared by rivals. Worshipped by markets.',
      category: MogulAvatarCategory.elite,
      emoji: '👑',
    ),
    
    // Futuristic Moguls
    MogulAvatar(
      id: 'galactic_tycoon',
      imagePath: 'assets/images/mogul_avatars/galactic_tycoon.jpg',
      name: 'Galactic Tycoon',
      description: 'Owns companies on Earth, moon resorts, and Martian mines.',
      category: MogulAvatarCategory.futuristic,
      emoji: '🚀',
    ),
    
    // Luxury Moguls
    MogulAvatar(
      id: 'ice_boss',
      imagePath: 'assets/images/mogul_avatars/ice_boss.jpg',
      name: 'The Ice Boss',
      description: 'Cold, calculated, and cash-loaded. Turns markets to ice.',
      category: MogulAvatarCategory.luxury,
      emoji: '❄️',
    ),
    
    // Mystic Moguls
    MogulAvatar(
      id: 'oracle_empire',
      imagePath: 'assets/images/mogul_avatars/oracle_empire.jpg',
      name: 'Oracle of Empire',
      description: 'Sees the future. Controls the present. Never misses a move.',
      category: MogulAvatarCategory.mystic,
      emoji: '🔮',
    ),
    
    // Royalty
    MogulAvatar(
      id: 'chateau_magnate',
      imagePath: 'assets/images/mogul_avatars/chateau_magnate.jpg',
      name: 'Chateau Magnate',
      description: 'Lives in castles, parties in yachts. Luxury is the baseline.',
      category: MogulAvatarCategory.royalty,
      emoji: '🏰',
    ),
    
    // Mythic Moguls
    MogulAvatar(
      id: 'dragon_investor',
      imagePath: 'assets/images/mogul_avatars/dragon_investor.jpg',
      name: 'Dragon Investor',
      description: 'Wherever he goes, fortunes fly.',
      category: MogulAvatarCategory.mythic,
      emoji: '🐉',
    ),
    
    // Lifestyle Moguls
    MogulAvatar(
      id: 'billionaire_on_break',
      imagePath: 'assets/images/mogul_avatars/billionaire_on_break.jpg',
      name: 'Billionaire on Break',
      description: 'Still makes millions while sipping piña coladas.',
      category: MogulAvatarCategory.lifestyle,
      emoji: '🏖️',
    ),
    
    // Visionary Moguls
    MogulAvatar(
      id: 'empire_architect',
      imagePath: 'assets/images/mogul_avatars/empire_architect.jpg',
      name: 'The Empire Architect',
      description: 'He builds dynasties. Brick by brick. Billion by billion.',
      category: MogulAvatarCategory.visionary,
      emoji: '🏗️',
    ),
    
    // Science Moguls
    MogulAvatar(
      id: 'bio_capitalist',
      imagePath: 'assets/images/mogul_avatars/bio_capitalist.jpg',
      name: 'BioCapitalist',
      description: 'Patents genes, disrupts medicine, profits from the future of life.',
      category: MogulAvatarCategory.science,
      emoji: '🧬',
    ),
    
    // More Mythic Moguls
    MogulAvatar(
      id: 'tycoon_of_atlantis',
      imagePath: 'assets/images/mogul_avatars/tycoon_of_atlantis.jpg',
      name: 'Tycoon of Atlantis',
      description: 'Owns what others can\'t find. Richer than Neptune.',
      category: MogulAvatarCategory.mythic,
      emoji: '🌊',
    ),
  ];
}