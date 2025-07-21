import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:ngage/models/submission.dart';
import 'package:ngage/models/enums.dart';
import 'package:ngage/services/submission_service.dart';
import 'package:ngage/repositories/submission_repository.dart';

import 'submission_service_test.mocks.dart';

@GenerateMocks([SubmissionRepository])
void main() {
  group('SubmissionService', () {
    late SubmissionService submissionService;
    late MockSubmissionRepository mockRepository;

    setUp(() {
      mockRepository = MockSubmissionRepository();
      submissionService = SubmissionService(mockRepository);
    });

    group('createSubmission', () {
      test('should create submission successfully with valid data', () async {
        // Arrange
        const eventId = 'event_123';
        const teamId = 'team_123';
        const submittedBy = 'member_123';
        final initialContent = {'text': 'Initial content'};

        when(mockRepository.create(any)).thenAnswer((invocation) async {
          return invocation.positionalArguments[0] as Submission;
        });

        // Act
        final result = await submissionService.createSubmission(
          eventId: eventId,
          teamId: teamId,
          submittedBy: submittedBy,
          initialContent: initialContent,
        );

        // Assert
        expect(result.eventId, equals(eventId));
        expect(result.teamId, equals(teamId));
        expect(result.submittedBy, equals(submittedBy));
        expect(result.content, equals(initialContent));
        expect(result.status, equals(SubmissionStatus.draft));
        expect(result.id, isNotEmpty);
        verify(mockRepository.create(any)).called(1);
      });

      test('should create submission with empty content when not provided', () async {
        // Arrange
        const eventId = 'event_123';
        const teamId = 'team_123';
        const submittedBy = 'member_123';

        when(mockRepository.create(any)).thenAnswer((invocation) async {
          return invocation.positionalArguments[0] as Submission;
        });

        // Act
        final result = await submissionService.createSubmission(
          eventId: eventId,
          teamId: teamId,
          submittedBy: submittedBy,
        );

        // Assert
        expect(result.content, isEmpty);
        expect(result.status, equals(SubmissionStatus.draft));
        verify(mockRepository.create(any)).called(1);
      });
    });

    group('getSubmission', () {
      test('should return submission when it exists', () async {
        // Arrange
        final submission = _createTestSubmission();
        when(mockRepository.getById(submission.id)).thenAnswer((_) async => submission);

        // Act
        final result = await submissionService.getSubmission(submission.id);

        // Assert
        expect(result, equals(submission));
        verify(mockRepository.getById(submission.id)).called(1);
      });

      test('should return null when submission does not exist', () async {
        // Arrange
        const submissionId = 'non_existent';
        when(mockRepository.getById(submissionId)).thenAnswer((_) async => null);

        // Act
        final result = await submissionService.getSubmission(submissionId);

        // Assert
        expect(result, isNull);
        verify(mockRepository.getById(submissionId)).called(1);
      });
    });

    group('updateSubmissionContent', () {
      test('should update content for draft submission', () async {
        // Arrange
        final submission = _createTestSubmission(status: SubmissionStatus.draft);
        final newContent = {'text': 'Updated content', 'photos': ['photo1.jpg']};

        when(mockRepository.getById(submission.id)).thenAnswer((_) async => submission);
        when(mockRepository.update(any)).thenAnswer((invocation) async {
          return invocation.positionalArguments[0] as Submission;
        });

        // Act
        final result = await submissionService.updateSubmissionContent(
          submissionId: submission.id,
          content: newContent,
        );

        // Assert
        expect(result.content, equals(newContent));
        verify(mockRepository.getById(submission.id)).called(1);
        verify(mockRepository.update(any)).called(1);
      });

      test('should throw exception when submission not found', () async {
        // Arrange
        const submissionId = 'non_existent';
        final newContent = {'text': 'Updated content'};

        when(mockRepository.getById(submissionId)).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => submissionService.updateSubmissionContent(
            submissionId: submissionId,
            content: newContent,
          ),
          throwsA(isA<Exception>()),
        );
        verifyNever(mockRepository.update(any));
      });

      test('should throw exception when submission is not in draft status', () async {
        // Arrange
        final submission = _createTestSubmission(status: SubmissionStatus.submitted);
        final newContent = {'text': 'Updated content'};

        when(mockRepository.getById(submission.id)).thenAnswer((_) async => submission);

        // Act & Assert
        expect(
          () => submissionService.updateSubmissionContent(
            submissionId: submission.id,
            content: newContent,
          ),
          throwsA(isA<Exception>()),
        );
        verifyNever(mockRepository.update(any));
      });
    });

    group('addTextContent', () {
      test('should add text content to draft submission', () async {
        // Arrange
        final submission = _createTestSubmission(status: SubmissionStatus.draft);
        const textContent = 'New text content';

        when(mockRepository.getById(submission.id)).thenAnswer((_) async => submission);
        when(mockRepository.update(any)).thenAnswer((invocation) async {
          return invocation.positionalArguments[0] as Submission;
        });

        // Act
        final result = await submissionService.addTextContent(
          submissionId: submission.id,
          text: textContent,
        );

        // Assert
        expect(result.textContent, equals(textContent));
        verify(mockRepository.getById(submission.id)).called(1);
        verify(mockRepository.update(any)).called(1);
      });

      test('should throw exception when submission cannot be edited', () async {
        // Arrange
        final submission = _createTestSubmission(status: SubmissionStatus.submitted);
        const textContent = 'New text content';

        when(mockRepository.getById(submission.id)).thenAnswer((_) async => submission);

        // Act & Assert
        expect(
          () => submissionService.addTextContent(
            submissionId: submission.id,
            text: textContent,
          ),
          throwsA(isA<Exception>()),
        );
        verifyNever(mockRepository.update(any));
      });
    });

    group('uploadFiles', () {
      test('should upload files and update submission for draft submission', () async {
        // Arrange
        final submission = _createTestSubmission(status: SubmissionStatus.draft);
        final files = [File('test1.jpg'), File('test2.jpg')];
        final fileNames = ['test1.jpg', 'test2.jpg'];
        final uploadedUrls = ['url1', 'url2'];
        const fileType = 'photos';

        when(mockRepository.getById(submission.id)).thenAnswer((_) async => submission);
        when(mockRepository.uploadFiles(submission.id, files, fileNames, any))
            .thenAnswer((_) async => uploadedUrls);
        when(mockRepository.update(any)).thenAnswer((invocation) async {
          return invocation.positionalArguments[0] as Submission;
        });

        // Act
        final result = await submissionService.uploadFiles(
          submissionId: submission.id,
          files: files,
          fileNames: fileNames,
          fileType: fileType,
        );

        // Assert
        expect(result.photoUrls, equals(uploadedUrls));
        verify(mockRepository.getById(submission.id)).called(1);
        verify(mockRepository.uploadFiles(submission.id, files, fileNames, any)).called(1);
        verify(mockRepository.update(any)).called(1);
      });

      test('should throw exception for invalid file type', () async {
        // Arrange
        final submission = _createTestSubmission(status: SubmissionStatus.draft);
        final files = [File('test.txt')];
        final fileNames = ['test.txt'];
        const invalidFileType = 'invalid';

        when(mockRepository.getById(submission.id)).thenAnswer((_) async => submission);

        // Act & Assert
        expect(
          () => submissionService.uploadFiles(
            submissionId: submission.id,
            files: files,
            fileNames: fileNames,
            fileType: invalidFileType,
          ),
          throwsA(isA<ArgumentError>()),
        );
        verifyNever(mockRepository.uploadFiles(any, any, any, any));
        verifyNever(mockRepository.update(any));
      });

      test('should throw exception when submission cannot be edited', () async {
        // Arrange
        final submission = _createTestSubmission(status: SubmissionStatus.submitted);
        final files = [File('test.jpg')];
        final fileNames = ['test.jpg'];
        const fileType = 'photos';

        when(mockRepository.getById(submission.id)).thenAnswer((_) async => submission);

        // Act & Assert
        expect(
          () => submissionService.uploadFiles(
            submissionId: submission.id,
            files: files,
            fileNames: fileNames,
            fileType: fileType,
          ),
          throwsA(isA<Exception>()),
        );
        verifyNever(mockRepository.uploadFiles(any, any, any, any));
        verifyNever(mockRepository.update(any));
      });
    });

    group('removeFile', () {
      test('should remove file from draft submission', () async {
        // Arrange
        final submission = _createTestSubmission(
          status: SubmissionStatus.draft,
          content: {
            'photos': ['url1', 'url2', 'url3']
          },
        );
        const fileUrl = 'url2';
        const fileType = 'photos';

        when(mockRepository.getById(submission.id)).thenAnswer((_) async => submission);
        when(mockRepository.deleteFile(submission.id, any)).thenAnswer((_) async {});
        when(mockRepository.update(any)).thenAnswer((invocation) async {
          return invocation.positionalArguments[0] as Submission;
        });

        // Act
        final result = await submissionService.removeFile(
          submissionId: submission.id,
          fileUrl: fileUrl,
          fileType: fileType,
        );

        // Assert
        expect(result.photoUrls, equals(['url1', 'url3']));
        verify(mockRepository.getById(submission.id)).called(1);
        verify(mockRepository.deleteFile(submission.id, any)).called(1);
        verify(mockRepository.update(any)).called(1);
      });

      test('should throw exception when submission cannot be edited', () async {
        // Arrange
        final submission = _createTestSubmission(status: SubmissionStatus.submitted);
        const fileUrl = 'url1';
        const fileType = 'photos';

        when(mockRepository.getById(submission.id)).thenAnswer((_) async => submission);

        // Act & Assert
        expect(
          () => submissionService.removeFile(
            submissionId: submission.id,
            fileUrl: fileUrl,
            fileType: fileType,
          ),
          throwsA(isA<Exception>()),
        );
        verifyNever(mockRepository.deleteFile(any, any));
        verifyNever(mockRepository.update(any));
      });
    });

    group('submitSubmission', () {
      test('should submit draft submission with content', () async {
        // Arrange
        final submission = _createTestSubmission(
          status: SubmissionStatus.draft,
          content: {'text': 'Some content'},
        );

        when(mockRepository.getById(submission.id)).thenAnswer((_) async => submission);
        when(mockRepository.update(any)).thenAnswer((invocation) async {
          return invocation.positionalArguments[0] as Submission;
        });

        // Act
        final result = await submissionService.submitSubmission(submission.id);

        // Assert
        expect(result.status, equals(SubmissionStatus.submitted));
        expect(result.submittedAt, isNotNull);
        verify(mockRepository.getById(submission.id)).called(1);
        verify(mockRepository.update(any)).called(1);
      });

      test('should throw exception when submission not found', () async {
        // Arrange
        const submissionId = 'non_existent';

        when(mockRepository.getById(submissionId)).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => submissionService.submitSubmission(submissionId),
          throwsA(isA<Exception>()),
        );
        verifyNever(mockRepository.update(any));
      });
    });

    group('updateSubmissionStatus', () {
      test('should update submission status', () async {
        // Arrange
        final submission = _createTestSubmission(status: SubmissionStatus.submitted);
        const newStatus = SubmissionStatus.underReview;

        when(mockRepository.getById(submission.id)).thenAnswer((_) async => submission);
        when(mockRepository.update(any)).thenAnswer((invocation) async {
          return invocation.positionalArguments[0] as Submission;
        });

        // Act
        final result = await submissionService.updateSubmissionStatus(
          submissionId: submission.id,
          status: newStatus,
        );

        // Assert
        expect(result.status, equals(newStatus));
        verify(mockRepository.getById(submission.id)).called(1);
        verify(mockRepository.update(any)).called(1);
      });

      test('should throw exception when submission not found', () async {
        // Arrange
        const submissionId = 'non_existent';
        const newStatus = SubmissionStatus.approved;

        when(mockRepository.getById(submissionId)).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => submissionService.updateSubmissionStatus(
            submissionId: submissionId,
            status: newStatus,
          ),
          throwsA(isA<Exception>()),
        );
        verifyNever(mockRepository.update(any));
      });
    });

    group('getEventSubmissions', () {
      test('should return submissions for event', () async {
        // Arrange
        const eventId = 'event_123';
        final submissions = [
          _createTestSubmission(id: 'sub_1', eventId: eventId),
          _createTestSubmission(id: 'sub_2', eventId: eventId),
        ];

        when(mockRepository.getByEventId(eventId)).thenAnswer((_) async => submissions);

        // Act
        final result = await submissionService.getEventSubmissions(eventId);

        // Assert
        expect(result, equals(submissions));
        verify(mockRepository.getByEventId(eventId)).called(1);
      });
    });

    group('getTeamSubmissions', () {
      test('should return submissions for team', () async {
        // Arrange
        const teamId = 'team_123';
        final submissions = [
          _createTestSubmission(id: 'sub_1', teamId: teamId),
          _createTestSubmission(id: 'sub_2', teamId: teamId),
        ];

        when(mockRepository.getByTeamId(teamId)).thenAnswer((_) async => submissions);

        // Act
        final result = await submissionService.getTeamSubmissions(teamId);

        // Assert
        expect(result, equals(submissions));
        verify(mockRepository.getByTeamId(teamId)).called(1);
      });
    });

    group('getMemberSubmissions', () {
      test('should return submissions for member', () async {
        // Arrange
        const memberId = 'member_123';
        final submissions = [
          _createTestSubmission(id: 'sub_1', submittedBy: memberId),
          _createTestSubmission(id: 'sub_2', submittedBy: memberId),
        ];

        when(mockRepository.getByMemberId(memberId)).thenAnswer((_) async => submissions);

        // Act
        final result = await submissionService.getMemberSubmissions(memberId);

        // Assert
        expect(result, equals(submissions));
        verify(mockRepository.getByMemberId(memberId)).called(1);
      });
    });

    group('hasTeamSubmitted', () {
      test('should return true when team has submitted', () async {
        // Arrange
        const eventId = 'event_123';
        const teamId = 'team_123';

        when(mockRepository.hasTeamSubmitted(eventId, teamId)).thenAnswer((_) async => true);

        // Act
        final result = await submissionService.hasTeamSubmitted(eventId, teamId);

        // Assert
        expect(result, isTrue);
        verify(mockRepository.hasTeamSubmitted(eventId, teamId)).called(1);
      });

      test('should return false when team has not submitted', () async {
        // Arrange
        const eventId = 'event_123';
        const teamId = 'team_123';

        when(mockRepository.hasTeamSubmitted(eventId, teamId)).thenAnswer((_) async => false);

        // Act
        final result = await submissionService.hasTeamSubmitted(eventId, teamId);

        // Assert
        expect(result, isFalse);
        verify(mockRepository.hasTeamSubmitted(eventId, teamId)).called(1);
      });
    });

    group('getSubmissionCount', () {
      test('should return submission count for event', () async {
        // Arrange
        const eventId = 'event_123';
        const expectedCount = 5;

        when(mockRepository.getSubmissionCount(eventId)).thenAnswer((_) async => expectedCount);

        // Act
        final result = await submissionService.getSubmissionCount(eventId);

        // Assert
        expect(result, equals(expectedCount));
        verify(mockRepository.getSubmissionCount(eventId)).called(1);
      });
    });

    group('deleteSubmission', () {
      test('should delete draft submission', () async {
        // Arrange
        final submission = _createTestSubmission(status: SubmissionStatus.draft);

        when(mockRepository.getById(submission.id)).thenAnswer((_) async => submission);
        when(mockRepository.delete(submission.id)).thenAnswer((_) async {});

        // Act
        await submissionService.deleteSubmission(submission.id);

        // Assert
        verify(mockRepository.getById(submission.id)).called(1);
        verify(mockRepository.delete(submission.id)).called(1);
      });

      test('should throw exception when submission not found', () async {
        // Arrange
        const submissionId = 'non_existent';

        when(mockRepository.getById(submissionId)).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => submissionService.deleteSubmission(submissionId),
          throwsA(isA<Exception>()),
        );
        verifyNever(mockRepository.delete(any));
      });

      test('should throw exception when submission cannot be edited', () async {
        // Arrange
        final submission = _createTestSubmission(status: SubmissionStatus.submitted);

        when(mockRepository.getById(submission.id)).thenAnswer((_) async => submission);

        // Act & Assert
        expect(
          () => submissionService.deleteSubmission(submission.id),
          throwsA(isA<Exception>()),
        );
        verifyNever(mockRepository.delete(any));
      });
    });

    group('streamEventSubmissions', () {
      test('should return stream of submissions for event', () {
        // Arrange
        const eventId = 'event_123';
        final submissions = [_createTestSubmission(eventId: eventId)];
        final stream = Stream.value(submissions);

        when(mockRepository.streamByEventId(eventId)).thenAnswer((_) => stream);

        // Act
        final result = submissionService.streamEventSubmissions(eventId);

        // Assert
        expect(result, equals(stream));
        verify(mockRepository.streamByEventId(eventId)).called(1);
      });
    });

    group('streamSubmission', () {
      test('should return stream of specific submission', () {
        // Arrange
        final submission = _createTestSubmission();
        final stream = Stream.value(submission);

        when(mockRepository.streamById(submission.id)).thenAnswer((_) => stream);

        // Act
        final result = submissionService.streamSubmission(submission.id);

        // Assert
        expect(result, equals(stream));
        verify(mockRepository.streamById(submission.id)).called(1);
      });
    });
  });
}

/// Helper function to create test submissions
Submission _createTestSubmission({
  String? id,
  String? eventId,
  String? teamId,
  String? submittedBy,
  Map<String, dynamic>? content,
  SubmissionStatus? status,
  DateTime? submittedAt,
}) {
  final now = DateTime.now();
  return Submission(
    id: id ?? 'test_submission_123',
    eventId: eventId ?? 'event_123',
    teamId: teamId ?? 'team_123',
    submittedBy: submittedBy ?? 'member_123',
    content: content ?? {},
    status: status ?? SubmissionStatus.draft,
    submittedAt: submittedAt,
    createdAt: now,
    updatedAt: now,
  );
}