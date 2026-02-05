import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/real_estate.dart';

class RealEstateDataLoader {
  // Load real estate upgrades from the CSV files
  static Future<Map<String, List<RealEstateUpgrade>>> loadUpgradesFromCSV() async {
    Map<String, List<RealEstateUpgrade>> upgradesByPropertyId = {};
    
    // Load both CSV files
    try {
      final String data1 = await rootBundle.loadString('attached_assets/RealEstateUpgradeset.txt');
      final String data2 = await rootBundle.loadString('attached_assets/RealEstateUpgradeset1.txt');
      
      // Process each CSV file
      _processCSVData(data1, upgradesByPropertyId);
      _processCSVData(data2, upgradesByPropertyId);
      
    } catch (e) {
      print('Error loading real estate upgrades: $e');
    }
    
    return upgradesByPropertyId;
  }
  
  // Process CSV data and extract upgrades
  static void _processCSVData(String csvData, Map<String, List<RealEstateUpgrade>> upgradesByPropertyId) {
    // Split the data into lines and skip the header
    List<String> lines = LineSplitter.split(csvData).toList();
    if (lines.isEmpty) return;
    
    // Skip the header line
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) continue;
      
      // Parse the CSV line - handling potential commas in quoted strings
      List<String> values = _parseCSVLine(line);
      if (values.length < 8) continue; // Skip invalid lines
      
      // Extract data from the CSV
      final String localeId = _normalizeId(values[0]);
      final String propertyId = values[1].replaceAll('"', ''); // Property ID
      final double baseCashFlow = double.tryParse(values[4]) ?? 0.0; // Base Income (/s)
      final String upgradeDescription = values[5].replaceAll('"', ''); // Upgrade Description
      final double upgradeCost = double.tryParse(values[6]) ?? 0.0; // Upgrade Cost
      final double newIncomePerSecond = double.tryParse(values[7]) ?? 0.0; // New Income (/s)
      
      // Create unique ID for the upgrade
      final String upgradeId = '${propertyId}_upgrade_${upgradeDescription.toLowerCase().replaceAll(' ', '_')}';
      
      // Create upgrade object
      final upgrade = RealEstateUpgrade(
        id: upgradeId,
        description: upgradeDescription,
        cost: upgradeCost,
        newIncomePerSecond: newIncomePerSecond,
        purchased: false,
      );
      
      // Add to the map, creating a list if needed
      if (!upgradesByPropertyId.containsKey(propertyId)) {
        upgradesByPropertyId[propertyId] = [];
      }
      
      // Add the upgrade to the list
      upgradesByPropertyId[propertyId]!.add(upgrade);
    }
  }
  
  // Helper to parse CSV line while respecting quoted strings that may contain commas
  static List<String> _parseCSVLine(String line) {
    List<String> result = [];
    bool inQuotes = false;
    String current = '';
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current);
        current = '';
      } else {
        current += char;
      }
    }
    
    // Add the last field
    if (current.isNotEmpty) {
      result.add(current);
    }
    
    return result;
  }
  
  // Apply loaded upgrades to properties in all locales
  static void applyUpgradesToProperties(List<RealEstateLocale> locales, Map<String, List<RealEstateUpgrade>> upgradesByPropertyId) {
    if (kDebugMode) print("🔄 Applying upgrades to properties. Total upgrade entries: ${upgradesByPropertyId.length}");

    for (var locale in locales) {
      if (kDebugMode) print("📍 Processing locale: ${locale.name} (${locale.id})");

      for (var property in locale.properties) {
        if (upgradesByPropertyId.containsKey(property.id)) {
          if (kDebugMode) print("🏠 Property ${property.name} (${property.id}) - Applying upgrades");

          // Create a copy of the upgrades for this property
          List<RealEstateUpgrade> propertyUpgrades = List.from(upgradesByPropertyId[property.id]!);

          // Sort upgrades by cost (ascending)
          propertyUpgrades.sort((a, b) => a.cost.compareTo(b.cost));

          if (kDebugMode) {
            print("  ⬆️ Adding ${propertyUpgrades.length} upgrades:");
            for (var upgrade in propertyUpgrades) {
              print("    - ${upgrade.description}: \$${upgrade.cost} → \$${upgrade.newIncomePerSecond}/sec");
            }
          }

          // Update the property with the upgrades
          property.upgrades.clear(); // Clear any existing upgrades
          property.upgrades.addAll(propertyUpgrades);
          if (kDebugMode) print("  ✅ Upgrades added successfully. Property now has ${property.upgrades.length} upgrades.");
        } else {
          if (kDebugMode) print("⚠️ No upgrades found for property: ${property.name} (${property.id})");
        }
      }
    }

    if (kDebugMode) print("✅ Finished applying upgrades to all properties");
  }
  
  // Normalize locale ID to match game internal IDs
  static String _normalizeId(String localeString) {
    String normalized = localeString.replaceAll('"', '').toLowerCase();
    
    // Map CSV locale names to game locale IDs
    switch (normalized) {
      case 'rural kenya':
        return 'rural_kenya';
      case 'lagos, nigeria':
        return 'lagos_nigeria';
      case 'cape town, south africa':
        return 'cape_town_sa';
      case 'rural thailand':
        return 'rural_thailand';
      case 'mumbai, india':
        return 'mumbai_india';
      case 'ho chi minh city, vietnam':
        return 'ho_chi_minh_city';
      case 'miami, florida':
        return 'miami_florida';
      case 'new york city, ny':
        return 'new_york_city';
      case 'los angeles, ca':
        return 'los_angeles';
      case 'lima, peru':
        return 'lima_peru';
      case 'sao paulo, brazil':
        return 'sao_paulo_brazil';
      case 'dubai, uae':
        return 'dubai_uae';
      default:
        return normalized.replaceAll(' ', '_').replaceAll(',', '');
    }
  }
}