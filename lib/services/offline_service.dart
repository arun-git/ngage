import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'realtime_service.dart';

/// Service for handling offline support and local caching
/// 
/// Manages local data storage, sync queues, and offline-first operations
/// to ensure the app works seamlessly when disconnected.
class OfflineService {
  final FirebaseFirestore _firestore;
  final RealtimeService _realtimeService;
  final Map<String, dynamic> _localCache = {};
  final List<PendingOperation> _pendingOperations = [];
  
  Timer? _syncTimer;
  bool _isSyncing = false;

  OfflineService({
    required RealtimeService realtimeService,
    FirebaseFirestore? firestore,
  }) : _realtimeService = realtimeService,
       _firestore = firestore ?? FirebaseFirestore.instance {
    _initializeOfflineSupport();
  }

  /// Initialize offline support
  void _initializeOfflineSupport() {
    // Listen to connection status changes
    _realtimeService.connectionStatus.listen((status) {
      if (status == ConnectionStatus.connected && !_isSyncing) {
        _syncPendingOperations();
      }
    });

    // Start periodic sync attempts
    _syncTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _syncPendingOperations(),
    );
  }

  /// Cache data locally
  void cacheData(String key, dynamic data) {
    _localCache[key] = data;
  }

  /// Get cached data
  T? getCachedData<T>(String key) {
    final data = _localCache[key];
    return data is T ? data : null;
  }

  /// Remove cached data
  void removeCachedData(String key) {
    _localCache.remove(key);
  }

  /// Clear all cached data
  void clearCache() {
    _localCache.clear();
  }

  /// Add operation to pending queue for later sync
  void addPendingOperation(PendingOperation operation) {
    _pendingOperations.add(operation);
  }

  /// Get posts with offline-first approach
  Future<List<Post>> getGroupPosts({
    required String groupId,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'group_posts_$groupId';
    
    // Try to get from cache first if not forcing refresh
    if (!forceRefresh) {
      final cached = getCachedData<List<Post>>(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }

    try {
      // Try to get from server
      final snapshot = await _firestore
          .collection('posts')
          .where('groupId', isEqualTo: groupId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final posts = snapshot.docs
          .map((doc) => Post.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      // Cache the results
      cacheData(cacheKey, posts);
      return posts;
    } catch (e) {
      // If server fails, try to get from Firestore cache
      try {
        final cachedSnapshot = await _firestore
            .collection('posts')
            .where('groupId', isEqualTo: groupId)
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get(const GetOptions(source: Source.cache));

        final posts = cachedSnapshot.docs
            .map((doc) => Post.fromJson({...doc.data(), 'id': doc.id}))
            .toList();

        cacheData(cacheKey, posts);
        return posts;
      } catch (cacheError) {
        // Return empty list if all fails
        return getCachedData<List<Post>>(cacheKey) ?? [];
      }
    }
  }

  /// Get notifications with offline-first approach
  Future<List<Notification>> getMemberNotifications({
    required String memberId,
    int limit = 50,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'notifications_$memberId';
    
    // Try to get from cache first if not forcing refresh
    if (!forceRefresh) {
      final cached = getCachedData<List<Notification>>(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }

    try {
      // Try to get from server
      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: memberId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final notifications = snapshot.docs
          .map((doc) => Notification.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      // Cache the results
      cacheData(cacheKey, notifications);
      return notifications;
    } catch (e) {
      // If server fails, try to get from Firestore cache
      try {
        final cachedSnapshot = await _firestore
            .collection('notifications')
            .where('recipientId', isEqualTo: memberId)
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get(const GetOptions(source: Source.cache));

        final notifications = cachedSnapshot.docs
            .map((doc) => Notification.fromJson({...doc.data(), 'id': doc.id}))
            .toList();

        cacheData(cacheKey, notifications);
        return notifications;
      } catch (cacheError) {
        // Return empty list if all fails
        return getCachedData<List<Notification>>(cacheKey) ?? [];
      }
    }
  }

  /// Get leaderboard with offline-first approach
  Future<Leaderboard?> getEventLeaderboard({
    required String eventId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'leaderboard_$eventId';
    
    // Try to get from cache first if not forcing refresh
    if (!forceRefresh) {
      final cached = getCachedData<Leaderboard>(cacheKey);
      if (cached != null) {
        return cached;
      }
    }

    try {
      // Try to get from server
      final snapshot = await _firestore
          .collection('leaderboards')
          .where('eventId', isEqualTo: eventId)
          .orderBy('calculatedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final leaderboard = Leaderboard.fromJson({...doc.data(), 'id': doc.id});

      // Cache the result
      cacheData(cacheKey, leaderboard);
      return leaderboard;
    } catch (e) {
      // If server fails, try to get from Firestore cache
      try {
        final cachedSnapshot = await _firestore
            .collection('leaderboards')
            .where('eventId', isEqualTo: eventId)
            .orderBy('calculatedAt', descending: true)
            .limit(1)
            .get(const GetOptions(source: Source.cache));

        if (cachedSnapshot.docs.isEmpty) return null;

        final doc = cachedSnapshot.docs.first;
        final leaderboard = Leaderboard.fromJson({...doc.data(), 'id': doc.id});

        cacheData(cacheKey, leaderboard);
        return leaderboard;
      } catch (cacheError) {
        // Return cached data if available
        return getCachedData<Leaderboard>(cacheKey);
      }
    }
  }

  /// Create post with offline support
  Future<Post> createPost({
    required String groupId,
    required String authorId,
    required String content,
    List<String> mediaUrls = const [],
  }) async {
    final now = DateTime.now();
    final post = Post(
      id: _generateId(),
      groupId: groupId,
      authorId: authorId,
      content: content,
      mediaUrls: mediaUrls,
      contentType: mediaUrls.isNotEmpty 
          ? (content.trim().isNotEmpty ? PostContentType.mixed : PostContentType.image)
          : PostContentType.text,
      createdAt: now,
      updatedAt: now,
    );

    // Add to local cache immediately for optimistic UI
    final cacheKey = 'group_posts_$groupId';
    final cachedPosts = getCachedData<List<Post>>(cacheKey) ?? <Post>[];
    cachedPosts.insert(0, post);
    cacheData(cacheKey, cachedPosts);

    // Try to save to server
    try {
      await _firestore.collection('posts').doc(post.id).set(post.toJson());
      return post;
    } catch (e) {
      // Add to pending operations if offline
      addPendingOperation(PendingOperation(
        id: _generateId(),
        type: OperationType.createPost,
        data: post.toJson(),
        timestamp: now,
      ));
      return post;
    }
  }

  /// Like post with offline support
  Future<void> likePost({
    required String postId,
    required String memberId,
  }) async {
    final like = PostLike(
      id: _generateId(),
      postId: postId,
      memberId: memberId,
      createdAt: DateTime.now(),
    );

    // Update local cache optimistically
    _updatePostLikeInCache(postId, memberId, true);

    try {
      await _firestore.collection('post_likes').doc(like.id).set(like.toJson());
      
      // Update post like count
      await _firestore.collection('posts').doc(postId).update({
        'likeCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Add to pending operations if offline
      addPendingOperation(PendingOperation(
        id: _generateId(),
        type: OperationType.likePost,
        data: like.toJson(),
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Unlike post with offline support
  Future<void> unlikePost({
    required String postId,
    required String memberId,
  }) async {
    // Update local cache optimistically
    _updatePostLikeInCache(postId, memberId, false);

    try {
      // Find and delete the like
      final likeQuery = await _firestore
          .collection('post_likes')
          .where('postId', isEqualTo: postId)
          .where('memberId', isEqualTo: memberId)
          .get();

      if (likeQuery.docs.isNotEmpty) {
        await likeQuery.docs.first.reference.delete();
        
        // Update post like count
        await _firestore.collection('posts').doc(postId).update({
          'likeCount': FieldValue.increment(-1),
        });
      }
    } catch (e) {
      // Add to pending operations if offline
      addPendingOperation(PendingOperation(
        id: _generateId(),
        type: OperationType.unlikePost,
        data: {
          'postId': postId,
          'memberId': memberId,
        },
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Add comment with offline support
  Future<PostComment> addComment({
    required String postId,
    required String authorId,
    required String content,
    String? parentCommentId,
  }) async {
    final now = DateTime.now();
    final comment = PostComment(
      id: _generateId(),
      postId: postId,
      authorId: authorId,
      content: content,
      parentCommentId: parentCommentId,
      createdAt: now,
      updatedAt: now,
    );

    // Add to local cache immediately for optimistic UI
    _addCommentToCache(comment);

    try {
      await _firestore.collection('post_comments').doc(comment.id).set(comment.toJson());
      
      // Update post comment count
      await _firestore.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });
      
      return comment;
    } catch (e) {
      // Add to pending operations if offline
      addPendingOperation(PendingOperation(
        id: _generateId(),
        type: OperationType.addComment,
        data: comment.toJson(),
        timestamp: now,
      ));
      return comment;
    }
  }

  /// Mark notification as read with offline support
  Future<void> markNotificationAsRead(String notificationId) async {
    // Update local cache immediately
    _updateNotificationInCache(notificationId, isRead: true);

    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Add to pending operations if offline
      addPendingOperation(PendingOperation(
        id: _generateId(),
        type: OperationType.markNotificationRead,
        data: {
          'notificationId': notificationId,
          'isRead': true,
          'readAt': DateTime.now().toIso8601String(),
        },
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Sync pending operations when online
  Future<void> _syncPendingOperations() async {
    if (_isSyncing || _pendingOperations.isEmpty) return;
    
    _isSyncing = true;
    
    try {
      final operationsToSync = List<PendingOperation>.from(_pendingOperations);
      
      for (final operation in operationsToSync) {
        try {
          await _executePendingOperation(operation);
          _pendingOperations.remove(operation);
        } catch (e) {
          // Keep operation in queue if it fails
          print('Failed to sync operation ${operation.id}: $e');
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Execute a pending operation
  Future<void> _executePendingOperation(PendingOperation operation) async {
    switch (operation.type) {
      case OperationType.createPost:
        final postData = operation.data as Map<String, dynamic>;
        await _firestore.collection('posts').doc(postData['id']).set(postData);
        break;
        
      case OperationType.likePost:
        final likeData = operation.data as Map<String, dynamic>;
        await _firestore.collection('post_likes').doc(likeData['id']).set(likeData);
        await _firestore.collection('posts').doc(likeData['postId']).update({
          'likeCount': FieldValue.increment(1),
        });
        break;
        
      case OperationType.unlikePost:
        final data = operation.data as Map<String, dynamic>;
        final likeQuery = await _firestore
            .collection('post_likes')
            .where('postId', isEqualTo: data['postId'])
            .where('memberId', isEqualTo: data['memberId'])
            .get();
        
        if (likeQuery.docs.isNotEmpty) {
          await likeQuery.docs.first.reference.delete();
          await _firestore.collection('posts').doc(data['postId']).update({
            'likeCount': FieldValue.increment(-1),
          });
        }
        break;
        
      case OperationType.addComment:
        final commentData = operation.data as Map<String, dynamic>;
        await _firestore.collection('post_comments').doc(commentData['id']).set(commentData);
        await _firestore.collection('posts').doc(commentData['postId']).update({
          'commentCount': FieldValue.increment(1),
        });
        break;
        
      case OperationType.markNotificationRead:
        final data = operation.data as Map<String, dynamic>;
        await _firestore.collection('notifications').doc(data['notificationId']).update({
          'isRead': data['isRead'],
          'readAt': data['readAt'],
        });
        break;
    }
  }

  /// Update post like status in local cache
  void _updatePostLikeInCache(String postId, String memberId, bool isLiked) {
    // Update in all relevant caches
    for (final key in _localCache.keys) {
      if (key.startsWith('group_posts_')) {
        final posts = getCachedData<List<Post>>(key);
        if (posts != null) {
          final updatedPosts = posts.map((post) {
            if (post.id == postId) {
              return post.copyWith(
                likeCount: isLiked ? post.likeCount + 1 : post.likeCount - 1,
              );
            }
            return post;
          }).toList();
          cacheData(key, updatedPosts);
        }
      }
    }
  }

  /// Add comment to local cache
  void _addCommentToCache(PostComment comment) {
    final cacheKey = 'post_comments_${comment.postId}';
    final cachedComments = getCachedData<List<PostComment>>(cacheKey) ?? <PostComment>[];
    cachedComments.add(comment);
    cacheData(cacheKey, cachedComments);
  }

  /// Update notification in local cache
  void _updateNotificationInCache(String notificationId, {required bool isRead}) {
    for (final key in _localCache.keys) {
      if (key.startsWith('notifications_')) {
        final notifications = getCachedData<List<Notification>>(key);
        if (notifications != null) {
          final updatedNotifications = notifications.map((notification) {
            if (notification.id == notificationId) {
              return notification.copyWith(
                isRead: isRead,
                readAt: isRead ? DateTime.now() : null,
              );
            }
            return notification;
          }).toList();
          cacheData(key, updatedNotifications);
        }
      }
    }
  }

  /// Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           (DateTime.now().microsecond % 1000).toString().padLeft(3, '0');
  }

  /// Get pending operations count
  int get pendingOperationsCount => _pendingOperations.length;

  /// Check if there are pending operations
  bool get hasPendingOperations => _pendingOperations.isNotEmpty;

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
  }
}

/// Represents a pending operation to be synced when online
class PendingOperation {
  final String id;
  final OperationType type;
  final dynamic data;
  final DateTime timestamp;

  const PendingOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      id: json['id'] as String,
      type: OperationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => OperationType.createPost,
      ),
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Types of operations that can be queued for offline sync
enum OperationType {
  createPost,
  likePost,
  unlikePost,
  addComment,
  markNotificationRead,
}