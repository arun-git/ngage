import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/realtime_service.dart';
import '../services/offline_service.dart';

/// Provider for RealtimeService
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  return RealtimeService();
});

/// Provider for OfflineService
final offlineServiceProvider = Provider<OfflineService>((ref) {
  final realtimeService = ref.watch(realtimeServiceProvider);
  return OfflineService(realtimeService: realtimeService);
});

/// Provider for connection status stream
final connectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  // Return a stream that emits connected status for now
  return Stream.value(ConnectionStatus.connected);
});

/// Provider for pending operations count
final pendingOperationsCountProvider = Provider<int>((ref) {
  final offlineService = ref.watch(offlineServiceProvider);
  return offlineService.pendingOperationsCount;
});

/// Stream provider for real-time group posts
final realtimeGroupPostsProvider = StreamProvider.family<List<Post>, RealtimeGroupPostsParams>((ref, params) {
  // Return empty stream for now - would need actual implementation
  return Stream.value(<Post>[]);
});

/// Stream provider for real-time social feed
final realtimeSocialFeedProvider = StreamProvider.family<List<Post>, RealtimeSocialFeedParams>((ref, params) {
  // Return empty stream for now - would need actual implementation
  return Stream.value(<Post>[]);
});

/// Stream provider for real-time post comments
final realtimePostCommentsProvider = StreamProvider.family<List<PostComment>, RealtimePostCommentsParams>((ref, params) {
  // Return empty stream for now - would need actual implementation
  return Stream.value(<PostComment>[]);
});

/// Stream provider for real-time member notifications
final realtimeMemberNotificationsProvider = StreamProvider.family<List<Notification>, RealtimeMemberNotificationsParams>((ref, params) {
  // Return empty stream for now - would need actual implementation
  return Stream.value(<Notification>[]);
});

/// Stream provider for real-time event leaderboard
final realtimeEventLeaderboardProvider = StreamProvider.family<Leaderboard?, String>((ref, eventId) {
  final realtimeService = ref.watch(realtimeServiceProvider);
  return realtimeService.streamEventLeaderboard(eventId);
});

/// Stream provider for real-time event updates
final realtimeEventProvider = StreamProvider.family<Event?, String>((ref, eventId) {
  final realtimeService = ref.watch(realtimeServiceProvider);
  return realtimeService.streamEvent(eventId);
});

/// Stream provider for real-time submission updates
final realtimeSubmissionProvider = StreamProvider.family<Submission?, String>((ref, submissionId) {
  final realtimeService = ref.watch(realtimeServiceProvider);
  return realtimeService.streamSubmission(submissionId);
});

/// Stream provider for real-time event submissions
final realtimeEventSubmissionsProvider = StreamProvider.family<List<Submission>, RealtimeEventSubmissionsParams>((ref, params) {
  // Return empty stream for now - would need actual implementation
  return Stream.value(<Submission>[]);
});

/// Stream provider for real-time unread notifications count
final realtimeUnreadNotificationsCountProvider = StreamProvider.family<int, String>((ref, memberId) {
  // Return zero count for now - would need actual implementation
  return Stream.value(0);
});

/// Provider for offline-first group posts
final offlineGroupPostsProvider = FutureProvider.family<List<Post>, OfflineGroupPostsParams>((ref, params) async {
  final offlineService = ref.watch(offlineServiceProvider);
  return offlineService.getGroupPosts(
    groupId: params.groupId,
    limit: params.limit,
    forceRefresh: params.forceRefresh,
  );
});

/// Provider for offline-first member notifications
final offlineMemberNotificationsProvider = FutureProvider.family<List<Notification>, OfflineMemberNotificationsParams>((ref, params) async {
  final offlineService = ref.watch(offlineServiceProvider);
  return offlineService.getMemberNotifications(
    memberId: params.memberId,
    limit: params.limit,
    forceRefresh: params.forceRefresh,
  );
});

/// Provider for offline-first event leaderboard
final offlineEventLeaderboardProvider = FutureProvider.family<Leaderboard?, OfflineEventLeaderboardParams>((ref, params) async {
  final offlineService = ref.watch(offlineServiceProvider);
  return offlineService.getEventLeaderboard(
    eventId: params.eventId,
    forceRefresh: params.forceRefresh,
  );
});

/// Combined provider that switches between real-time and offline data based on connection
final adaptiveGroupPostsProvider = Provider.family<AsyncValue<List<Post>>, AdaptiveGroupPostsParams>((ref, params) {
  final connectionStatus = ref.watch(connectionStatusProvider);
  
  return connectionStatus.when(
    data: (status) {
      if (status == ConnectionStatus.connected) {
        // Use real-time data when connected
        final realtimeData = ref.watch(realtimeGroupPostsProvider(RealtimeGroupPostsParams(
          groupId: params.groupId,
          limit: params.limit,
        )));
        return realtimeData;
      } else {
        // Use offline data when disconnected
        final offlineData = ref.watch(offlineGroupPostsProvider(OfflineGroupPostsParams(
          groupId: params.groupId,
          limit: params.limit,
          forceRefresh: false,
        )));
        return offlineData;
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Combined provider for notifications
final adaptiveMemberNotificationsProvider = Provider.family<AsyncValue<List<Notification>>, AdaptiveMemberNotificationsParams>((ref, params) {
  final connectionStatus = ref.watch(connectionStatusProvider);
  
  return connectionStatus.when(
    data: (status) {
      if (status == ConnectionStatus.connected) {
        // Use real-time data when connected
        final realtimeData = ref.watch(realtimeMemberNotificationsProvider(RealtimeMemberNotificationsParams(
          memberId: params.memberId,
          limit: params.limit,
        )));
        return realtimeData;
      } else {
        // Use offline data when disconnected
        final offlineData = ref.watch(offlineMemberNotificationsProvider(OfflineMemberNotificationsParams(
          memberId: params.memberId,
          limit: params.limit,
          forceRefresh: false,
        )));
        return offlineData;
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Combined provider for leaderboard
final adaptiveEventLeaderboardProvider = Provider.family<AsyncValue<Leaderboard?>, AdaptiveEventLeaderboardParams>((ref, params) {
  final connectionStatus = ref.watch(connectionStatusProvider);
  
  return connectionStatus.when(
    data: (status) {
      if (status == ConnectionStatus.connected) {
        // Use real-time data when connected
        final realtimeData = ref.watch(realtimeEventLeaderboardProvider(params.eventId));
        return realtimeData;
      } else {
        // Use offline data when disconnected
        final offlineData = ref.watch(offlineEventLeaderboardProvider(OfflineEventLeaderboardParams(
          eventId: params.eventId,
          forceRefresh: false,
        )));
        return offlineData;
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Parameter classes for providers

class RealtimeGroupPostsParams {
  final String groupId;
  final int limit;

  const RealtimeGroupPostsParams({
    required this.groupId,
    this.limit = 20,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RealtimeGroupPostsParams &&
        other.groupId == groupId &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(groupId, limit);
}

class RealtimeSocialFeedParams {
  final List<String> groupIds;
  final int limit;

  const RealtimeSocialFeedParams({
    required this.groupIds,
    this.limit = 20,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RealtimeSocialFeedParams &&
        _listEquals(other.groupIds, groupIds) &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(groupIds.toString(), limit);

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class RealtimePostCommentsParams {
  final String postId;
  final int limit;

  const RealtimePostCommentsParams({
    required this.postId,
    this.limit = 50,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RealtimePostCommentsParams &&
        other.postId == postId &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(postId, limit);
}

class RealtimeMemberNotificationsParams {
  final String memberId;
  final int limit;

  const RealtimeMemberNotificationsParams({
    required this.memberId,
    this.limit = 50,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RealtimeMemberNotificationsParams &&
        other.memberId == memberId &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(memberId, limit);
}

class RealtimeEventSubmissionsParams {
  final String eventId;
  final String? teamId;
  final int limit;

  const RealtimeEventSubmissionsParams({
    required this.eventId,
    this.teamId,
    this.limit = 50,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RealtimeEventSubmissionsParams &&
        other.eventId == eventId &&
        other.teamId == teamId &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(eventId, teamId, limit);
}

class OfflineGroupPostsParams {
  final String groupId;
  final int limit;
  final bool forceRefresh;

  const OfflineGroupPostsParams({
    required this.groupId,
    this.limit = 20,
    this.forceRefresh = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfflineGroupPostsParams &&
        other.groupId == groupId &&
        other.limit == limit &&
        other.forceRefresh == forceRefresh;
  }

  @override
  int get hashCode => Object.hash(groupId, limit, forceRefresh);
}

class OfflineMemberNotificationsParams {
  final String memberId;
  final int limit;
  final bool forceRefresh;

  const OfflineMemberNotificationsParams({
    required this.memberId,
    this.limit = 50,
    this.forceRefresh = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfflineMemberNotificationsParams &&
        other.memberId == memberId &&
        other.limit == limit &&
        other.forceRefresh == forceRefresh;
  }

  @override
  int get hashCode => Object.hash(memberId, limit, forceRefresh);
}

class OfflineEventLeaderboardParams {
  final String eventId;
  final bool forceRefresh;

  const OfflineEventLeaderboardParams({
    required this.eventId,
    this.forceRefresh = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfflineEventLeaderboardParams &&
        other.eventId == eventId &&
        other.forceRefresh == forceRefresh;
  }

  @override
  int get hashCode => Object.hash(eventId, forceRefresh);
}

class AdaptiveGroupPostsParams {
  final String groupId;
  final int limit;

  const AdaptiveGroupPostsParams({
    required this.groupId,
    this.limit = 20,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdaptiveGroupPostsParams &&
        other.groupId == groupId &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(groupId, limit);
}

class AdaptiveMemberNotificationsParams {
  final String memberId;
  final int limit;

  const AdaptiveMemberNotificationsParams({
    required this.memberId,
    this.limit = 50,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdaptiveMemberNotificationsParams &&
        other.memberId == memberId &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(memberId, limit);
}

class AdaptiveEventLeaderboardParams {
  final String eventId;

  const AdaptiveEventLeaderboardParams({
    required this.eventId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdaptiveEventLeaderboardParams &&
        other.eventId == eventId;
  }

  @override
  int get hashCode => eventId.hashCode;
}