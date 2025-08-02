import 'validation.dart';
import 'scoring_rubric.dart';

/// Score model for submission evaluations
///
/// Represents a score given by a judge for a specific submission.
/// Supports flexible scoring criteria and aggregation.
class Score {
  final String id;
  final String submissionId;
  final String judgeId; // Member ID of the judge
  final String eventId;
  final Map<String, dynamic> scores; // Flexible scoring structure
  final String? comments;
  final double? totalScore; // Calculated total score
  final DateTime createdAt;
  final DateTime updatedAt;

  const Score({
    required this.id,
    required this.submissionId,
    required this.judgeId,
    required this.eventId,
    this.scores = const {},
    this.comments,
    this.totalScore,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Score from JSON data
  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      id: json['id'] as String,
      submissionId: json['submissionId'] as String,
      judgeId: json['judgeId'] as String,
      eventId: json['eventId'] as String,
      scores: Map<String, dynamic>.from(json['scores'] as Map? ?? {}),
      comments: json['comments'] as String?,
      totalScore: json['totalScore'] as double?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert Score to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'submissionId': submissionId,
      'judgeId': judgeId,
      'eventId': eventId,
      'scores': scores,
      'comments': comments,
      'totalScore': totalScore,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of Score with updated fields
  Score copyWith({
    String? id,
    String? submissionId,
    String? judgeId,
    String? eventId,
    Map<String, dynamic>? scores,
    String? comments,
    double? totalScore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Score(
      id: id ?? this.id,
      submissionId: submissionId ?? this.submissionId,
      judgeId: judgeId ?? this.judgeId,
      eventId: eventId ?? this.eventId,
      scores: scores ?? this.scores,
      comments: comments ?? this.comments,
      totalScore: totalScore ?? this.totalScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get a specific score value by criterion key
  T? getScore<T>(String criterion, [T? defaultValue]) {
    final value = scores[criterion];
    if (value is T) return value;
    return defaultValue;
  }

  /// Get numeric score value
  double? getNumericScore(String criterion) {
    final value = scores[criterion];
    if (value is num) return value.toDouble();
    return null;
  }

  /// Update a specific score criterion
  Score updateScore(String criterion, dynamic value) {
    final newScores = Map<String, dynamic>.from(scores);
    newScores[criterion] = value;
    return copyWith(scores: newScores);
  }

  /// Remove a score criterion
  Score removeScore(String criterion) {
    final newScores = Map<String, dynamic>.from(scores);
    newScores.remove(criterion);
    return copyWith(scores: newScores);
  }

  /// Calculate total score based on scoring rubric
  Score calculateTotalScore(ScoringRubric rubric) {
    double total = 0.0;
    double totalWeight = 0.0;

    for (final criterion in rubric.criteria) {
      final score = getNumericScore(criterion.key);
      if (score != null) {
        total += score * criterion.weight;
        totalWeight += criterion.weight;
      }
    }

    // Normalize to 0-100 scale if weights don't add up to 1
    //TODO: final normalizedTotal = totalWeight > 0 ? (total / totalWeight) * 100 : 0.0;
    final normalizedTotal = totalWeight > 0 ? (total / totalWeight) : 0.0;

    return copyWith(
      totalScore: normalizedTotal,
      updatedAt: DateTime.now(),
    );
  }

  /// Check if all required criteria have been scored
  bool isComplete(ScoringRubric rubric) {
    for (final criterion in rubric.criteria) {
      if (criterion.required && !scores.containsKey(criterion.key)) {
        return false;
      }
    }
    return true;
  }

  /// Get completion percentage
  double getCompletionPercentage(ScoringRubric rubric) {
    if (rubric.criteria.isEmpty) return 100.0;

    int scoredCriteria = 0;
    for (final criterion in rubric.criteria) {
      if (scores.containsKey(criterion.key)) {
        scoredCriteria++;
      }
    }

    return (scoredCriteria / rubric.criteria.length) * 100;
  }

  /// Validate Score data
  ValidationResult validate() {
    final results = [
      Validators.validateId(id, 'Score ID'),
      Validators.validateId(submissionId, 'Submission ID'),
      Validators.validateId(judgeId, 'Judge ID'),
      Validators.validateId(eventId, 'Event ID'),
      Validators.validateDate(createdAt, 'Created date'),
      Validators.validateDate(updatedAt, 'Updated date'),
    ];

    // Additional business logic validation
    final additionalErrors = <String>[];

    // Validate total score range
    if (totalScore != null && (totalScore! < 0 || totalScore! > 100)) {
      additionalErrors.add('Total score must be between 0 and 100');
    }

    // Validate comments length
    if (comments != null && comments!.length > 2000) {
      additionalErrors.add('Comments must not exceed 2000 characters');
    }

    // Validate individual scores
    for (final entry in scores.entries) {
      final value = entry.value;
      if (value is num) {
        if (value < 0 || value > 100) {
          additionalErrors
              .add('Score for ${entry.key} must be between 0 and 100');
        }
      }
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

    return other is Score &&
        other.id == id &&
        other.submissionId == submissionId &&
        other.judgeId == judgeId &&
        other.eventId == eventId &&
        _mapEquals(other.scores, scores) &&
        other.comments == comments &&
        other.totalScore == totalScore &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      submissionId,
      judgeId,
      eventId,
      scores.toString(),
      comments,
      totalScore,
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
    return 'Score(id: $id, submissionId: $submissionId, judgeId: $judgeId, totalScore: $totalScore)';
  }
}
