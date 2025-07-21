import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';

import 'package:ngage/ui/widgets/realtime_post_feed.dart';
import 'package:ngage/ui/widgets/connection_status_widget.dart';
import 'package:ngage/providers/realtime_providers.dart';
import 'package:ngage/services/realtime_service.dart';
import 'package:ngage/models/models.dart';

// Generate mocks
@GenerateMocks([])
import 'realtime_widgets_test.mocks.dart';

void main() {
  group('Real-time Widget Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('ConnectionStatusWidget', () {
      testWidgets('should show connected status', (tester) async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            connectionStatusProvider.overrideWith(
              (ref) => Stream.value(ConnectionStatus.connected),
            ),
            pendingOperationsCountProvider.overrideWith((ref) => 0),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: ConnectionStatusWidget(showDetails: true),
              ),
            ),
          ),
        );

        // Assert
        expect(find.text('Online'), findsOneWidget);
        expect(find.byIcon(Icons.wifi), findsOneWidget);
      });

      testWidgets('should show disconnected status', (tester) async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            connectionStatusProvider.overrideWith(
              (ref) => Stream.value(ConnectionStatus.disconnected),
            ),
            pendingOperationsCountProvider.overrideWith((ref) => 2),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: ConnectionStatusWidget(),
              ),
            ),
          ),
        );

        // Assert
        expect(find.text('Offline (2 pending)'), findsOneWidget);
        expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      });

      testWidgets('should show reconnecting status', (tester) async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            connectionStatusProvider.overrideWith(
              (ref) => Stream.value(ConnectionStatus.reconnecting),
            ),
            pendingOperationsCountProvider.overrideWith((ref) => 0),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: ConnectionStatusWidget(),
              ),
            ),
          ),
        );

        // Assert
        expect(find.text('Reconnecting...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should show syncing status when connected with pending operations', (tester) async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            connectionStatusProvider.overrideWith(
              (ref) => Stream.value(ConnectionStatus.connected),
            ),
            pendingOperationsCountProvider.overrideWith((ref) => 3),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: ConnectionStatusWidget(),
              ),
            ),
          ),
        );

        // Assert
        expect(find.text('Syncing 3 items...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should handle retry action', (tester) async {
        // Arrange
        bool retryPressed = false;
        container = ProviderContainer(
          overrides: [
            connectionStatusProvider.overrideWith(
              (ref) => Stream.value(ConnectionStatus.disconnected),
            ),
            pendingOperationsCountProvider.overrideWith((ref) => 0),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: ConnectionStatusWidget(
                  onRetry: () => retryPressed = true,
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.refresh));

        // Assert
        expect(retryPressed, isTrue);
      });
    });

    group('ConnectionStatusBanner', () {
      testWidgets('should not show banner when connected with no pending operations', (tester) async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            connectionStatusProvider.overrideWith(
              (ref) => Stream.value(ConnectionStatus.connected),
            ),
            pendingOperationsCountProvider.overrideWith((ref) => 0),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: ConnectionStatusBanner(),
              ),
            ),
          ),
        );

        // Assert
        expect(find.byType(Container), findsNothing);
      });

      testWidgets('should show banner when disconnected', (tester) async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            connectionStatusProvider.overrideWith(
              (ref) => Stream.value(ConnectionStatus.disconnected),
            ),
            pendingOperationsCountProvider.overrideWith((ref) => 1),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: ConnectionStatusBanner(),
              ),
            ),
          ),
        );

        // Assert
        expect(find.text('You\'re offline. 1 change will sync when reconnected.'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('should show banner when syncing', (tester) async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            connectionStatusProvider.overrideWith(
              (ref) => Stream.value(ConnectionStatus.connected),
            ),
            pendingOperationsCountProvider.overrideWith((ref) => 2),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: ConnectionStatusBanner(),
              ),
            ),
          ),
        );

        // Assert
        expect(find.text('Syncing 2 items...'), findsOneWidget);
        expect(find.byIcon(Icons.sync), findsOneWidget);
      });
    });

    group('ConnectionStatusFAB', () {
      testWidgets('should not show FAB when connected with no pending operations', (tester) async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            connectionStatusProvider.overrideWith(
              (ref) => Stream.value(ConnectionStatus.connected),
            ),
            pendingOperationsCountProvider.overrideWith((ref) => 0),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: ConnectionStatusFAB(),
              ),
            ),
          ),
        );

        // Assert
        expect(find.byType(FloatingActionButton), findsNothing);
      });

      testWidgets('should show FAB when disconnected', (tester) async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            connectionStatusProvider.overrideWith(
              (ref) => Stream.value(ConnectionStatus.disconnected),
            ),
            pendingOperationsCountProvider.overrideWith((ref) => 0),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: ConnectionStatusFAB(),
              ),
            ),
          ),
        );

        // Assert
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      });

      testWidgets('should show syncing FAB when connected with pending operations', (tester) async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            connectionStatusProvider.overrideWith(
              (ref) => Stream.value(ConnectionStatus.connected),
            ),
            pendingOperationsCountProvider.overrideWith((ref) => 1),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: ConnectionStatusFAB(),
              ),
            ),
          ),
        );

        // Assert
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('RealtimePostFeed', () {
      testWidgets('should show loading indicator initially', (tester) async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            realtimeGroupPostsProvider.overrideWith(
              (ref, params) => const Stream.empty(),
            ),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: RealtimePostFeed(groupId: 'group1'),
              ),
            ),
          ),
        );

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should show empty state when no posts', (tester) async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            realtimeGroupPostsProvider.overrideWith(
              (ref, params) => Stream.value(<Post>[]),
            ),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: RealtimePostFeed(groupId: 'group1'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(find.text('No posts yet'), findsOneWidget);
        expect(find.text('Be the first to share something!'), findsOneWidget);
        expect(find.byIcon(Icons.post_add), findsOneWidget);
      });

      testWidgets('should show posts when data is available', (tester) async {
        // Arrange
        final testPosts = [
          _createTestPost('post1', 'group1', 'Test post 1'),
          _createTestPost('post2', 'group1', 'Test post 2'),
        ];

        container = ProviderContainer(
          overrides: [
            realtimeGroupPostsProvider.overrideWith(
              (ref, params) => Stream.value(testPosts),
            ),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: RealtimePostFeed(groupId: 'group1'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(PostCard), findsNWidgets(2));
        expect(find.text('Test post 1'), findsOneWidget);
        expect(find.text('Test post 2'), findsOneWidget);
      });

      testWidgets('should show error state when stream fails', (tester) async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            realtimeGroupPostsProvider.overrideWith(
              (ref, params) => Stream.error(Exception('Network error')),
            ),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: RealtimePostFeed(groupId: 'group1'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Failed to load posts'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('should handle pull to refresh', (tester) async {
        // Arrange
        final testPosts = [_createTestPost('post1', 'group1', 'Test post')];

        container = ProviderContainer(
          overrides: [
            realtimeGroupPostsProvider.overrideWith(
              (ref, params) => Stream.value(testPosts),
            ),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: RealtimePostFeed(groupId: 'group1'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Perform pull to refresh
        await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Assert - Should not throw and should complete refresh
        expect(find.byType(PostCard), findsOneWidget);
      });

      testWidgets('should show connection status banner when enabled', (tester) async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            realtimeGroupPostsProvider.overrideWith(
              (ref, params) => Stream.value(<Post>[]),
            ),
            connectionStatusProvider.overrideWith(
              (ref) => Stream.value(ConnectionStatus.disconnected),
            ),
            pendingOperationsCountProvider.overrideWith((ref) => 1),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: RealtimePostFeed(
                  groupId: 'group1',
                  showConnectionStatus: true,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(ConnectionStatusBanner), findsOneWidget);
      });

      testWidgets('should not show connection status banner when disabled', (tester) async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            realtimeGroupPostsProvider.overrideWith(
              (ref, params) => Stream.value(<Post>[]),
            ),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: RealtimePostFeed(
                  groupId: 'group1',
                  showConnectionStatus: false,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(ConnectionStatusBanner), findsNothing);
      });
    });

    group('PostCard', () {
      testWidgets('should display post content correctly', (tester) async {
        // Arrange
        final testPost = _createTestPost('post1', 'group1', 'Test post content');

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PostCard(post: testPost),
            ),
          ),
        );

        // Assert
        expect(find.text('Test post content'), findsOneWidget);
        expect(find.text('User ${testPost.authorId}'), findsOneWidget);
        expect(find.text('0'), findsNWidgets(2)); // Like and comment counts
        expect(find.text('Share'), findsOneWidget);
      });

      testWidgets('should handle action button taps', (tester) async {
        // Arrange
        final testPost = _createTestPost('post1', 'group1', 'Test post');
        bool likeTapped = false;
        bool commentTapped = false;
        bool shareTapped = false;

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PostCard(
                post: testPost,
                onLike: () => likeTapped = true,
                onComment: () => commentTapped = true,
                onShare: () => shareTapped = true,
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.favorite_border));
        await tester.tap(find.byIcon(Icons.comment_outlined));
        await tester.tap(find.byIcon(Icons.share_outlined));

        // Assert
        expect(likeTapped, isTrue);
        expect(commentTapped, isTrue);
        expect(shareTapped, isTrue);
      });

      testWidgets('should format timestamp correctly', (tester) async {
        // Arrange
        final now = DateTime.now();
        final testPost = Post(
          id: 'post1',
          groupId: 'group1',
          authorId: 'author1',
          content: 'Test post',
          contentType: PostContentType.text,
          likeCount: 0,
          commentCount: 0,
          createdAt: now.subtract(const Duration(minutes: 30)),
          updatedAt: now,
        );

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PostCard(post: testPost),
            ),
          ),
        );

        // Assert
        expect(find.textContaining('30m ago'), findsOneWidget);
      });
    });

    group('RealtimeLeaderboard', () {
      testWidgets('should show loading indicator initially', (tester) async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            realtimeEventLeaderboardProvider.overrideWith(
              (ref, eventId) => const Stream.empty(),
            ),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: RealtimeLeaderboard(eventId: 'event1'),
              ),
            ),
          ),
        );

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should show empty state when no leaderboard', (tester) async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            realtimeEventLeaderboardProvider.overrideWith(
              (ref, eventId) => Stream.value(null),
            ),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: RealtimeLeaderboard(eventId: 'event1'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(find.text('No leaderboard data'), findsOneWidget);
        expect(find.byIcon(Icons.leaderboard), findsOneWidget);
      });

      testWidgets('should show leaderboard entries when data is available', (tester) async {
        // Arrange
        final testLeaderboard = _createTestLeaderboard('event1');

        container = ProviderContainer(
          overrides: [
            realtimeEventLeaderboardProvider.overrideWith(
              (ref, eventId) => Stream.value(testLeaderboard),
            ),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: RealtimeLeaderboard(eventId: 'event1'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(LeaderboardEntryCard), findsNWidgets(2));
        expect(find.text('Team Alpha'), findsOneWidget);
        expect(find.text('Team Beta'), findsOneWidget);
      });
    });

    group('RealtimeNotificationsList', () {
      testWidgets('should show empty state when no notifications', (tester) async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            realtimeMemberNotificationsProvider.overrideWith(
              (ref, params) => Stream.value(<Notification>[]),
            ),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: RealtimeNotificationsList(memberId: 'member1'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(find.text('No notifications'), findsOneWidget);
        expect(find.byIcon(Icons.notifications_none), findsOneWidget);
      });

      testWidgets('should show notifications when data is available', (tester) async {
        // Arrange
        final testNotifications = [
          _createTestNotification('notif1', 'member1', 'Test notification 1'),
          _createTestNotification('notif2', 'member1', 'Test notification 2'),
        ];

        container = ProviderContainer(
          overrides: [
            realtimeMemberNotificationsProvider.overrideWith(
              (ref, params) => Stream.value(testNotifications),
            ),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: RealtimeNotificationsList(memberId: 'member1'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(NotificationCard), findsNWidgets(2));
        expect(find.text('Test Notification'), findsNWidgets(2));
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
      const LeaderboardEntry(
        teamId: 'team1',
        teamName: 'Team Alpha',
        totalScore: 95.5,
        rank: 1,
      ),
      const LeaderboardEntry(
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