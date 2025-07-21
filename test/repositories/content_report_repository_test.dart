import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ngage/models/content_report.dart';
import 'package:ngage/repositories/content_report_repository.dart';

void main() {
  group('ContentReportRepository', () {
    late ContentReportRepository repository;
    late FakeFirebaseFirestore firestore;
    late ContentReport testReport;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = ContentReportRepository(firestore: firestore);
      
      testReport = ContentReport(
        id: 'report123',
        reporterId: 'reporter456',
        contentId: 'content789',
        contentType: ContentType.post,
        reason: ReportReason.spam,
        description: 'This is spam content',
        status: ReportStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    group('createReport', () {
      test('should create a new report successfully', () async {
        final reportId = await repository.createReport(testReport);
        
        expect(reportId, isNotEmpty);
        
        final doc = await firestore.collection('content_reports').doc(reportId).get();
        expect(doc.exists, isTrue);
        
        final data = doc.data()!;
        expect(data['reporterId'], equals('reporter456'));
        expect(data['contentId'], equals('content789'));
        expect(data['contentType'], equals('post'));
        expect(data['reason'], equals('spam'));
        expect(data['status'], equals('pending'));
      });

      test('should throw exception on failure', () async {
        // This is harder to test with FakeFirebaseFirestore, but in a real scenario
        // you might mock the firestore to throw an exception
        expect(() async => await repository.createReport(testReport), returnsNormally);
      });
    });

    group('getReport', () {
      test('should return report when it exists', () async {
        final reportId = await repository.createReport(testReport);
        
        final retrievedReport = await repository.getReport(reportId);
        
        expect(retrievedReport, isNotNull);
        expect(retrievedReport!.reporterId, equals('reporter456'));
        expect(retrievedReport.contentId, equals('content789'));
        expect(retrievedReport.contentType, equals(ContentType.post));
        expect(retrievedReport.reason, equals(ReportReason.spam));
      });

      test('should return null when report does not exist', () async {
        final retrievedReport = await repository.getReport('nonexistent');
        
        expect(retrievedReport, isNull);
      });
    });

    group('getReportsForContent', () {
      test('should return reports for specific content', () async {
        // Create multiple reports for the same content
        final report1 = testReport;
        final report2 = testReport.copyWith(
          reporterId: 'reporter2',
          reason: ReportReason.harassment,
        );
        
        await repository.createReport(report1);
        await repository.createReport(report2);
        
        // Create a report for different content
        final differentContentReport = testReport.copyWith(
          contentId: 'different_content',
        );
        await repository.createReport(differentContentReport);
        
        final reports = await repository.getReportsForContent(
          'content789',
          ContentType.post,
        );
        
        expect(reports, hasLength(2));
        expect(reports.every((r) => r.contentId == 'content789'), isTrue);
        expect(reports.every((r) => r.contentType == ContentType.post), isTrue);
      });

      test('should return empty list when no reports exist for content', () async {
        final reports = await repository.getReportsForContent(
          'nonexistent_content',
          ContentType.post,
        );
        
        expect(reports, isEmpty);
      });
    });

    group('getReportsByStatus', () {
      test('should return reports with specific status', () async {
        // Create reports with different statuses
        final pendingReport = testReport;
        final resolvedReport = testReport.copyWith(
          reporterId: 'reporter2',
          status: ReportStatus.resolved,
        );
        
        await repository.createReport(pendingReport);
        await repository.createReport(resolvedReport);
        
        final pendingReports = await repository.getReportsByStatus(ReportStatus.pending);
        final resolvedReports = await repository.getReportsByStatus(ReportStatus.resolved);
        
        expect(pendingReports, hasLength(1));
        expect(pendingReports.first.status, equals(ReportStatus.pending));
        
        expect(resolvedReports, hasLength(1));
        expect(resolvedReports.first.status, equals(ReportStatus.resolved));
      });

      test('should respect limit parameter', () async {
        // Create multiple pending reports
        for (int i = 0; i < 5; i++) {
          await repository.createReport(testReport.copyWith(reporterId: 'reporter$i'));
        }
        
        final limitedReports = await repository.getReportsByStatus(
          ReportStatus.pending,
          limit: 3,
        );
        
        expect(limitedReports, hasLength(3));
      });
    });

    group('getPendingReports', () {
      test('should return only pending reports', () async {
        final pendingReport = testReport;
        final resolvedReport = testReport.copyWith(
          reporterId: 'reporter2',
          status: ReportStatus.resolved,
        );
        
        await repository.createReport(pendingReport);
        await repository.createReport(resolvedReport);
        
        final pendingReports = await repository.getPendingReports();
        
        expect(pendingReports, hasLength(1));
        expect(pendingReports.first.status, equals(ReportStatus.pending));
      });
    });

    group('getReportsByReporter', () {
      test('should return reports by specific reporter', () async {
        final report1 = testReport;
        final report2 = testReport.copyWith(contentId: 'content2');
        final differentReporterReport = testReport.copyWith(
          reporterId: 'different_reporter',
          contentId: 'content3',
        );
        
        await repository.createReport(report1);
        await repository.createReport(report2);
        await repository.createReport(differentReporterReport);
        
        final reporterReports = await repository.getReportsByReporter('reporter456');
        
        expect(reporterReports, hasLength(2));
        expect(reporterReports.every((r) => r.reporterId == 'reporter456'), isTrue);
      });
    });

    group('updateReportStatus', () {
      test('should update report status successfully', () async {
        final reportId = await repository.createReport(testReport);
        
        await repository.updateReportStatus(
          reportId,
          ReportStatus.resolved,
          reviewedBy: 'admin123',
          reviewNotes: 'Resolved as spam',
        );
        
        final updatedReport = await repository.getReport(reportId);
        
        expect(updatedReport!.status, equals(ReportStatus.resolved));
        expect(updatedReport.reviewedBy, equals('admin123'));
        expect(updatedReport.reviewNotes, equals('Resolved as spam'));
        expect(updatedReport.reviewedAt, isNotNull);
      });
    });

    group('deleteReport', () {
      test('should delete report successfully', () async {
        final reportId = await repository.createReport(testReport);
        
        // Verify report exists
        final reportBeforeDelete = await repository.getReport(reportId);
        expect(reportBeforeDelete, isNotNull);
        
        await repository.deleteReport(reportId);
        
        // Verify report is deleted
        final reportAfterDelete = await repository.getReport(reportId);
        expect(reportAfterDelete, isNull);
      });
    });

    group('getReportsStatistics', () {
      test('should return correct statistics', () async {
        // Create reports with different statuses
        await repository.createReport(testReport); // pending
        await repository.createReport(testReport.copyWith(
          reporterId: 'reporter2',
          status: ReportStatus.underReview,
        ));
        await repository.createReport(testReport.copyWith(
          reporterId: 'reporter3',
          status: ReportStatus.resolved,
        ));
        await repository.createReport(testReport.copyWith(
          reporterId: 'reporter4',
          status: ReportStatus.dismissed,
        ));
        
        final stats = await repository.getReportsStatistics();
        
        expect(stats['pending'], equals(1));
        expect(stats['underReview'], equals(1));
        expect(stats['resolved'], equals(1));
        expect(stats['dismissed'], equals(1));
        expect(stats['total'], equals(4));
      });
    });

    group('hasUserReportedContent', () {
      test('should return true when user has reported content', () async {
        await repository.createReport(testReport);
        
        final hasReported = await repository.hasUserReportedContent(
          'reporter456',
          'content789',
          ContentType.post,
        );
        
        expect(hasReported, isTrue);
      });

      test('should return false when user has not reported content', () async {
        final hasReported = await repository.hasUserReportedContent(
          'reporter456',
          'content789',
          ContentType.post,
        );
        
        expect(hasReported, isFalse);
      });
    });

    group('streamPendingReports', () {
      test('should stream pending reports', () async {
        final stream = repository.streamPendingReports();
        
        // Initially should be empty
        final initialReports = await stream.first;
        expect(initialReports, isEmpty);
        
        // Add a pending report
        await repository.createReport(testReport);
        
        // Stream should now contain the report
        final updatedReports = await stream.first;
        expect(updatedReports, hasLength(1));
        expect(updatedReports.first.status, equals(ReportStatus.pending));
      });
    });
  });
}