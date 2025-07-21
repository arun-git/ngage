import 'package:flutter_test/flutter_test.dart';
import 'package:ngage/models/models.dart';

void main() {
  group('Notification', () {
    late DateTime testDateTime;

    setUp(() {
      testDateTime = DateTime(2024, 1, 15, 10, 30, 0);
    });

    group('constructor', () {
      test('should create notification with required fields', () {
        // Act
        final notification = Notification(
          id: 'test-id',
          recipientId: 'member-1',
          type: NotificationType.eventReminder,
          title: 'Test Notification',
          message: 'Test message',
          createdAt: testDateTime,
        );

        // Assert
        expect(notification.id, equals('test-id'));
        expect(notification.recipientId, equals('member-1'));
        expect(notification.type, equals(NotificationType.eventReminder));
        expect(notification.title, equals('Test Notification'));
        expect(notification.message, equals('Test message'));
        expect(notification.isRead, isFalse);
        expect(notification.channels, equals([NotificationChannel.inApp]));
        expect(notification.priority, equals(NotificationPriority.normal));
        expect(notification.createdAt, equals(testDateTime));
        expect(notification.data, isNull);
        expect(notification.scheduledAt, isNull);
        expect(notification.readAt, isNull);
      });

      test('should create notification with all optional fields', () {
        // Arrange
        final scheduledAt = testDateTime.add(const Duration(hours: 1));
        final readAt = testDateTime.add(const Duration(minutes: 30));
        final data = {'eventId': 'event-1', 'priority': 'high'};

        // Act
        final notification = Notification(
          id: 'test-id',
          recipientId: 'member-1',
          type: NotificationType.deadlineAlert,
          title: 'Urgent Notification',
          message: 'Deadline approaching',
          data: data,
          isRead: true,
          channels: [NotificationChannel.inApp, NotificationChannel.email],
          priority: NotificationPriority.urgent,
          scheduledAt: scheduledAt,
          createdAt: testDateTime,
          readAt: readAt,
        );

        // Assert
        expect(notification.data, equals(data));
        expect(notification.isRead, isTrue);
        expect(notification.channels, containsAll([NotificationChannel.inApp, NotificationChannel.email]));
        expect(notification.priority, equals(NotificationPriority.urgent));
        expect(notification.scheduledAt, equals(scheduledAt));
        expect(notification.readAt, equals(readAt));
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        // Arrange
        final original = Notification(
          id: 'test-id',
          recipientId: 'member-1',
          type: NotificationType.eventReminder,
          title: 'Original Title',
          message: 'Original message',
          createdAt: testDateTime,
        );

        // Act
        final updated = original.copyWith(
          title: 'Updated Title',
          isRead: true,
          readAt: testDateTime.add(const Duration(minutes: 15)),
        );

        // Assert
        expect(updated.id, equals(original.id));
        expect(updated.recipientId, equals(original.recipientId));
        expect(updated.type, equals(original.type));
        expect(updated.title, equals('Updated Title'));
        expect(updated.message, equals(original.message));
        expect(updated.isRead, isTrue);
        expect(updated.readAt, equals(testDateTime.add(const Duration(minutes: 15))));
        expect(updated.createdAt, equals(original.createdAt));
      });
    });

    group('JSON serialization', () {
      test('should convert to JSON correctly', () {
        // Arrange
        final notification = Notification(
          id: 'test-id',
          recipientId: 'member-1',
          type: NotificationType.eventReminder,
          title: 'Test Notification',
          message: 'Test message',
          data: {'eventId': 'event-1'},
          isRead: true,
          channels: [NotificationChannel.inApp, NotificationChannel.email],
          priority: NotificationPriority.high,
          scheduledAt: testDateTime.add(const Duration(hours: 1)),
          createdAt: testDateTime,
          readAt: testDateTime.add(const Duration(minutes: 30)),
        );

        // Act
        final json = notification.toJson();

        // Assert
        expect(json['id'], equals('test-id'));
        expect(json['recipientId'], equals('member-1'));
        expect(json['type'], equals('event_reminder'));
        expect(json['title'], equals('Test Notification'));
        expect(json['message'], equals('Test message'));
        expect(json['data'], equals({'eventId': 'event-1'}));
        expect(json['isRead'], isTrue);
        expect(json['channels'], equals(['in_app', 'email']));
        expect(json['priority'], equals('high'));
        expect(json['scheduledAt'], equals(testDateTime.add(const Duration(hours: 1)).toIso8601String()));
        expect(json['createdAt'], equals(testDateTime.toIso8601String()));
        expect(json['readAt'], equals(testDateTime.add(const Duration(minutes: 30)).toIso8601String()));
      });

      test('should handle null optional fields in JSON', () {
        // Arrange
        final notification = Notification(
          id: 'test-id',
          recipientId: 'member-1',
          type: NotificationType.eventReminder,
          title: 'Test Notification',
          message: 'Test message',
          createdAt: testDateTime,
        );

        // Act
        final json = notification.toJson();

        // Assert
        expect(json['data'], isNull);
        expect(json['scheduledAt'], isNull);
        expect(json['readAt'], isNull);
      });

      test('should create from JSON correctly', () {
        // Arrange
        final json = {
          'id': 'test-id',
          'recipientId': 'member-1',
          'type': 'deadline_alert',
          'title': 'Deadline Alert',
          'message': 'Deadline approaching',
          'data': {'eventId': 'event-1', 'timeRemaining': 60},
          'isRead': false,
          'channels': ['in_app', 'push'],
          'priority': 'urgent',
          'scheduledAt': testDateTime.add(const Duration(hours: 1)).toIso8601String(),
          'createdAt': testDateTime.toIso8601String(),
          'readAt': testDateTime.add(const Duration(minutes: 30)).toIso8601String(),
        };

        // Act
        final notification = Notification.fromJson(json);

        // Assert
        expect(notification.id, equals('test-id'));
        expect(notification.recipientId, equals('member-1'));
        expect(notification.type, equals(NotificationType.deadlineAlert));
        expect(notification.title, equals('Deadline Alert'));
        expect(notification.message, equals('Deadline approaching'));
        expect(notification.data, equals({'eventId': 'event-1', 'timeRemaining': 60}));
        expect(notification.isRead, isFalse);
        expect(notification.channels, containsAll([NotificationChannel.inApp, NotificationChannel.push]));
        expect(notification.priority, equals(NotificationPriority.urgent));
        expect(notification.scheduledAt, equals(testDateTime.add(const Duration(hours: 1))));
        expect(notification.createdAt, equals(testDateTime));
        expect(notification.readAt, equals(testDateTime.add(const Duration(minutes: 30))));
      });

      test('should handle missing optional fields in JSON', () {
        // Arrange
        final json = {
          'id': 'test-id',
          'recipientId': 'member-1',
          'type': 'event_reminder',
          'title': 'Test Notification',
          'message': 'Test message',
          'createdAt': testDateTime.toIso8601String(),
        };

        // Act
        final notification = Notification.fromJson(json);

        // Assert
        expect(notification.data, isNull);
        expect(notification.isRead, isFalse);
        expect(notification.channels, equals([NotificationChannel.inApp]));
        expect(notification.priority, equals(NotificationPriority.normal));
        expect(notification.scheduledAt, isNull);
        expect(notification.readAt, isNull);
      });
    });

    group('equality and hashCode', () {
      test('should be equal when all key fields match', () {
        // Arrange
        final notification1 = Notification(
          id: 'test-id',
          recipientId: 'member-1',
          type: NotificationType.eventReminder,
          title: 'Test Notification',
          message: 'Test message',
          isRead: false,
          createdAt: testDateTime,
        );

        final notification2 = Notification(
          id: 'test-id',
          recipientId: 'member-1',
          type: NotificationType.eventReminder,
          title: 'Test Notification',
          message: 'Test message',
          isRead: false,
          createdAt: testDateTime.add(const Duration(seconds: 1)), // Different createdAt
        );

        // Act & Assert
        expect(notification1, equals(notification2));
        expect(notification1.hashCode, equals(notification2.hashCode));
      });

      test('should not be equal when key fields differ', () {
        // Arrange
        final notification1 = Notification(
          id: 'test-id-1',
          recipientId: 'member-1',
          type: NotificationType.eventReminder,
          title: 'Test Notification',
          message: 'Test message',
          createdAt: testDateTime,
        );

        final notification2 = Notification(
          id: 'test-id-2',
          recipientId: 'member-1',
          type: NotificationType.eventReminder,
          title: 'Test Notification',
          message: 'Test message',
          createdAt: testDateTime,
        );

        // Act & Assert
        expect(notification1, isNot(equals(notification2)));
        expect(notification1.hashCode, isNot(equals(notification2.hashCode)));
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        // Arrange
        final notification = Notification(
          id: 'test-id',
          recipientId: 'member-1',
          type: NotificationType.eventReminder,
          title: 'Test Notification',
          message: 'Test message',
          isRead: true,
          createdAt: testDateTime,
        );

        // Act
        final string = notification.toString();

        // Assert
        expect(string, contains('test-id'));
        expect(string, contains('member-1'));
        expect(string, contains('NotificationType.eventReminder'));
        expect(string, contains('Test Notification'));
        expect(string, contains('true'));
      });
    });
  });

  group('NotificationChannel', () {
    test('should convert from string correctly', () {
      expect(NotificationChannel.fromString('in_app'), equals(NotificationChannel.inApp));
      expect(NotificationChannel.fromString('email'), equals(NotificationChannel.email));
      expect(NotificationChannel.fromString('push'), equals(NotificationChannel.push));
    });

    test('should throw error for invalid string', () {
      expect(() => NotificationChannel.fromString('invalid'), throwsArgumentError);
    });
  });

  group('NotificationPriority', () {
    test('should convert from string correctly', () {
      expect(NotificationPriority.fromString('low'), equals(NotificationPriority.low));
      expect(NotificationPriority.fromString('normal'), equals(NotificationPriority.normal));
      expect(NotificationPriority.fromString('high'), equals(NotificationPriority.high));
      expect(NotificationPriority.fromString('urgent'), equals(NotificationPriority.urgent));
    });

    test('should default to normal for invalid string', () {
      expect(NotificationPriority.fromString('invalid'), equals(NotificationPriority.normal));
    });
  });

  group('NotificationPreferences', () {
    test('should create with default values', () {
      // Act
      final preferences = NotificationPreferences(
        memberId: 'member-1',
        updatedAt: testDateTime,
      );

      // Assert
      expect(preferences.memberId, equals('member-1'));
      expect(preferences.eventReminders, isTrue);
      expect(preferences.deadlineAlerts, isTrue);
      expect(preferences.resultAnnouncements, isTrue);
      expect(preferences.leaderboardUpdates, isTrue);
      expect(preferences.preferredChannels, equals([NotificationChannel.inApp]));
      expect(preferences.typePreferences, isEmpty);
      expect(preferences.updatedAt, equals(testDateTime));
    });

    test('should convert to and from JSON correctly', () {
      // Arrange
      final preferences = NotificationPreferences(
        memberId: 'member-1',
        eventReminders: false,
        deadlineAlerts: true,
        resultAnnouncements: false,
        leaderboardUpdates: true,
        preferredChannels: [NotificationChannel.email, NotificationChannel.push],
        typePreferences: {NotificationType.eventReminder: false},
        updatedAt: testDateTime,
      );

      // Act
      final json = preferences.toJson();
      final fromJson = NotificationPreferences.fromJson(json);

      // Assert
      expect(fromJson.memberId, equals(preferences.memberId));
      expect(fromJson.eventReminders, equals(preferences.eventReminders));
      expect(fromJson.deadlineAlerts, equals(preferences.deadlineAlerts));
      expect(fromJson.resultAnnouncements, equals(preferences.resultAnnouncements));
      expect(fromJson.leaderboardUpdates, equals(preferences.leaderboardUpdates));
      expect(fromJson.preferredChannels, equals(preferences.preferredChannels));
      expect(fromJson.typePreferences, equals(preferences.typePreferences));
      expect(fromJson.updatedAt, equals(preferences.updatedAt));
    });

    test('should create copy with updated fields', () {
      // Arrange
      final original = NotificationPreferences(
        memberId: 'member-1',
        eventReminders: true,
        deadlineAlerts: true,
        updatedAt: testDateTime,
      );

      // Act
      final updated = original.copyWith(
        eventReminders: false,
        preferredChannels: [NotificationChannel.email],
        updatedAt: testDateTime.add(const Duration(hours: 1)),
      );

      // Assert
      expect(updated.memberId, equals(original.memberId));
      expect(updated.eventReminders, isFalse);
      expect(updated.deadlineAlerts, equals(original.deadlineAlerts));
      expect(updated.preferredChannels, equals([NotificationChannel.email]));
      expect(updated.updatedAt, equals(testDateTime.add(const Duration(hours: 1))));
    });
  });
}