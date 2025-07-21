/// Score history for tracking team/member performance over time
class ScoreHistory {
  final String teamId;
  final List<ScoreHistoryEntry> entries;
  final DateTime calculatedAt;
  final Map<String, dynamic> metadata;

  const ScoreHistory({
    required this.teamId,
    required this.entries,
    required this.calculatedAt,
    this.metadata = const {},
  });

  factory ScoreHistory.fromJson(Map<String, dynamic> json) {
    final entriesList = json['entries'] as List? ?? [];
    return ScoreHistory(
      teamId: json['teamId'] as String,
      entries: entriesList
          .map((e) => ScoreHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'entries': entries.map((e) => e.toJson()).toList(),
      'calculatedAt': calculatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  ScoreHistory copyWith({
    String? teamId,
    List<ScoreHistoryEntry>? entries,
    DateTime? calculatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ScoreHistory(
      teamId: teamId ?? this.teamId,
      entries: entries ?? this.entries,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get average score across all entries
  double get averageScore {
    if (entries.isEmpty) return 0.0;
    final sum = entries.fold(0.0, (sum, entry) => sum + entry.score);
    return sum / entries.length;
  }

  /// Get highest score
  double get highestScore {
    if (entries.isEmpty) return 0.0;
    return entries.map((e) => e.score).reduce((a, b) => a > b ? a : b);
  }

  /// Get lowest score
  double get lowestScore {
    if (entries.isEmpty) return 0.0;
    return entries.map((e) => e.score).reduce((a, b) => a < b ? a : b);
  }

  /// Get entries within date range
  List<ScoreHistoryEntry> getEntriesInRange(DateTime start, DateTime end) {
    return entries.where((entry) => 
        entry.submittedAt.isAfter(start) && entry.submittedAt.isBefore(end)
    ).toList();
  }

  /// Get recent entries
  List<ScoreHistoryEntry> getRecentEntries(int count) {
    final sortedEntries = List<ScoreHistoryEntry>.from(entries)
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return sortedEntries.take(count).toList();
  }

  bool get hasEntries => entries.isNotEmpty;
  int get entryCount => entries.length;
}

/// Individual entry in score history
class ScoreHistoryEntry {
  final String submissionId;
  final String eventId;
  final String eventName;
  final double score;
  final double totalScore;
  final int judgeCount;
  final Map<String, double> criteriaScores;
  final DateTime submittedAt;

  const ScoreHistoryEntry({
    required this.submissionId,
    required this.eventId,
    required this.eventName,
    required this.score,
    required this.totalScore,
    required this.judgeCount,
    this.criteriaScores = const {},
    required this.submittedAt,
  });

  factory ScoreHistoryEntry.fromJson(Map<String, dynamic> json) {
    final criteriaScoresMap = json['criteriaScores'] as Map<String, dynamic>? ?? {};
    return ScoreHistoryEntry(
      submissionId: json['submissionId'] as String,
      eventId: json['eventId'] as String,
      eventName: json['eventName'] as String,
      score: (json['score'] as num).toDouble(),
      totalScore: (json['totalScore'] as num).toDouble(),
      judgeCount: json['judgeCount'] as int,
      criteriaScores: criteriaScoresMap.map((k, v) => MapEntry(k, (v as num).toDouble())),
      submittedAt: DateTime.parse(json['submittedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'submissionId': submissionId,
      'eventId': eventId,
      'eventName': eventName,
      'score': score,
      'totalScore': totalScore,
      'judgeCount': judgeCount,
      'criteriaScores': criteriaScores,
      'submittedAt': submittedAt.toIso8601String(),
    };
  }

  ScoreHistoryEntry copyWith({
    String? submissionId,
    String? eventId,
    String? eventName,
    double? score,
    double? totalScore,
    int? judgeCount,
    Map<String, double>? criteriaScores,
    DateTime? submittedAt,
  }) {
    return ScoreHistoryEntry(
      submissionId: submissionId ?? this.submissionId,
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      score: score ?? this.score,
      totalScore: totalScore ?? this.totalScore,
      judgeCount: judgeCount ?? this.judgeCount,
      criteriaScores: criteriaScores ?? this.criteriaScores,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

  /// Get score for specific criterion
  double? getCriteriaScore(String criterion) {
    return criteriaScores[criterion];
  }

  /// Check if this is a high-scoring entry (>= 80)
  bool get isHighScore => score >= 80.0;

  /// Check if this is a low-scoring entry (< 60)
  bool get isLowScore => score < 60.0;
}

/// Score trend analysis
class ScoreTrend {
  final String teamId;
  final TrendDirection trendDirection;
  final double trendPercentage;
  final double averageScore;
  final List<ScoreTrendPoint> dataPoints;
  final DateTime calculatedAt;
  final Map<String, dynamic> metadata;

  const ScoreTrend({
    required this.teamId,
    required this.trendDirection,
    required this.trendPercentage,
    required this.averageScore,
    required this.dataPoints,
    required this.calculatedAt,
    this.metadata = const {},
  });

  factory ScoreTrend.fromJson(Map<String, dynamic> json) {
    final dataPointsList = json['dataPoints'] as List? ?? [];
    return ScoreTrend(
      teamId: json['teamId'] as String,
      trendDirection: TrendDirection.fromString(json['trendDirection'] as String),
      trendPercentage: (json['trendPercentage'] as num).toDouble(),
      averageScore: (json['averageScore'] as num).toDouble(),
      dataPoints: dataPointsList
          .map((e) => ScoreTrendPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'trendDirection': trendDirection.value,
      'trendPercentage': trendPercentage,
      'averageScore': averageScore,
      'dataPoints': dataPoints.map((e) => e.toJson()).toList(),
      'calculatedAt': calculatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  ScoreTrend copyWith({
    String? teamId,
    TrendDirection? trendDirection,
    double? trendPercentage,
    double? averageScore,
    List<ScoreTrendPoint>? dataPoints,
    DateTime? calculatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ScoreTrend(
      teamId: teamId ?? this.teamId,
      trendDirection: trendDirection ?? this.trendDirection,
      trendPercentage: trendPercentage ?? this.trendPercentage,
      averageScore: averageScore ?? this.averageScore,
      dataPoints: dataPoints ?? this.dataPoints,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if trend is improving
  bool get isImproving => trendDirection == TrendDirection.upward;

  /// Check if trend is declining
  bool get isDeclining => trendDirection == TrendDirection.downward;

  /// Check if trend is stable
  bool get isStable => trendDirection == TrendDirection.stable;

  /// Get trend description
  String get trendDescription {
    switch (trendDirection) {
      case TrendDirection.upward:
        return 'Improving by ${trendPercentage.abs().toStringAsFixed(1)}%';
      case TrendDirection.downward:
        return 'Declining by ${trendPercentage.abs().toStringAsFixed(1)}%';
      case TrendDirection.stable:
        return 'Stable performance';
    }
  }

  /// Get latest score
  double? get latestScore {
    if (dataPoints.isEmpty) return null;
    final sortedPoints = List<ScoreTrendPoint>.from(dataPoints)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sortedPoints.first.score;
  }

  /// Get earliest score
  double? get earliestScore {
    if (dataPoints.isEmpty) return null;
    final sortedPoints = List<ScoreTrendPoint>.from(dataPoints)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return sortedPoints.first.score;
  }

  bool get hasDataPoints => dataPoints.isNotEmpty;
  int get dataPointCount => dataPoints.length;
}

/// Individual data point in score trend
class ScoreTrendPoint {
  final DateTime timestamp;
  final double score;
  final String eventName;
  final String submissionId;

  const ScoreTrendPoint({
    required this.timestamp,
    required this.score,
    required this.eventName,
    required this.submissionId,
  });

  factory ScoreTrendPoint.fromJson(Map<String, dynamic> json) {
    return ScoreTrendPoint(
      timestamp: DateTime.parse(json['timestamp'] as String),
      score: (json['score'] as num).toDouble(),
      eventName: json['eventName'] as String,
      submissionId: json['submissionId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'score': score,
      'eventName': eventName,
      'submissionId': submissionId,
    };
  }

  ScoreTrendPoint copyWith({
    DateTime? timestamp,
    double? score,
    String? eventName,
    String? submissionId,
  }) {
    return ScoreTrendPoint(
      timestamp: timestamp ?? this.timestamp,
      score: score ?? this.score,
      eventName: eventName ?? this.eventName,
      submissionId: submissionId ?? this.submissionId,
    );
  }
}

/// Position history for tracking leaderboard position changes
class PositionHistory {
  final String teamId;
  final List<PositionHistoryEntry> entries;
  final DateTime calculatedAt;
  final Map<String, dynamic> metadata;

  const PositionHistory({
    required this.teamId,
    required this.entries,
    required this.calculatedAt,
    this.metadata = const {},
  });

  factory PositionHistory.fromJson(Map<String, dynamic> json) {
    final entriesList = json['entries'] as List? ?? [];
    return PositionHistory(
      teamId: json['teamId'] as String,
      entries: entriesList
          .map((e) => PositionHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'entries': entries.map((e) => e.toJson()).toList(),
      'calculatedAt': calculatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  PositionHistory copyWith({
    String? teamId,
    List<PositionHistoryEntry>? entries,
    DateTime? calculatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return PositionHistory(
      teamId: teamId ?? this.teamId,
      entries: entries ?? this.entries,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get current position
  int? get currentPosition {
    if (entries.isEmpty) return null;
    final sortedEntries = List<PositionHistoryEntry>.from(entries)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sortedEntries.first.position;
  }

  /// Get best position ever achieved
  int? get bestPosition {
    if (entries.isEmpty) return null;
    return entries.map((e) => e.position).reduce((a, b) => a < b ? a : b);
  }

  /// Get position change from previous entry
  int? get positionChange {
    if (entries.length < 2) return null;
    final sortedEntries = List<PositionHistoryEntry>.from(entries)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sortedEntries[1].position - sortedEntries[0].position;
  }

  bool get hasEntries => entries.isNotEmpty;
  int get entryCount => entries.length;
}

/// Individual entry in position history
class PositionHistoryEntry {
  final String eventId;
  final String eventName;
  final int position;
  final double score;
  final int totalTeams;
  final DateTime timestamp;

  const PositionHistoryEntry({
    required this.eventId,
    required this.eventName,
    required this.position,
    required this.score,
    required this.totalTeams,
    required this.timestamp,
  });

  factory PositionHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PositionHistoryEntry(
      eventId: json['eventId'] as String,
      eventName: json['eventName'] as String,
      position: json['position'] as int,
      score: (json['score'] as num).toDouble(),
      totalTeams: json['totalTeams'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'eventName': eventName,
      'position': position,
      'score': score,
      'totalTeams': totalTeams,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  PositionHistoryEntry copyWith({
    String? eventId,
    String? eventName,
    int? position,
    double? score,
    int? totalTeams,
    DateTime? timestamp,
  }) {
    return PositionHistoryEntry(
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      position: position ?? this.position,
      score: score ?? this.score,
      totalTeams: totalTeams ?? this.totalTeams,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Check if this is a winning position (top 3)
  bool get isWinningPosition => position <= 3;

  /// Check if this is first place
  bool get isFirstPlace => position == 1;

  /// Get position percentile
  double get positionPercentile {
    if (totalTeams == 0) return 0.0;
    return ((totalTeams - position + 1) / totalTeams) * 100;
  }
}

/// Trend direction enumeration
enum TrendDirection {
  upward('upward'),
  downward('downward'),
  stable('stable');

  const TrendDirection(this.value);
  final String value;

  static TrendDirection fromString(String value) {
    return TrendDirection.values.firstWhere(
      (direction) => direction.value == value,
      orElse: () => TrendDirection.stable,
    );
  }
}

/// Leaderboard filter options
class LeaderboardFilter {
  final double? minScore;
  final double? maxScore;
  final int? minSubmissions;
  final List<String>? teamIds;
  final int? topN;

  const LeaderboardFilter({
    this.minScore,
    this.maxScore,
    this.minSubmissions,
    this.teamIds,
    this.topN,
  });

  factory LeaderboardFilter.fromJson(Map<String, dynamic> json) {
    final teamIdsList = json['teamIds'] as List?;
    return LeaderboardFilter(
      minScore: json['minScore'] as double?,
      maxScore: json['maxScore'] as double?,
      minSubmissions: json['minSubmissions'] as int?,
      teamIds: teamIdsList?.cast<String>(),
      topN: json['topN'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minScore': minScore,
      'maxScore': maxScore,
      'minSubmissions': minSubmissions,
      'teamIds': teamIds,
      'topN': topN,
    };
  }

  LeaderboardFilter copyWith({
    double? minScore,
    double? maxScore,
    int? minSubmissions,
    List<String>? teamIds,
    int? topN,
  }) {
    return LeaderboardFilter(
      minScore: minScore ?? this.minScore,
      maxScore: maxScore ?? this.maxScore,
      minSubmissions: minSubmissions ?? this.minSubmissions,
      teamIds: teamIds ?? this.teamIds,
      topN: topN ?? this.topN,
    );
  }
}

/// Leaderboard sort options
class LeaderboardSort {
  final LeaderboardSortField field;
  final bool ascending;

  const LeaderboardSort({
    required this.field,
    this.ascending = false,
  });

  factory LeaderboardSort.fromJson(Map<String, dynamic> json) {
    return LeaderboardSort(
      field: LeaderboardSortField.fromString(json['field'] as String),
      ascending: json['ascending'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field': field.value,
      'ascending': ascending,
    };
  }

  LeaderboardSort copyWith({
    LeaderboardSortField? field,
    bool? ascending,
  }) {
    return LeaderboardSort(
      field: field ?? this.field,
      ascending: ascending ?? this.ascending,
    );
  }
}

/// Leaderboard sort field enumeration
enum LeaderboardSortField {
  averageScore('averageScore'),
  totalScore('totalScore'),
  submissionCount('submissionCount'),
  teamName('teamName');

  const LeaderboardSortField(this.value);
  final String value;

  static LeaderboardSortField fromString(String value) {
    return LeaderboardSortField.values.firstWhere(
      (field) => field.value == value,
      orElse: () => LeaderboardSortField.averageScore,
    );
  }
}