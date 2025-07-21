import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import 'package:ngage/services/realtime_service.dart';
import 'package:ngage/models/models.dart';

// Generate mocks
@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  Query,
  QuerySnapshot,
  DocumentSnapshot,
  QueryDocumentSnapshot,
  SnapshotMetadata,
])
import 'realtime_service_test.mocks.dart';

void main() {
  group('RealtimeService', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocument;
    late MockQuery mockQuery;
    late MockQuerySnapshot mockSnapshot;
    late MockDocumentSnapshot mockDocSnapshot;
    late RealtimeService realtimeService;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockDocument = MockDocumentReference();
      mockQuery = MockQuery();
      mockSnapshot = MockQuerySnapshot();
      mockDocSnapshot = MockDocumentSnapshot();

      // Setup basic mocking
      when(mockFirestore.collection(any)).thenReturn(mockCollection);
      when(mockFirestore.enablePersistence()).thenAnswer((_) async {});
      when(mockCollection.doc(any)).thenReturn(mockDocument);
      when(mockCollection.where(any, isEqualTo: any)).thenReturn(mockQuery);
      when(mockCollection.where(any, whereIn: any)).thenReturn(mockQuery);
      when(mockQuery.where(any, isEqualTo: any)).thenReturn(mockQuery);
      when(mockQuery.orderBy(any, descending: any)).thenReturn(mockQuery);
      when(mockQuery.limit(any)).thenReturn(mockQuery);

      realtimeService = RealtimeService(firestore: mockFirestore);
    });

    tearDown(() {
      realtimeService.dispose();
    });

    group('Connection Monitoring', () {
      test('should initialize with connection monitoring', () {
        // Assert
        expect(realtimeService.currentConnectionStatus, isA<ConnectionStatus>());
      });

      test('should provide connection status stream', () {
        // Act
        final stream = realtimeService.connectionStatus;

        // Assert
        expect(stream, isA<Stream<ConnectionStatus>>());
      });

      test('should force sync when online', () async {
        // Arrange
        when(mockDocument.get(any)).thenAnswer((_) async => mockDocSnapshot);

        // Act
        await realtimeService.forceSyncWhenOnline();

        // Assert - Should not throw
        expect(realtimeService.currentConnectionStatus, isA<ConnectionStatus>());
      });
    });

    group('Real-time Post Streaming', () {
      test('should stream group posts', () async {
        // Arrange
        final testPosts = [
          _createTestPost('post1', 'group1', 'Test post 1'),
          _createTestPost('post2', 'group1', 'Test post 2'),
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
        final stream = realtimeService.streamGroupPosts(groupId: 'group1');
        final streamFuture = stream.first;

        streamController.add(mockSnapshot);

        // Assert
        final result = await streamFuture;
        expect(result.length, equals(2));
        expect(result[0].id, equals('post1'));
        expect(result[1].id, equals('post2'));

        streamController.close();
      });

      test('should stream social feed from multiple groups', () async {
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

      test('should return empty stream for empty group list', () async {
        // Act
        final stream = realtimeService.streamSocialFeed(groupIds: []);
        final result = await stream.first;

        // Assert
        expect(result, isEmpty);
      });

      test('should handle large group lists (>10 groups)', () async {
        // Arrange
        final groupIds = List.generate(15, (i) => 'group$i');
        final testPosts = [_createTestPost('post1', 'group1', 'Test post')];

        final streamController = StreamController<QuerySnapshot>();
        when(mockQuery.snapshots()).thenAnswer((_) => streamController.stream);

        when(mockSnapshot.docs).thenReturn([
          _createMockQueryDocSnapshot('post1', testPosts[0].toJson()),
        ]);

        // Act
        final stream = realtimeService.streamSocialFeed(groupIds: groupIds);
        final streamFuture = stream.first;

        streamController.add(mockSnapshot);

        // Assert
        final result = await streamFuture;
        expect(result, isA<List<Post>>());

        streamController.close();
      });
    });

    group('Real-time Comments Streaming', () {
      test('should stream post comments', () async {
        // Arrange
        final testComments = [
          _createTestComment('comment1', 'post1', 'Test comment 1'),
          _createTestComment('comment2', 'post1', 'Test comment 2'),
        ];

        final streamController = StreamController<QuerySnapshot>();
        when(mockQuery.snapshots(includeMetadataChanges: true))
            .thenAnswer((_) => streamController.stream);

        when(mockSnapshot.docs).thenReturn([
          _createMockQueryDocSnapshot('comment1', testComments[0].toJson()),
          _createMockQueryDocSnapshot('comment2', testComments[1].toJson()),
        ]);
        when(mockSnapshot.metadata).thenReturn(_createMockSnapshotMetadata(false, false));

        // Act
        final stream = realtimeService.streamPostComments(postId: 'post1');
        final streamFuture = stream.first;

        streamController.add(mockSnapshot);

        // Assert
        final result = await streamFuture;
        expect(result.length, equals(2));
        expect(result[0].postId, equals('post1'));
        expect(result[1].postId, equals('post1'));

        streamController.close();
      });
    });

    group('Real-time Notifications Streaming', () {
      test('should stream member notifications', () async {
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

      test('should stream unread notifications count', () async {
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

    group('Real-time Leaderboard Streaming', () {
      test('should stream event leaderboard', () async {
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

        streamController.close();
      });

      test('should return null when no leaderboard exists', () async {
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

    group('Real-time Event Streaming', () {
      test('should stream event updates', () async {
        // Arrange
        final testEvent = _createTestEvent('event1', 'group1');

        final streamController = StreamController<DocumentSnapshot>();
        when(mockDocument.snapshots(includeMetadataChanges: true))
            .thenAnswer((_) => streamController.stream);

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(testEvent.toJson());
        when(mockDocSnapshot.id).thenReturn('event1');
        when(mockDocSnapshot.metadata).thenReturn(_createMockSnapshotMetadata(false, false));

        // Act
        final stream = realtimeService.streamEvent('event1');
        final streamFuture = stream.first;

        streamController.add(mockDocSnapshot);

        // Assert
        final result = await streamFuture;
        expect(result, isNotNull);
        expect(result!.id, equals('event1'));

        streamController.close();
      });

      test('should return null when event does not exist', () async {
        // Arrange
        final streamController = StreamController<DocumentSnapshot>();
        when(mockDocument.snapshots(includeMetadataChanges: true))
            .thenAnswer((_) => streamController.stream);

        when(mockDocSnapshot.exists).thenReturn(false);
        when(mockDocSnapshot.metadata).thenReturn(_createMockSnapshotMetadata(false, false));

        // Act
        final stream = realtimeService.streamEvent('event1');
        final streamFuture = stream.first;

        streamController.add(mockDocSnapshot);

        // Assert
        final result = await streamFuture;
        expect(result, isNull);

        streamController.close();
      });
    });

    group('Real-time Submissions Streaming', () {
      test('should stream event submissions', () async {
        // Arrange
        final testSubmissions = [
          _createTestSubmission('sub1', 'event1', 'team1'),
          _createTestSubmission('sub2', 'event1', 'team2'),
        ];

        final streamController = StreamController<QuerySnapshot>();
        when(mockQuery.snapshots(includeMetadataChanges: true))
            .thenAnswer((_) => streamController.stream);

        when(mockSnapshot.docs).thenReturn([
          _createMockQueryDocSnapshot('sub1', testSubmissions[0].toJson()),
          _createMockQueryDocSnapshot('sub2', testSubmissions[1].toJson()),
        ]);
        when(mockSnapshot.metadata).thenReturn(_createMockSnapshotMetadata(false, false));

        // Act
        final stream = realtimeService.streamEventSubmissions(eventId: 'event1');
        final streamFuture = stream.first;

        streamController.add(mockSnapshot);

        // Assert
        final result = await streamFuture;
        expect(result.length, equals(2));
        expect(result[0].eventId, equals('event1'));
        expect(result[1].eventId, equals('event1'));

        streamController.close();
      });

      test('should stream team-specific submissions', () async {
        // Arrange
        final testSubmissions = [
          _createTestSubmission('sub1', 'event1', 'team1'),
        ];

        final streamController = StreamController<QuerySnapshot>();
        when(mockQuery.snapshots(includeMetadataChanges: true))
            .thenAnswer((_) => streamController.stream);

        when(mockSnapshot.docs).thenReturn([
          _createMockQueryDocSnapshot('sub1', testSubmissions[0].toJson()),
        ]);
        when(mockSnapshot.metadata).thenReturn(_createMockSnapshotMetadata(false, false));

        // Act
        final stream = realtimeService.streamEventSubmissions(
          eventId: 'event1',
          teamId: 'team1',
        );
        final streamFuture = stream.first;

        streamController.add(mockSnapshot);

        // Assert
        final result = await streamFuture;
        expect(result.length, equals(1));
        expect(result[0].teamId, equals('team1'));

        streamController.close();
      });
    });

    group('Cached Data Retrieval', () {
      test('should get cached group posts', () async {
        // Arrange
        final testPosts = [_createTestPost('post1', 'group1', 'Cached post')];

        when(mockQuery.get(any)).thenAnswer((_) async {
          when(mockSnapshot.docs).thenReturn([
            _createMockQueryDocSnapshot('post1', testPosts[0].toJson()),
          ]);
          return mockSnapshot;
        });

        // Act
        final result = await realtimeService.getCachedGroupPosts(groupId: 'group1');

        // Assert
        expect(result.length, equals(1));
        expect(result[0].id, equals('post1'));
      });

      test('should return empty list when cache fails', () async {
        // Arrange
        when(mockQuery.get(any)).thenThrow(Exception('Cache error'));

        // Act
        final result = await realtimeService.getCachedGroupPosts(groupId: 'group1');

        // Assert
        expect(result, isEmpty);
      });

      test('should get cached notifications', () async {
        // Arrange
        final testNotifications = [_createTestNotification('notif1', 'member1', 'Cached')];

        when(mockQuery.get(any)).thenAnswer((_) async {
          when(mockSnapshot.docs).thenReturn([
            _createMockQueryDocSnapshot('notif1', testNotifications[0].toJson()),
          ]);
          return mockSnapshot;
        });

        // Act
        final result = await realtimeService.getCachedNotifications(memberId: 'member1');

        // Assert
        expect(result.length, equals(1));
        expect(result[0].id, equals('notif1'));
      });

      test('should get cached leaderboard', () async {
        // Arrange
        final testLeaderboard = _createTestLeaderboard('event1');

        when(mockQuery.get(any)).thenAnswer((_) async {
          when(mockSnapshot.docs).thenReturn([
            _createMockQueryDocSnapshot('leaderboard1', testLeaderboard.toJson()),
          ]);
          return mockSnapshot;
        });

        // Act
        final result = await realtimeService.getCachedLeaderboard('event1');

        // Assert
        expect(result, isNotNull);
        expect(result!.eventId, equals('event1'));
      });
    });

    group('Connection Status Handling', () {
      test('should update connection status based on snapshot metadata', () async {
        // Arrange
        final streamController = StreamController<QuerySnapshot>();
        when(mockQuery.snapshots(includeMetadataChanges: true))
            .thenAnswer((_) => streamController.stream);

        // Mock offline snapshot
        when(mockSnapshot.docs).thenReturn([]);
        when(mockSnapshot.metadata).thenReturn(_createMockSnapshotMetadata(true, false));

        // Act
        final stream = realtimeService.streamGroupPosts(groupId: 'group1');
        stream.listen((_) {}); // Start listening

        final connectionStream = realtimeService.connectionStatus;
        final connectionFuture = connectionStream.first;

        streamController.add(mockSnapshot);

        // Assert
        final status = await connectionFuture;
        expect(status, equals(ConnectionStatus.disconnected));

        streamController.close();
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

PostComment _createTestComment(String id, String postId, String content) {
  return PostComment(
    id: id,
    postId: postId,
    authorId: 'author1',
    content: content,
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
      const LeaderboardEntry(
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

Event _createTestEvent(String id, String groupId) {
  return Event(
    id: id,
    groupId: groupId,
    title: 'Test Event',
    description: 'Test event description',
    eventType: EventType.competition,
    status: EventStatus.active,
    createdBy: 'creator1',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

Submission _createTestSubmission(String id, String eventId, String teamId) {
  return Submission(
    id: id,
    eventId: eventId,
    teamId: teamId,
    submittedBy: 'member1',
    content: {'text': 'Test submission'},
    status: SubmissionStatus.submitted,
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

MockSnapshotMetadata _createMockSnapshotMetadata(bool isFromCache, bool hasPendingWrites) {
  final mockMetadata = MockSnapshotMetadata();
  when(mockMetadata.isFromCache).thenReturn(isFromCache);
  when(mockMetadata.hasPendingWrites).thenReturn(hasPendingWrites);
  return mockMetadata;
}