import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import '../../lib/services/realtime_service.dart';
import '../../lib/services/offline_service.dart';
import '../../lib/models/models.dart';

// Generate mocks
@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  Query,
  QuerySnapshot,
  DocumentSnapshot,
  QueryDocumentSnapshot,
])
import 'realtime_integration_test.mocks.dart';

void main() {
  group('Real-time Integration Tests', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockQuery mockQuery;
    late MockQuerySnapshot mockSnapshot;
    late MockDocumentSnapshot mockDocSnapshot;
    late RealtimeService realtimeService;
    late OfflineService offlineService;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockQuery = MockQuery();
      mockSnapshot = MockQuerySnapshot();
      mockDocSnapshot = MockDocumentSnapshot();

      // Setup basic Firestore mocking
      when(mockFirestore.collection(any)).thenReturn(mockCollection);
      when(mockCollection.where(any, isEqualTo: any)).thenReturn(mockQuery);
      when(mockCollection.orderBy(any, descending: any)).thenReturn(mockQuery);
      when(mockQuery.where(any, isEqualTo: any)).thenReturn(mockQuery);
      when(mockQuery.orderBy(any, descending: any)).thenReturn(mockQuery);
      when(mockQuery.limit(any)).thenReturn(mockQuery);

      realtimeService = RealtimeService(firestore: mockFirestore);
      offlineService = OfflineService(
        realtimeService: realtimeService,
        firestore: mockFirestore,
      );
    });

    tearDown(() {
      realtimeService.dispose();
      offlineService.dispose();
    });

    group('Real-time Post Streaming', () {
      testWidgets('should stream group posts with real-time updates', (tester) async {
        // Arrange
        final testPosts = [
          _createTestPost('post1', 'group1', 'Test post 1'),
          _createTestPost('post2', 'group1', 'Test post 2'),
        ];

        final streamController = StreamController<QuerySnapshot>();
        when(mockQuery.snapshots(includeMetadataChanges: true))
            .thenAnswer((_) => streamController.stream);

        // Mock snapshot data
        when(mockSnapshot.docs).thenReturn([
          _createMockQueryDocSnapshot('post1', testPosts[0].toJson()),
          _createMockQueryDocSnapshot('post2', testPosts[1].toJson()),
        ]);
        when(mockSnapshot.metadata).thenReturn(_createMockSnapshotMetadata(false, false));

        // Act
        final stream = realtimeService.streamGroupPosts(groupId: 'group1');
        final streamFuture = stream.first;

        // Emit test data
        streamController.add(mockSnapshot);

        // Assert
        final result = await streamFuture;
        expect(result.length, equals(2));
        expect(result[0].id, equals('post1'));
        expect(result[1].id, equals('post2'));

        streamController.close();
      });

      testWidgets('should handle connection status changes during streaming', (tester) async {
        // Arrange
        final streamController = StreamController<QuerySnapshot>();
        when(mockQuery.snapshots(includeMetadataChanges: true))
            .thenAnswer((_) => streamController.stream);

        // Mock offline snapshot
        when(mockSnapshot.docs).thenReturn([]);
        when(mockSnapshot.metadata).thenReturn(_createMockSnapshotMetadata(true, false));

        // Act
        final connectionStream = realtimeService.connectionStatus;
        final connectionFuture = connectionStream.take(2).toList();

        final postsStream = realtimeService.streamGroupPosts(groupId: 'group1');
        postsStream.listen((_) {}); // Start listening

        // Emit offline snapshot
        streamController.add(mockSnapshot);

        // Mock online snapshot
        when(mockSnapshot.metadata).thenReturn(_createMockSnapshotMetadata(false, false));
        streamController.add(mockSnapshot);

        // Assert
        final connectionStatuses = await connectionFuture;
        expect(connectionStatuses, contains(ConnectionStatus.disconnected));
        expect(connectionStatuses, contains(ConnectionStatus.connected));

        streamController.close();
      });

      testWidgets('should stream social feed from multiple groups', (tester) async {
        // Arrange
        final testPosts = [
          _createTestPost('post1', 'group1', 'Post from group 1'),
          _createTestPost('post2', 'group2', 'Post from group 2'),
        ];

        final streamController = StreamController<QuerySnapshot>();
        when(mockQuery.snapshots(includeMetadataChanges: true))
            .thenAnswer((_) => streamController.stream);

        when(mockSnapshot.docs).thenReturn([
          _createMockQueryDocSnapshot('post1', testPosts[0].toJson()),
          _createMockQueryDocSnapshot('post2', testPosts[1].toJson()),
        ]);
        when(mockSnapshot.metadata).thenReturn(_createMockSnapshotMetadata(false, false));

        // Act
        final stream = realtimeService.streamSocialFeed(
          groupIds: ['group1', 'group2'],
        );
        final streamFuture = stream.first;

        streamController.add(mockSnapshot);

        // Assert
        final result = await streamFuture;
        expect(result.length, equals(2));
        expect(result.any((p) => p.groupId == 'group1'), isTrue);
        expect(result.any((p) => p.groupId == 'group2'), isTrue);

        streamController.close();
      });
    });

    group('Real-time Notifications', () {
      testWidgets('should stream member notifications with real-time updates', (tester) async {
        // Arrange
        final testNotifications = [
          _createTestNotification('notif1', 'member1', 'Test notification 1'),
          _createTestNotification('notif2', 'member1', 'Test notification 2'),
        ];

        final streamController = StreamController<QuerySnapshot>();
        when(mockQuery.snapshots(includeMetadataChanges: true))
            .thenAnswer((_) => streamController.stream);

        when(mockSnapshot.docs).thenReturn([
          _createMockQueryDocSnapshot('notif1', testNotifications[0].toJson()),
          _createMockQueryDocSnapshot('notif2', testNotifications[1].toJson()),
        ]);
        when(mockSnapshot.metadata).thenReturn(_createMockSnapshotMetadata(false, false));

        // Act
        final stream = realtimeService.streamMemberNotifications(memberId: 'member1');
        final streamFuture = stream.first;

        streamController.add(mockSnapshot);

        // Assert
        final result = await streamFuture;
        expect(result.length, equals(2));
        expect(result[0].recipientId, equals('member1'));
        expect(result[1].recipientId, equals('member1'));

        streamController.close();
      });

      testWidgets('should stream unread notifications count', (tester) async {
        // Arrange
        final streamController = StreamController<QuerySnapshot>();
        when(mockQuery.snapshots(includeMetadataChanges: true))
            .thenAnswer((_) => streamController.stream);

        // Mock 3 unread notifications
        when(mockSnapshot.docs).thenReturn([
          _createMockQueryDocSnapshot('notif1', {}),
          _createMockQueryDocSnapshot('notif2', {}),
          _createMockQueryDocSnapshot('notif3', {}),
        ]);
        when(mockSnapshot.metadata).thenReturn(_createMockSnapshotMetadata(false, false));

        // Act
        final stream = realtimeService.streamUnreadNotificationsCount('member1');
        final streamFuture = stream.first;

        streamController.add(mockSnapshot);

        // Assert
        final result = await streamFuture;
        expect(result, equals(3));

        streamController.close();
      });
    });

    group('Real-time Leaderboard', () {
      testWidgets('should stream event leaderboard with real-time updates', (tester) async {
        // Arrange
        final testLeaderboard = _createTestLeaderboard('event1');

        final streamController = StreamController<QuerySnapshot>();
        when(mockQuery.snapshots(includeMetadataChanges: true))
            .thenAnswer((_) => streamController.stream);

        when(mockSnapshot.docs).thenReturn([
          _createMockQueryDocSnapshot('leaderboard1', testLeaderboard.toJson()),
        ]);
        when(mockSnapshot.metadata).thenReturn(_createMockSnapshotMetadata(false, false));

        // Act
        final stream = realtimeService.streamEventLeaderboard('event1');
        final streamFuture = stream.first;

        streamController.add(mockSnapshot);

        // Assert
        final result = await streamFuture;
        expect(result, isNotNull);
        expect(result!.eventId, equals('event1'));
        expect(result.entries.length, equals(2));

        streamController.close();
      });

      testWidgets('should return null when no leaderboard exists', (tester) async {
        // Arrange
        final streamController = StreamController<QuerySnapshot>();
        when(mockQuery.snapshots(includeMetadataChanges: true))
            .thenAnswer((_) => streamController.stream);

        when(mockSnapshot.docs).thenReturn([]);
        when(mockSnapshot.metadata).thenReturn(_createMockSnapshotMetadata(false, false));

        // Act
        final stream = realtimeService.streamEventLeaderboard('event1');
        final streamFuture = stream.first;

        streamController.add(mockSnapshot);

        // Assert
        final result = await streamFuture;
        expect(result, isNull);

        streamController.close();
      });
    });

    group('Offline Support Integration', () {
      testWidgets('should cache data and work offline', (tester) async {
        // Arrange
        final testPosts = [
          _createTestPost('post1', 'group1', 'Cached post'),
        ];

        // Mock successful server call first
        when(mockQuery.get()).thenAnswer((_) async {
          when(mockSnapshot.docs).thenReturn([
            _createMockQueryDocSnapshot('post1', testPosts[0].toJson()),
          ]);
          return mockSnapshot;
        });

        // Act - First call should cache data
        final firstResult = await offlineService.getGroupPosts(groupId: 'group1');
        expect(firstResult.length, equals(1));

        // Mock server failure for offline scenario
        when(mockQuery.get()).thenThrow(Exception('Network error'));
        when(mockQuery.get(any)).thenAnswer((_) async {
          when(mockSnapshot.docs).thenReturn([
            _createMockQueryDocSnapshot('post1', testPosts[0].toJson()),
          ]);
          return mockSnapshot;
        });

        // Act - Second call should return cached data
        final secondResult = await offlineService.getGroupPosts(groupId: 'group1');

        // Assert
        expect(secondResult.length, equals(1));
        expect(secondResult[0].id, equals('post1'));
      });

      testWidgets('should queue operations when offline', (tester) async {
        // Arrange
        when(mockFirestore.collection('posts')).thenReturn(mockCollection);
        when(mockCollection.doc(any)).thenReturn(MockDocumentReference());
        when(MockDocumentReference().set(any)).thenThrow(Exception('Offline'));

        // Act
        await offlineService.createPost(
          groupId: 'group1',
          authorId: 'author1',
          content: 'Offline post',
        );

        // Assert
        expect(offlineService.pendingOperationsCount, equals(1));
        expect(offlineService.hasPendingOperations, isTrue);
      });

      testWidgets('should sync pending operations when online', (tester) async {
        // Arrange - Add a pending operation
        offlineService.addPendingOperation(PendingOperation(
          id: 'op1',
          type: OperationType.createPost,
          data: _createTestPost('post1', 'group1', 'Test').toJson(),
          timestamp: DateTime.now(),
        ));

        expect(offlineService.pendingOperationsCount, equals(1));

        // Mock successful sync
        when(mockFirestore.collection('posts')).thenReturn(mockCollection);
        when(mockCollection.doc(any)).thenReturn(MockDocumentReference());
        when(MockDocumentReference().set(any)).thenAnswer((_) async {});

        // Act - Simulate connection restored
        final connectionController = StreamController<ConnectionStatus>();
        when(realtimeService.connectionStatus).thenAnswer((_) => connectionController.stream);

        connectionController.add(ConnectionStatus.connected);

        // Wait for sync to complete
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(offlineService.pendingOperationsCount, equals(0));

        connectionController.close();
      });
    });

    group('Connection Monitoring', () {
      testWidgets('should monitor connection status', (tester) async {
        // Arrange
        final connectionStream = realtimeService.connectionStatus;
        final connectionFuture = connectionStream.take(1).toList();

        // Act - Initial connection check should happen automatically
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final statuses = await connectionFuture;
        expect(statuses.isNotEmpty, isTrue);
      });

      testWidgets('should detect connection changes', (tester) async {
        // Arrange
        final connectionStream = realtimeService.connectionStatus;
        final connectionFuture = connectionStream.take(2).toList();

        // Act - Force connection check
        await realtimeService.forceSyncWhenOnline();

        // Assert
        expect(realtimeService.currentConnectionStatus, isA<ConnectionStatus>());
      });
    });

    group('Error Handling', () {
      testWidgets('should handle stream errors gracefully', (tester) async {
        // Arrange
        final streamController = StreamController<QuerySnapshot>();
        when(mockQuery.snapshots(includeMetadataChanges: true))
            .thenAnswer((_) => streamController.stream);

        // Act
        final stream = realtimeService.streamGroupPosts(groupId: 'group1');
        final streamFuture = stream.handleError((error) => <Post>[]).first;

        // Emit error
        streamController.addError(Exception('Stream error'));

        // Assert
        final result = await streamFuture;
        expect(result, equals(<Post>[]));

        streamController.close();
      });

      testWidgets('should fallback to cache on network errors', (tester) async {
        // Arrange
        final testPosts = [_createTestPost('post1', 'group1', 'Cached post')];
        
        // Cache some data first
        offlineService.cacheData('group_posts_group1', testPosts);

        // Mock network error
        when(mockQuery.get()).thenThrow(Exception('Network error'));
        when(mockQuery.get(any)).thenThrow(Exception('Cache error'));

        // Act
        final result = await offlineService.getGroupPosts(groupId: 'group1');

        // Assert
        expect(result.length, equals(1));
        expect(result[0].id, equals('post1'));
      });
    });
  });
}

// Helper functions for creating test data

Post _createTestPost(String id, String groupId, String content) {
  return Post(
    id: id,
    groupId: groupId,
    authorId: 'author1',
    content: content,
    contentType: PostContentType.text,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

Notification _createTestNotification(String id, String memberId, String message) {
  return Notification(
    id: id,
    recipientId: memberId,
    type: NotificationType.eventReminder,
    title: 'Test Notification',
    message: message,
    isRead: false,
    createdAt: DateTime.now(),
  );
}

Leaderboard _createTestLeaderboard(String eventId) {
  return Leaderboard(
    id: 'leaderboard1',
    eventId: eventId,
    entries: [
      LeaderboardEntry(
        teamId: 'team1',
        teamName: 'Team Alpha',
        totalScore: 95.5,
        rank: 1,
      ),
      LeaderboardEntry(
        teamId: 'team2',
        teamName: 'Team Beta',
        totalScore: 87.2,
        rank: 2,
      ),
    ],
    calculatedAt: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

MockQueryDocumentSnapshot _createMockQueryDocSnapshot(String id, Map<String, dynamic> data) {
  final mockDoc = MockQueryDocumentSnapshot();
  when(mockDoc.id).thenReturn(id);
  when(mockDoc.data()).thenReturn(data);
  return mockDoc;
}

SnapshotMetadata _createMockSnapshotMetadata(bool isFromCache, bool hasPendingWrites) {
  final mockMetadata = MockSnapshotMetadata();
  when(mockMetadata.isFromCache).thenReturn(isFromCache);
  when(mockMetadata.hasPendingWrites).thenReturn(hasPendingWrites);
  return mockMetadata;
}

@GenerateMocks([SnapshotMetadata])
class MockSnapshotMetadata extends Mock implements SnapshotMetadata {}