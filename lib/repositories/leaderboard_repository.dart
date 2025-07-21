import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

/// Repository for managing leaderboard data in Firestore
class LeaderboardRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'leaderboards';
  final String _historyCollection = 'score_history';

  LeaderboardRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ===== LEADERBOARD CRUD OPERATIONS =====

  /// Create a new leaderboard
  Future<Leaderboard> create(Leaderboard leaderboard) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(leaderboard.id)
          .set(leaderboard.toJson());
      return leaderboard;
    } catch (e) {
      throw Exception('Failed to create leaderboard: $e');
    }
  }

  /// Get leaderboard by ID
  Future<Leaderboard?> getById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      return Leaderboard.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get leaderboard: $e');
    }
  }

  /// Get latest leaderboard for an event
  Future<Leaderboard?> getLatestByEventId(String eventId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('eventId', isEqualTo: eventId)
          .orderBy('calculatedAt', descending: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return Leaderboard.fromJson(query.docs.first.data());
    } catch (e) {
      throw Exception('Failed to get latest leaderboard: $e');
    }
  }

  /// Get all leaderboards for an event
  Future<List<Leaderboard>> getByEventId(String eventId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('eventId', isEqualTo: eventId)
          .orderBy('calculatedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => Leaderboard.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get leaderboards for event: $e');
    }
  }

  /// Update leaderboard
  Future<Leaderboard> update(Leaderboard leaderboard) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(leaderboard.id)
          .update(leaderboard.toJson());
      return leaderboard;
    } catch (e) {
      throw Exception('Failed to update leaderboard: $e');
    }
  }

  /// Delete leaderboard
  Future<void> delete(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete leaderboard: $e');
    }
  }

  /// Stream leaderboard by ID
  Stream<Leaderboard?> streamById(String id) {
    return _firestore
        .collection(_collection)
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? Leaderboard.fromJson(doc.data()!) : null);
  }

  /// Stream latest leaderboard for an event
  Stream<Leaderboard?> streamLatestByEventId(String eventId) {
    return _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .orderBy('calculatedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((query) => query.docs.isEmpty 
            ? null 
            : Leaderboard.fromJson(query.docs.first.data()));
  }

  /// Stream all leaderboards for an event
  Stream<List<Leaderboard>> streamByEventId(String eventId) {
    return _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .orderBy('calculatedAt', descending: true)
        .snapshots()
        .map((query) => query.docs
            .map((doc) => Leaderboard.fromJson(doc.data()))
            .toList());
  }

  // ===== SCORE HISTORY OPERATIONS =====

  /// Save score history
  Future<ScoreHistory> saveScoreHistory(ScoreHistory history) async {
    try {
      await _firestore
          .collection(_historyCollection)
          .doc('${history.teamId}_${DateTime.now().millisecondsSinceEpoch}')
          .set(history.toJson());
      return history;
    } catch (e) {
      throw Exception('Failed to save score history: $e');
    }
  }

  /// Get score history for a team
  Future<ScoreHistory?> getScoreHistoryByTeamId(String teamId) async {
    try {
      final query = await _firestore
          .collection(_historyCollection)
          .where('teamId', isEqualTo: teamId)
          .orderBy('calculatedAt', descending: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return ScoreHistory.fromJson(query.docs.first.data());
    } catch (e) {
      throw Exception('Failed to get score history: $e');
    }
  }

  /// Get all score histories for a team
  Future<List<ScoreHistory>> getAllScoreHistoriesByTeamId(String teamId) async {
    try {
      final query = await _firestore
          .collection(_historyCollection)
          .where('teamId', isEqualTo: teamId)
          .orderBy('calculatedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => ScoreHistory.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get score histories: $e');
    }
  }

  /// Stream score history for a team
  Stream<ScoreHistory?> streamScoreHistoryByTeamId(String teamId) {
    return _firestore
        .collection(_historyCollection)
        .where('teamId', isEqualTo: teamId)
        .orderBy('calculatedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((query) => query.docs.isEmpty 
            ? null 
            : ScoreHistory.fromJson(query.docs.first.data()));
  }

  // ===== LEADERBOARD SNAPSHOTS =====

  /// Save leaderboard snapshot for historical tracking
  Future<void> saveLeaderboardSnapshot(Leaderboard leaderboard) async {
    try {
      final snapshotId = '${leaderboard.eventId}_${leaderboard.calculatedAt.millisecondsSinceEpoch}';
      await _firestore
          .collection('leaderboard_snapshots')
          .doc(snapshotId)
          .set({
            ...leaderboard.toJson(),
            'snapshotId': snapshotId,
            'isSnapshot': true,
          });
    } catch (e) {
      throw Exception('Failed to save leaderboard snapshot: $e');
    }
  }

  /// Get leaderboard snapshots for an event
  Future<List<Leaderboard>> getLeaderboardSnapshots({
    required String eventId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      var query = _firestore
          .collection('leaderboard_snapshots')
          .where('eventId', isEqualTo: eventId);

      if (startDate != null) {
        query = query.where('calculatedAt', isGreaterThanOrEqualTo: startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.where('calculatedAt', isLessThanOrEqualTo: endDate.toIso8601String());
      }

      query = query.orderBy('calculatedAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final result = await query.get();
      return result.docs
          .map((doc) => Leaderboard.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get leaderboard snapshots: $e');
    }
  }

  // ===== ANALYTICS AND STATISTICS =====

  /// Get leaderboard statistics for an event
  Future<LeaderboardStatistics> getLeaderboardStatistics(String eventId) async {
    try {
      final leaderboards = await getByEventId(eventId);
      
      if (leaderboards.isEmpty) {
        return LeaderboardStatistics(
          eventId: eventId,
          totalSnapshots: 0,
          averageTeamCount: 0.0,
          averageScore: 0.0,
          highestScore: 0.0,
          lowestScore: 0.0,
          calculatedAt: DateTime.now(),
        );
      }

      final totalSnapshots = leaderboards.length;
      final teamCounts = leaderboards.map((l) => l.teamCount).toList();
      final averageTeamCount = teamCounts.fold(0, (a, b) => a + b) / teamCounts.length;

      // Calculate score statistics across all leaderboards
      final allScores = leaderboards
          .expand((l) => l.entries.map((e) => e.averageScore))
          .toList();

      final averageScore = allScores.isNotEmpty 
          ? allScores.fold(0.0, (a, b) => a + b) / allScores.length 
          : 0.0;
      
      final highestScore = allScores.isNotEmpty 
          ? allScores.reduce((a, b) => a > b ? a : b) 
          : 0.0;
      
      final lowestScore = allScores.isNotEmpty 
          ? allScores.reduce((a, b) => a < b ? a : b) 
          : 0.0;

      return LeaderboardStatistics(
        eventId: eventId,
        totalSnapshots: totalSnapshots,
        averageTeamCount: averageTeamCount,
        averageScore: averageScore,
        highestScore: highestScore,
        lowestScore: lowestScore,
        calculatedAt: DateTime.now(),
        metadata: {
          'firstSnapshot': leaderboards.last.calculatedAt.toIso8601String(),
          'lastSnapshot': leaderboards.first.calculatedAt.toIso8601String(),
          'totalScores': allScores.length,
        },
      );
    } catch (e) {
      throw Exception('Failed to get leaderboard statistics: $e');
    }
  }

  /// Get team position history
  Future<PositionHistory> getTeamPositionHistory({
    required String teamId,
    String? eventId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get leaderboard snapshots
      List<Leaderboard> snapshots;
      
      if (eventId != null) {
        snapshots = await getLeaderboardSnapshots(
          eventId: eventId,
          startDate: startDate,
          endDate: endDate,
        );
      } else {
        // Get all snapshots and filter by team
        final allSnapshots = await _firestore
            .collection('leaderboard_snapshots')
            .orderBy('calculatedAt', descending: true)
            .get();
        
        snapshots = allSnapshots.docs
            .map((doc) => Leaderboard.fromJson(doc.data()))
            .where((leaderboard) => 
                leaderboard.entries.any((entry) => entry.teamId == teamId))
            .toList();
      }

      // Extract position history entries
      final List<PositionHistoryEntry> entries = [];
      
      for (final snapshot in snapshots) {
        final teamEntry = snapshot.getEntryByTeam(teamId);
        if (teamEntry != null) {
          // Get event name (placeholder - would need event service)
          final eventName = 'Event ${snapshot.eventId.substring(0, 8)}';
          
          entries.add(PositionHistoryEntry(
            eventId: snapshot.eventId,
            eventName: eventName,
            position: teamEntry.position,
            score: teamEntry.averageScore,
            totalTeams: snapshot.teamCount,
            timestamp: snapshot.calculatedAt,
          ));
        }
      }

      return PositionHistory(
        teamId: teamId,
        entries: entries,
        calculatedAt: DateTime.now(),
        metadata: {
          'totalSnapshots': snapshots.length,
          'entriesWithTeam': entries.length,
          'dateRange': {
            'start': startDate?.toIso8601String(),
            'end': endDate?.toIso8601String(),
          },
        },
      );
    } catch (e) {
      throw Exception('Failed to get team position history: $e');
    }
  }

  // ===== CLEANUP OPERATIONS =====

  /// Delete old leaderboard snapshots
  Future<void> cleanupOldSnapshots({
    required Duration retentionPeriod,
    int? batchSize,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(retentionPeriod);
      final batchSizeLimit = batchSize ?? 100;

      final query = await _firestore
          .collection('leaderboard_snapshots')
          .where('calculatedAt', isLessThan: cutoffDate.toIso8601String())
          .limit(batchSizeLimit)
          .get();

      if (query.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to cleanup old snapshots: $e');
    }
  }

  /// Delete leaderboards for an event
  Future<void> deleteByEventId(String eventId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('eventId', isEqualTo: eventId)
          .get();

      if (query.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete leaderboards for event: $e');
    }
  }
}

/// Leaderboard statistics model
class LeaderboardStatistics {
  final String eventId;
  final int totalSnapshots;
  final double averageTeamCount;
  final double averageScore;
  final double highestScore;
  final double lowestScore;
  final DateTime calculatedAt;
  final Map<String, dynamic> metadata;

  const LeaderboardStatistics({
    required this.eventId,
    required this.totalSnapshots,
    required this.averageTeamCount,
    required this.averageScore,
    required this.highestScore,
    required this.lowestScore,
    required this.calculatedAt,
    this.metadata = const {},
  });

  factory LeaderboardStatistics.fromJson(Map<String, dynamic> json) {
    return LeaderboardStatistics(
      eventId: json['eventId'] as String,
      totalSnapshots: json['totalSnapshots'] as int,
      averageTeamCount: (json['averageTeamCount'] as num).toDouble(),
      averageScore: (json['averageScore'] as num).toDouble(),
      highestScore: (json['highestScore'] as num).toDouble(),
      lowestScore: (json['lowestScore'] as num).toDouble(),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'totalSnapshots': totalSnapshots,
      'averageTeamCount': averageTeamCount,
      'averageScore': averageScore,
      'highestScore': highestScore,
      'lowestScore': lowestScore,
      'calculatedAt': calculatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  LeaderboardStatistics copyWith({
    String? eventId,
    int? totalSnapshots,
    double? averageTeamCount,
    double? averageScore,
    double? highestScore,
    double? lowestScore,
    DateTime? calculatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return LeaderboardStatistics(
      eventId: eventId ?? this.eventId,
      totalSnapshots: totalSnapshots ?? this.totalSnapshots,
      averageTeamCount: averageTeamCount ?? this.averageTeamCount,
      averageScore: averageScore ?? this.averageScore,
      highestScore: highestScore ?? this.highestScore,
      lowestScore: lowestScore ?? this.lowestScore,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get score range
  double get scoreRange => highestScore - lowestScore;

  /// Check if there are multiple snapshots
  bool get hasMultipleSnapshots => totalSnapshots > 1;

  /// Get metadata value
  T? getMetadata<T>(String key, [T? defaultValue]) {
    final value = metadata[key];
    if (value is T) return value;
    return defaultValue;
  }
}