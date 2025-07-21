import 'validation.dart';
import 'enums.dart';

/// Scoring rubric template
/// 
/// Defines the structure and criteria for scoring submissions.
/// Can be reused across multiple events.
class ScoringRubric {
  final String id;
  final String name;
  final String description;
  final List<ScoringCriterion> criteria;
  final String? eventId; // Optional - specific to an event
  final String? groupId; // Optional - specific to a group
  final bool isTemplate; // Whether this is a reusable template
  final String createdBy; // Member ID
  final DateTime createdAt;
  final DateTime updatedAt;

  const ScoringRubric({
    required this.id,
    required this.name,
    required this.description,
    required this.criteria,
    this.eventId,
    this.groupId,
    this.isTemplate = false,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create ScoringRubric from JSON data
  factory ScoringRubric.fromJson(Map<String, dynamic> json) {
    final criteriaList = json['criteria'] as List? ?? [];
    return ScoringRubric(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      criteria: criteriaList
          .map((c) => ScoringCriterion.fromJson(c as Map<String, dynamic>))
          .toList(),
      eventId: json['eventId'] as String?,
      groupId: json['groupId'] as String?,
      isTemplate: json['isTemplate'] as bool? ?? false,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert ScoringRubric to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'criteria': criteria.map((c) => c.toJson()).toList(),
      'eventId': eventId,
      'groupId': groupId,
      'isTemplate': isTemplate,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of ScoringRubric with updated fields
  ScoringRubric copyWith({
    String? id,
    String? name,
    String? description,
    List<ScoringCriterion>? criteria,
    String? eventId,
    String? groupId,
    bool? isTemplate,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScoringRubric(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      criteria: criteria ?? this.criteria,
      eventId: eventId ?? this.eventId,
      groupId: groupId ?? this.groupId,
      isTemplate: isTemplate ?? this.isTemplate,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get criterion by key
  ScoringCriterion? getCriterion(String criterionKey) {
    try {
      return criteria.firstWhere((c) => c.key == criterionKey);
    } catch (e) {
      return null;
    }
  }

  /// Get all criterion keys
  List<String> get criterionKeys => criteria.map((c) => c.key).toList();

  /// Calculate maximum possible score
  double get maxPossibleScore {
    return criteria.fold(0.0, (sum, criterion) => sum + criterion.maxScore);
  }

  /// Calculate weighted maximum score
  double get weightedMaxScore {
    return criteria.fold(0.0, (sum, criterion) => sum + (criterion.maxScore * criterion.weight));
  }

  /// Check if rubric has any criteria
  bool get hasCriteria => criteria.isNotEmpty;

  /// Add criterion
  ScoringRubric addCriterion(ScoringCriterion criterion) {
    final newCriteria = [...criteria, criterion];
    return copyWith(
      criteria: newCriteria,
      updatedAt: DateTime.now(),
    );
  }

  /// Remove criterion
  ScoringRubric removeCriterion(String criterionKey) {
    final newCriteria = criteria.where((c) => c.key != criterionKey).toList();
    return copyWith(
      criteria: newCriteria,
      updatedAt: DateTime.now(),
    );
  }

  /// Update criterion
  ScoringRubric updateCriterion(String criterionKey, ScoringCriterion updatedCriterion) {
    final newCriteria = criteria.map((c) {
      return c.key == criterionKey ? updatedCriterion : c;
    }).toList();
    return copyWith(
      criteria: newCriteria,
      updatedAt: DateTime.now(),
    );
  }

  /// Validate ScoringRubric data
  ValidationResult validate() {
    final results = [
      Validators.validateId(id, 'Rubric ID'),
      Validators.validateNonEmpty(name, 'Rubric name'),
      Validators.validateNonEmpty(description, 'Rubric description'),
      Validators.validateId(createdBy, 'Created by member ID'),
      Validators.validateDate(createdAt, 'Created date'),
      Validators.validateDate(updatedAt, 'Updated date'),
    ];

    // Additional business logic validation
    final additionalErrors = <String>[];
    
    // Must have at least one criterion
    if (criteria.isEmpty) {
      additionalErrors.add('Scoring rubric must have at least one criterion');
    }
    
    // Validate each criterion
    for (int i = 0; i < criteria.length; i++) {
      final criterion = criteria[i];
      
      // Validate criterion fields
      if (criterion.key.isEmpty) {
        additionalErrors.add('Criterion ${i + 1} must have a key');
      }
      if (criterion.name.isEmpty) {
        additionalErrors.add('Criterion ${i + 1} must have a name');
      }
      if (criterion.maxScore <= 0) {
        additionalErrors.add('Criterion ${i + 1} max score must be positive');
      }
      if (criterion.weight <= 0) {
        additionalErrors.add('Criterion ${i + 1} weight must be positive');
      }
    }
    
    // Check for duplicate criterion keys
    final criterionKeys = criteria.map((c) => c.key).toList();
    final uniqueKeys = criterionKeys.toSet();
    if (criterionKeys.length != uniqueKeys.length) {
      additionalErrors.add('Criterion keys must be unique');
    }
    
    // Validate name length
    if (name.length > 100) {
      additionalErrors.add('Rubric name must not exceed 100 characters');
    }
    
    // Validate description length
    if (description.length > 1000) {
      additionalErrors.add('Rubric description must not exceed 1000 characters');
    }
    
    // updatedAt should be after or equal to createdAt
    if (updatedAt.isBefore(createdAt)) {
      additionalErrors.add('Updated timestamp must be after or equal to creation timestamp');
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
    
    return other is ScoringRubric &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        _listEquals(other.criteria, criteria) &&
        other.eventId == eventId &&
        other.groupId == groupId &&
        other.isTemplate == isTemplate &&
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
      criteria.length,
      createdBy,
      createdAt,
      updatedAt,
    );
  }

  /// Helper method to compare lists
  bool _listEquals(List<ScoringCriterion> list1, List<ScoringCriterion> list2) {
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    
    return true;
  }

  @override
  String toString() {
    return 'ScoringRubric(id: $id, name: $name, criteria: ${criteria.length})';
  }
}

/// Individual scoring criterion within a rubric
class ScoringCriterion {
  final String key;
  final String name;
  final String description;
  final ScoringType type;
  final double maxScore;
  final double weight;
  final bool required;
  final Map<String, dynamic>? options; // For scale/boolean types

  const ScoringCriterion({
    required this.key,
    required this.name,
    required this.description,
    this.type = ScoringType.numeric,
    this.maxScore = 100.0,
    this.weight = 1.0,
    this.required = true,
    this.options,
  });

  factory ScoringCriterion.fromJson(Map<String, dynamic> json) {
    return ScoringCriterion(
      key: json['key'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: ScoringType.fromString(json['type'] as String? ?? 'numeric'),
      maxScore: (json['maxScore'] as num?)?.toDouble() ?? 100.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      required: json['required'] as bool? ?? true,
      options: json['options'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'name': name,
      'description': description,
      'type': type.value,
      'maxScore': maxScore,
      'weight': weight,
      'required': required,
      'options': options,
    };
  }

  ScoringCriterion copyWith({
    String? key,
    String? name,
    String? description,
    ScoringType? type,
    double? maxScore,
    double? weight,
    bool? required,
    Map<String, dynamic>? options,
  }) {
    return ScoringCriterion(
      key: key ?? this.key,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      maxScore: maxScore ?? this.maxScore,
      weight: weight ?? this.weight,
      required: required ?? this.required,
      options: options ?? this.options,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ScoringCriterion &&
        other.key == key &&
        other.name == name &&
        other.description == description &&
        other.type == type &&
        other.maxScore == maxScore &&
        other.weight == weight &&
        other.required == required &&
        _mapEquals(other.options, options);
  }

  @override
  int get hashCode {
    return Object.hash(
      key,
      name,
      description,
      type,
      maxScore,
      weight,
      required,
      options?.toString(),
    );
  }

  bool _mapEquals(Map<String, dynamic>? map1, Map<String, dynamic>? map2) {
    if (map1 == null && map2 == null) return true;
    if (map1 == null || map2 == null) return false;
    if (map1.length != map2.length) return false;
    
    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) {
        return false;
      }
    }
    
    return true;
  }

  /// Validate if a score value is valid for this criterion
  bool isValidScore(dynamic value) {
    switch (type) {
      case ScoringType.numeric:
        if (value is! num) return false;
        final numValue = value.toDouble();
        return numValue >= 0 && numValue <= maxScore;
      
      case ScoringType.scale:
        if (value is! num) return false;
        final numValue = value.toDouble();
        // For scale type, check if value is within the defined scale
        final scaleMin = options?['min'] as num? ?? 0;
        final scaleMax = options?['max'] as num? ?? maxScore;
        return numValue >= scaleMin && numValue <= scaleMax;
      
      case ScoringType.boolean:
        return value is bool;
    }
  }

  @override
  String toString() {
    return 'ScoringCriterion(key: $key, name: $name, type: ${type.value})';
  }
}