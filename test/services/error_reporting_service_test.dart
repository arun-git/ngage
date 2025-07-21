import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mockito/annotations.dart';

import 'package:ngage/services/error_reporting_service.dart';
import 'package:ngage/utils/logger.dart';
import 'package:ngage/utils/error_types.dart';

import 'error_reporting_service_test.mocks.dart';

@GenerateMocks([Logger])
void main() {
  group('ErrorReportingService', () {
    late ErrorReportingService service;
    late FakeFirebaseFirestore fakeFirestore;
    late MockLogger mockLogger;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockLogger = MockLogger();
      service = ErrorReportingService(
        firestore: fakeFirestore,
        logger: mockLogger,
      );
    });

    group('Submit Error Report', () {
      test('should submit error report successfully', () async {
        final report = await service.submitErrorReport(
          userId: 'test-user',
          memberId: 'test-member',
          title: 'Test Bug Report',
          description: 'This is a test bug report',
          type: ErrorReportType.bug,
          priority: ErrorReportPriority.medium,
        );

        expect(report.userId, equals('test-user'));
        expect(report.memberId, equals('test-member'));
        expect(report.title, equals('Test Bug Report'));
        expect(report.description, equals('This is a test bug report'));
        expect(report.type, equals(ErrorReportType.bug));
        expect(report.priority, equals(ErrorReportPriority.medium));
        expect(report.status, equals(ErrorReportStatus.open));

        // Verify it was saved to Firestore
        final doc = await fakeFirestore
            .collection('error_reports')
            .doc(report.id)
            .get();
        expect(doc.exists, isTrue);
      });

      test('should submit error report with technical details', () async {
        final technicalDetails = {
          'error': 'NullPointerException',
          'stackTrace': 'Stack trace here',
          'platform': 'android',
        };

        final report = await service.submitErrorReport(
          userId: 'test-user',
          title: 'Crash Report',
          description: 'App crashed unexpectedly',
          type: ErrorReportType.crash,
          priority: ErrorReportPriority.high,
          technicalDetails: technicalDetails,
        );

        expect(report.technicalDetails, equals(technicalDetails));
      });

      test('should submit error report with attachments', () async {
        final attachments = ['screenshot1.png', 'log.txt'];

        final report = await service.submitErrorReport(
          userId: 'test-user',
          title: 'UI Issue',
          description: 'Button not working',
          type: ErrorReportType.ui,
          attachments: attachments,
        );

        expect(report.attachments, equals(attachments));
      });
    });

    group('Submit Automatic Error Report', () {
      test('should submit automatic error report from exception', () async {
        final error = Exception('Test error');
        final stackTrace = StackTrace.current;

        final report = await service.submitAutomaticErrorReport(
          userId: 'test-user',
          memberId: 'test-member',
          error: error,
          stackTrace: stackTrace,
          context: 'test context',
          additionalData: {'key': 'value'},
        );

        expect(report, isNotNull);
        expect(report!.title, contains('Automatic Error Report'));
        expect(report.description, contains(error.toString()));
        expect(report.technicalDetails, isNotNull);
        expect(report.technicalDetails!['error'], equals(error.toString()));
        expect(report.technicalDetails!['context'], equals('test context'));
        expect(report.technicalDetails!['additionalData'], equals({'key': 'value'}));
      });

      test('should categorize authentication errors correctly', () async {
        const error = AuthenticationException(
          'Invalid credentials',
          authErrorType: AuthErrorType.invalidCredentials,
        );

        final report = await service.submitAutomaticErrorReport(
          userId: 'test-user',
          error: error,
          stackTrace: StackTrace.current,
        );

        expect(report!.type, equals(ErrorReportType.bug));
        expect(report.priority, equals(ErrorReportPriority.high));
      });

      test('should categorize network errors correctly', () async {
        const error = NetworkException(
          'Connection failed',
          networkErrorType: NetworkErrorType.connectionTimeout,
        );

        final report = await service.submitAutomaticErrorReport(
          userId: 'test-user',
          error: error,
          stackTrace: StackTrace.current,
        );

        expect(report!.type, equals(ErrorReportType.bug));
        expect(report.priority, equals(ErrorReportPriority.medium));
      });
    });

    group('Get Error Reports', () {
      test('should get user error reports', () async {
        // Submit some reports
        await service.submitErrorReport(
          userId: 'test-user',
          title: 'Report 1',
          description: 'Description 1',
          type: ErrorReportType.bug,
        );

        await service.submitErrorReport(
          userId: 'test-user',
          title: 'Report 2',
          description: 'Description 2',
          type: ErrorReportType.feature,
        );

        await service.submitErrorReport(
          userId: 'other-user',
          title: 'Report 3',
          description: 'Description 3',
          type: ErrorReportType.bug,
        );

        final userReports = await service.getUserErrorReports('test-user');
        
        expect(userReports.length, equals(2));
        expect(userReports.every((r) => r.userId == 'test-user'), isTrue);
      });

      test('should get error report by ID', () async {
        final report = await service.submitErrorReport(
          userId: 'test-user',
          title: 'Test Report',
          description: 'Test Description',
          type: ErrorReportType.bug,
        );

        final retrievedReport = await service.getErrorReport(report.id);
        
        expect(retrievedReport, isNotNull);
        expect(retrievedReport!.id, equals(report.id));
        expect(retrievedReport.title, equals('Test Report'));
      });

      test('should return null for non-existent report', () async {
        final report = await service.getErrorReport('non-existent-id');
        expect(report, isNull);
      });
    });

    group('Update Error Report Status', () {
      test('should update error report status', () async {
        final report = await service.submitErrorReport(
          userId: 'test-user',
          title: 'Test Report',
          description: 'Test Description',
          type: ErrorReportType.bug,
        );

        await service.updateErrorReportStatus(
          report.id,
          ErrorReportStatus.inProgress,
          assignedTo: 'admin-user',
        );

        final updatedReport = await service.getErrorReport(report.id);
        
        expect(updatedReport!.status, equals(ErrorReportStatus.inProgress));
        expect(updatedReport.assignedTo, equals('admin-user'));
      });

      test('should update error report with resolution', () async {
        final report = await service.submitErrorReport(
          userId: 'test-user',
          title: 'Test Report',
          description: 'Test Description',
          type: ErrorReportType.bug,
        );

        await service.updateErrorReportStatus(
          report.id,
          ErrorReportStatus.resolved,
          resolution: 'Fixed in version 1.2.0',
        );

        final updatedReport = await service.getErrorReport(report.id);
        
        expect(updatedReport!.status, equals(ErrorReportStatus.resolved));
        expect(updatedReport.resolution, equals('Fixed in version 1.2.0'));
      });
    });

    group('Error Report Statistics', () {
      test('should get error report statistics', () async {
        // Submit various reports
        await service.submitErrorReport(
          userId: 'user1',
          title: 'Bug 1',
          description: 'Description',
          type: ErrorReportType.bug,
          priority: ErrorReportPriority.high,
        );

        await service.submitErrorReport(
          userId: 'user2',
          title: 'Feature 1',
          description: 'Description',
          type: ErrorReportType.feature,
          priority: ErrorReportPriority.low,
        );

        await service.submitErrorReport(
          userId: 'user3',
          title: 'Bug 2',
          description: 'Description',
          type: ErrorReportType.bug,
          priority: ErrorReportPriority.medium,
        );

        final stats = await service.getErrorReportStatistics();
        
        expect(stats['total'], equals(3));
        expect(stats['byType']['bug'], equals(2));
        expect(stats['byType']['feature'], equals(1));
        expect(stats['byPriority']['high'], equals(1));
        expect(stats['byPriority']['medium'], equals(1));
        expect(stats['byPriority']['low'], equals(1));
        expect(stats['byStatus']['open'], equals(3));
      });
    });

    group('Error Report Serialization', () {
      test('should serialize and deserialize error reports', () async {
        final originalReport = await service.submitErrorReport(
          userId: 'test-user',
          memberId: 'test-member',
          title: 'Test Report',
          description: 'Test Description',
          type: ErrorReportType.bug,
          priority: ErrorReportPriority.high,
          technicalDetails: {'key': 'value'},
          attachments: ['file1.txt'],
        );

        final json = originalReport.toJson();
        final deserializedReport = ErrorReport.fromJson(json);

        expect(deserializedReport.id, equals(originalReport.id));
        expect(deserializedReport.userId, equals(originalReport.userId));
        expect(deserializedReport.memberId, equals(originalReport.memberId));
        expect(deserializedReport.title, equals(originalReport.title));
        expect(deserializedReport.description, equals(originalReport.description));
        expect(deserializedReport.type, equals(originalReport.type));
        expect(deserializedReport.priority, equals(originalReport.priority));
        expect(deserializedReport.technicalDetails, equals(originalReport.technicalDetails));
        expect(deserializedReport.attachments, equals(originalReport.attachments));
        expect(deserializedReport.status, equals(originalReport.status));
      });

      test('should copy error report with changes', () async {
        final originalReport = await service.submitErrorReport(
          userId: 'test-user',
          title: 'Original Title',
          description: 'Original Description',
          type: ErrorReportType.bug,
        );

        final copiedReport = originalReport.copyWith(
          title: 'Updated Title',
          status: ErrorReportStatus.resolved,
          resolution: 'Fixed',
        );

        expect(copiedReport.id, equals(originalReport.id));
        expect(copiedReport.title, equals('Updated Title'));
        expect(copiedReport.description, equals('Original Description'));
        expect(copiedReport.status, equals(ErrorReportStatus.resolved));
        expect(copiedReport.resolution, equals('Fixed'));
      });
    });
  });
}