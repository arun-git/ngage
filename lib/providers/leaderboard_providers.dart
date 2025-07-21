import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/leaderboard_service.dart';
import '../repositories/leaderboard_repository.dart';
import '../repositories/repository_providers.dart';
import 'judging_providers.dart';

/// Provider for the LeaderboardRepository
final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository();
});

/// Provider for the LeaderboardService
final leaderboardServiceProvider = Provider<LeaderboardService>((ref) {
  return LeaderboardService(
    scoreRepository: ref.read(scoreRepositoryProvider),
    submissionRepository: ref.read(submissionRepositoryProvider),
    teamRepository: ref.read(teamRepositoryProvider),
    eventRepository: ref.read(eventRepositoryProvider),
    judgingService: ref.read(judgingServiceProvider),
  );
});

// ===== LEADERBOARD PROVIDERS =====

/// Provider for getting event leaderboard
final eventLeaderboardProvider =
    FutureProvider.family<Leaderboard, String>((ref, eventId) async {
  final leaderboardService = ref.read(leaderboardServiceProvider);
  return await leaderboardService.calculateEventLeaderboard(eventId);
});

/// Provider for getting individual leaderboard
final individualLeaderboardProvider =
    FutureProvider.family<IndividualLeaderboard, String>((ref, eventId) async {
  final leaderboardService = ref.read(leaderboardServiceProvider);
  return await leaderboardService.calculateIndividualLeaderboard(eventId);
});

/// Provider for getting filtered leaderboard
final filteredLeaderboardProvider =
    FutureProvider.family<Leaderboard, LeaderboardRequest>(
        (ref, request) async {
  final leaderboardService = ref.read(leaderboardServiceProvider);
  return await leaderboardService.getFilteredLeaderboard(
    eventId: request.eventId,
    filter: request.filter,
    sort: request.sort,
    limit: request.limit,
    offset: request.offset,
  );
});

/// Stream provider for real-time event leaderboard
final eventLeaderboardStreamProvider =
    StreamProvider.family<Leaderboard, String>((ref, eventId) {
  final leaderboardService = ref.read(leaderboardServiceProvider);
  return leaderboardService.streamEventLeaderboard(eventId);
});

/// Stream provider for real-time individual leaderboard
final individualLeaderboardStreamProvider =
    StreamProvider.family<IndividualLeaderboard, String>((ref, eventId) {
  final leaderboardService = ref.read(leaderboardServiceProvider);
  return leaderboardService.streamIndividualLeaderboard(eventId);
});

/// Provider for getting leaderboard from repository
final storedLeaderboardProvider =
    FutureProvider.family<Leaderboard?, String>((ref, eventId) async {
  final repository = ref.read(leaderboardRepositoryProvider);
  return await repository.getLatestByEventId(eventId);
});

/// Stream provider for stored leaderboard
final storedLeaderboardStreamProvider =
    StreamProvider.family<Leaderboard?, String>((ref, eventId) {
  final repository = ref.read(leaderboardRepositoryProvider);
  return repository.streamLatestByEventId(eventId);
});

// ===== SCORE HISTORY PROVIDERS =====

/// Provider for getting team score history
final teamScoreHistoryProvider =
    FutureProvider.family<ScoreHistory, ScoreHistoryRequest>(
        (ref, request) async {
  final leaderboardService = ref.read(leaderboardServiceProvider);
  return await leaderboardService.getTeamScoreHistory(
    teamId: request.teamId,
    groupId: request.groupId,
    startDate: request.startDate,
    endDate: request.endDate,
    limit: request.limit,
  );
});

/// Provider for getting team score trend
final teamScoreTrendProvider =
    FutureProvider.family<ScoreTrend, ScoreTrendRequest>((ref, request) async {
  final leaderboardService = ref.read(leaderboardServiceProvider);
  return await leaderboardService.getTeamScoreTrend(
    teamId: request.teamId,
    groupId: request.groupId,
    period: request.period,
    dataPoints: request.dataPoints,
  );
});

/// Provider for getting team position history
final teamPositionHistoryProvider =
    FutureProvider.family<PositionHistory, PositionHistoryRequest>(
        (ref, request) async {
  final repository = ref.read(leaderboardRepositoryProvider);
  return await repository.getTeamPositionHistory(
    teamId: request.teamId,
    eventId: request.eventId,
    startDate: request.startDate,
    endDate: request.endDate,
  );
});

/// Stream provider for team score history
final teamScoreHistoryStreamProvider =
    StreamProvider.family<ScoreHistory?, String>((ref, teamId) {
  final repository = ref.read(leaderboardRepositoryProvider);
  return repository.streamScoreHistoryByTeamId(teamId);
});

// ===== LEADERBOARD STATISTICS PROVIDERS =====

/// Provider for getting leaderboard statistics
final leaderboardStatisticsProvider =
    FutureProvider.family<LeaderboardStatistics, String>((ref, eventId) async {
  final repository = ref.read(leaderboardRepositoryProvider);
  return await repository.getLeaderboardStatistics(eventId);
});

/// Provider for getting leaderboard snapshots
final leaderboardSnapshotsProvider =
    FutureProvider.family<List<Leaderboard>, LeaderboardSnapshotRequest>(
        (ref, request) async {
  final repository = ref.read(leaderboardRepositoryProvider);
  return await repository.getLeaderboardSnapshots(
    eventId: request.eventId,
    startDate: request.startDate,
    endDate: request.endDate,
    limit: request.limit,
  );
});

// ===== ACTION PROVIDERS =====

/// Provider for saving leaderboard
final saveLeaderboardProvider =
    Provider<Future<Leaderboard> Function(Leaderboard)>((ref) {
  final repository = ref.read(leaderboardRepositoryProvider);
  return (leaderboard) async {
    return await repository.create(leaderboard);
  };
});

/// Provider for saving leaderboard snapshot
final saveLeaderboardSnapshotProvider =
    Provider<Future<void> Function(Leaderboard)>((ref) {
  final repository = ref.read(leaderboardRepositoryProvider);
  return (leaderboard) async {
    await repository.saveLeaderboardSnapshot(leaderboard);
  };
});

/// Provider for saving score history
final saveScoreHistoryProvider =
    Provider<Future<ScoreHistory> Function(ScoreHistory)>((ref) {
  final repository = ref.read(leaderboardRepositoryProvider);
  return (history) async {
    return await repository.saveScoreHistory(history);
  };
});

/// Provider for refreshing leaderboard
final refreshLeaderboardProvider =
    Provider<Future<Leaderboard> Function(String)>((ref) {
  final leaderboardService = ref.read(leaderboardServiceProvider);
  return (eventId) async {
    // Invalidate cached leaderboard
    ref.invalidate(eventLeaderboardProvider(eventId));

    // Calculate fresh leaderboard
    return await leaderboardService.calculateEventLeaderboard(eventId);
  };
});

// ===== REQUEST MODELS =====

/// Request model for leaderboard filtering and sorting
class LeaderboardRequest {
  final String eventId;
  final LeaderboardFilter? filter;
  final LeaderboardSort? sort;
  final int? limit;
  final int? offset;

  const LeaderboardRequest({
    required this.eventId,
    this.filter,
    this.sort,
    this.limit,
    this.offset,
  });

  LeaderboardRequest copyWith({
    String? eventId,
    LeaderboardFilter? filter,
    LeaderboardSort? sort,
    int? limit,
    int? offset,
  }) {
    return LeaderboardRequest(
      eventId: eventId ?? this.eventId,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaderboardRequest &&
        other.eventId == eventId &&
        other.filter == filter &&
        other.sort == sort &&
        other.limit == limit &&
        other.offset == offset;
  }

  @override
  int get hashCode {
    return Object.hash(eventId, filter, sort, limit, offset);
  }
}

/// Request model for score history
class ScoreHistoryRequest {
  final String teamId;
  final String? groupId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? limit;

  const ScoreHistoryRequest({
    required this.teamId,
    this.groupId,
    this.startDate,
    this.endDate,
    this.limit,
  });

  ScoreHistoryRequest copyWith({
    String? teamId,
    String? groupId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) {
    return ScoreHistoryRequest(
      teamId: teamId ?? this.teamId,
      groupId: groupId ?? this.groupId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      limit: limit ?? this.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScoreHistoryRequest &&
        other.teamId == teamId &&
        other.groupId == groupId &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    return Object.hash(teamId, groupId, startDate, endDate, limit);
  }
}

/// Request model for score trend
class ScoreTrendRequest {
  final String teamId;
  final String? groupId;
  final Duration? period;
  final int? dataPoints;

  const ScoreTrendRequest({
    required this.teamId,
    this.groupId,
    this.period,
    this.dataPoints,
  });

  ScoreTrendRequest copyWith({
    String? teamId,
    String? groupId,
    Duration? period,
    int? dataPoints,
  }) {
    return ScoreTrendRequest(
      teamId: teamId ?? this.teamId,
      groupId: groupId ?? this.groupId,
      period: period ?? this.period,
      dataPoints: dataPoints ?? this.dataPoints,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScoreTrendRequest &&
        other.teamId == teamId &&
        other.groupId == groupId &&
        other.period == period &&
        other.dataPoints == dataPoints;
  }

  @override
  int get hashCode {
    return Object.hash(teamId, groupId, period, dataPoints);
  }
}

/// Request model for position history
class PositionHistoryRequest {
  final String teamId;
  final String? eventId;
  final DateTime? startDate;
  final DateTime? endDate;

  const PositionHistoryRequest({
    required this.teamId,
    this.eventId,
    this.startDate,
    this.endDate,
  });

  PositionHistoryRequest copyWith({
    String? teamId,
    String? eventId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return PositionHistoryRequest(
      teamId: teamId ?? this.teamId,
      eventId: eventId ?? this.eventId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PositionHistoryRequest &&
        other.teamId == teamId &&
        other.eventId == eventId &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    return Object.hash(teamId, eventId, startDate, endDate);
  }
}

/// Request model for leaderboard snapshots
class LeaderboardSnapshotRequest {
  final String eventId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? limit;

  const LeaderboardSnapshotRequest({
    required this.eventId,
    this.startDate,
    this.endDate,
    this.limit,
  });

  LeaderboardSnapshotRequest copyWith({
    String? eventId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) {
    return LeaderboardSnapshotRequest(
      eventId: eventId ?? this.eventId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      limit: limit ?? this.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaderboardSnapshotRequest &&
        other.eventId == eventId &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    return Object.hash(eventId, startDate, endDate, limit);
  }
}
