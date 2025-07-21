import 'dart:math';
import 'package:ngage/repositories/team_repository.dart';

import '../models/models.dart';
import '../repositories/score_repository.dart';
import '../repositories/submission_repository.dart';
import '../repositories/event_repository.dart';
import 'judging_service.dart';

/// Service for managing leaderboards and scoring display
/// 
/// Provides real-time score calculation, ranking, and trend tracking
/// for individual and team leaderboards.
class LeaderboardService {
  final ScoreRepository _scoreRepository;
  final SubmissionRepository _submissionRepository;
  final EventRepository _eventRepository;
  final JudgingService _judgingService;

  LeaderboardService({
    ScoreRepository? scoreRepository,
    SubmissionRepository? submissionRepository,
    EventRepository? eventRepository,
    JudgingService? judgingService, required TeamRepository teamRepository,
  })  : _scoreRepository = scoreRepository ?? ScoreRepository(),
        _submissionRepository = submissionRepository ?? SubmissionRepository(),
        _eventRepository = eventRepository ?? EventRepository(),
        _judgingService = judgingService ?? JudgingService();

  // ===== REAL-TIME LEADERBOARD CALCULATION =====

  /// Calculate real-time leaderboard for an event
  Future<Leaderboard> calculateEventLeaderboard(String eventId) async {
    return await _judgingService.calculateLeaderboard(eventId);
  }

  /// Calculate individual member leaderboard for an event
  Future<IndividualLeaderboard> calculateIndividualLeaderboard(String eventId) async {
    // Get all submissions for the event
    final submissions = await _submissionRepository.getByEventId(eventId);
    final submittedSubmissions = submissions
        .where((s) => s.status == SubmissionStatus.submitted || s.status == SubmissionStatus.approved)
        .toList();
    
    if (submittedSubmissions.isEmpty) {
      return IndividualLeaderboard(
        id: _generateLeaderboardId(),
        eventId: eventId,
        entries: [],
        calculatedAt: DateTime.now(),
      );
    }

    // Get all scores for these submissions
    final submissionIds = submittedSubmissions.map((s) => s.id).toList();
    final scoresBySubmission = await _scoreRepository.getBySubmissionIds(submissionIds);

    // Calculate individual member scores
    final Map<String, IndividualScoreData> memberScores = {};
    
    for (final submission in submittedSubmissions) {
      final submissionScores = scoresBySubmission[submission.id] ?? [];
      
      if (submissionScores.isNotEmpty) {
        final aggregation = await _judgingService.calculateSubmissionAggregation(submission.id);
        final memberId = submission.submittedBy;
        
        if (!memberScores.containsKey(memberId)) {
          memberScores[memberId] = IndividualScoreData(
            memberId: memberId,
            totalScore: 0.0,
            submissionCount: 0,
            criteriaScores: {},
          );
        }
        
        final memberData = memberScores[memberId]!;
        memberData.totalScore += aggregation.averageScore;
        memberData.submissionCount += 1;
        
        // Aggregate criteria scores
        for (final entry in aggregation.criteriaAverages.entries) {
          memberData.criteriaScores.putIfAbsent(entry.key, () => []).add(entry.value);
        }
      }
    }

    // Calculate final member averages and create leaderboard entries
    final List<IndividualLeaderboardEntry> entries = [];
    
    for (final memberData in memberScores.values) {
      // Get member name (placeholder - would need member service)
      final memberName = 'Member ${memberData.memberId.substring(0, 8)}';
      
      // Calculate average score
      final averageScore = memberData.submissionCount > 0 
          ? memberData.totalScore / memberData.submissionCount 
          : 0.0;
      
      // Calculate criteria averages
      final Map<String, double> finalCriteriaScores = {};
      for (final entry in memberData.criteriaScores.entries) {
        final sum = entry.value.fold(0.0, (a, b) => a + b);
        finalCriteriaScores[entry.key] = sum / entry.value.length;
      }
      
      entries.add(IndividualLeaderboardEntry(
        memberId: memberData.memberId,
        memberName: memberName,
        totalScore: memberData.totalScore,
        averageScore: averageScore,
        submissionCount: memberData.submissionCount,
        position: 0, // Will be set after sorting
        criteriaScores: finalCriteriaScores,
      ));
    }

    // Sort by average score (descending) and assign positions
    entries.sort((a, b) => b.averageScore.compareTo(a.averageScore));
    
    final List<IndividualLeaderboardEntry> rankedEntries = [];
    for (int i = 0; i < entries.length; i++) {
      rankedEntries.add(entries[i].copyWith(position: i + 1));
    }

    return IndividualLeaderboard(
      id: _generateLeaderboardId(),
      eventId: eventId,
      entries: rankedEntries,
      calculatedAt: DateTime.now(),
      metadata: {
        'totalSubmissions': submittedSubmissions.length,
        'totalScores': scoresBySubmission.values.expand((scores) => scores).length,
        'membersWithScores': memberScores.length,
      },
    );
  }

  /// Get filtered leaderboard with options
  Future<Leaderboard> getFilteredLeaderboard({
    required String eventId,
    LeaderboardFilter? filter,
    LeaderboardSort? sort,
    int? limit,
    int? offset,
  }) async {
    final baseLeaderboard = await calculateEventLeaderboard(eventId);
    
    var entries = List<LeaderboardEntry>.from(baseLeaderboard.entries);
    
    // Apply filters
    if (filter != null) {
      entries = _applyLeaderboardFilter(entries, filter);
    }
    
    // Apply sorting
    if (sort != null) {
      entries = _applyLeaderboardSort(entries, sort);
    }
    
    // Apply pagination
    if (offset != null) {
      entries = entries.skip(offset).toList();
    }
    if (limit != null) {
      entries = entries.take(limit).toList();
    }
    
    // Recalculate positions after filtering
    final rankedEntries = <LeaderboardEntry>[];
    for (int i = 0; i < entries.length; i++) {
      rankedEntries.add(entries[i].copyWith(position: i + 1));
    }
    
    return baseLeaderboard.copyWith(
      entries: rankedEntries,
      metadata: {
        ...baseLeaderboard.metadata,
        'filtered': filter != null,
        'sorted': sort != null,
        'totalEntries': baseLeaderboard.entries.length,
        'filteredEntries': rankedEntries.length,
      },
    );
  }

  // ===== SCORE HISTORY AND TREND TRACKING =====

  /// Get score history for a team across multiple events
  Future<ScoreHistory> getTeamScoreHistory({
    required String teamId,
    String? groupId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    // Get team's submissions within date range
    final submissions = await _submissionRepository.getByTeamId(teamId);
    
    var filteredSubmissions = submissions;
    
    // Apply date filters
    if (startDate != null) {
      filteredSubmissions = filteredSubmissions
          .where((s) => s.createdAt.isAfter(startDate))
          .toList();
    }
    if (endDate != null) {
      filteredSubmissions = filteredSubmissions
          .where((s) => s.createdAt.isBefore(endDate))
          .toList();
    }
    
    // Apply limit
    if (limit != null) {
      filteredSubmissions = filteredSubmissions.take(limit).toList();
    }
    
    // Get scores for each submission
    final List<ScoreHistoryEntry> entries = [];
    
    for (final submission in filteredSubmissions) {
      final aggregation = await _judgingService.calculateSubmissionAggregation(submission.id);
      
      // Get event details
      final event = await _eventRepository.getEventById(submission.eventId);
      
      entries.add(ScoreHistoryEntry(
        submissionId: submission.id,
        eventId: submission.eventId,
        eventName: event?.title ?? 'Unknown Event',
        score: aggregation.averageScore,
        totalScore: aggregation.totalScore,
        judgeCount: aggregation.judgeCount,
        criteriaScores: aggregation.criteriaAverages,
        submittedAt: submission.submittedAt ?? submission.createdAt,
      ));
    }
    
    // Sort by submission date
    entries.sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
    
    return ScoreHistory(
      teamId: teamId,
      entries: entries,
      calculatedAt: DateTime.now(),
      metadata: {
        'totalSubmissions': submissions.length,
        'filteredSubmissions': filteredSubmissions.length,
        'dateRange': {
          'start': startDate?.toIso8601String(),
          'end': endDate?.toIso8601String(),
        },
      },
    );
  }

  /// Get score trends for a team
  Future<ScoreTrend> getTeamScoreTrend({
    required String teamId,
    String? groupId,
    Duration? period,
    int? dataPoints,
  }) async {
    final history = await getTeamScoreHistory(
      teamId: teamId,
      groupId: groupId,
      startDate: period != null ? DateTime.now().subtract(period) : null,
      limit: dataPoints,
    );
    
    if (history.entries.isEmpty) {
      return ScoreTrend(
        teamId: teamId,
        trendDirection: TrendDirection.stable,
        trendPercentage: 0.0,
        averageScore: 0.0,
        dataPoints: <ScoreTrendPoint>[],
        calculatedAt: DateTime.now(),
      );
    }
    
    // Calculate trend
    final scores = history.entries.map((e) => e.score).toList();
    final trendDirection = _calculateTrendDirection(scores);
    final trendPercentage = _calculateTrendPercentage(scores);
    final averageScore = scores.fold(0.0, (a, b) => a + b) / scores.length;
    
    // Create data points for visualization
    final List<ScoreTrendPoint> trendDataPoints = history.entries.map((entry) => ScoreTrendPoint(
      timestamp: entry.submittedAt,
      score: entry.score,
      eventName: entry.eventName,
      submissionId: entry.submissionId,
    )).toList();
    
    return ScoreTrend(
      teamId: teamId,
      trendDirection: trendDirection,
      trendPercentage: trendPercentage,
      averageScore: averageScore,
      dataPoints: trendDataPoints,
      calculatedAt: DateTime.now(),
      metadata: {
        'period': period?.inDays,
        'totalDataPoints': trendDataPoints.length,
        'highestScore': scores.isNotEmpty ? scores.reduce(max) : 0.0,
        'lowestScore': scores.isNotEmpty ? scores.reduce(min) : 0.0,
      },
    );
  }

  /// Get leaderboard position history for a team
  Future<PositionHistory> getTeamPositionHistory({
    required String teamId,
    String? groupId,
    Duration? period,
  }) async {
    // This would require storing historical leaderboard snapshots
    // For now, return a placeholder implementation
    return PositionHistory(
      teamId: teamId,
      entries: [],
      calculatedAt: DateTime.now(),
    );
  }

  // ===== REAL-TIME UPDATES =====

  /// Stream real-time leaderboard updates
  Stream<Leaderboard> streamEventLeaderboard(String eventId) async* {
    // Initial calculation
    yield await calculateEventLeaderboard(eventId);
    
    // Stream updates when scores change
    // Get submissions for this event and stream their scores
    final submissions = await _submissionRepository.getByEventId(eventId);
    if (submissions.isNotEmpty) {
      final submissionIds = submissions.map((s) => s.id).toList();
      await for (final _ in _scoreRepository.streamBySubmissionId(submissionIds.first)) {
        yield await calculateEventLeaderboard(eventId);
      }
    }
  }

  /// Stream individual leaderboard updates
  Stream<IndividualLeaderboard> streamIndividualLeaderboard(String eventId) async* {
    // Initial calculation
    yield await calculateIndividualLeaderboard(eventId);
    
    // Stream updates when scores change
    // Get submissions for this event and stream their scores
    final submissions = await _submissionRepository.getByEventId(eventId);
    if (submissions.isNotEmpty) {
      final submissionIds = submissions.map((s) => s.id).toList();
      await for (final _ in _scoreRepository.streamBySubmissionId(submissionIds.first)) {
        yield await calculateIndividualLeaderboard(eventId);
      }
    }
  }

  // ===== HELPER METHODS =====

  /// Apply leaderboard filters
  List<LeaderboardEntry> _applyLeaderboardFilter(
    List<LeaderboardEntry> entries,
    LeaderboardFilter filter,
  ) {
    var filtered = entries;
    
    if (filter.minScore != null) {
      filtered = filtered.where((e) => e.averageScore >= filter.minScore!).toList();
    }
    
    if (filter.maxScore != null) {
      filtered = filtered.where((e) => e.averageScore <= filter.maxScore!).toList();
    }
    
    if (filter.minSubmissions != null) {
      filtered = filtered.where((e) => e.submissionCount >= filter.minSubmissions!).toList();
    }
    
    if (filter.teamIds != null && filter.teamIds!.isNotEmpty) {
      filtered = filtered.where((e) => filter.teamIds!.contains(e.teamId)).toList();
    }
    
    if (filter.topN != null) {
      filtered = filtered.take(filter.topN!).toList();
    }
    
    return filtered;
  }

  /// Apply leaderboard sorting
  List<LeaderboardEntry> _applyLeaderboardSort(
    List<LeaderboardEntry> entries,
    LeaderboardSort sort,
  ) {
    switch (sort.field) {
      case LeaderboardSortField.averageScore:
        entries.sort((a, b) => sort.ascending 
            ? a.averageScore.compareTo(b.averageScore)
            : b.averageScore.compareTo(a.averageScore));
        break;
      case LeaderboardSortField.totalScore:
        entries.sort((a, b) => sort.ascending 
            ? a.totalScore.compareTo(b.totalScore)
            : b.totalScore.compareTo(a.totalScore));
        break;
      case LeaderboardSortField.submissionCount:
        entries.sort((a, b) => sort.ascending 
            ? a.submissionCount.compareTo(b.submissionCount)
            : b.submissionCount.compareTo(a.submissionCount));
        break;
      case LeaderboardSortField.teamName:
        entries.sort((a, b) => sort.ascending 
            ? a.teamName.compareTo(b.teamName)
            : b.teamName.compareTo(a.teamName));
        break;
    }
    
    return entries;
  }

  /// Calculate trend direction from score sequence
  TrendDirection _calculateTrendDirection(List<double> scores) {
    if (scores.length < 2) return TrendDirection.stable;
    
    int upward = 0;
    int downward = 0;
    
    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > scores[i - 1]) {
        upward++;
      } else if (scores[i] < scores[i - 1]) {
        downward++;
      }
    }
    
    if (upward > downward) return TrendDirection.upward;
    if (downward > upward) return TrendDirection.downward;
    return TrendDirection.stable;
  }

  /// Calculate trend percentage
  double _calculateTrendPercentage(List<double> scores) {
    if (scores.length < 2) return 0.0;
    
    final firstScore = scores.first;
    final lastScore = scores.last;
    
    if (firstScore == 0) return 0.0;
    
    return ((lastScore - firstScore) / firstScore) * 100;
  }

  /// Generate unique leaderboard ID
  String _generateLeaderboardId() => 
      'leaderboard_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
}

// ===== SUPPORTING CLASSES =====

/// Individual leaderboard for member-based rankings
class IndividualLeaderboard {
  final String id;
  final String eventId;
  final List<IndividualLeaderboardEntry> entries;
  final DateTime calculatedAt;
  final Map<String, dynamic> metadata;

  const IndividualLeaderboard({
    required this.id,
    required this.eventId,
    required this.entries,
    required this.calculatedAt,
    this.metadata = const {},
  });

  factory IndividualLeaderboard.fromJson(Map<String, dynamic> json) {
    final entriesList = json['entries'] as List? ?? [];
    return IndividualLeaderboard(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      entries: entriesList
          .map((e) => IndividualLeaderboardEntry.fromJson(e as Map<String, dynamic>))
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

  IndividualLeaderboard copyWith({
    String? id,
    String? eventId,
    List<IndividualLeaderboardEntry>? entries,
    DateTime? calculatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return IndividualLeaderboard(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      entries: entries ?? this.entries,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get hasEntries => entries.isNotEmpty;
  int get memberCount => entries.length;
  IndividualLeaderboardEntry? get firstPlace => 
      entries.isNotEmpty ? entries.firstWhere((e) => e.position == 1, orElse: () => entries.first) : null;
}

/// Individual leaderboard entry
class IndividualLeaderboardEntry {
  final String memberId;
  final String memberName;
  final double totalScore;
  final double averageScore;
  final int submissionCount;
  final int position;
  final Map<String, double> criteriaScores;

  const IndividualLeaderboardEntry({
    required this.memberId,
    required this.memberName,
    required this.totalScore,
    required this.averageScore,
    required this.submissionCount,
    required this.position,
    this.criteriaScores = const {},
  });

  factory IndividualLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final criteriaScoresMap = json['criteriaScores'] as Map<String, dynamic>? ?? {};
    return IndividualLeaderboardEntry(
      memberId: json['memberId'] as String,
      memberName: json['memberName'] as String,
      totalScore: (json['totalScore'] as num).toDouble(),
      averageScore: (json['averageScore'] as num).toDouble(),
      submissionCount: json['submissionCount'] as int,
      position: json['position'] as int,
      criteriaScores: criteriaScoresMap.map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'totalScore': totalScore,
      'averageScore': averageScore,
      'submissionCount': submissionCount,
      'position': position,
      'criteriaScores': criteriaScores,
    };
  }

  IndividualLeaderboardEntry copyWith({
    String? memberId,
    String? memberName,
    double? totalScore,
    double? averageScore,
    int? submissionCount,
    int? position,
    Map<String, double>? criteriaScores,
  }) {
    return IndividualLeaderboardEntry(
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      totalScore: totalScore ?? this.totalScore,
      averageScore: averageScore ?? this.averageScore,
      submissionCount: submissionCount ?? this.submissionCount,
      position: position ?? this.position,
      criteriaScores: criteriaScores ?? this.criteriaScores,
    );
  }

  bool get isWinningPosition => position <= 3;
  bool get isFirstPlace => position == 1;
}

/// Helper class for individual score calculation
class IndividualScoreData {
  final String memberId;
  double totalScore;
  int submissionCount;
  final Map<String, List<double>> criteriaScores;

  IndividualScoreData({
    required this.memberId,
    required this.totalScore,
    required this.submissionCount,
    required this.criteriaScores,
  });
}