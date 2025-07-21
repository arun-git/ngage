import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../lib/models/models.dart';
import '../../lib/repositories/notification_repository.dart';
import '../../lib/services/notification_service.dart';

// Generate mocks
@GenerateMocks([NotificationRepository, NotificationChannelHandler])
import 'notification_service_test.mocks.dart';

void main() {
  group('NotificationService', () {
    late NotificationService notificationService;
    late MockNotificationRepository mockRepository;
    late MockNotificationChannelHandler mockInAppHandler;
    late MockNotificationChannelHandler mockEmailHandler;
    late MockNotificationChannelHandler mockPushHandler;

    setUp(() {
      mockRepository = MockNotificationRepository();
      mockInAppHandler = MockNotificationChannelHandler();
      mockEmailHandler = MockNotificationChannelHandler();
      mockPushHandler = MockNotificationChannelHandler();

      notificationService = NotificationService(repository: mockRepository);
      notificationService.registerChannelHandler(NotificationChannel.inApp, mockInAppHandler);
      notificationService.registerChannelHandler(NotificationChannel.email, mockEmailHandler);
      notificationService.registerChannelHandler(NotificationChannel.push, mockPushHandler);
    });

    group('sendNotification', () {
      test('should save notification to repository and send through enabled channels', () async {
        // Arrange
        final notification = Notification(
          id: 'test-id',
          recipientId: 'member-1',
          type: NotificationType.eventReminder,
          title: 'Test Notification',
          message: 'Test message',
          channels: [NotificationChannel.inApp, NotificationChannel.email],
          createdAt: DateTime.now(),
        );

        final preferences = NotificationPreferences(
          memberId: 'member-1',
          eventReminders: true,
          preferredChannels: [NotificationChannel.inApp, NotificationChannel.email],
          updatedAt: DateTime.now(),
        );

        when(mockRepository.createNotification(any)).thenAnswer((_) async {});
        when(mockRepository.getNotificationPreferences('member-1'))
            .thenAnswer((_) async => preferences);
        when(mockInAppHandler.sendNotification(any)).thenAnswer((_) async {});
        when(mockEmailHandler.sendNotification(any)).thenAnswer((_) async {});

        // Act
        await notificationService.sendNotification(notification);

        // Assert
        verify(mockRepository.createNotification(notification)).called(1);
        verify(mockInAppHandler.sendNotification(notification)).called(1);
        verify(mockEmailHandler.sendNotification(notification)).called(1);
        verifyNever(mockPushHandler.sendNotification(any));
      });

      test('should not send notification if type is disabled in preferences', () async {
        // Arrange
        final notification = Notification(
          id: 'test-id',
          recipientId: 'member-1',
          type: NotificationType.eventReminder,
          title: 'Test Notification',
          message: 'Test message',
          channels: [NotificationChannel.inApp],
          createdAt: DateTime.now(),
        );

        final preferences = NotificationPreferences(
          memberId: 'member-1',
          eventReminders: false, // Disabled
          preferredChannels: [NotificationChannel.inApp],
          updatedAt: DateTime.now(),
        );

        when(mockRepository.createNotification(any)).thenAnswer((_) async {});
        when(mockRepository.getNotificationPreferences('member-1'))
            .thenAnswer((_) async => preferences);

        // Act
        await notificationService.sendNotification(notification);

        // Assert
        verify(mockRepository.createNotification(notification)).called(1);
        verifyNever(mockInAppHandler.sendNotification(any));
      });

      test('should handle channel handler failures gracefully', () async {
        // Arrange
        final notification = Notification(
          id: 'test-id',
          recipientId: 'member-1',
          type: NotificationType.eventReminder,
          title: 'Test Notification',
          message: 'Test message',
          channels: [NotificationChannel.inApp, NotificationChannel.email],
          createdAt: DateTime.now(),
        );

        final preferences = NotificationPreferences(
          memberId: 'member-1',
          eventReminders: true,
          preferredChannels: [NotificationChannel.inApp, NotificationChannel.email],
          updatedAt: DateTime.now(),
        );

        when(mockRepository.createNotification(any)).thenAnswer((_) async {});
        when(mockRepository.getNotificationPreferences('member-1'))
            .thenAnswer((_) async => preferences);
        when(mockInAppHandler.sendNotification(any)).thenAnswer((_) async {});
        when(mockEmailHandler.sendNotification(any)).thenThrow(Exception('Email failed'));

        // Act & Assert - Should not throw
        await notificationService.sendNotification(notification);

        verify(mockRepository.createNotification(notification)).called(1);
        verify(mockInAppHandler.sendNotification(notification)).called(1);
        verify(mockEmailHandler.sendNotification(notification)).called(1);
      });
    });

    group('sendEventReminder', () {
      test('should create and send event reminder notifications', () async {
        // Arrange
        final event = Event(
          id: 'event-1',
          groupId: 'group-1',
          title: 'Test Event',
          description: 'Test Description',
          eventType: EventType.competition,
          status: EventStatus.scheduled,
          startTime: DateTime.now().add(const Duration(hours: 2)),
          createdBy: 'creator-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final memberIds = ['member-1', 'member-2'];
        final timeUntilEvent = const Duration(hours: 2);

        when(mockRepository.createNotificationsBatch(any)).thenAnswer((_) async {});
        when(mockRepository.getNotificationPreferences(any))
            .thenAnswer((_) async => NotificationPreferences(
              memberId: 'member-1',
              eventReminders: true,
              preferredChannels: [NotificationChannel.inApp, NotificationChannel.push],
              updatedAt: DateTime.now(),
            ));
        when(mockInAppHandler.sendNotification(any)).thenAnswer((_) async {});
        when(mockPushHandler.sendNotification(any)).thenAnswer((_) async {});

        // Act
        await notificationService.sendEventReminder(
          event: event,
          memberIds: memberIds,
          timeUntilEvent: timeUntilEvent,
        );

        // Assert
        verify(mockRepository.createNotificationsBatch(any)).called(1);
        verify(mockInAppHandler.sendNotification(any)).called(2); // Once per member
        verify(mockPushHandler.sendNotification(any)).called(2); // Once per member
      });
    });

    group('sendDeadlineAlert', () {
      test('should send deadline alerts with appropriate priority and channels', () async {
        // Arrange
        final event = Event(
          id: 'event-1',
          groupId: 'group-1',
          title: 'Test Event',
          description: 'Test Description',
          eventType: EventType.competition,
          status: EventStatus.active,
          submissionDeadline: DateTime.now().add(const Duration(minutes: 30)),
          createdBy: 'creator-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final memberIds = ['member-1'];
        final timeUntilDeadline = const Duration(minutes: 30);

        when(mockRepository.createNotificationsBatch(any)).thenAnswer((_) async {});
        when(mockRepository.getNotificationPreferences(any))
            .thenAnswer((_) async => NotificationPreferences(
              memberId: 'member-1',
              deadlineAlerts: true,
              preferredChannels: [NotificationChannel.inApp, NotificationChannel.email, NotificationChannel.push],
              updatedAt: DateTime.now(),
            ));
        when(mockInAppHandler.sendNotification(any)).thenAnswer((_) async {});
        when(mockEmailHandler.sendNotification(any)).thenAnswer((_) async {});
        when(mockPushHandler.sendNotification(any)).thenAnswer((_) async {});

        // Act
        await notificationService.sendDeadlineAlert(
          event: event,
          memberIds: memberIds,
          timeUntilDeadline: timeUntilDeadline,
        );

        // Assert
        verify(mockRepository.createNotificationsBatch(any)).called(1);
        // Should use all channels for urgent deadline (30 minutes)
        verify(mockInAppHandler.sendNotification(any)).called(1);
        verify(mockEmailHandler.sendNotification(any)).called(1);
        verify(mockPushHandler.sendNotification(any)).called(1);
      });

      test('should escalate notifications with higher priority', () async {
        // Arrange
        final event = Event(
          id: 'event-1',
          groupId: 'group-1',
          title: 'Test Event',
          description: 'Test Description',
          eventType: EventType.competition,
          status: EventStatus.active,
          submissionDeadline: DateTime.now().add(const Duration(hours: 6)),
          createdBy: 'creator-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final memberIds = ['member-1'];
        final timeUntilDeadline = const Duration(hours: 6);

        when(mockRepository.createNotificationsBatch(any)).thenAnswer((_) async {});
        when(mockRepository.getNotificationPreferences(any))
            .thenAnswer((_) async => NotificationPreferences(
              memberId: 'member-1',
              deadlineAlerts: true,
              preferredChannels: [NotificationChannel.inApp, NotificationChannel.push],
              updatedAt: DateTime.now(),
            ));
        when(mockInAppHandler.sendNotification(any)).thenAnswer((_) async {});
        when(mockPushHandler.sendNotification(any)).thenAnswer((_) async {});

        // Act
        await notificationService.sendDeadlineAlert(
          event: event,
          memberIds: memberIds,
          timeUntilDeadline: timeUntilDeadline,
          isEscalated: true,
        );

        // Assert
        verify(mockRepository.createNotificationsBatch(any)).called(1);
        // Should use all available channels when escalated
        verify(mockInAppHandler.sendNotification(any)).called(1);
        verify(mockPushHandler.sendNotification(any)).called(1);
      });
    });

    group('sendResultAnnouncement', () {
      test('should send result announcement notifications', () async {
        // Arrange
        final event = Event(
          id: 'event-1',
          groupId: 'group-1',
          title: 'Test Event',
          description: 'Test Description',
          eventType: EventType.competition,
          status: EventStatus.completed,
          createdBy: 'creator-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final memberIds = ['member-1', 'member-2'];
        const resultSummary = 'Results are now available for Test Event';

        when(mockRepository.createNotificationsBatch(any)).thenAnswer((_) async {});
        when(mockRepository.getNotificationPreferences(any))
            .thenAnswer((_) async => NotificationPreferences(
              memberId: 'member-1',
              resultAnnouncements: true,
              preferredChannels: [NotificationChannel.inApp, NotificationChannel.email],
              updatedAt: DateTime.now(),
            ));
        when(mockInAppHandler.sendNotification(any)).thenAnswer((_) async {});
        when(mockEmailHandler.sendNotification(any)).thenAnswer((_) async {});

        // Act
        await notificationService.sendResultAnnouncement(
          event: event,
          memberIds: memberIds,
          resultSummary: resultSummary,
        );

        // Assert
        verify(mockRepository.createNotificationsBatch(any)).called(1);
        verify(mockInAppHandler.sendNotification(any)).called(2);
        verify(mockEmailHandler.sendNotification(any)).called(2);
      });
    });

    group('sendLeaderboardUpdate', () {
      test('should send leaderboard update notifications', () async {
        // Arrange
        final event = Event(
          id: 'event-1',
          groupId: 'group-1',
          title: 'Test Event',
          description: 'Test Description',
          eventType: EventType.competition,
          status: EventStatus.active,
          createdBy: 'creator-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final memberIds = ['member-1', 'member-2'];
        const updateMessage = 'New leader in Test Event!';

        when(mockRepository.createNotificationsBatch(any)).thenAnswer((_) async {});
        when(mockRepository.getNotificationPreferences(any))
            .thenAnswer((_) async => NotificationPreferences(
              memberId: 'member-1',
              leaderboardUpdates: true,
              preferredChannels: [NotificationChannel.inApp],
              updatedAt: DateTime.now(),
            ));
        when(mockInAppHandler.sendNotification(any)).thenAnswer((_) async {});

        // Act
        await notificationService.sendLeaderboardUpdate(
          event: event,
          memberIds: memberIds,
          updateMessage: updateMessage,
        );

        // Assert
        verify(mockRepository.createNotificationsBatch(any)).called(1);
        verify(mockInAppHandler.sendNotification(any)).called(2);
      });
    });

    group('processScheduledNotifications', () {
      test('should process and send scheduled notifications', () async {
        // Arrange
        final scheduledNotifications = [
          Notification(
            id: 'scheduled-1',
            recipientId: 'member-1',
            type: NotificationType.eventReminder,
            title: 'Scheduled Notification',
            message: 'This was scheduled',
            scheduledAt: DateTime.now().subtract(const Duration(minutes: 1)),
            createdAt: DateTime.now(),
          ),
        ];

        when(mockRepository.getScheduledNotifications())
            .thenAnswer((_) async => scheduledNotifications);
        when(mockRepository.getNotificationPreferences(any))
            .thenAnswer((_) async => NotificationPreferences(
              memberId: 'member-1',
              eventReminders: true,
              preferredChannels: [NotificationChannel.inApp],
              updatedAt: DateTime.now(),
            ));
        when(mockRepository.deleteNotification(any)).thenAnswer((_) async {});
        when(mockInAppHandler.sendNotification(any)).thenAnswer((_) async {});

        // Act
        await notificationService.processScheduledNotifications();

        // Assert
        verify(mockRepository.getScheduledNotifications()).called(1);
        verify(mockInAppHandler.sendNotification(any)).called(1);
        verify(mockRepository.deleteNotification('scheduled-1')).called(1);
      });
    });

    group('notification preferences', () {
      test('should save and retrieve notification preferences', () async {
        // Arrange
        final preferences = NotificationPreferences(
          memberId: 'member-1',
          eventReminders: false,
          deadlineAlerts: true,
          preferredChannels: [NotificationChannel.email],
          updatedAt: DateTime.now(),
        );

        when(mockRepository.saveNotificationPreferences(preferences))
            .thenAnswer((_) async {});
        when(mockRepository.getNotificationPreferences('member-1'))
            .thenAnswer((_) async => preferences);

        // Act
        await notificationService.saveNotificationPreferences(preferences);
        final retrieved = await notificationService.getNotificationPreferences('member-1');

        // Assert
        verify(mockRepository.saveNotificationPreferences(preferences)).called(1);
        verify(mockRepository.getNotificationPreferences('member-1')).called(1);
        expect(retrieved, equals(preferences));
      });

      test('should return default preferences when none exist', () async {
        // Arrange
        const memberId = 'member-1';
        final defaultPrefs = NotificationPreferences(
          memberId: memberId,
          updatedAt: DateTime.now(),
        );

        when(mockRepository.getNotificationPreferences(memberId))
            .thenAnswer((_) async => null);
        when(mockRepository.getDefaultPreferences(memberId))
            .thenReturn(defaultPrefs);

        // Act
        final preferences = await notificationService.getNotificationPreferences(memberId);

        // Assert
        expect(preferences.memberId, equals(memberId));
        expect(preferences.eventReminders, isTrue);
        expect(preferences.deadlineAlerts, isTrue);
      });
    });

    group('utility methods', () {
      test('should mark notifications as read', () async {
        // Arrange
        const notificationId = 'notif-1';
        when(mockRepository.markNotificationAsRead(notificationId))
            .thenAnswer((_) async {});

        // Act
        await notificationService.markAsRead(notificationId);

        // Assert
        verify(mockRepository.markNotificationAsRead(notificationId)).called(1);
      });

      test('should mark all notifications as read for member', () async {
        // Arrange
        const memberId = 'member-1';
        when(mockRepository.markAllNotificationsAsRead(memberId))
            .thenAnswer((_) async {});

        // Act
        await notificationService.markAllAsRead(memberId);

        // Assert
        verify(mockRepository.markAllNotificationsAsRead(memberId)).called(1);
      });

      test('should get unread notifications count', () async {
        // Arrange
        const memberId = 'member-1';
        const unreadCount = 5;
        when(mockRepository.getUnreadNotificationsCount(memberId))
            .thenAnswer((_) async => unreadCount);

        // Act
        final count = await notificationService.getUnreadCount(memberId);

        // Assert
        expect(count, equals(unreadCount));
        verify(mockRepository.getUnreadNotificationsCount(memberId)).called(1);
      });
    });
  });
}