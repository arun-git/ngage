import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../lib/services/offline_service.dart';
import '../../lib/services/realtime_service.dart';
import '../../lib/models/models.dart';

// Generate mocks
@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  Query,
  QuerySnapshot,
  DocumentSnapshot,
  RealtimeService,
])
import 'offline_service_test.mocks.dart';

void main() {
  group('OfflineService', () {
    late MockFirebaseFirestore mockFirestore;
    late MockRealtimeService mockRealtimeService;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocument;
    late MockQuery mockQuery;
    late MockQuerySnapshot mockSnapshot;
    late OfflineService offlineService;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockRealtimeService = MockRealtimeService();
      mockCollection = MockCollectionReference();
      mockDocument = MockDocumentReference();
      mockQuery = MockQuery();
      mockSnapshot = MockQuerySnapshot();

      // Setup basic mocking
      when(mockFirestore.collection(any)).thenReturn(mockCollection);
      when(mockCollection.doc(any)).thenReturn(mockDocument);
      when(mockCollection.where(any, isEqualTo: any)).thenReturn(mockQuery);
      when(mockQuery.where(any, isEqualTo: any)).thenReturn(mockQuery);
      when(mockQuery.orderBy(any, descending: any)).thenReturn(mockQuery);
      when(mockQuery.limit(any)).thenReturn(mockQuery);

      offlineService = OfflineService(
        realtimeService: mockRealtimeService,
        firestore: mockFirestore,
      );
    });

    tearDown(() {
      offlineService.dispose();
    });

    group('Local Caching', () {
      test('should cache and retrieve data', () {
        // Arrange
        const testKey = 'test_key';
        const testData = 'test_data';

        // Act
        offlineService.cacheData(testKey, testData);
        final result = offlineService.getCachedData<String>(testKey);

        // Assert
        expect(result, equals(testData));
      });

      test('should return null for non-existent cache key', () {
        // Act
        final result = offlineService.getCachedData<String>('non_existent');

        // Assert
        expect(result, isNull);
      });

      test('should remove cached data', () {
        // Arrange
        const testKey = 'test_key';
        const testData = 'test_data';
        offlineService.cacheData(testKey, testData);

        // Act
        offlineService.removeCachedData(testKey);
        final result = offlineService.getCachedData<String>(testKey);

        // Assert
        expect(result, isNull);
      });

      test('should clear all cached data', () {
        // Arrange
        offlineService.cacheData('key1', 'data1');
        offlineService.cacheData('key2', 'data2');

        // Act
        offlineService.clearCache();

        // Assert
        expect(offlineService.getCachedData<String>('key1'), isNull);
        expect(offlineService.getCachedData<String>('key2'), isNull);
      });
    });

    group('Offline-First Data Retrieval', () {
      test('should get group posts from server and cache them', () async {
        // Arrange
        final testPosts = [
          _createTestPost('post1', 'group1', 'Test post 1'),
          _createTestPost('post2', 'group1', 'Test post 2'),
        ];

        when(mockQuery.get()).thenAnswer((_) async {
          when(mockSnapshot.docs).thenReturn([
            _createMockQueryDocSnapshot('post1', testPosts[0].toJson()),
            _createMockQueryDocSnapshot('post2', testPosts[1].toJson()),
          ]);
          return mockSnapshot;
        });

        // Act
        final result = await offlineService.getGroupPosts(groupId: 'group1');

        // Assert
        expect(result.length, equals(2));
        expect(result[0].id, equals('post1'));
        expect(result[1].id, equals('post2'));

        // Verify data was cached
        final cached = offlineService.getCachedData<List<Post>>('group_posts_group1');
        expect(cached, isNotNull);
        expect(cached!.length, equals(2));
      });

      test('should return cached data when server fails', () async {
        // Arrange
        final testPosts = [_createTestPost('post1', 'group1', 'Cached post')];
        offlineService.cacheData('group_posts_group1', testPosts);

        when(mockQuery.get()).thenThrow(Exception('Network error'));
        when(mockQuery.get(any)).thenThrow(Exception('Cache error'));

        // Act
        final result = await offlineService.getGroupPosts(groupId: 'group1');

        // Assert
        expect(result.length, equals(1));
        expect(result[0].id, equals('post1'));
      });

      test('should get notifications from server and cache them', () async {
        // Arrange
        final testNotifications = [
          _createTestNotification('notif1', 'member1', 'Test notification'),
        ];

        when(mockQuery.get()).thenAnswer((_) async {
          when(mockSnapshot.docs).thenReturn([
            _createMockQueryDocSnapshot('notif1', testNotifications[0].toJson()),
          ]);
          return mockSnapshot;
        });

        // Act
        final result = await offlineService.getMemberNotifications(memberId: 'member1');

        // Assert
        expect(result.length, equals(1));
        expect(result[0].id, equals('notif1'));

        // Verify data was cached
        final cached = offlineService.getCachedData<List<Notification>>('notifications_member1');
        expect(cached, isNotNull);
        expect(cached!.length, equals(1));
      });

      test('should get leaderboard from server and cache it', () async {
        // Arrange
        final testLeaderboard = _createTestLeaderboard('event1');

        when(mockQuery.get()).thenAnswer((_) async {
          when(mockSnapshot.docs).thenReturn([
            _createMockQueryDocSnapshot('leaderboard1', testLeaderboard.toJson()),
          ]);
          return mockSnapshot;
        });

        // Act
        final result = await offlineService.getEventLeaderboard(eventId: 'event1');

        // Assert
        expect(result, isNotNull);
        expect(result!.eventId, equals('event1'));

        // Verify data was cached
        final cached = offlineService.getCachedData<Leaderboard>('leaderboard_event1');
        expect(cached, isNotNull);
        expect(cached!.eventId, equals('event1'));
      });
    });

    group('Offline Operations', () {
      test('should create post with optimistic UI update', () async {
        // Arrange
        when(mockDocument.set(any)).thenAnswer((_) async {});

        // Act
        final result = await offlineService.createPost(
          groupId: 'group1',
          authorId: 'author1',
          content: 'Test post',
        );

        // Assert
        expect(result.groupId, equals('group1'));
        expect(result.authorId, equals('author1'));
        expect(result.content, equals('Test post'));

        // Verify post was added to cache
        final cached = offlineService.getCachedData<List<Post>>('group_posts_group1');
        expect(cached, isNotNull);
        expect(cached!.length, equals(1));
        expect(cached[0].id, equals(result.id));
      });

      test('should queue post creation when offline', () async {
        // Arrange
        when(mockDocument.set(any)).thenThrow(Exception('Offline'));

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

      test('should like post with optimistic UI update', () async {
        // Arrange
        final testPost = _createTestPost('post1', 'group1', 'Test post');
        offlineService.cacheData('group_posts_group1', [testPost]);

        when(mockDocument.set(any)).thenAnswer((_) async {});
        when(mockDocument.update(any)).thenAnswer((_) async {});

        // Act
        await offlineService.likePost(postId: 'post1', memberId: 'member1');

        // Assert
        verify(mockDocument.set(any)).called(1);
        verify(mockDocument.update(any)).called(1);

        // Verify like count was updated in cache
        final cached = offlineService.getCachedData<List<Post>>('group_posts_group1');
        expect(cached, isNotNull);
        expect(cached![0].likeCount, equals(testPost.likeCount + 1));
      });

      test('should queue like operation when offline', () async {
        // Arrange
        when(mockDocument.set(any)).thenThrow(Exception('Offline'));

        // Act
        await offlineService.likePost(postId: 'post1', memberId: 'member1');

        // Assert
        expect(offlineService.pendingOperationsCount, equals(1));
      });

      test('should add comment with optimistic UI update', () async {
        // Arrange
        when(mockDocument.set(any)).thenAnswer((_) async {});
        when(mockDocument.update(any)).thenAnswer((_) async {});

        // Act
        final result = await offlineService.addComment(
          postId: 'post1',
          authorId: 'author1',
          content: 'Test comment',
        );

        // Assert
        expect(result.postId, equals('post1'));
        expect(result.authorId, equals('author1'));
        expect(result.content, equals('Test comment'));

        // Verify comment was added to cache
        final cached = offlineService.getCachedData<List<PostComment>>('post_comments_post1');
        expect(cached, isNotNull);
        expect(cached!.length, equals(1));
      });

      test('should mark notification as read with optimistic update', () async {
        // Arrange
        final testNotification = _createTestNotification('notif1', 'member1', 'Test');
        offlineService.cacheData('notifications_member1', [testNotification]);

        when(mockDocument.update(any)).thenAnswer((_) async {});

        // Act
        await offlineService.markNotificationAsRead('notif1');

        // Assert
        verify(mockDocument.update(any)).called(1);

        // Verify notification was marked as read in cache
        final cached = offlineService.getCachedData<List<Notification>>('notifications_member1');
        expect(cached, isNotNull);
        expect(cached![0].isRead, isTrue);
      });
    });

    group('Pending Operations Management', () {
      test('should add pending operation', () {
        // Arrange
        final operation = PendingOperation(
          id: 'op1',
          type: OperationType.createPost,
          data: {'test': 'data'},
          timestamp: DateTime.now(),
        );

        // Act
        offlineService.addPendingOperation(operation);

        // Assert
        expect(offlineService.pendingOperationsCount, equals(1));
        expect(offlineService.hasPendingOperations, isTrue);
      });

      test('should serialize and deserialize pending operations', () {
        // Arrange
        final operation = PendingOperation(
          id: 'op1',
          type: OperationType.likePost,
          data: {'postId': 'post1', 'memberId': 'member1'},
          timestamp: DateTime.now(),
        );

        // Act
        final json = operation.toJson();
        final deserialized = PendingOperation.fromJson(json);

        // Assert
        expect(deserialized.id, equals(operation.id));
        expect(deserialized.type, equals(operation.type));
        expect(deserialized.data, equals(operation.data));
        expect(deserialized.timestamp, equals(operation.timestamp));
      });
    });

    group('Cache Management', () {
      test('should update post like count in all relevant caches', () {
        // Arrange
        final testPost = _createTestPost('post1', 'group1', 'Test post');
        offlineService.cacheData('group_posts_group1', [testPost]);
        offlineService.cacheData('group_posts_group2', [testPost]);

        // Act - This is tested indirectly through likePost
        when(mockDocument.set(any)).thenAnswer((_) async {});
        when(mockDocument.update(any)).thenAnswer((_) async {});
        
        offlineService.likePost(postId: 'post1', memberId: 'member1');

        // Assert
        final cached1 = offlineService.getCachedData<List<Post>>('group_posts_group1');
        final cached2 = offlineService.getCachedData<List<Post>>('group_posts_group2');
        
        expect(cached1![0].likeCount, equals(testPost.likeCount + 1));
        expect(cached2![0].likeCount, equals(testPost.likeCount + 1));
      });

      test('should update notification read status in cache', () {
        // Arrange
        final testNotification = _createTestNotification('notif1', 'member1', 'Test');
        offlineService.cacheData('notifications_member1', [testNotification]);

        // Act - This is tested indirectly through markNotificationAsRead
        when(mockDocument.update(any)).thenAnswer((_) async {});
        
        offlineService.markNotificationAsRead('notif1');

        // Assert
        final cached = offlineService.getCachedData<List<Notification>>('notifications_member1');
        expect(cached![0].isRead, isTrue);
        expect(cached[0].readAt, isNotNull);
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
    likeCount: 0,
    commentCount: 0,
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

@GenerateMocks([QueryDocumentSnapshot])
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot {}