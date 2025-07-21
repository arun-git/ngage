import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../lib/models/content_report.dart';
import '../../lib/models/moderation_action.dart';
import '../../lib/repositories/content_report_repository.dart';
import '../../lib/repositories/moderation_action_repository.dart';
import '../../lib/services/moderation_service.dart';
import '../../lib/services/notification_service.dart';
import '../../lib/services/permission_service.dart';

@GenerateMocks([
  ContentReportRepository,
  ModerationActionRepository,
  NotificationService,
  PermissionService,
])
import 'moderation_service_test.mocks.dart';

void main() {
  group('ModerationService', () {
    late ModerationService service;
    late MockContentReportRepository mockReportRepository;
    late MockModerationActionRepository mockActionRepository;
    late MockNotificationService mockNotificationService;
    late MockPermissionService mockPermissionService;

    setUp(() {
      mockReportRepository = MockContentReportRepository();
      mockActionRepository = MockModerationActionRepository();
      mockNotificationService = MockNotificationService();
      mockPermissionService = MockPermissionService();
      
      service = ModerationService(
        reportRepository: mockReportRepository,
        actionRepository: mockActionRepository,
        notificationService: mockNotificationService,
        permissionService: mockPermissionService,
      );
    });

    group('reportContent', () {
      test('should create report successfully when user has not reported before', () async {
        when(mockReportRepository.hasUserReportedContent(
          'reporter123',
          'content456',
          ContentType.post,
        )).thenAnswer((_) async => false);
        
        when(mockReportRepository.createReport(any))
            .thenAnswer((_) async => 'report123');

        final reportId = await service.reportContent(
          reporterId: 'reporter123',
          contentId: 'content456',
          contentType: ContentType.post,
          reason: ReportReason.spam,
          description: 'This is spam',
        );

        expect(reportId, equals('report123'));
        
        verify(mockReportRepository.hasUserReportedContent(
          'reporter123',
          'content456',
          ContentType.post,
        )).called(1);
        
        verify(mockReportRepository.createReport(any)).called(1);
      });

      test('should throw exception when user has already reported content', () async {
        when(mockReportRepository.hasUserReportedContent(
          'reporter123',
          'content456',
          ContentType.post,
        )).thenAnswer((_) async => true);

        expect(
          () => service.reportContent(
            reporterId: 'reporter123',
            contentId: 'content456',
            contentType: ContentType.post,
            reason: ReportReason.spam,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('already reported'),
          )),
        );
      });
    });

    group('getPendingReports', () {
      test('should return pending reports', () async {
        final mockReports = [
          ContentReport(
            id: 'report1',
            reporterId: 'reporter1',
            contentId: 'content1',
            contentType: ContentType.post,
            reason: ReportReason.spam,
            status: ReportStatus.pending,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockReportRepository.getPendingReports(limit: null))
            .thenAnswer((_) async => mockReports);

        final reports = await service.getPendingReports();

        expect(reports, equals(mockReports));
        verify(mockReportRepository.getPendingReports(limit: null)).called(1);
      });
    });

    group('reviewReport', () {
      test('should review report successfully when user has permission', () async {
        when(mockPermissionService.hasPermission('admin123', 'moderate_content'))
            .thenAnswer((_) async => true);
        
        when(mockReportRepository.updateReportStatus(
          'report123',
          ReportStatus.resolved,
          reviewedBy: 'admin123',
          reviewNotes: 'Resolved',
        )).thenAnswer((_) async {});

        when(mockReportRepository.getReport('report123'))
            .thenAnswer((_) async => ContentReport(
              id: 'report123',
              reporterId: 'reporter1',
              contentId: 'content1',
              contentType: ContentType.post,
              reason: ReportReason.spam,
              status: ReportStatus.resolved,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ));

        await service.reviewReport(
          reportId: 'report123',
          reviewerId: 'admin123',
          newStatus: ReportStatus.resolved,
          reviewNotes: 'Resolved',
        );

        verify(mockPermissionService.hasPermission('admin123', 'moderate_content')).called(1);
        verify(mockReportRepository.updateReportStatus(
          'report123',
          ReportStatus.resolved,
          reviewedBy: 'admin123',
          reviewNotes: 'Resolved',
        )).called(1);
      });

      test('should throw exception when user lacks permission', () async {
        when(mockPermissionService.hasPermission('user123', 'moderate_content'))
            .thenAnswer((_) async => false);

        expect(
          () => service.reviewReport(
            reportId: 'report123',
            reviewerId: 'user123',
            newStatus: ReportStatus.resolved,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Insufficient permissions'),
          )),
        );
      });
    });

    group('takeModerationAction', () {
      test('should take moderation action successfully when user has permission', () async {
        when(mockPermissionService.hasPermission('admin123', 'moderate_content'))
            .thenAnswer((_) async => true);
        
        when(mockActionRepository.createAction(any))
            .thenAnswer((_) async => 'action123');

        final actionId = await service.takeModerationAction(
          moderatorId: 'admin123',
          targetId: 'content456',
          targetType: ModerationTargetType.post,
          actionType: ModerationActionType.hide,
          reason: 'Inappropriate content',
        );

        expect(actionId, equals('action123'));
        
        verify(mockPermissionService.hasPermission('admin123', 'moderate_content')).called(1);
        verify(mockActionRepository.createAction(any)).called(1);
      });

      test('should throw exception when user lacks permission', () async {
        when(mockPermissionService.hasPermission('user123', 'moderate_content'))
            .thenAnswer((_) async => false);

        expect(
          () => service.takeModerationAction(
            moderatorId: 'user123',
            targetId: 'content456',
            targetType: ModerationTargetType.post,
            actionType: ModerationActionType.hide,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Insufficient permissions'),
          )),
        );
      });

      test('should update report status when reportId is provided', () async {
        when(mockPermissionService.hasPermission('admin123', 'moderate_content'))
            .thenAnswer((_) async => true);
        
        when(mockActionRepository.createAction(any))
            .thenAnswer((_) async => 'action123');
        
        when(mockReportRepository.updateReportStatus(
          'report123',
          ReportStatus.resolved,
          reviewedBy: 'admin123',
          reviewNotes: any,
        )).thenAnswer((_) async {});

        await service.takeModerationAction(
          moderatorId: 'admin123',
          targetId: 'content456',
          targetType: ModerationTargetType.post,
          actionType: ModerationActionType.hide,
          reportId: 'report123',
        );

        verify(mockReportRepository.updateReportStatus(
          'report123',
          ReportStatus.resolved,
          reviewedBy: 'admin123',
          reviewNotes: any,
        )).called(1);
      });
    });

    group('hideContent', () {
      test('should hide content successfully', () async {
        when(mockPermissionService.hasPermission('admin123', 'moderate_content'))
            .thenAnswer((_) async => true);
        
        when(mockActionRepository.createAction(any))
            .thenAnswer((_) async => 'action123');

        final actionId = await service.hideContent(
          moderatorId: 'admin123',
          contentId: 'content456',
          contentType: ModerationTargetType.post,
          reason: 'Inappropriate',
        );

        expect(actionId, equals('action123'));
        
        final capturedAction = verify(mockActionRepository.createAction(captureAny)).captured.first as ModerationAction;
        expect(capturedAction.actionType, equals(ModerationActionType.hide));
        expect(capturedAction.targetId, equals('content456'));
        expect(capturedAction.targetType, equals(ModerationTargetType.post));
      });
    });

    group('suspendUser', () {
      test('should suspend user with expiration date', () async {
        when(mockPermissionService.hasPermission('admin123', 'moderate_content'))
            .thenAnswer((_) async => true);
        
        when(mockActionRepository.createAction(any))
            .thenAnswer((_) async => 'action123');

        final expiresAt = DateTime.now().add(const Duration(days: 7));
        
        final actionId = await service.suspendUser(
          moderatorId: 'admin123',
          userId: 'user456',
          expiresAt: expiresAt,
          reason: 'Harassment',
        );

        expect(actionId, equals('action123'));
        
        final capturedAction = verify(mockActionRepository.createAction(captureAny)).captured.first as ModerationAction;
        expect(capturedAction.actionType, equals(ModerationActionType.suspend));
        expect(capturedAction.targetId, equals('user456'));
        expect(capturedAction.targetType, equals(ModerationTargetType.user));
        expect(capturedAction.expiresAt, equals(expiresAt));
      });
    });

    group('isContentModerated', () {
      test('should return moderation status', () async {
        when(mockActionRepository.isContentHidden('content456', ModerationTargetType.post))
            .thenAnswer((_) async => true);

        final isModerated = await service.isContentModerated('content456', ModerationTargetType.post);

        expect(isModerated, isTrue);
        verify(mockActionRepository.isContentHidden('content456', ModerationTargetType.post)).called(1);
      });
    });

    group('isUserRestricted', () {
      test('should return user restriction status', () async {
        when(mockActionRepository.isUserRestricted('user456'))
            .thenAnswer((_) async => true);

        final isRestricted = await service.isUserRestricted('user456');

        expect(isRestricted, isTrue);
        verify(mockActionRepository.isUserRestricted('user456')).called(1);
      });
    });

    group('getModerationStatistics', () {
      test('should return combined statistics', () async {
        final reportStats = {
          'pending': 5,
          'resolved': 10,
          'total': 15,
        };
        
        final actionStats = {
          'hidden': 3,
          'deleted': 2,
          'totalActive': 5,
        };

        when(mockReportRepository.getReportsStatistics())
            .thenAnswer((_) async => reportStats);
        
        when(mockActionRepository.getModerationStatistics())
            .thenAnswer((_) async => actionStats);

        final stats = await service.getModerationStatistics();

        expect(stats['reports'], equals(reportStats));
        expect(stats['actions'], equals(actionStats));
      });
    });

    group('reverseModerationAction', () {
      test('should reverse action when user has permission', () async {
        when(mockPermissionService.hasPermission('admin123', 'moderate_content'))
            .thenAnswer((_) async => true);
        
        when(mockActionRepository.deactivateAction('action123'))
            .thenAnswer((_) async {});

        await service.reverseModerationAction('action123', 'admin123');

        verify(mockPermissionService.hasPermission('admin123', 'moderate_content')).called(1);
        verify(mockActionRepository.deactivateAction('action123')).called(1);
      });

      test('should throw exception when user lacks permission', () async {
        when(mockPermissionService.hasPermission('user123', 'moderate_content'))
            .thenAnswer((_) async => false);

        expect(
          () => service.reverseModerationAction('action123', 'user123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Insufficient permissions'),
          )),
        );
      });
    });

    group('cleanupExpiredActions', () {
      test('should cleanup expired actions', () async {
        when(mockActionRepository.cleanupExpiredActions())
            .thenAnswer((_) async {});

        await service.cleanupExpiredActions();

        verify(mockActionRepository.cleanupExpiredActions()).called(1);
      });
    });

    group('streamPendingReports', () {
      test('should return stream of pending reports', () {
        final mockStream = Stream<List<ContentReport>>.value([]);
        
        when(mockReportRepository.streamPendingReports())
            .thenAnswer((_) => mockStream);

        final stream = service.streamPendingReports();

        expect(stream, equals(mockStream));
        verify(mockReportRepository.streamPendingReports()).called(1);
      });
    });
  });
}