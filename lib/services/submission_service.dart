import 'package:file_picker/file_picker.dart';
import '../models/submission.dart';
import '../models/enums.dart';
import '../repositories/submission_repository.dart';

/// Service for managing submissions with CRUD operations and file upload handling
class SubmissionService {
  final SubmissionRepository _repository;

  SubmissionService(this._repository);

  /// Create a new submission
  Future<Submission> createSubmission({
    required String eventId,
    required String teamId,
    required String submittedBy,
    Map<String, dynamic>? initialContent,
  }) async {
    final now = DateTime.now();
    final submission = Submission(
      id: _generateSubmissionId(),
      eventId: eventId,
      teamId: teamId,
      submittedBy: submittedBy,
      content: initialContent ?? {},
      status: SubmissionStatus.draft,
      createdAt: now,
      updatedAt: now,
    );

    return await _repository.create(submission);
  }

  /// Get submission by ID
  Future<Submission?> getSubmission(String id) async {
    return await _repository.getById(id);
  }

  /// Update submission content
  Future<Submission> updateSubmissionContent({
    required String submissionId,
    required Map<String, dynamic> content,
  }) async {
    final submission = await _repository.getById(submissionId);
    if (submission == null) {
      throw Exception('Submission not found');
    }

    if (!submission.canBeEdited) {
      throw Exception('Cannot edit submission that is not in draft status');
    }

    final updatedSubmission = submission.copyWith(
      content: content,
      updatedAt: DateTime.now(),
    );

    return await _repository.update(updatedSubmission);
  }

  /// Add text content to submission
  Future<Submission> addTextContent({
    required String submissionId,
    required String text,
  }) async {
    final submission = await _repository.getById(submissionId);
    if (submission == null) {
      throw Exception('Submission not found');
    }

    if (!submission.canBeEdited) {
      throw Exception('Cannot edit submission that is not in draft status');
    }

    final updatedSubmission = submission.addTextContent(text);
    return await _repository.update(updatedSubmission);
  }

  /// Upload platform files and add to submission
  Future<Submission> uploadPlatformFiles({
    required String submissionId,
    required List<PlatformFile> files,
    required String fileType, // 'photos', 'videos', 'documents'
    void Function(double progress)? onProgress,
  }) async {
    final submission = await _repository.getById(submissionId);
    if (submission == null) {
      throw Exception('Submission not found');
    }

    if (!submission.canBeEdited) {
      throw Exception('Cannot edit submission that is not in draft status');
    }

    // Validate file type
    if (!['photos', 'videos', 'documents'].contains(fileType)) {
      throw ArgumentError('Invalid file type: $fileType');
    }

    // Upload files to storage
    final urls = await _repository.uploadPlatformFiles(
      submissionId,
      files,
      onProgress,
    );

    // Update submission with new file URLs
    final currentFiles =
        submission.getContent<List>(fileType, [])?.cast<String>() ?? [];
    final updatedFiles = [...currentFiles, ...urls];

    final updatedSubmission = submission.updateContent(fileType, updatedFiles);
    return await _repository.update(updatedSubmission);
  }

  /// Upload single platform file and add to submission
  Future<Submission> uploadPlatformFile({
    required String submissionId,
    required PlatformFile file,
    required String fileType,
  }) async {
    return await uploadPlatformFiles(
      submissionId: submissionId,
      files: [file],
      fileType: fileType,
    );
  }

  /// Remove file from submission
  Future<Submission> removeFile({
    required String submissionId,
    required String fileUrl,
    required String fileType,
  }) async {
    final submission = await _repository.getById(submissionId);
    if (submission == null) {
      throw Exception('Submission not found');
    }

    if (!submission.canBeEdited) {
      throw Exception('Cannot edit submission that is not in draft status');
    }

    final currentFiles =
        submission.getContent<List>(fileType, [])?.cast<String>() ?? [];
    final updatedFiles = currentFiles.where((url) => url != fileUrl).toList();

    final updatedSubmission = submission.updateContent(fileType, updatedFiles);

    // Delete file from storage using download URL
    try {
      await _repository.deleteFile(fileUrl);
    } catch (e) {
      // Log error but don't fail the operation
      print('Warning: Could not delete file from storage: $e');
    }

    return await _repository.update(updatedSubmission);
  }

  /// Submit the submission (change status from draft to submitted)
  Future<Submission> submitSubmission(String submissionId) async {
    final submission = await _repository.getById(submissionId);
    if (submission == null) {
      throw Exception('Submission not found');
    }

    final submittedSubmission = submission.submit();
    return await _repository.update(submittedSubmission);
  }

  /// Update submission status
  Future<Submission> updateSubmissionStatus({
    required String submissionId,
    required SubmissionStatus status,
  }) async {
    final submission = await _repository.getById(submissionId);
    if (submission == null) {
      throw Exception('Submission not found');
    }

    final updatedSubmission = submission.copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );

    return await _repository.update(updatedSubmission);
  }

  /// Get submissions for an event
  Future<List<Submission>> getEventSubmissions(String eventId) async {
    return await _repository.getByEventId(eventId);
  }

  /// Get submissions for a team
  Future<List<Submission>> getTeamSubmissions(String teamId) async {
    return await _repository.getByTeamId(teamId);
  }

  /// Get submissions by a member
  Future<List<Submission>> getMemberSubmissions(String memberId) async {
    return await _repository.getByMemberId(memberId);
  }

  /// Check if team has already submitted for an event
  Future<bool> hasTeamSubmitted(String eventId, String teamId) async {
    return await _repository.hasTeamSubmitted(eventId, teamId);
  }

  /// Check if member has already submitted for an event
  Future<bool> hasMemberSubmitted(String eventId, String memberId) async {
    return await _repository.hasMemberSubmitted(eventId, memberId);
  }

  /// Get submission count for an event
  Future<int> getSubmissionCount(String eventId) async {
    return await _repository.getSubmissionCount(eventId);
  }

  /// Delete submission
  Future<void> deleteSubmission(String submissionId) async {
    final submission = await _repository.getById(submissionId);
    if (submission == null) {
      throw Exception('Submission not found');
    }

    //if (!submission.canBeEdited) {
    //  throw Exception('Cannot delete submission that is not in draft status');
    // }

    await _repository.delete(submissionId);
  }

  /// Stream submissions for real-time updates
  Stream<List<Submission>> streamEventSubmissions(String eventId) {
    return _repository.streamByEventId(eventId);
  }

  /// Stream a specific submission for real-time updates
  Stream<Submission?> streamSubmission(String submissionId) {
    return _repository.streamById(submissionId);
  }

  /// Get submissions with pagination
  Future<List<Submission>> getSubmissionsPaginated({
    String? eventId,
    String? teamId,
    String? lastSubmissionId,
    int limit = 20,
  }) async {
    // Note: This is a simplified version. In a real implementation,
    // you'd need to handle the DocumentSnapshot for pagination
    return await _repository.getSubmissionsPaginated(
      eventId: eventId,
      teamId: teamId,
      limit: limit,
    );
  }

  /// Generate a unique submission ID
  String _generateSubmissionId() {
    return 'sub_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
  }

  /// Generate random string for ID
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(length, (index) => chars[random % chars.length])
        .join();
  }

  /// Extract filename from Firebase Storage URL
  String _extractFileNameFromUrl(String url) {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    if (pathSegments.length >= 2) {
      return pathSegments.last;
    }
    throw Exception('Could not extract filename from URL: $url');
  }
}
