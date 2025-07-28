import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/submission.dart';
import '../services/submission_service.dart';
import '../repositories/submission_repository.dart';

/// Provider for submission service
final submissionServiceProvider = Provider<SubmissionService>((ref) {
  return SubmissionService(ref.watch(submissionRepositoryProvider));
});

/// Provider for submission repository
final submissionRepositoryProvider = Provider((ref) {
  return SubmissionRepository();
});

/// Provider for streaming submissions by event ID
final eventSubmissionsStreamProvider =
    StreamProvider.family<List<Submission>, String>((ref, eventId) {
  final submissionService = ref.watch(submissionServiceProvider);
  return submissionService.streamEventSubmissions(eventId);
});

/// Provider for streaming a specific submission
final submissionStreamProvider =
    StreamProvider.family<Submission?, String>((ref, submissionId) {
  final submissionService = ref.watch(submissionServiceProvider);
  return submissionService.streamSubmission(submissionId);
});

/// Provider for getting submissions by event ID
final eventSubmissionsProvider =
    FutureProvider.family<List<Submission>, String>((ref, eventId) async {
  final submissionService = ref.watch(submissionServiceProvider);
  return submissionService.getEventSubmissions(eventId);
});

/// Provider for getting submissions by team ID
final teamSubmissionsProvider =
    FutureProvider.family<List<Submission>, String>((ref, teamId) async {
  final submissionService = ref.watch(submissionServiceProvider);
  return submissionService.getTeamSubmissions(teamId);
});

/// Provider for getting submissions by member ID
final memberSubmissionsProvider =
    FutureProvider.family<List<Submission>, String>((ref, memberId) async {
  final submissionService = ref.watch(submissionServiceProvider);
  return submissionService.getMemberSubmissions(memberId);
});

/// Provider for checking if a team has submitted for an event
final hasTeamSubmittedProvider =
    FutureProvider.family<bool, ({String eventId, String teamId})>(
        (ref, params) async {
  final submissionService = ref.watch(submissionServiceProvider);
  return submissionService.hasTeamSubmitted(params.eventId, params.teamId);
});

/// Provider for getting submission count for an event
final submissionCountProvider =
    FutureProvider.family<int, String>((ref, eventId) async {
  final submissionService = ref.watch(submissionServiceProvider);
  return submissionService.getSubmissionCount(eventId);
});

/// State notifier for managing submission form state
class SubmissionFormNotifier extends StateNotifier<SubmissionFormState> {
  final SubmissionService _submissionService;
  final Ref _ref;

  SubmissionFormNotifier(this._submissionService, this._ref)
      : super(SubmissionFormState.initial());

  /// Create a new submission
  Future<void> createSubmission({
    required String eventId,
    required String teamId,
    required String submittedBy,
    Map<String, dynamic>? initialContent,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final submission = await _submissionService.createSubmission(
        eventId: eventId,
        teamId: teamId,
        submittedBy: submittedBy,
        initialContent: initialContent,
      );

      state = state.copyWith(
        isLoading: false,
        submission: submission,
        isSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update submission content
  Future<void> updateContent({
    required String submissionId,
    required Map<String, dynamic> content,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final submission = await _submissionService.updateSubmissionContent(
        submissionId: submissionId,
        content: content,
      );

      state = state.copyWith(
        isLoading: false,
        submission: submission,
        isSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Upload platform files
  Future<void> uploadPlatformFiles({
    required String submissionId,
    required List<PlatformFile> files,
    required String fileType,
    void Function(double progress)? onProgress,
  }) async {
    state = state.copyWith(isUploading: true, uploadProgress: 0.0, error: null);

    try {
      final submission = await _submissionService.uploadPlatformFiles(
        submissionId: submissionId,
        files: files,
        fileType: fileType,
        onProgress: (progress) {
          state = state.copyWith(uploadProgress: progress);
          onProgress?.call(progress);
        },
      );

      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        submission: submission,
        isSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        error: e.toString(),
      );
    }
  }

  /// Submit the submission
  Future<void> submitSubmission(String submissionId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final submission =
          await _submissionService.submitSubmission(submissionId);

      // Invalidate relevant providers to refresh data
      _ref.invalidate(eventSubmissionsProvider(submission.eventId));
      _ref.invalidate(eventSubmissionsStreamProvider(submission.eventId));

      state = state.copyWith(
        isLoading: false,
        submission: submission,
        isSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear the current state
  void clearState() {
    state = SubmissionFormState.initial();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear success flag
  void clearSuccess() {
    state = state.copyWith(isSuccess: false);
  }
}

/// State class for submission form
class SubmissionFormState {
  final bool isLoading;
  final bool isUploading;
  final double uploadProgress;
  final bool isSuccess;
  final String? error;
  final Submission? submission;

  const SubmissionFormState({
    required this.isLoading,
    required this.isUploading,
    required this.uploadProgress,
    required this.isSuccess,
    this.error,
    this.submission,
  });

  factory SubmissionFormState.initial() {
    return const SubmissionFormState(
      isLoading: false,
      isUploading: false,
      uploadProgress: 0.0,
      isSuccess: false,
    );
  }

  SubmissionFormState copyWith({
    bool? isLoading,
    bool? isUploading,
    double? uploadProgress,
    bool? isSuccess,
    String? error,
    Submission? submission,
  }) {
    return SubmissionFormState(
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error ?? this.error,
      submission: submission ?? this.submission,
    );
  }
}

/// Provider for submission form state notifier
final submissionFormProvider =
    StateNotifierProvider<SubmissionFormNotifier, SubmissionFormState>((ref) {
  final submissionService = ref.watch(submissionServiceProvider);
  return SubmissionFormNotifier(submissionService, ref);
});
