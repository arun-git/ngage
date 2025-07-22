import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/judging_service.dart';
import '../repositories/repository_providers.dart';

/// Provider for the JudgingService
final judgingServiceProvider = Provider<JudgingService>((ref) {
  return JudgingService(
    scoreRepository: ref.read(scoreRepositoryProvider),
    rubricRepository: ref.read(scoringRubricRepositoryProvider),
    submissionRepository: ref.read(submissionRepositoryProvider),
    teamRepository: ref.read(teamRepositoryProvider),
    commentRepository: ref.read(judgeCommentRepositoryProvider),
    assignmentRepository: ref.read(judgeAssignmentRepositoryProvider),
  );
});

/// Provider for getting a specific score by submission and judge
final judgeScoreProvider = FutureProvider.family<Score?, (String, String)>((ref, params) async {
  final (submissionId, judgeId) = params;
  final judgingService = ref.read(judgingServiceProvider);
  return await judgingService.getJudgeScore(submissionId, judgeId);
});

/// Provider for getting all scores for a submission
final submissionScoresProvider = FutureProvider.family<List<Score>, String>((ref, submissionId) async {
  final judgingService = ref.read(judgingServiceProvider);
  return await judgingService.getSubmissionScores(submissionId);
});

/// Provider for getting aggregated scores for a submission
final submissionAggregationProvider = FutureProvider.family<AggregatedScore, String>((ref, submissionId) async {
  final judgingService = ref.read(judgingServiceProvider);
  return await judgingService.calculateSubmissionAggregation(submissionId);
});

/// Provider for getting event leaderboard
final eventLeaderboardProvider = FutureProvider.family<Leaderboard, String>((ref, eventId) async {
  final judgingService = ref.read(judgingServiceProvider);
  return await judgingService.calculateLeaderboard(eventId);
});

/// Provider for getting scoring rubrics for an event
final eventRubricsProvider = FutureProvider.family<List<ScoringRubric>, String>((ref, eventId) async {
  final judgingService = ref.read(judgingServiceProvider);
  return await judgingService.getAvailableRubrics(eventId: eventId);
});

/// Provider for getting a specific scoring rubric
final scoringRubricProvider = FutureProvider.family<ScoringRubric?, String>((ref, rubricId) async {
  final judgingService = ref.read(judgingServiceProvider);
  return await judgingService.getScoringRubric(rubricId);
});

/// Provider for getting template rubrics
final templateRubricsProvider = FutureProvider<List<ScoringRubric>>((ref) async {
  final judgingService = ref.read(judgingServiceProvider);
  return await judgingService.getAvailableRubrics(isTemplate: true);
});

/// Provider for getting group rubrics
final groupRubricsProvider = FutureProvider.family<List<ScoringRubric>, String>((ref, groupId) async {
  final judgingService = ref.read(judgingServiceProvider);
  return await judgingService.getAvailableRubrics(groupId: groupId);
});

/// Provider for checking if a judge has scored a submission
final hasJudgeScoredProvider = FutureProvider.family<bool, (String, String)>((ref, params) async {
  final (submissionId, judgeId) = params;
  final judgingService = ref.read(judgingServiceProvider);
  return await judgingService.hasJudgeScored(submissionId, judgeId);
});

/// Provider for getting event scoring statistics
final eventScoringStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, eventId) async {
  final judgingService = ref.read(judgingServiceProvider);
  return await judgingService.getEventScoringStats(eventId);
});

/// Stream provider for real-time submission scores
final submissionScoresStreamProvider = StreamProvider.family<List<Score>, String>((ref, submissionId) {
  final scoreRepository = ref.read(scoreRepositoryProvider);
  return scoreRepository.streamBySubmissionId(submissionId);
});

/// Stream provider for real-time scoring rubric
final scoringRubricStreamProvider = StreamProvider.family<ScoringRubric?, String>((ref, rubricId) {
  final rubricRepository = ref.read(scoringRubricRepositoryProvider);
  return rubricRepository.streamById(rubricId);
});

/// Provider for creating a new scoring rubric
final createScoringRubricProvider = Provider<Future<ScoringRubric> Function({
  required String name,
  required String description,
  required List<ScoringCriterion> criteria,
  String? eventId,
  String? groupId,
  bool isTemplate,
  required String createdBy,
})>((ref) {
  final judgingService = ref.read(judgingServiceProvider);
  return ({
    required String name,
    required String description,
    required List<ScoringCriterion> criteria,
    String? eventId,
    String? groupId,
    bool isTemplate = false,
    required String createdBy,
  }) async {
    return await judgingService.createScoringRubric(
      name: name,
      description: description,
      criteria: criteria,
      eventId: eventId,
      groupId: groupId,
      isTemplate: isTemplate,
      createdBy: createdBy,
    );
  };
});

/// Provider for cloning a scoring rubric
final cloneRubricProvider = Provider<Future<ScoringRubric> Function({
  required String rubricId,
  required String createdBy,
  String? newName,
  String? newDescription,
  String? eventId,
  String? groupId,
  bool? isTemplate,
})>((ref) {
  final judgingService = ref.read(judgingServiceProvider);
  return ({
    required String rubricId,
    required String createdBy,
    String? newName,
    String? newDescription,
    String? eventId,
    String? groupId,
    bool? isTemplate,
  }) async {
    return await judgingService.cloneRubric(
      rubricId: rubricId,
      createdBy: createdBy,
      newName: newName,
      newDescription: newDescription,
      eventId: eventId,
      groupId: groupId,
      isTemplate: isTemplate,
    );
  };
});

/// Provider for submitting a score
final submitScoreProvider = Provider<Future<Score> Function({
  required String submissionId,
  required String judgeId,
  required String eventId,
  required Map<String, dynamic> scores,
  String? comments,
  ScoringRubric? rubric,
})>((ref) {
  final judgingService = ref.read(judgingServiceProvider);
  return ({
    required String submissionId,
    required String judgeId,
    required String eventId,
    required Map<String, dynamic> scores,
    String? comments,
    ScoringRubric? rubric,
  }) async {
    return await judgingService.scoreSubmission(
      submissionId: submissionId,
      judgeId: judgeId,
      eventId: eventId,
      scores: scores,
      comments: comments,
      rubric: rubric,
    );
  };
});

// ===== JUDGE COLLABORATION PROVIDERS =====

/// Provider for getting judge comments for a submission
final submissionCommentsProvider = FutureProvider.family<List<JudgeComment>, String>((ref, submissionId) async {
  final judgingService = ref.read(judgingServiceProvider);
  return await judgingService.getSubmissionComments(submissionId);
});

/// Stream provider for real-time judge comments
final submissionCommentsStreamProvider = StreamProvider.family<List<JudgeComment>, String>((ref, submissionId) {
  final judgingService = ref.read(judgingServiceProvider);
  return judgingService.streamSubmissionComments(submissionId);
});

/// Provider for getting top-level comments for a submission
final topLevelCommentsProvider = FutureProvider.family<List<JudgeComment>, String>((ref, submissionId) async {
  final judgingService = ref.read(judgingServiceProvider);
  return await judgingService.getTopLevelComments(submissionId);
});

/// Provider for getting comment replies
final commentRepliesProvider = FutureProvider.family<List<JudgeComment>, String>((ref, parentCommentId) async {
  final judgingService = ref.read(judgingServiceProvider);
  return await judgingService.getCommentReplies(parentCommentId);
});

/// Provider for getting judge assignments for an event
final eventJudgeAssignmentsProvider = FutureProvider.family<List<JudgeAssignment>, String>((ref, eventId) async {
  final judgingService = ref.read(judgingServiceProvider);
  return await judgingService.getEventJudges(eventId);
});

/// Stream provider for real-time judge assignments
final eventJudgeAssignmentsStreamProvider = StreamProvider.family<List<JudgeAssignment>, String>((ref, eventId) {
  final judgingService = ref.read(judgingServiceProvider);
  return judgingService.streamEventJudges(eventId);
});

/// Provider for getting judge assignments for a specific judge
final judgeAssignmentsProvider = FutureProvider.family<List<JudgeAssignment>, String>((ref, judgeId) async {
  final judgingService = ref.read(judgingServiceProvider);
  return await judgingService.getJudgeAssignments(judgeId);
});

/// Provider for checking if a judge is assigned to an event
final isJudgeAssignedProvider = FutureProvider.family<bool, (String, String)>((ref, params) async {
  final (eventId, judgeId) = params;
  final judgingService = ref.read(judgingServiceProvider);
  return await judgingService.isJudgeAssigned(eventId, judgeId);
});

/// Provider for checking judge permissions
final judgePermissionProvider = FutureProvider.family<bool, (String, String, String)>((ref, params) async {
  final (eventId, judgeId, permission) = params;
  final judgingService = ref.read(judgingServiceProvider);
  return await judgingService.hasJudgePermission(
    eventId: eventId,
    judgeId: judgeId,
    permission: permission,
  );
});

/// Provider for getting lead judges for an event
final leadJudgesProvider = FutureProvider.family<List<JudgeAssignment>, String>((ref, eventId) async {
  final judgingService = ref.read(judgingServiceProvider);
  return await judgingService.getLeadJudges(eventId);
});

/// Provider for getting regular judges for an event
final regularJudgesProvider = FutureProvider.family<List<JudgeAssignment>, String>((ref, eventId) async {
  final judgingService = ref.read(judgingServiceProvider);
  return await judgingService.getRegularJudges(eventId);
});

/// Provider for available judges (members who can be assigned as judges)
/// This is a placeholder - in a real implementation, this would fetch from member service
final availableJudgesProvider = FutureProvider<List<Member>>((ref) async {
  // TODO: Implement actual logic to get available judges from member service
  // For now, return empty list as placeholder
  return <Member>[];
});