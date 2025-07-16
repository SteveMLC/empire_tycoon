import 'package:flutter/material.dart';

/// Types of events that can occur in the game
enum EventType {
  disaster,  // Natural disasters like fires, floods, earthquakes
  economic,  // Economic events like recessions, inflation
  security,  // Security events like theft, break-ins, cybercrime
  utility,   // Utility issues like power outages, water main breaks
  staff,     // Staff issues like strikes, shortages, etc.
}

/// Extension for EventType to identify natural disasters
extension EventTypeProperties on EventType {
  bool get isNaturalDisaster {
    return this == EventType.disaster;
  }
}

/// Types of resolution mechanisms for events
enum EventResolutionType {
  timeBased,     // Resolves automatically after a period of time
  adBased,       // Resolves when player watches an ad
  feeBased,      // Resolves when player pays a fee
  tapChallenge,  // Resolves when player taps a certain number of times
}

/// Resolution parameter and state for an event
class EventResolution {
  /// Type of resolution mechanism
  final EventResolutionType type;
  
  /// Value depends on resolution type:
  /// - For timeBased: seconds remaining (int)
  /// - For adBased: null
  /// - For feeBased: the cost to resolve (double)
  /// - For tapChallenge: Map with 'required' and 'current' tap counts (Map<String, int>)
  dynamic value;
  
  EventResolution({
    required this.type,
    this.value,
  });
  
  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'value': value,
    };
  }
  
  /// Create from JSON data
  factory EventResolution.fromJson(Map<String, dynamic> json) {
    return EventResolution(
      type: EventResolutionType.values[json['type'] as int],
      value: json['value'],
    );
  }
}

/// Represents an event that can affect businesses and properties
class GameEvent {
  final String id;             // Unique identifier for the event
  final String name;           // Name of the event
  final String description;    // Description of what happened
  final EventType type;        // Type of event
  final List<String> affectedBusinessIds;  // IDs of affected businesses
  final List<String> affectedLocaleIds;    // IDs of affected locales
  final DateTime startTime;    // When the event started
  final EventResolution resolution;  // How the event can be resolved
  bool isResolved = false;     // Whether the event has been resolved
  DateTime? completedTimestamp; // When the event was resolved
  DateTime? timestamp;          // Event creation timestamp
  double? resolutionFeePaid;    // Amount paid to resolve (for fee-based)
  
  /// Auto-expiry time in seconds (default 60 minutes)
  final int autoExpirySeconds;
  
  /// Standard event income penalty (25% reduction)
  static const double EVENT_INCOME_PENALTY = -0.25; // -25% of income (negative value)
  
  GameEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.affectedBusinessIds,
    required this.affectedLocaleIds,
    required this.resolution,
    required this.startTime,
    this.isResolved = false,
    this.completedTimestamp,
    this.timestamp,
    this.resolutionFeePaid,
    this.autoExpirySeconds = 3600, // Default 60 minutes (60 * 60 = 3600 seconds)
  }) {
    // Set creation timestamp if not provided
    this.timestamp ??= DateTime.now();
  }
  
  /// Get the remaining time until auto-expiry (works for ALL events)
  int get timeRemaining {
    final elapsedSeconds = DateTime.now().difference(startTime).inSeconds;
    final remaining = autoExpirySeconds - elapsedSeconds;
    return remaining > 0 ? remaining : 0;
  }
  
  /// Check if this event has expired and should be auto-resolved
  bool get hasExpired {
    return timeRemaining <= 0;
  }
  
  /// Get a formatted string of time remaining (e.g., "45:30", "5:00")
  String get timeRemainingFormatted {
    final remaining = timeRemaining;
    if (remaining <= 0) return "00:00";
    
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }
  
  /// Get the tap count required for tap challenges
  int get requiredTaps {
    if (resolution.type != EventResolutionType.tapChallenge) return 0;
    
    final Map<String, dynamic> tapData = resolution.value as Map<String, dynamic>;
    return tapData['required'] ?? 0;
  }
  
  /// Get the fee for fee-based resolutions
  double get resolutionFee {
    if (resolution.type != EventResolutionType.feeBased) return 0.0;
    
    return resolution.value as double;
  }
  
  /// Mark the event as resolved 
  void resolve({double? feePaid}) {
    isResolved = true;
    completedTimestamp = DateTime.now();
    
    // If fee was provided, track it
    if (feePaid != null) {
      resolutionFeePaid = feePaid;
    } else if (resolution.type == EventResolutionType.feeBased) {
      // Default to the resolution fee value
      resolutionFeePaid = resolutionFee;
    }
  }
  
  /// Get a display-friendly string of affected entities
  String getAffectedEntitiesDisplay(List<dynamic> businesses, List<dynamic> locales) {
    List<String> descriptions = [];
    
    // Get business names
    if (affectedBusinessIds.isNotEmpty) {
      List<String> businessNames = [];
      for (String businessId in affectedBusinessIds) {
        try {
          final business = businesses.firstWhere((b) => b.id == businessId, orElse: () => null);
          if (business != null) {
            businessNames.add(business.name);
          }
        } catch (e) {
          print('Error resolving business name for $businessId: $e');
        }
      }
      if (businessNames.isNotEmpty) {
        descriptions.add("Business: ${businessNames.join(', ')}");
      }
    }
    
    // Get locale names
    if (affectedLocaleIds.isNotEmpty) {
      List<String> localeNames = [];
      for (String localeId in affectedLocaleIds) {
        try {
          final locale = locales.firstWhere((l) => l.id == localeId, orElse: () => null);
          if (locale != null) {
            localeNames.add(locale.name);
          }
        } catch (e) {
          print('Error resolving locale name for $localeId: $e');
        }
      }
      if (localeNames.isNotEmpty) {
        descriptions.add("Location: ${localeNames.join(', ')}");
      }
    }
    
    return descriptions.join(' • ');
  }
  
  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.index,
      'affectedBusinessIds': affectedBusinessIds,
      'affectedLocaleIds': affectedLocaleIds,
      'startTime': startTime.toIso8601String(),
      'resolution': resolution.toJson(),
      'isResolved': isResolved,
      'completedTimestamp': completedTimestamp?.toIso8601String(),
      'timestamp': timestamp?.toIso8601String(),
      'resolutionFeePaid': resolutionFeePaid,
      'autoExpirySeconds': autoExpirySeconds,
    };
  }
  
  /// Create from JSON data
  factory GameEvent.fromJson(Map<String, dynamic> json) {
    return GameEvent(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: EventType.values[json['type'] as int],
      affectedBusinessIds: List<String>.from(json['affectedBusinessIds'] as List),
      affectedLocaleIds: List<String>.from(json['affectedLocaleIds'] as List),
      startTime: DateTime.parse(json['startTime'] as String),
      resolution: EventResolution.fromJson(json['resolution'] as Map<String, dynamic>),
      isResolved: json['isResolved'] as bool,
      completedTimestamp: json['completedTimestamp'] != null 
          ? DateTime.parse(json['completedTimestamp'] as String) 
          : null,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'] as String) 
          : null,
      resolutionFeePaid: json['resolutionFeePaid'] as double?,
      autoExpirySeconds: json['autoExpirySeconds'] as int? ?? 3600, // Default to 3600 if not provided
    );
  }
}