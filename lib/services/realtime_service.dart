import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

/// Service for real-time data updates
/// 
/// Provides streams for real-time updates to various data types
/// including posts, notifications, events, and submissions.
class RealtimeService {
  final FirebaseFirestore _firestore;
  
  RealtimeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ===== SOCIAL FEED STREAMS =====

  /// Stream posts for a group feed
  Stream<List<Post>> streamGroupFeed(String groupId, {int limit = 20}) {
    return _firestore
        .collection('posts')
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Post.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Stream posts for a member feed
  Stream<List<Post>> streamMemberFeed(String memberId, {int limit = 20}) {
    return _firestore
        .collection('posts')
        .where('authorId', isEqualTo: memberId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Post.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Stream trending posts
  Stream<List<Post>> streamTrendingPosts({int limit = 20}) {
    return _firestore
        .collection('posts')
        .orderBy('engagementScore', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Post.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Stream a specific post
  Stream<Post?> streamPost(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return Post.fromJson({...snapshot.data()!, 'id': snapshot.id});
    });
  }

  /// Stream comments for a post
  Stream<List<PostComment>> streamPostComments(String postId, {int limit = 50}) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostComment.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Stream social feed for a member based on their group memberships
  Stream<List<Post>> streamSocialFeed(String memberId, {int limit = 20}) {
    // Get groups the member belongs to
    return _firestore
        .collection('groupMembers')
        .where('memberId', isEqualTo: memberId)
        .get()
        .asStream()
        .asyncExpand((groupMemberships) {
      if (groupMemberships.docs.isEmpty) {
        return Stream.value(<Post>[]);
      }

      // Extract group IDs
      final groupIds = groupMemberships.docs
          .map((doc) => doc.data()['groupId'] as String)
          .toList();

      // Create a stream for each group
      final streams = groupIds.map((groupId) => streamGroupFeed(groupId, limit: limit));

      // Combine streams
      return _combinePostStreams(streams, limit);
    });
  }

  /// Combine multiple post streams and sort by creation time
  Stream<List<Post>> _combinePostStreams(Iterable<Stream<List<Post>>> streams, int limit) {
    // Create a controller to merge streams
    final controller = StreamController<List<Post>>();
    final subscriptions = <StreamSubscription>[];
    final allPosts = <Post>[];
    
    // Subscribe to each stream
    for (final stream in streams) {
      final subscription = stream.listen((posts) {
        // Add new posts
        allPosts.addAll(posts);
        
        // Sort and limit
        allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final limitedPosts = allPosts.take(limit).toList();
        
        // Send to controller
        controller.add(limitedPosts);
      });
      
      subscriptions.add(subscription);
    }
    
    // Clean up subscriptions when controller is closed
    controller.onCancel = () {
      for (final subscription in subscriptions) {
        subscription.cancel();
      }
    };
    
    return controller.stream;
  }

  // ===== NOTIFICATION STREAMS =====

  /// Stream notifications for a member
  Stream<List<Notification>> streamNotifications(String memberId, {int limit = 50}) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: memberId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Notification.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // ===== EVENT STREAMS =====

  /// Stream events for a group
  Stream<List<Event>> streamGroupEvents(String groupId) {
    return _firestore
        .collection('events')
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Stream leaderboard for an event
  Stream<Leaderboard?> streamEventLeaderboard(String eventId) {
    return _firestore
        .collection('leaderboards')
        .where('eventId', isEqualTo: eventId)
        .orderBy('calculatedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      
      final doc = snapshot.docs.first;
      return Leaderboard.fromJson({...doc.data(), 'id': doc.id});
    });
  }

  /// Stream event status changes
  Stream<Event?> streamEvent(String eventId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      
      return Event.fromJson({...snapshot.data()!, 'id': snapshot.id});
    });
  }

  /// Stream submission status changes
  Stream<Submission?> streamSubmission(String submissionId) {
    return _firestore
        .collection('submissions')
        .doc(submissionId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      
      return Submission.fromJson({...snapshot.data()!, 'id': snapshot.id});
    });
  }

  /// Stream submissions for an event
  Stream<List<Submission>> streamSubmissions({
    required String eventId,
    String? teamId,
    int limit = 50,
  }) {
    var query = _firestore
        .collection('submissions')
        .where('eventId', isEqualTo: eventId);
    
    if (teamId != null) {
      query = query.where('teamId', isEqualTo: teamId);
    }
    
    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Submission.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Stream unread notifications count
  Stream<int> streamUnreadNotificationsCount(String memberId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: memberId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Stream connection status
  Stream<ConnectionStatus> streamConnectionStatus() {
    final controller = StreamController<ConnectionStatus>();
    
    // Initial status
    controller.add(ConnectionStatus.connected);
    
    // Listen for Firestore connection changes
    final unsubscribe = _firestore.snapshotsInSync().listen(
      (_) {
        controller.add(ConnectionStatus.connected);
      },
      onError: (_) {
        controller.add(ConnectionStatus.disconnected);
      },
    );
    
    controller.onCancel = () {
      unsubscribe.cancel();
    };
    
    return controller.stream;
  }
}

/// Connection status enum
enum ConnectionStatus {
  connected,
  disconnected,
  reconnecting,
}