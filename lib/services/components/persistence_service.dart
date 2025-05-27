import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/game_state.dart';
import '../../utils/time_utils.dart';
import '../../services/income_service.dart'; // ADDED: Import IncomeService

/// Persistence management component for GameService
class PersistenceService {
  static const String _saveKey = 'empire_tycoon_save';
  static const String _versionKey = 'empire_tycoon_version';
  static const String _currentVersion = '1.0.1'; // Increment this whenever significant game balance changes are made
  
  final SharedPreferences _prefs;
  final GameState _gameState;
  final IncomeService? _incomeService; // ADDED: IncomeService field
  
  PersistenceService(this._prefs, this._gameState, {IncomeService? incomeService}) : _incomeService = incomeService;
  
  Future<void> checkVersion() async {
    final String? savedVersion = _prefs.getString(_versionKey);
    print("📊 Current game version: $_currentVersion, Saved version: $savedVersion");

    // If version is different or not set, clear saved data to apply new balance changes
    if (savedVersion != _currentVersion) {
      print("🔄 Game version changed from $savedVersion to $_currentVersion. Resetting game data.");
      await _prefs.remove(_saveKey);
      await _prefs.setString(_versionKey, _currentVersion);
    }
  }
  
  Future<void> performAutoSave() async {
    try {
      print("💾 Auto-saving game at ${TimeUtils.formatTime(DateTime.now())}");
      await saveGame();
      print("✅ Auto-save completed successfully");
    } catch (e) {
      print("⚠️ Error during auto-save: $e");
    }
  }
  
  Future<void> performInitialSave() async {
    try {
      // Only perform initial save if the game state is not already saved
      if (!_prefs.containsKey(_saveKey)) {
        print("💾 Performing initial save");
        await saveGame();
        print("✅ Initial save completed successfully");
      } else {
        print("ℹ️ Initial save skipped - save data already exists");
      }
    } catch (e) {
      print("⚠️ Error during initial save: $e");
    }
  }
  
  Future<void> saveGame() async {
    try {
      final DateTime beforeSave = DateTime.now();
      
      // Update the last saved timestamp in the game state
      _gameState.lastSaved = beforeSave;
      
      // Convert the game state to JSON
      final Map<String, dynamic> gameData = _gameState.toJson();
      final String jsonData = jsonEncode(gameData);
      
      // Save to SharedPreferences
      await _prefs.setString(_saveKey, jsonData);
      
      // Also save to a file for backup
      if (!kIsWeb) {
        try {
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/empire_tycoon_save.json');
          await file.writeAsString(jsonData);
          print("💾 Backup save to file: ${file.path}");
        } catch (e) {
          print("⚠️ Error during backup save to file: $e");
          // Continue even if backup fails
        }
      }
      
      final DateTime afterSave = DateTime.now();
      final Duration saveDuration = afterSave.difference(beforeSave);
      print("💾 Game saved successfully in ${saveDuration.inMilliseconds}ms");
    } catch (e) {
      print("⚠️ Error during save: $e");
      throw Exception("Failed to save game: $e");
    }
  }
  
  Future<void> loadGame() async {
    try {
      // Get the saved game data from SharedPreferences
      final String? jsonData = _prefs.getString(_saveKey);
      
      if (jsonData == null || jsonData.isEmpty) {
        print("ℹ️ No saved game found, starting new game");
        return;
      }
      
      // Parse the JSON data
      final Map<String, dynamic> gameData = jsonDecode(jsonData) as Map<String, dynamic>;
      
      // Load the game state from the JSON data
      // UPDATED: Pass the IncomeService to ensure consistent income calculation
      await _gameState.fromJson(gameData, incomeService: _incomeService);
      
      print("📊 Loaded game state with ${_gameState.businesses.length} businesses and ${_gameState.investments.length} investments");
      print("💰 Player has ${_gameState.money} money and ${_gameState.platinumPoints} platinum points");
      
      // Process offline income if applicable
      final DateTime now = DateTime.now();
      final DateTime lastSaved = _gameState.lastSaved;
      final Duration offlineTime = now.difference(lastSaved);
      
      if (offlineTime.inMinutes > 1) {
        print("⏱️ Player was offline for ${offlineTime.inMinutes} minutes");
        // UPDATED: Pass the IncomeService to ensure consistent income calculation
        _gameState.processOfflineIncome(lastSaved, incomeService: _incomeService);
      }
    } catch (e) {
      print("⚠️ Error during load: $e");
      throw Exception("Failed to load game: $e");
    }
  }
  
  Future<void> resetGame() async {
    try {
      print("🔄 Resetting game data");
      await _prefs.remove(_saveKey);
      _gameState.resetToDefaults();
      print("✅ Game reset successfully");
    } catch (e) {
      print("⚠️ Error during reset: $e");
      throw Exception("Failed to reset game: $e");
    }
  }
  
  String exportGameData() {
    final Map<String, dynamic> gameData = _gameState.toJson();
    return jsonEncode(gameData);
  }
  
  Future<void> importGameData(String data) async {
    try {
      final Map<String, dynamic> gameData = jsonDecode(data) as Map<String, dynamic>;
      // UPDATED: Pass the IncomeService to ensure consistent income calculation
      await _gameState.fromJson(gameData, incomeService: _incomeService);
      await saveGame();
      print("✅ Game data imported successfully");
    } catch (e) {
      print("⚠️ Error during import: $e");
      throw Exception("Failed to import game data: $e");
    }
  }
}
