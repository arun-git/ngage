import 'dart:math';
import '../models/models.dart';
import '../repositories/score_repository.dart';
import '../repositories/scoring_rubric_repository.dart';
import '../repositories/submission_repository.dart';
import '../repositories/team_repository.dart';
import '../repositories/judge_comment_repository.dart';
import '../repositories/judge_assignment_repository.dart';

/// Service for managing judging and scoring functionality
class JudgingService {
  final ScoreRepository _scoreRepository;
  final ScoringRubricRepository _rubricRepository;
  final SubmissionRepository _submissionRepository;
  final TeamRepository _teamRepository;
  final JudgeCommentRepository _commentRepository;
  final JudgeAssignmentRepository _assignmentRepository;

  JudgingService({
    ScoreRepository? scoreRepository,
    ScoringRubricRepository? rubricRepository,
    SubmissionRepository? submissionRepository,
    TeamRepository? teamRepository,
    JudgeCommentRepository? commentRepository,
    JudgeAssignmentRepository? assignmentRepository,
  })  : _scoreRepository = scoreRepository ?? ScoreRepository(),
        _rubricRepository = rubricRepository ?? ScoringRubricRepository(),
        _submissionRepository = submissionRepository ?? SubmissionRepository(),
        _teamRepository = teamRepository ?? TeamRepository(),
        _commentRepository = commentRepository ?? JudgeCommentRepository(),
        _assignmentRepository =
            assignmentRepository ?? JudgeAssignmentRepository();

  // ===== JUDGE COLLABORATION FEATURES =====

  /// Create a private judge comment on a submission
  Future<JudgeComment> createJudgeComment({
    required String submissionId,
    required String eventId,
    required String judgeId,
    required String content,
    JudgeCommentType type = JudgeCommentType.general,
    String? parentCommentId,
    bool isPrivate = true,
  }) async {
    // Validate judge is assigned to the event
    await _validateJudgeAssignment(eventId, judgeId);

    final now = DateTime.now();
    final comment = JudgeComment(
      id: _generateCommentId(),
      submissionId: submissionId,
      eventId: eventId,
      judgeId: judgeId,
      content: content,
      type: type,
      parentCommentId: parentCommentId,
      isPrivate: isPrivate,
      createdAt: now,
      updatedAt: now,
    );

    return await _commentRepository.create(comment);
  }

  /// Get all judge comments for a submission
  Future<List<JudgeComment>> getSubmissionComments(String submissionId) async {
    return await _commentRepository.getBySubmissionId(submissionId);
  }

  /// Get threaded comments (replies to a parent comment)
  Future<List<JudgeComment>> getCommentReplies(String parentCommentId) async {
    return await _commentRepository.getReplies(parentCommentId);
  }

  /// Get top-level comments for a submission
  Future<List<JudgeComment>> getTopLevelComments(String submissionId) async {
    return await _commentRepository.getTopLevelComments(submissionId);
  }

  /// Update a judge comment
  Future<JudgeComment> updateJudgeComment({
    required String commentId,
    required String judgeId,
    required String content,
    JudgeCommentType? type,
  }) async {
    final existingComment = await _commentRepository.getById(commentId);
    if (existingComment == null) {
      throw Exception('Comment not found: $commentId');
    }

    // Validate judge owns the comment
    if (existingComment.judgeId != judgeId) {
      throw Exception('Judge can only edit their own comments');
    }

    final updatedComment = existingComment.copyWith(
      content: content,
      type: type,
      updatedAt: DateTime.now(),
    );

    return await _commentRepository.update(updatedComment);
  }

  /// Delete a judge comment
  Future<void> deleteJudgeComment(String commentId, String judgeId) async {
    final existingComment = await _commentRepository.getById(commentId);
    if (existingComment == null) {
      throw Exception('Comment not found: $commentId');
    }

    // Validate judge owns the comment
    if (existingComment.judgeId != judgeId) {
      throw Exception('Judge can only delete their own comments');
    }

    await _commentRepository.delete(commentId);
  }

  /// Stream comments for real-time collaboration
  Stream<List<JudgeComment>> streamSubmissionComments(String submissionId) {
    return _commentRepository.streamBySubmissionId(submissionId);
  }

  /// Stream comments for an event
  Stream<List<JudgeComment>> streamEventComments(String eventId) {
    return _commentRepository.streamByEventId(eventId);
  }

  // ===== JUDGE ASSIGNMENT MANAGEMENT =====

  /// Assign a judge to an event
  Future<JudgeAssignment> assignJudge({
    required String eventId,
    required String judgeId,
    required String assignedBy,
    JudgeRole role = JudgeRole.judge,
    List<String> permissions = const [],
  }) async {
    // Check if judge is already assigned
    final existingAssignment =
        await _assignmentRepository.getAssignment(eventId, judgeId);
    if (existingAssignment != null && existingAssignment.isActive) {
      throw Exception('Judge is already assigned to this event');
    }

    final now = DateTime.now();
    final assignment = JudgeAssignment(
      id: _generateAssignmentId(),
      eventId: eventId,
      judgeId: judgeId,
      assignedBy: assignedBy,
      role: role,
      permissions: permissions,
      isActive: true,
      assignedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    return await _assignmentRepository.create(assignment);
  }

  /// Remove a judge from an event
  Future<JudgeAssignment> removeJudge({
    required String eventId,
    required String judgeId,
  }) async {
    final assignment =
        await _assignmentRepository.getActiveAssignment(eventId, judgeId);
    if (assignment == null) {
      throw Exception('Judge is not assigned to this event');
    }

    final revokedAssignment = assignment.revoke();
    return await _assignmentRepository.update(revokedAssignment);
  }

  /// Get all judges assigned to an event
  Future<List<JudgeAssignment>> getEventJudges(String eventId) async {
    return await _assignmentRepository.getActiveByEventId(eventId);
  }

  /// Get all events a judge is assigned to
  Future<List<JudgeAssignment>> getJudgeAssignments(String judgeId) async {
    return await _assignmentRepository.getActiveByJudgeId(judgeId);
  }

  /// Update judge role and permissions
  Future<JudgeAssignment> updateJudgeAssignment({
    required String eventId,
    required String judgeId,
    JudgeRole? role,
    List<String>? permissions,
  }) async {
    final assignment =
        await _assignmentRepository.getActiveAssignment(eventId, judgeId);
    if (assignment == null) {
      throw Exception('Judge is not assigned to this event');
    }

    final updatedAssignment = assignment.copyWith(
      role: role,
      permissions: permissions,
      updatedAt: DateTime.now(),
    );

    return await _assignmentRepository.update(updatedAssignment);
  }

  /// Add permission to a judge
  Future<JudgeAssignment> addJudgePermission({
    required String eventId,
    required String judgeId,
    required String permission,
  }) async {
    final assignment =
        await _assignmentRepository.getActiveAssignment(eventId, judgeId);
    if (assignment == null) {
      throw Exception('Judge is not assigned to this event');
    }

    final updatedAssignment = assignment.addPermission(permission);
    return await _assignmentRepository.update(updatedAssignment);
  }

  /// Remove permission from a judge
  Future<JudgeAssignment> removeJudgePermission({
    required String eventId,
    required String judgeId,
    required String permission,
  }) async {
    final assignment =
        await _assignmentRepository.getActiveAssignment(eventId, judgeId);
    if (assignment == null) {
      throw Exception('Judge is not assigned to this event');
    }

    final updatedAssignment = assignment.removePermission(permission);
    return await _assignmentRepository.update(updatedAssignment);
  }

  /// Check if a judge has a specific permission
  Future<bool> hasJudgePermission({
    required String eventId,
    required String judgeId,
    required String permission,
  }) async {
    final assignment =
        await _assignmentRepository.getActiveAssignment(eventId, judgeId);
    if (assignment == null) return false;

    return assignment.hasPermission(permission);
  }

  /// Check if a judge is assigned to an event
  Future<bool> isJudgeAssigned(String eventId, String judgeId) async {
    return await _assignmentRepository.isJudgeActivelyAssigned(
        eventId, judgeId);
  }

  /// Get lead judges for an event
  Future<List<JudgeAssignment>> getLeadJudges(String eventId) async {
    return await _assignmentRepository.getLeadJudges(eventId);
  }

  /// Get regular judges for an event
  Future<List<JudgeAssignment>> getRegularJudges(String eventId) async {
    return await _assignmentRepository.getRegularJudges(eventId);
  }

  /// Stream judge assignments for real-time updates
  Stream<List<JudgeAssignment>> streamEventJudges(String eventId) {
    return _assignmentRepository.streamActiveByEventId(eventId);
  }

  // ===== PERMISSION VALIDATION =====

  /// Validate that a judge is assigned to an event
  Future<void> _validateJudgeAssignment(String eventId, String judgeId) async {
    final isAssigned = await isJudgeAssigned(eventId, judgeId);
    if (!isAssigned) {
      throw Exception('Judge is not assigned to this event');
    }
  }

  /// Validate judge permissions for specific actions
  Future<void> validateJudgeAction({
    required String eventId,
    required String judgeId,
    required String action,
  }) async {
    await _validateJudgeAssignment(eventId, judgeId);

    final hasPermission = await hasJudgePermission(
      eventId: eventId,
      judgeId: judgeId,
      permission: action,
    );

    if (!hasPermission) {
      throw Exception('Judge does not have permission for action: $action');
    }
  }

  /// Submit a score for a submission
  Future<Score> scoreSubmission({
    required String submissionId,
    required String judgeId,
    required String eventId,
    required Map<String, dynamic> scores,
    String? comments,
    ScoringRubric? rubric,
  }) async {
    // Validate submission exists
    final submission = await _submissionRepository.getById(submissionId);
    if (submission == null) {
      throw Exception('Submission not found: $submissionId');
    }

    // Check if judge has already scored this submission
    final existingScore = await getJudgeScore(submissionId, judgeId);

    final now = DateTime.now();

    if (existingScore != null) {
      // Update existing score
      final updatedScore = existingScore.copyWith(
        scores: scores,
        comments: comments,
        updatedAt: now,
      );

      // Calculate total score if rubric is provided
      final finalScore = rubric != null
          ? updatedScore.calculateTotalScore(rubric)
          : updatedScore;

      return await _scoreRepository.update(finalScore);
    } else {
      // Create new score
      final newScore = Score(
        id: _generateScoreId(),
        submissionId: submissionId,
        judgeId: judgeId,
        eventId: eventId,
        scores: scores,
        comments: comments,
        createdAt: now,
        updatedAt: now,
      );

      // Calculate total score if rubric is provided
      final finalScore =
          rubric != null ? newScore.calculateTotalScore(rubric) : newScore;

      return await _scoreRepository.create(finalScore);
    }
  }

  /// Get all scores for a submission
  Future<List<Score>> getSubmissionScores(String submissionId) async {
    return await _scoreRepository.getBySubmissionId(submissionId);
  }

  /// Get score by a specific judge for a submission
  Future<Score?> getJudgeScore(String submissionId, String judgeId) async {
    return await _scoreRepository.getBySubmissionAndJudge(
        submissionId, judgeId);
  }

  /// Add private judge comment
  Future<void> addJudgeComment({
    required String submissionId,
    required String judgeId,
    required String eventId,
    required String comment,
  }) async {
    final existingScore = await getJudgeScore(submissionId, judgeId);

    if (existingScore != null) {
      // Update existing score with comment
      final updatedScore = existingScore.copyWith(
        comments: comment,
        updatedAt: DateTime.now(),
      );
      await _scoreRepository.update(updatedScore);
    } else {
      // Create a new score entry with just the comment
      final newScore = Score(
        id: _generateScoreId(),
        submissionId: submissionId,
        judgeId: judgeId,
        eventId: eventId,
        scores: const {}, // Empty scores, just comment
        comments: comment,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _scoreRepository.create(newScore);
    }
  }

  /// Calculate aggregated scores for a submission
  Future<AggregatedScore> calculateSubmissionAggregation(
      String submissionId) async {
    final scores = await _scoreRepository.getBySubmissionId(submissionId);

    if (scores.isEmpty) {
      return AggregatedScore(
        submissionId: submissionId,
        totalScore: 0.0,
        averageScore: 0.0,
        judgeCount: 0,
        criteriaAverages: {},
        scoreRange: const ScoreRange(min: 0.0, max: 0.0),
        individualScores: [],
      );
    }

    // Calculate total scores
    final totalScores = scores
        .where((s) => s.totalScore != null)
        .map((s) => s.totalScore!)
        .toList();

    final totalSum = totalScores.fold(0.0, (a, b) => a + b);
    final averageTotal =
        totalScores.isNotEmpty ? totalSum / totalScores.length : 0.0;

    // Calculate criteria averages
    final Map<String, List<double>> criteriaScores = {};

    for (final score in scores) {
      for (final entry in score.scores.entries) {
        if (entry.value is num) {
          criteriaScores
              .putIfAbsent(entry.key, () => [])
              .add((entry.value as num).toDouble());
        }
      }
    }

    final Map<String, double> criteriaAverages = {};
    for (final entry in criteriaScores.entries) {
      final sum = entry.value.fold(0.0, (a, b) => a + b);
      criteriaAverages[entry.key] = sum / entry.value.length;
    }

    // Calculate score range
    final minScore = totalScores.isNotEmpty ? totalScores.reduce(min) : 0.0;
    final maxScore = totalScores.isNotEmpty ? totalScores.reduce(max) : 0.0;

    return AggregatedScore(
      submissionId: submissionId,
      totalScore: totalSum,
      averageScore: averageTotal,
      judgeCount: scores.length,
      criteriaAverages: criteriaAverages,
      scoreRange: ScoreRange(min: minScore, max: maxScore),
      individualScores: scores,
    );
  }

  /// Calculate leaderboard for an event
  Future<Leaderboard> calculateLeaderboard(String eventId) async {
    // Get all submissions for the event
    final submissions = await _submissionRepository.getByEventId(eventId);
    final submittedSubmissions = submissions
        .where((s) =>
            s.status == SubmissionStatus.submitted ||
            s.status == SubmissionStatus.approved)
        .toList();

    if (submittedSubmissions.isEmpty) {
      return Leaderboard(
        id: _generateLeaderboardId(),
        eventId: eventId,
        entries: [],
        calculatedAt: DateTime.now(),
      );
    }

    // Get all scores for these submissions
    final submissionIds = submittedSubmissions.map((s) => s.id).toList();
    final scoresBySubmission =
        await _scoreRepository.getBySubmissionIds(submissionIds);

    // Calculate team scores
    final Map<String, TeamScoreData> teamScores = {};

    for (final submission in submittedSubmissions) {
      final submissionScores = scoresBySubmission[submission.id] ?? [];

      if (submissionScores.isNotEmpty) {
        final aggregation = await calculateSubmissionAggregation(submission.id);
        final teamId = submission.teamId;

        if (!teamScores.containsKey(teamId)) {
          teamScores[teamId] = TeamScoreData(
            teamId: teamId,
            totalScore: 0.0,
            submissionCount: 0,
            criteriaScores: {},
            submittedBy: <String>{},
          );
        }

        final teamData = teamScores[teamId]!;
        teamData.totalScore += aggregation.averageScore;
        teamData.submissionCount += 1;
        teamData.submittedBy.add(submission.submittedBy); // Track who submitted

        // Aggregate criteria scores
        for (final entry in aggregation.criteriaAverages.entries) {
          teamData.criteriaScores
              .putIfAbsent(entry.key, () => [])
              .add(entry.value);
        }
      }
    }

    // Calculate final team averages and create leaderboard entries
    final List<LeaderboardEntry> entries = [];

    for (final teamData in teamScores.values) {
      // Get team name
      final team = await _teamRepository.getTeamById(teamData.teamId);
      final teamName = team?.name ?? 'Unknown Team';

      // Calculate average score
      final averageScore = teamData.submissionCount > 0
          ? teamData.totalScore / teamData.submissionCount
          : 0.0;

      // Calculate criteria averages
      final Map<String, double> finalCriteriaScores = {};
      for (final entry in teamData.criteriaScores.entries) {
        final sum = entry.value.fold(0.0, (a, b) => a + b);
        finalCriteriaScores[entry.key] = sum / entry.value.length;
      }

      entries.add(LeaderboardEntry(
        teamId: teamData.teamId,
        teamName: teamName,
        totalScore: teamData.totalScore,
        averageScore: averageScore,
        submissionCount: teamData.submissionCount,
        position: 0, // Will be set after sorting
        criteriaScores: finalCriteriaScores,
        submittedBy: teamData.submittedBy.toList(), // Convert Set to List
      ));
    }

    // Sort by average score (descending) and assign positions
    entries.sort((a, b) => b.averageScore.compareTo(a.averageScore));

    final List<LeaderboardEntry> rankedEntries = [];
    for (int i = 0; i < entries.length; i++) {
      rankedEntries.add(entries[i].copyWith(position: i + 1));
    }

    return Leaderboard(
      id: _generateLeaderboardId(),
      eventId: eventId,
      entries: rankedEntries,
      calculatedAt: DateTime.now(),
      metadata: {
        'totalSubmissions': submittedSubmissions.length,
        'totalScores':
            scoresBySubmission.values.expand((scores) => scores).length,
        'teamsWithScores': teamScores.length,
      },
    );
  }

  /// Create a new scoring rubric
  Future<ScoringRubric> createScoringRubric({
    required String name,
    required String description,
    required List<ScoringCriterion> criteria,
    String? eventId,
    String? groupId,
    bool isTemplate = false,
    required String createdBy,
  }) async {
    final now = DateTime.now();
    final rubric = ScoringRubric(
      id: _generateRubricId(),
      name: name,
      description: description,
      criteria: criteria,
      eventId: eventId,
      groupId: groupId,
      isTemplate: isTemplate,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );

    return await _rubricRepository.create(rubric);
  }

  /// Get scoring rubric by ID
  Future<ScoringRubric?> getScoringRubric(String rubricId) async {
    return await _rubricRepository.getById(rubricId);
  }

  /// Get all available rubrics for template reuse
  Future<List<ScoringRubric>> getAvailableRubrics({
    String? eventId,
    String? groupId,
    bool? isTemplate,
    int limit = 50,
  }) async {
    return await _rubricRepository.getRubricsPaginated(
      eventId: eventId,
      groupId: groupId,
      isTemplate: isTemplate,
      limit: limit,
    );
  }

  /// Clone an existing rubric
  Future<ScoringRubric> cloneRubric({
    required String rubricId,
    required String createdBy,
    String? newName,
    String? newDescription,
    String? eventId,
    String? groupId,
    bool? isTemplate,
  }) async {
    return await _rubricRepository.clone(
      rubricId,
      newName: newName,
      newEventId: eventId,
      newGroupId: groupId,
      isTemplate: isTemplate,
      createdBy: createdBy,
    );
  }

  /// Check if a judge has scored a submission
  Future<bool> hasJudgeScored(String submissionId, String judgeId) async {
    final score = await getJudgeScore(submissionId, judgeId);
    return score != null;
  }

  /// Get scoring statistics for an event
  Future<Map<String, dynamic>> getEventScoringStats(String eventId) async {
    final scores = await _scoreRepository.getByEventId(eventId);

    if (scores.isEmpty) {
      return {
        'totalScores': 0,
        'averageScore': 0.0,
        'completedSubmissions': 0,
        'pendingSubmissions': 0,
        'judgeParticipation': <String, int>{},
      };
    }

    final totalScores = scores.length;
    final totalScore = scores.fold<double>(
        0.0, (sum, score) => sum + (score.totalScore ?? 0.0));
    final averageScore = totalScore / totalScores;

    // Count judge participation
    final judgeParticipation = <String, int>{};
    for (final score in scores) {
      judgeParticipation[score.judgeId] =
          (judgeParticipation[score.judgeId] ?? 0) + 1;
    }

    return {
      'totalScores': totalScores,
      'averageScore': averageScore,
      'completedSubmissions': scores.map((s) => s.submissionId).toSet().length,
      'pendingSubmissions': 0, // Would need additional logic to calculate
      'judgeParticipation': judgeParticipation,
    };
  }

  /// Validate score against rubric
  bool validateScoreAgainstRubric(
      Map<String, dynamic> scores, ScoringRubric rubric) {
    // Check if all required criteria are present
    for (final criterion in rubric.criteria) {
      if (criterion.required && !scores.containsKey(criterion.key)) {
        return false;
      }

      // Validate score values
      if (scores.containsKey(criterion.key)) {
        if (!criterion.isValidScore(scores[criterion.key])) {
          return false;
        }
      }
    }

    return true;
  }

  /// Generate unique IDs
  String _generateScoreId() =>
      'score_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  String _generateRubricId() =>
      'rubric_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  String _generateLeaderboardId() =>
      'leaderboard_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  String _generateCommentId() =>
      'comment_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  String _generateAssignmentId() =>
      'assignment_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
}

/// Aggregated score data for a submission
class AggregatedScore {
  final String submissionId;
  final double totalScore;
  final double averageScore;
  final int judgeCount;
  final Map<String, double> criteriaAverages;
  final ScoreRange scoreRange;
  final List<Score> individualScores;

  const AggregatedScore({
    required this.submissionId,
    required this.totalScore,
    required this.averageScore,
    required this.judgeCount,
    required this.criteriaAverages,
    required this.scoreRange,
    required this.individualScores,
  });
}

/// Score range data
class ScoreRange {
  final double min;
  final double max;

  const ScoreRange({
    required this.min,
    required this.max,
  });

  double get range => max - min;
}

/// Helper class for team score calculation
class TeamScoreData {
  final String teamId;
  double totalScore;
  int submissionCount;
  final Map<String, List<double>> criteriaScores;
  final Set<String> submittedBy; // Track unique member IDs who submitted

  TeamScoreData({
    required this.teamId,
    required this.totalScore,
    required this.submissionCount,
    required this.criteriaScores,
    required this.submittedBy,
  });
}
