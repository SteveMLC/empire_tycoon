import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Model class for app settings
class AppSettings {
  final bool isPlatinumUIActive;

  const AppSettings({this.isPlatinumUIActive = false});

  AppSettings copyWith({bool? isPlatinumUIActive}) {
    return AppSettings(
      isPlatinumUIActive: isPlatinumUIActive ?? this.isPlatinumUIActive,
    );
  }
}

// Notifier class to handle state changes
class AppSettingsNotifier extends StateNotifier<AppSettings> {
  static const String _platinumUIKey = 'isPlatinumUIActive';
  
  AppSettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isPlatinumUIActive = prefs.getBool(_platinumUIKey) ?? false;
      state = AppSettings(isPlatinumUIActive: isPlatinumUIActive);
    } catch (e) {
      print('Error loading app settings: $e');
    }
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_platinumUIKey, state.isPlatinumUIActive);
    } catch (e) {
      print('Error saving app settings: $e');
    }
  }

  // Toggle platinum UI mode
  void togglePlatinumUI() {
    state = state.copyWith(isPlatinumUIActive: !state.isPlatinumUIActive);
    _saveSettings();
  }
}

// Provider for app settings
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier();
}); 