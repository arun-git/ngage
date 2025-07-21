import 'enums.dart';
import 'validation.dart';

/// Group model
/// 
/// Represents a group that contains members and teams. Groups can be of different
/// types (corporate, educational, community, social) and have various settings
/// that control their behavior.
class Group {
  final String id;
  final String name;
  final String description;
  final GroupType groupType;
  final Map<String, dynamic> settings;
  final String createdBy; // Member ID
  final DateTime createdAt;
  final DateTime updatedAt;

  const Group({
    required this.id,
    required this.name,
    required this.description,
    required this.groupType,
    this.settings = const {},
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Group from JSON data
  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      groupType: GroupType.fromString(json['groupType'] as String),
      settings: Map<String, dynamic>.from(json['settings'] as Map? ?? {}),
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert Group to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'groupType': groupType.value,
      'settings': settings,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of Group with updated fields
  Group copyWith({
    String? id,
    String? name,
    String? description,
    GroupType? groupType,
    Map<String, dynamic>? settings,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      groupType: groupType ?? this.groupType,
      settings: settings ?? this.settings,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get a setting value with optional default
  T? getSetting<T>(String key, [T? defaultValue]) {
    final value = settings[key];
    if (value is T) return value;
    return defaultValue;
  }

  /// Create a new Group with updated settings
  Group updateSetting(String key, dynamic value) {
    final newSettings = Map<String, dynamic>.from(settings);
    newSettings[key] = value;
    return copyWith(settings: newSettings);
  }

  /// Remove a setting
  Group removeSetting(String key) {
    final newSettings = Map<String, dynamic>.from(settings);
    newSettings.remove(key);
    return copyWith(settings: newSettings);
  }

  /// Validate Group data
  ValidationResult validate() {
    final results = [
      Validators.validateId(id, 'Group ID'),
      Validators.validateName(name, 'Group name'),
      Validators.validateDescription(description, maxLength: 1000),
      Validators.validateId(createdBy, 'Created by member ID'),
      Validators.validateDate(createdAt, 'Created date'),
      Validators.validateDate(updatedAt, 'Updated date'),
    ];

    // Additional validation for name length
    final additionalErrors = <String>[];
    
    if (name.length > 100) {
      additionalErrors.add('Group name must not exceed 100 characters');
    }
    
    if (description.isEmpty) {
      additionalErrors.add('Group description is required');
    }

    final baseValidation = Validators.combine(results);
    
    if (additionalErrors.isNotEmpty) {
      final allErrors = [...baseValidation.errors, ...additionalErrors];
      return ValidationResult.invalid(allErrors);
    }
    
    return baseValidation;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Group &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.groupType == groupType &&
        _mapEquals(other.settings, settings) &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      groupType,
      settings.toString(), // Simple hash for map
      createdBy,
      createdAt,
      updatedAt,
    );
  }

  /// Helper method to compare maps
  bool _mapEquals(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    
    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) {
        return false;
      }
    }
    
    return true;
  }

  @override
  String toString() {
    return 'Group(id: $id, name: $name, groupType: ${groupType.value}, createdBy: $createdBy)';
  }
}