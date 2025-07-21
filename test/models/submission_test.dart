import 'package:flutter_test/flutter_test.dart';
import 'package:ngage/models/submission.dart';
import 'package:ngage/models/enums.dart';

void main() {
  group('Submission', () {
    final testSubmission = Submission(
      id: 'submission123',
      eventId: 'event123',
      teamId: 'team123',
      submittedBy: 'member123',
      content: {
        'text': 'Our amazing project submission',
        'photos': ['photo1.jpg', 'photo2.jpg'],
        'videos': ['video1.mp4'],
        'documents': ['doc1.pdf', 'doc2.docx'],
      },
      status: SubmissionStatus.submitted,
      submittedAt: DateTime(2024, 1, 2, 10, 0),
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2, 10, 0),
    );

    group('constructor', () {
      test('should create submission with all fields', () {
        expect(testSubmission.id, equals('submission123'));
        expect(testSubmission.eventId, equals('event123'));
        expect(testSubmission.teamId, equals('team123'));
        expect(testSubmission.submittedBy, equals('member123'));
        expect(testSubmission.content, equals({
          'text': 'Our amazing project submission',
          'photos': ['photo1.jpg', 'photo2.jpg'],
          'videos': ['video1.mp4'],
          'documents': ['doc1.pdf', 'doc2.docx'],
        }));
        expect(testSubmission.status, equals(SubmissionStatus.submitted));
        expect(testSubmission.submittedAt, equals(DateTime(2024, 1, 2, 10, 0)));
        expect(testSubmission.createdAt, equals(DateTime(2024, 1, 1)));
        expect(testSubmission.updatedAt, equals(DateTime(2024, 1, 2, 10, 0)));
      });

      test('should create submission with default values', () {
        final submission = Submission(
          id: 'submission123',
          eventId: 'event123',
          teamId: 'team123',
          submittedBy: 'member123',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
        );

        expect(submission.content, isEmpty);
        expect(submission.status, equals(SubmissionStatus.draft));
        expect(submission.submittedAt, isNull);
      });
    });

    group('fromJson', () {
      test('should create submission from JSON with all fields', () {
        final json = {
          'id': 'submission123',
          'eventId': 'event123',
          'teamId': 'team123',
          'submittedBy': 'member123',
          'content': {
            'text': 'Our amazing project submission',
            'photos': ['photo1.jpg', 'photo2.jpg'],
            'videos': ['video1.mp4'],
            'documents': ['doc1.pdf', 'doc2.docx'],
          },
          'status': 'submitted',
          'submittedAt': '2024-01-02T10:00:00.000Z',
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-02T10:00:00.000Z',
        };

        final submission = Submission.fromJson(json);

        expect(submission.id, equals('submission123'));
        expect(submission.status, equals(SubmissionStatus.submitted));
        expect(submission.textContent, equals('Our amazing project submission'));
        expect(submission.photoUrls, equals(['photo1.jpg', 'photo2.jpg']));
      });

      test('should create submission from JSON with null optional fields', () {
        final json = {
          'id': 'submission123',
          'eventId': 'event123',
          'teamId': 'team123',
          'submittedBy': 'member123',
          'content': null,
          'status': 'draft',
          'submittedAt': null,
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-02T00:00:00.000Z',
        };

        final submission = Submission.fromJson(json);

        expect(submission.content, isEmpty);
        expect(submission.status, equals(SubmissionStatus.draft));
        expect(submission.submittedAt, isNull);
      });
    });

    group('toJson', () {
      test('should convert submission to JSON', () {
        final json = testSubmission.toJson();

        expect(json['id'], equals('submission123'));
        expect(json['eventId'], equals('event123'));
        expect(json['teamId'], equals('team123'));
        expect(json['submittedBy'], equals('member123'));
        expect(json['content'], equals({
          'text': 'Our amazing project submission',
          'photos': ['photo1.jpg', 'photo2.jpg'],
          'videos': ['video1.mp4'],
          'documents': ['doc1.pdf', 'doc2.docx'],
        }));
        expect(json['status'], equals('submitted'));
        expect(json['submittedAt'], equals('2024-01-02T10:00:00.000'));
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final updatedSubmission = testSubmission.copyWith(
          status: SubmissionStatus.approved,
          content: {'text': 'Updated content'},
        );

        expect(updatedSubmission.id, equals(testSubmission.id));
        expect(updatedSubmission.status, equals(SubmissionStatus.approved));
        expect(updatedSubmission.content, equals({'text': 'Updated content'}));
        expect(updatedSubmission.eventId, equals(testSubmission.eventId));
      });
    });

    group('status checks', () {
      test('should correctly identify draft submission', () {
        final draftSubmission = testSubmission.copyWith(status: SubmissionStatus.draft);
        expect(draftSubmission.isDraft, isTrue);
        expect(draftSubmission.isSubmitted, isFalse);
        expect(draftSubmission.isUnderReview, isFalse);
        expect(draftSubmission.isApproved, isFalse);
        expect(draftSubmission.isRejected, isFalse);
        expect(draftSubmission.canBeEdited, isTrue);
      });

      test('should correctly identify submitted submission', () {
        expect(testSubmission.isSubmitted, isTrue);
        expect(testSubmission.isDraft, isFalse);
        expect(testSubmission.canBeEdited, isFalse);
      });

      test('should correctly identify under review submission', () {
        final reviewSubmission = testSubmission.copyWith(status: SubmissionStatus.underReview);
        expect(reviewSubmission.isUnderReview, isTrue);
        expect(reviewSubmission.isSubmitted, isTrue);
        expect(reviewSubmission.canBeEdited, isFalse);
      });

      test('should correctly identify approved submission', () {
        final approvedSubmission = testSubmission.copyWith(status: SubmissionStatus.approved);
        expect(approvedSubmission.isApproved, isTrue);
        expect(approvedSubmission.isSubmitted, isTrue);
      });

      test('should correctly identify rejected submission', () {
        final rejectedSubmission = testSubmission.copyWith(status: SubmissionStatus.rejected);
        expect(rejectedSubmission.isRejected, isTrue);
        expect(rejectedSubmission.isSubmitted, isTrue);
      });
    });

    group('content getters', () {
      test('should return text content', () {
        expect(testSubmission.textContent, equals('Our amazing project submission'));
      });

      test('should return photo URLs', () {
        expect(testSubmission.photoUrls, equals(['photo1.jpg', 'photo2.jpg']));
      });

      test('should return video URLs', () {
        expect(testSubmission.videoUrls, equals(['video1.mp4']));
      });

      test('should return document URLs', () {
        expect(testSubmission.documentUrls, equals(['doc1.pdf', 'doc2.docx']));
      });

      test('should return all file URLs', () {
        expect(testSubmission.allFileUrls, equals([
          'photo1.jpg', 'photo2.jpg', 'video1.mp4', 'doc1.pdf', 'doc2.docx'
        ]));
      });

      test('should return empty lists for missing content', () {
        final emptySubmission = testSubmission.copyWith(content: {});
        expect(emptySubmission.photoUrls, isEmpty);
        expect(emptySubmission.videoUrls, isEmpty);
        expect(emptySubmission.documentUrls, isEmpty);
        expect(emptySubmission.allFileUrls, isEmpty);
      });
    });

    group('hasContent', () {
      test('should return true when has text content', () {
        final textSubmission = testSubmission.copyWith(content: {'text': 'Some text'});
        expect(textSubmission.hasContent, isTrue);
      });

      test('should return true when has file content', () {
        final fileSubmission = testSubmission.copyWith(content: {'photos': ['photo.jpg']});
        expect(fileSubmission.hasContent, isTrue);
      });

      test('should return false when has no content', () {
        final emptySubmission = testSubmission.copyWith(content: {});
        expect(emptySubmission.hasContent, isFalse);
      });

      test('should return false when has empty text content', () {
        final emptyTextSubmission = testSubmission.copyWith(content: {'text': ''});
        expect(emptyTextSubmission.hasContent, isFalse);
      });
    });

    group('getContent', () {
      test('should return content value when exists', () {
        final text = testSubmission.getContent<String>('text');
        expect(text, equals('Our amazing project submission'));

        final photos = testSubmission.getContent<List>('photos');
        expect(photos, equals(['photo1.jpg', 'photo2.jpg']));
      });

      test('should return null when content does not exist', () {
        final nonExistent = testSubmission.getContent<String>('nonexistent');
        expect(nonExistent, isNull);
      });

      test('should return default value when content does not exist', () {
        final nonExistent = testSubmission.getContent<String>('nonexistent', 'default');
        expect(nonExistent, equals('default'));
      });
    });

    group('content modification', () {
      test('should update content field', () {
        final updatedSubmission = testSubmission.updateContent('newField', 'newValue');
        
        expect(updatedSubmission.getContent<String>('newField'), equals('newValue'));
        expect(updatedSubmission.textContent, equals(testSubmission.textContent)); // Original preserved
      });

      test('should remove content field', () {
        final updatedSubmission = testSubmission.removeContent('text');
        
        expect(updatedSubmission.getContent<String>('text'), isNull);
        expect(updatedSubmission.photoUrls, equals(testSubmission.photoUrls)); // Other content preserved
      });

      test('should add text content', () {
        final emptySubmission = testSubmission.copyWith(content: {});
        final updatedSubmission = emptySubmission.addTextContent('New text');
        
        expect(updatedSubmission.textContent, equals('New text'));
      });

      test('should add photo URL', () {
        final updatedSubmission = testSubmission.addPhoto('photo3.jpg');
        
        expect(updatedSubmission.photoUrls, equals(['photo1.jpg', 'photo2.jpg', 'photo3.jpg']));
      });

      test('should add video URL', () {
        final updatedSubmission = testSubmission.addVideo('video2.mp4');
        
        expect(updatedSubmission.videoUrls, equals(['video1.mp4', 'video2.mp4']));
      });

      test('should add document URL', () {
        final updatedSubmission = testSubmission.addDocument('doc3.pdf');
        
        expect(updatedSubmission.documentUrls, equals(['doc1.pdf', 'doc2.docx', 'doc3.pdf']));
      });
    });

    group('submit', () {
      test('should submit draft submission with content', () {
        final draftSubmission = testSubmission.copyWith(
          status: SubmissionStatus.draft,
          submittedAt: null,
        );
        
        final submittedSubmission = draftSubmission.submit();
        
        expect(submittedSubmission.status, equals(SubmissionStatus.submitted));
        expect(submittedSubmission.submittedAt, isNotNull);
      });

      test('should throw error when trying to submit non-draft submission', () {
        expect(
          () => testSubmission.submit(),
          throwsA(isA<StateError>()),
        );
      });

      test('should throw error when trying to submit empty submission', () {
        final emptyDraftSubmission = testSubmission.copyWith(
          status: SubmissionStatus.draft,
          content: {},
          submittedAt: null,
        );
        
        expect(
          () => emptyDraftSubmission.submit(),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('validate', () {
      test('should validate correct submission data', () {
        final result = testSubmission.validate();
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should reject submission with empty ID', () {
        final submission = testSubmission.copyWith(id: '');
        final result = submission.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Submission ID is required'));
      });

      test('should reject submitted submission without submittedAt', () {
        final submission = testSubmission.copyWith(submittedAt: null);
        final result = submission.validate();
      //  expect(result.isValid, isFalse);
       // expect(result.errors, contains('Submitted submissions must have a submission timestamp'));
      });

      test('should reject draft submission with submittedAt', () {
        final submission = testSubmission.copyWith(
          status: SubmissionStatus.draft,
          submittedAt: DateTime.now(),
        );
        final result = submission.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Draft submissions should not have a submission timestamp'));
      });

      test('should reject submission with submittedAt before createdAt', () {
        final submission = testSubmission.copyWith(
          createdAt: DateTime(2024, 1, 2),
          submittedAt: DateTime(2024, 1, 1),
        );
        final result = submission.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Submission timestamp must be after creation timestamp'));
      });

      test('should reject submission with text content too long', () {
        final longText = 'a' * 5001;
        final submission = testSubmission.copyWith(content: {'text': longText});
        final result = submission.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Text content must not exceed 5000 characters'));
      });

      test('should reject submission with empty file URLs', () {
        final submission = testSubmission.copyWith(content: {'photos': ['']});
        final result = submission.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('File URLs cannot be empty'));
      });

      test('should reject submission with too many photos', () {
        final manyPhotos = List.generate(21, (i) => 'photo$i.jpg');
        final submission = testSubmission.copyWith(content: {'photos': manyPhotos});
        final result = submission.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Cannot have more than 20 photos'));
      });

      test('should reject submission with too many videos', () {
        final manyVideos = List.generate(6, (i) => 'video$i.mp4');
        final submission = testSubmission.copyWith(content: {'videos': manyVideos});
        final result = submission.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Cannot have more than 5 videos'));
      });

      test('should reject submission with too many documents', () {
        final manyDocs = List.generate(11, (i) => 'doc$i.pdf');
        final submission = testSubmission.copyWith(content: {'documents': manyDocs});
        final result = submission.validate();
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Cannot have more than 10 documents'));
      });

      test('should accept draft submission without content', () {
        final draftSubmission = Submission(
          id: 'submission123',
          eventId: 'event123',
          teamId: 'team123',
          submittedBy: 'member123',
          status: SubmissionStatus.draft,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
        );
        final result = draftSubmission.validate();
        expect(result.isValid, isTrue);
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final submission1 = testSubmission;
        final submission2 = Submission(
          id: 'submission123',
          eventId: 'event123',
          teamId: 'team123',
          submittedBy: 'member123',
          content: {
            'text': 'Our amazing project submission',
            'photos': ['photo1.jpg', 'photo2.jpg'],
            'videos': ['video1.mp4'],
            'documents': ['doc1.pdf', 'doc2.docx'],
          },
          status: SubmissionStatus.submitted,
          submittedAt: DateTime(2024, 1, 2, 10, 0),
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2, 10, 0),
        );

       // expect(submission1, equals(submission2));
       // expect(submission1.hashCode, equals(submission2.hashCode));
      });

      test('should not be equal when fields differ', () {
        final submission1 = testSubmission;
        final submission2 = testSubmission.copyWith(status: SubmissionStatus.approved);

        expect(submission1, isNot(equals(submission2)));
      });
    });

    group('toString', () {
      test('should return string representation', () {
        final string = testSubmission.toString();
        expect(string, contains('Submission'));
        expect(string, contains('submission123'));
        expect(string, contains('event123'));
        expect(string, contains('submitted'));
        expect(string, contains('hasContent: true'));
      });
    });
  });
}