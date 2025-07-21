import 'validation.dart';

/// Leaderboard entry representing a team's position and score
class LeaderboardEntry {
  final String teamId;
  final String teamName;
  final double totalScore;
  final double averageScore;
  final int submissionCount;
  final int position;
  final Map<String, double> criteriaScores; // Average scores by criterion

  const LeaderboardEntry({
    required this.teamId,
    required this.teamName,
    required this.totalScore,
    required this.averageScore,
    required this.submissionCount,
    required this.position,
    this.criteriaScores = const {},
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final criteriaScoresMap = json['criteriaScores'] as Map<String, dynamic>? ?? {};
    return LeaderboardEntry(
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      totalScore: (json['totalScore'] as num).toDouble(),
      averageScore: (json['averageScore'] as num).toDouble(),
      submissionCount: json['submissionCount'] as int,
      position: json['position'] as int,
      criteriaScores: criteriaScoresMap.map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'totalScore': totalScore,
      'averageScore': averageScore,
      'submissionCount': submissionCount,
      'position': position,
      'criteriaScores': criteriaScores,
    };
  }

  LeaderboardEntry copyWith({
    String? teamId,
    String? teamName,
    double? totalScore,
    double? averageScore,
    int? submissionCount,
    int? position,
    Map<String, double>? criteriaScores,
  }) {
    return LeaderboardEntry(
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      totalScore: totalScore ?? this.totalScore,
      averageScore: averageScore ?? this.averageScore,
      submissionCount: submissionCount ?? this.submissionCount,
      position: position ?? this.position,
      criteriaScores: criteriaScores ?? this.criteriaScores,
    );
  }

  /// Get score for a specific criterion
  double? getCriteriaScore(String criterion) {
    return criteriaScores[criterion];
  }

  /// Check if this is a winning position (top 3)
  bool get isWinningPosition => position <= 3;

  /// Check if this is first place
  bool get isFirstPlace => position == 1;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is LeaderboardEntry &&
        other.teamId == teamId &&
        other.teamName == teamName &&
        other.totalScore == totalScore &&
        other.averageScore == averageScore &&
        other.submissionCount == submissionCount &&
        other.position == position &&
        _mapEquals(other.criteriaScores, criteriaScores);
  }

  @override
  int get hashCode {
    return Object.hash(
      teamId,
      teamName,
      totalScore,
      averageScore,
      submissionCount,
      position,
      criteriaScores.toString(),
    );
  }

  bool _mapEquals(Map<String, double> map1, Map<String, double> map2) {
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
    return 'LeaderboardEntry(position: $position, team: $teamName, score: $totalScore)';
  }
}

/// Leaderboard for an event
class Leaderboard {
  final String id;
  final String eventId;
  final List<LeaderboardEntry> entries;
  final DateTime calculatedAt;
  final Map<String, dynamic> metadata; // Additional leaderboard info

  const Leaderboard({
    required this.id,
    required this.eventId,
    required this.entries,
    required this.calculatedAt,
    this.metadata = const {},
  });

  factory Leaderboard.fromJson(Map<String, dynamic> json) {
    final entriesList = json['entries'] as List? ?? [];
    return Leaderboard(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      entries: entriesList
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'entries': entries.map((e) => e.toJson()).toList(),
      'calculatedAt': calculatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  Leaderboard copyWith({
    String? id,
    String? eventId,
    List<LeaderboardEntry>? entries,
    DateTime? calculatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Leaderboard(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      entries: entries ?? this.entries,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get entry by team ID
  LeaderboardEntry? getEntryByTeam(String teamId) {
    try {
      return entries.firstWhere((entry) => entry.teamId == teamId);
    } catch (e) {
      return null;
    }
  }

  /// Get entry by position
  LeaderboardEntry? getEntryByPosition(int position) {
    try {
      return entries.firstWhere((entry) => entry.position == position);
    } catch (e) {
      return null;
    }
  }

  /// Get top N entries
  List<LeaderboardEntry> getTopEntries(int count) {
    final sortedEntries = List<LeaderboardEntry>.from(entries)
      ..sort((a, b) => a.position.compareTo(b.position));
    return sortedEntries.take(count).toList();
  }

  /// Get winning entries (top 3)
  List<LeaderboardEntry> get winners => getTopEntries(3);

  /// Get first place entry
  LeaderboardEntry? get firstPlace => getEntryByPosition(1);

  /// Check if leaderboard has entries
  bool get hasEntries => entries.isNotEmpty;

  /// Get total number of teams
  int get teamCount => entries.length;

  /// Get metadata value
  T? getMetadata<T>(String key, [T? defaultValue]) {
    final value = metadata[key];
    if (value is T) return value;
    return defaultValue;
  }

  /// Update metadata
  Leaderboard updateMetadata(String key, dynamic value) {
    final newMetadata = Map<String, dynamic>.from(metadata);
    newMetadata[key] = value;
    return copyWith(metadata: newMetadata);
  }

  /// Validate Leaderboard data
  ValidationResult validate() {
    final results = [
      Validators.validateId(id, 'Leaderboard ID'),
      Validators.validateId(eventId, 'Event ID'),
      Validators.validateDate(calculatedAt, 'Calculated date'),
    ];

    // Additional business logic validation
    final additionalErrors = <String>[];
    
    // Check for duplicate team IDs
    final teamIds = entries.map((e) => e.teamId).toList();
    final uniqueTeamIds = teamIds.toSet();
    if (teamIds.length != uniqueTeamIds.length) {
      additionalErrors.add('Team IDs must be unique in leaderboard');
    }
    
    // Check for duplicate positions
    final positions = entries.map((e) => e.position).toList();
    final uniquePositions = positions.toSet();
    if (positions.length != uniquePositions.length) {
      additionalErrors.add('Positions must be unique in leaderboard');
    }
    
    // Validate position sequence (should be 1, 2, 3, ...)
    if (entries.isNotEmpty) {
      final sortedPositions = List<int>.from(positions)..sort();
      for (int i = 0; i < sortedPositions.length; i++) {
        if (sortedPositions[i] != i + 1) {
          additionalErrors.add('Positions must be sequential starting from 1');
          break;
        }
      }
    }
    
    // Validate each entry
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      
      if (entry.teamId.isEmpty) {
        additionalErrors.add('Entry ${i + 1} must have a team ID');
      }
      if (entry.teamName.isEmpty) {
        additionalErrors.add('Entry ${i + 1} must have a team name');
      }
      if (entry.totalScore < 0) {
        additionalErrors.add('Entry ${i + 1} total score cannot be negative');
      }
      if (entry.averageScore < 0) {
        additionalErrors.add('Entry ${i + 1} average score cannot be negative');
      }
      if (entry.submissionCount < 0) {
        additionalErrors.add('Entry ${i + 1} submission count cannot be negative');
      }
      if (entry.position <= 0) {
        additionalErrors.add('Entry ${i + 1} position must be positive');
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
    
    return other is Leaderboard &&
        other.id == id &&
        other.eventId == eventId &&
        _listEquals(other.entries, entries) &&
        other.calculatedAt == calculatedAt &&
        _mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      eventId,
      entries.length,
      calculatedAt,
      metadata.toString(),
    );
  }

  bool _listEquals(List<LeaderboardEntry> list1, List<LeaderboardEntry> list2) {
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    
    return true;
  }

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
    return 'Leaderboard(id: $id, eventId: $eventId, teams: ${entries.length})';
  }
}