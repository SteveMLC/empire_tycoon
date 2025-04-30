import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'sound_assets.dart';

/// Utility class for preloading and caching game assets
class AssetLoader {
  static final AssetLoader _instance = AssetLoader._internal();
  factory AssetLoader() => _instance;
  AssetLoader._internal();
  
  // Track preloaded assets
  final Set<String> _preloadedSounds = {};
  bool _isInitialized = false;
  
  /// Initialize the asset loader
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('Initializing AssetLoader...');
      // Start preloading assets
      unawaited(_preloadCommonAssets());
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing AssetLoader: $e');
      // We don't want to fail the game if asset preloading fails
    }
  }
  
  /// Preload commonly used assets
  Future<void> _preloadCommonAssets() async {
    try {
      // Start with common UI sounds
      await _preloadSounds([
         SoundAssets.uiTap,
         SoundAssets.uiTapBoosted,
         SoundAssets.uiTabChange,
         SoundAssets.buttonClick, 
      ]);
      
      // Then load the rest in the background
      unawaited(_preloadSounds(SoundAssets.allSounds));
    } catch (e) {
      debugPrint('Error preloading common assets: $e');
    }
  }
  
  /// Preload a list of sound assets
  Future<void> _preloadSounds(List<String> soundPaths) async {
    for (final path in soundPaths) {
      if (!_preloadedSounds.contains(path)) {
        try {
          // Load the asset into memory
          final ByteData data = await rootBundle.load(path);
          if (data.lengthInBytes > 0) {
            _preloadedSounds.add(path);
            debugPrint('Preloaded sound: $path');
          }
        } catch (e) {
          debugPrint('Error preloading sound $path: $e');
          // Continue with other sounds
        }
      }
    }
  }
  
  /// Check if a specific sound is preloaded
  bool isSoundPreloaded(String path) {
    return _preloadedSounds.contains(path);
  }
  
  /// Manually preload a specific sound
  Future<void> preloadSound(String path) async {
    await _preloadSounds([path]);
  }
  
  /// Manually preload a specific list of sounds
  Future<void> preloadSounds(List<String> paths) async {
    await _preloadSounds(paths);
  }
} 