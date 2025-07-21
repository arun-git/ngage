import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../lib/models/models.dart';
import '../../lib/repositories/notification_repository.dart';

// Mock classes
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}
class MockWriteBatch extends Mock implements WriteBatch {}
class MockAggregateQuerySnapshot extends Mock implements AggregateQuerySnapshot {}
class MockAggregateQuery extends Mock implements AggregateQuery {}

void main() {
  group('NotificationRepository', () {
    late NotificationRepository repository;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockNotificationsCollection;
    late MockCollectionReference mockPreferencesCollection;
    late MockDocumentReference mockDocumentReference;
    late MockDocumentSnapshot mockDocumentSnapshot;
    late MockQuerySnapshot mockQuerySnapshot;
    late MockQuery mockQuery;
    late MockWriteBatch mockBatch;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockNotificationsCollection = MockCollectionReference();
      mockPreferencesCollection = MockCollectionReference();
      mockDocumentReference = MockDocumentReference();
      mockDocumentSnapshot = MockDocumentSnapshot();
      mockQuerySnapshot = MockQuerySnapshot();
      mockQuery = MockQuery();
      mockBatch = MockWriteBatch();

      when(mockFirestore.collection('notifications'))
          .thenReturn(mockNotificationsCollection);
      when(mockFirestore.collection('notification_preferences'))
          .thenReturn(mockPreferencesCollection);

      repository = NotificationRepository(firestore: mockFirestore);
    });

    group('createNotification', () {
      test('should create notification in Firestore', () async {
        // Arrange
        final notification = Notification(
          id: 'test-id',
          recipientId: 'member-1',
          type: NotificationType.eventReminder,
          title: 'Test Notification',
          message: 'Test message',
          createdAt: DateTime.now(),
        );

        when(mockNotificationsCollection.doc(notification.id))
            .thenReturn(mockDocumentReference);
        when(mockDocumentReference.set(any)).thenAnswer((_) async {});

        // Act
        await repository.createNotification(notification);

        // Assert
        verify(mockNotificationsCollection.doc(notification.id)).called(1);
        verify(mockDocumentReference.set(notification.toJson())).called(1);
      });
    });

    group('getMemberNotifications', () {
      test('should retrieve notifications for member with pagination', () async {
        // Arrange
        const memberId = 'member-1';
        const limit = 10;
        final lastCreatedAt = DateTime.now().subtract(const Duration(hours: 1));

        final mockNotificationData = {
          'id': 'notif-1',
          'recipientId': memberId,
          'type': 'event_reminder',
          'title': 'Test Notification',
          'message': 'Test message',
          'isRead': false,
          'channels': ['in_app'],
          'priority': 'normal',
          'createdAt': DateTime.now().toIso8601String(),
        };

        final mockQueryDocumentSnapshot = MockQueryDocumentSnapshot();
        when(mockQueryDocumentSnapshot.data()).thenReturn(mockNotificationData);

        when(mockNotificationsCollection.where('recipientId', isEqualTo: memberId))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.startAfter([lastCreatedAt.toIso8601String()]))
            .thenReturn(mockQuery);
        when(mockQuery.limit(limit)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocumentSnapshot]);

        // Act
        final notifications = await repository.getMemberNotifications(
          memberId,
          limit: limit,
          lastCreatedAt: lastCreatedAt,
        );

        // Assert
        expect(notifications, hasLength(1));
        expect(notifications.first.id, equals('notif-1'));
        expect(notifications.first.recipientId, equals(memberId));
        verify(mockQuery.startAfter([lastCreatedAt.toIso8601String()])).called(1);
        verify(mockQuery.limit(limit)).called(1);
      });
    });

    group('getUnreadNotificationsCount', () {
      test('should return count of unread notifications', () async {
        // Arrange
        const memberId = 'member-1';
        const expectedCount = 5;

        final mockAggregateQuery = MockAggregateQuery();
        final mockAggregateQuerySnapshot = MockAggregateQuerySnapshot();

        when(mockNotificationsCollection.where('recipientId', isEqualTo: memberId))
            .thenReturn(mockQuery);
        when(mockQuery.where('isRead', isEqualTo: false))
            .thenReturn(mockQuery);
        when(mockQuery.count()).thenReturn(mockAggregateQuery);
        when(mockAggregateQuery.get())
            .thenAnswer((_) async => mockAggregateQuerySnapshot);
        when(mockAggregateQuerySnapshot.count).thenReturn(expectedCount);

        // Act
        final count = await repository.getUnreadNotificationsCount(memberId);

        // Assert
        expect(count, equals(expectedCount));
      });
    });

    group('markNotificationAsRead', () {
      test('should mark notification as read with timestamp', () async {
        // Arrange
        const notificationId = 'notif-1';

        when(mockNotificationsCollection.doc(notificationId))
            .thenReturn(mockDocumentReference);
        when(mockDocumentReference.update(any)).thenAnswer((_) async {});

        // Act
        await repository.markNotificationAsRead(notificationId);

        // Assert
        verify(mockNotificationsCollection.doc(notificationId)).called(1);
        verify(mockDocumentReference.update(argThat(allOf(
          containsPair('isRead', true),
          containsKey('readAt'),
        )))).called(1);
      });
    });

    group('markAllNotificationsAsRead', () {
      test('should mark all unread notifications as read for member', () async {
        // Arrange
        const memberId = 'member-1';

        final mockQueryDocumentSnapshot1 = MockQueryDocumentSnapshot();
        final mockQueryDocumentSnapshot2 = MockQueryDocumentSnapshot();
        when(mockQueryDocumentSnapshot1.reference).thenReturn(mockDocumentReference);
        when(mockQueryDocumentSnapshot2.reference).thenReturn(mockDocumentReference);

        when(mockNotificationsCollection.where('recipientId', isEqualTo: memberId))
            .thenReturn(mockQuery);
        when(mockQuery.where('isRead', isEqualTo: false))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs)
            .thenReturn([mockQueryDocumentSnapshot1, mockQueryDocumentSnapshot2]);

        when(mockFirestore.batch()).thenReturn(mockBatch);
        when(mockBatch.update(any, any)).thenReturn(mockBatch);
        when(mockBatch.commit()).thenAnswer((_) async {});

        // Act
        await repository.markAllNotificationsAsRead(memberId);

        // Assert
        verify(mockBatch.update(mockDocumentReference, argThat(allOf(
          containsPair('isRead', true),
          containsKey('readAt'),
        )))).called(2);
        verify(mockBatch.commit()).called(1);
      });
    });

    group('getScheduledNotifications', () {
      test('should retrieve notifications scheduled for current time or earlier', () async {
        // Arrange
        final now = DateTime.now();
        final mockNotificationData = {
          'id': 'scheduled-1',
          'recipientId': 'member-1',
          'type': 'event_reminder',
          'title': 'Scheduled Notification',
          'message': 'This was scheduled',
          'isRead': false,
          'channels': ['in_app'],
          'priority': 'normal',
          'scheduledAt': now.subtract(const Duration(minutes: 1)).toIso8601String(),
          'createdAt': now.toIso8601String(),
        };

        final mockQueryDocumentSnapshot = MockQueryDocumentSnapshot();
        when(mockQueryDocumentSnapshot.data()).thenReturn(mockNotificationData);

        when(mockNotificationsCollection.where('scheduledAt', isLessThanOrEqualTo: any))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocumentSnapshot]);

        // Act
        final notifications = await repository.getScheduledNotifications();

        // Assert
        expect(notifications, hasLength(1));
        expect(notifications.first.id, equals('scheduled-1'));
        expect(notifications.first.scheduledAt, isNotNull);
      });
    });

    group('notification preferences', () {
      test('should save notification preferences', () async {
        // Arrange
        final preferences = NotificationPreferences(
          memberId: 'member-1',
          eventReminders: false,
          deadlineAlerts: true,
          preferredChannels: [NotificationChannel.email],
          updatedAt: DateTime.now(),
        );

        when(mockPreferencesCollection.doc(preferences.memberId))
            .thenReturn(mockDocumentReference);
        when(mockDocumentReference.set(any)).thenAnswer((_) async {});

        // Act
        await repository.saveNotificationPreferences(preferences);

        // Assert
        verify(mockPreferencesCollection.doc(preferences.memberId)).called(1);
        verify(mockDocumentReference.set(preferences.toJson())).called(1);
      });

      test('should retrieve notification preferences', () async {
        // Arrange
        const memberId = 'member-1';
        final preferencesData = {
          'memberId': memberId,
          'eventReminders': false,
          'deadlineAlerts': true,
          'resultAnnouncements': true,
          'leaderboardUpdates': false,
          'preferredChannels': ['email'],
          'typePreferences': {},
          'updatedAt': DateTime.now().toIso8601String(),
        };

        when(mockPreferencesCollection.doc(memberId))
            .thenReturn(mockDocumentReference);
        when(mockDocumentReference.get())
            .thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn(preferencesData);

        // Act
        final preferences = await repository.getNotificationPreferences(memberId);

        // Assert
        expect(preferences, isNotNull);
        expect(preferences!.memberId, equals(memberId));
        expect(preferences.eventReminders, isFalse);
        expect(preferences.deadlineAlerts, isTrue);
        expect(preferences.preferredChannels, contains(NotificationChannel.email));
      });

      test('should return null when preferences do not exist', () async {
        // Arrange
        const memberId = 'member-1';

        when(mockPreferencesCollection.doc(memberId))
            .thenReturn(mockDocumentReference);
        when(mockDocumentReference.get())
            .thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(false);

        // Act
        final preferences = await repository.getNotificationPreferences(memberId);

        // Assert
        expect(preferences, isNull);
      });
    });

    group('batch operations', () {
      test('should create multiple notifications in batch', () async {
        // Arrange
        final notifications = [
          Notification(
            id: 'notif-1',
            recipientId: 'member-1',
            type: NotificationType.eventReminder,
            title: 'Notification 1',
            message: 'Message 1',
            createdAt: DateTime.now(),
          ),
          Notification(
            id: 'notif-2',
            recipientId: 'member-2',
            type: NotificationType.deadlineAlert,
            title: 'Notification 2',
            message: 'Message 2',
            createdAt: DateTime.now(),
          ),
        ];

        when(mockFirestore.batch()).thenReturn(mockBatch);
        when(mockNotificationsCollection.doc(any)).thenReturn(mockDocumentReference);
        when(mockBatch.set(any, any)).thenReturn(mockBatch);
        when(mockBatch.commit()).thenAnswer((_) async {});

        // Act
        await repository.createNotificationsBatch(notifications);

        // Assert
        verify(mockBatch.set(mockDocumentReference, any)).called(2);
        verify(mockBatch.commit()).called(1);
      });
    });

    group('cleanup operations', () {
      test('should delete old notifications', () async {
        // Arrange
        final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
        final mockQueryDocumentSnapshot = MockQueryDocumentSnapshot();
        when(mockQueryDocumentSnapshot.reference).thenReturn(mockDocumentReference);

        when(mockNotificationsCollection.where('createdAt', isLessThan: cutoffDate.toIso8601String()))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocumentSnapshot]);

        when(mockFirestore.batch()).thenReturn(mockBatch);
        when(mockBatch.delete(any)).thenReturn(mockBatch);
        when(mockBatch.commit()).thenAnswer((_) async {});

        // Act
        await repository.deleteOldNotifications(olderThan: const Duration(days: 30));

        // Assert
        verify(mockBatch.delete(mockDocumentReference)).called(1);
        verify(mockBatch.commit()).called(1);
      });
    });
  });
}

// Mock class for QueryDocumentSnapshot
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}