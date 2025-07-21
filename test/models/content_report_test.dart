import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ngage/models/content_report.dart';

void main() {
  group('ContentReport', () {
    late ContentReport testReport;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime.now();
      testReport = ContentReport(
        id: 'report123',
        reporterId: 'reporter456',
        contentId: 'content789',
        contentType: ContentType.post,
        reason: ReportReason.spam,
        description: 'This is spam content',
        status: ReportStatus.pending,
        createdAt: testDate,
        updatedAt: testDate,
      );
    });

    test('should create ContentReport with required fields', () {
      expect(testReport.id, equals('report123'));
      expect(testReport.reporterId, equals('reporter456'));
      expect(testReport.contentId, equals('content789'));
      expect(testReport.contentType, equals(ContentType.post));
      expect(testReport.reason, equals(ReportReason.spam));
      expect(testReport.status, equals(ReportStatus.pending));
    });

    test('should create ContentReport with optional fields', () {
      expect(testReport.description, equals('This is spam content'));
      expect(testReport.reviewedBy, isNull);
      expect(testReport.reviewNotes, isNull);
      expect(testReport.reviewedAt, isNull);
    });

    test('should convert to Firestore format correctly', () {
      final firestoreData = testReport.toFirestore();

      expect(firestoreData['reporterId'], equals('reporter456'));
      expect(firestoreData['contentId'], equals('content789'));
      expect(firestoreData['contentType'], equals('post'));
      expect(firestoreData['reason'], equals('spam'));
      expect(firestoreData['description'], equals('This is spam content'));
      expect(firestoreData['status'], equals('pending'));
      expect(firestoreData['reviewedBy'], isNull);
      expect(firestoreData['reviewNotes'], isNull);
      expect(firestoreData['reviewedAt'], isNull);
      expect(firestoreData['createdAt'], isA<Timestamp>());
      expect(firestoreData['updatedAt'], isA<Timestamp>());
    });

    test('should create from Firestore document correctly', () async {
      final firestore = FakeFirebaseFirestore();
      final docRef = firestore.collection('reports').doc('report123');
      
      await docRef.set({
        'reporterId': 'reporter456',
        'contentId': 'content789',
        'contentType': 'post',
        'reason': 'spam',
        'description': 'This is spam content',
        'status': 'pending',
        'reviewedBy': null,
        'reviewNotes': null,
        'reviewedAt': null,
        'createdAt': Timestamp.fromDate(testDate),
        'updatedAt': Timestamp.fromDate(testDate),
      });

      final doc = await docRef.get();
      final report = ContentReport.fromFirestore(doc);

      expect(report.id, equals('report123'));
      expect(report.reporterId, equals('reporter456'));
      expect(report.contentId, equals('content789'));
      expect(report.contentType, equals(ContentType.post));
      expect(report.reason, equals(ReportReason.spam));
      expect(report.description, equals('This is spam content'));
      expect(report.status, equals(ReportStatus.pending));
    });

    test('should create copyWith correctly', () {
      final updatedReport = testReport.copyWith(
        status: ReportStatus.resolved,
        reviewedBy: 'admin123',
        reviewNotes: 'Resolved as spam',
        reviewedAt: testDate.add(const Duration(hours: 1)),
      );

      expect(updatedReport.id, equals(testReport.id));
      expect(updatedReport.reporterId, equals(testReport.reporterId));
      expect(updatedReport.status, equals(ReportStatus.resolved));
      expect(updatedReport.reviewedBy, equals('admin123'));
      expect(updatedReport.reviewNotes, equals('Resolved as spam'));
      expect(updatedReport.reviewedAt, equals(testDate.add(const Duration(hours: 1))));
    });

    test('should handle equality correctly', () {
      final sameReport = ContentReport(
        id: 'report123',
        reporterId: 'reporter456',
        contentId: 'content789',
        contentType: ContentType.post,
        reason: ReportReason.spam,
        description: 'This is spam content',
        status: ReportStatus.pending,
        createdAt: testDate,
        updatedAt: testDate,
      );

      final differentReport = testReport.copyWith(id: 'different123');

      expect(testReport, equals(sameReport));
      expect(testReport, isNot(equals(differentReport)));
    });

    test('should generate correct hashCode', () {
      final sameReport = ContentReport(
        id: 'report123',
        reporterId: 'reporter456',
        contentId: 'content789',
        contentType: ContentType.post,
        reason: ReportReason.spam,
        description: 'This is spam content',
        status: ReportStatus.pending,
        createdAt: testDate,
        updatedAt: testDate,
      );

      expect(testReport.hashCode, equals(sameReport.hashCode));
    });

    test('should generate correct toString', () {
      final stringRepresentation = testReport.toString();
      
      expect(stringRepresentation, contains('ContentReport'));
      expect(stringRepresentation, contains('report123'));
      expect(stringRepresentation, contains('reporter456'));
      expect(stringRepresentation, contains('content789'));
      expect(stringRepresentation, contains('post'));
      expect(stringRepresentation, contains('spam'));
      expect(stringRepresentation, contains('pending'));
    });

    group('Enums', () {
      test('ReportReason should have all expected values', () {
        expect(ReportReason.values, hasLength(6));
        expect(ReportReason.values, contains(ReportReason.spam));
        expect(ReportReason.values, contains(ReportReason.harassment));
        expect(ReportReason.values, contains(ReportReason.inappropriateContent));
        expect(ReportReason.values, contains(ReportReason.copyright));
        expect(ReportReason.values, contains(ReportReason.misinformation));
        expect(ReportReason.values, contains(ReportReason.other));
      });

      test('ReportStatus should have all expected values', () {
        expect(ReportStatus.values, hasLength(4));
        expect(ReportStatus.values, contains(ReportStatus.pending));
        expect(ReportStatus.values, contains(ReportStatus.underReview));
        expect(ReportStatus.values, contains(ReportStatus.resolved));
        expect(ReportStatus.values, contains(ReportStatus.dismissed));
      });

      test('ContentType should have all expected values', () {
        expect(ContentType.values, hasLength(3));
        expect(ContentType.values, contains(ContentType.post));
        expect(ContentType.values, contains(ContentType.comment));
        expect(ContentType.values, contains(ContentType.submission));
      });
    });
  });
}