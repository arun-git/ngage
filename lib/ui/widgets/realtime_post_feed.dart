import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../models/notification.dart' as notification_model;
import '../../providers/realtime_providers.dart';
import 'connection_status_widget.dart';
import 'error_widgets.dart';

/// Real-time post feed widget that updates automatically
/// 
/// Uses StreamBuilder with Riverpod to provide real-time updates
/// for social posts with offline support and connection status.
class RealtimePostFeed extends ConsumerStatefulWidget {
  final String? groupId;
  final List<String>? groupIds;
  final int limit;
  final bool showConnectionStatus;

  const RealtimePostFeed({
    super.key,
    this.groupId,
    this.groupIds,
    this.limit = 20,
    this.showConnectionStatus = true,
  }) : assert(groupId != null || groupIds != null, 'Either groupId or groupIds must be provided');

  @override
  ConsumerState<RealtimePostFeed> createState() => _RealtimePostFeedState();
}

class _RealtimePostFeedState extends ConsumerState<RealtimePostFeed> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    // Simulate loading more posts
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine which provider to use based on parameters
    if (widget.groupId != null) {
      return _buildGroupFeed();
    } else if (widget.groupIds != null) {
      return _buildSocialFeed();
    } else {
      return const Center(
        child: Text('No feed configuration provided'),
      );
    }
  }

  Widget _buildGroupFeed() {
    final postsAsync = ref.watch(realtimeGroupPostsProvider(
      RealtimeGroupPostsParams(
        groupId: widget.groupId!,
        limit: widget.limit,
      ),
    ));

    return Column(
      children: [
        if (widget.showConnectionStatus)
          const ConnectionStatusBanner(),
        Expanded(
          child: postsAsync.when(
            data: (posts) => _buildPostsList(posts),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorWidget(error),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialFeed() {
    final postsAsync = ref.watch(realtimeSocialFeedProvider(
      RealtimeSocialFeedParams(
        groupIds: widget.groupIds!,
        limit: widget.limit,
      ),
    ));

    return Column(
      children: [
        if (widget.showConnectionStatus)
          const ConnectionStatusBanner(),
        Expanded(
          child: postsAsync.when(
            data: (posts) => _buildPostsList(posts),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorWidget(error),
          ),
        ),
      ],
    );
  }

  Widget _buildPostsList(List<Post> posts) {
    if (posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.post_add,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Be the first to share something!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: posts.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= posts.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final post = posts[index];
          return PostCard(
            post: post,
            onLike: () => _handleLike(post),
            onComment: () => _handleComment(post),
            onShare: () => _handleShare(post),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    return ErrorDisplayWidget(
      error: error,
      context: 'Loading posts',
      onRetry: _onRefresh,
      showReportButton: true,
      showDetails: false,
    );
  }

  Future<void> _onRefresh() async {
    // Force refresh by invalidating the provider
    if (widget.groupId != null) {
      ref.invalidate(realtimeGroupPostsProvider);
    } else if (widget.groupIds != null) {
      ref.invalidate(realtimeSocialFeedProvider);
    }
  }

  void _handleLike(Post post) {
    // TODO: Implement like functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Liked post: ${post.id}')),
    );
  }

  void _handleComment(Post post) {
    // TODO: Implement comment functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Comment on post: ${post.id}')),
    );
  }

  void _handleShare(Post post) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share post: ${post.id}')),
    );
  }
}

/// Individual post card widget
class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  const PostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  child: Text(post.authorId.substring(0, 1).toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User ${post.authorId}', // TODO: Get actual user name
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatTimestamp(post.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Post content
            Text(
              post.content,
              style: const TextStyle(fontSize: 16),
            ),
            
            // Media content
            if (post.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildMediaContent(),
            ],
            
            const SizedBox(height: 12),
            
            // Post actions
            Row(
              children: [
                _buildActionButton(
                  icon: Icons.favorite_border,
                  label: '${post.likeCount}',
                  onTap: onLike,
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  label: '${post.commentCount}',
                  onTap: onComment,
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: onShare,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContent() {
    if (post.mediaUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          post.mediaUrls.first,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.broken_image, size: 48),
              ),
            );
          },
        ),
      );
    } else {
      return SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: post.mediaUrls.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(right: index < post.mediaUrls.length - 1 ? 8 : 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  post.mediaUrls[index],
                  height: 120,
                  width: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 120,
                      width: 120,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 24),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      );
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

/// Real-time leaderboard widget
class RealtimeLeaderboard extends ConsumerWidget {
  final String eventId;
  final bool showConnectionStatus;

  const RealtimeLeaderboard({
    super.key,
    required this.eventId,
    this.showConnectionStatus = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(realtimeEventLeaderboardProvider(eventId));

    return Column(
      children: [
        if (showConnectionStatus)
          const ConnectionStatusBanner(),
        Expanded(
          child: leaderboardAsync.when(
            data: (leaderboard) => _buildLeaderboard(leaderboard),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorWidget(context, error),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboard(Leaderboard? leaderboard) {
    if (leaderboard == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No leaderboard data',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: leaderboard.entries.length,
      itemBuilder: (context, index) {
        final entry = leaderboard.entries[index];
        return LeaderboardEntryCard(
          entry: entry,
          rank: index + 1,
        );
      },
    );
  }

  Widget _buildErrorWidget(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load leaderboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Individual leaderboard entry card
class LeaderboardEntryCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;

  const LeaderboardEntryCard({
    super.key,
    required this.entry,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRankColor(),
          child: Text(
            '$rank',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          entry.teamName ?? 'Team ${entry.teamId}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Score: ${entry.totalScore.toStringAsFixed(1)}'),
        trailing: rank <= 3 ? _getRankIcon() : null,
      ),
    );
  }

  Color _getRankColor() {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  Widget? _getRankIcon() {
    switch (rank) {
      case 1:
        return const Icon(Icons.emoji_events, color: Colors.amber);
      case 2:
        return const Icon(Icons.emoji_events, color: Colors.grey);
      case 3:
        return const Icon(Icons.emoji_events, color: Colors.brown);
      default:
        return null;
    }
  }
}

/// Real-time notifications list widget
class RealtimeNotificationsList extends ConsumerWidget {
  final String memberId;
  final bool showConnectionStatus;

  const RealtimeNotificationsList({
    super.key,
    required this.memberId,
    this.showConnectionStatus = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(realtimeMemberNotificationsProvider(
      RealtimeMemberNotificationsParams(memberId: memberId),
    ));

    return Column(
      children: [
        if (showConnectionStatus)
          const ConnectionStatusBanner(),
        Expanded(
          child: notificationsAsync.when(
            data: (notifications) => _buildNotificationsList(notifications),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorWidget(context, error),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsList(List<notification_model.Notification> notifications) {
    if (notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No notifications',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return NotificationCard(notification: notification);
      },
    );
  }

  Widget _buildErrorWidget(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Individual notification card
class NotificationCard extends StatelessWidget {
  final notification_model.Notification notification;

  const NotificationCard({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: notification.isRead ? null : Colors.blue.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(),
          child: Icon(
            _getTypeIcon(),
            color: Colors.white,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(notification.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: notification.isRead 
            ? null 
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }

  Color _getTypeColor() {
    switch (notification.type) {
      case NotificationType.eventReminder:
        return Colors.orange;
      case NotificationType.deadlineAlert:
        return Colors.red;
      case NotificationType.resultAnnouncement:
        return Colors.green;
      case NotificationType.leaderboardUpdate:
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  IconData _getTypeIcon() {
    switch (notification.type) {
      case NotificationType.eventReminder:
        return Icons.event;
      case NotificationType.deadlineAlert:
        return Icons.warning;
      case NotificationType.resultAnnouncement:
        return Icons.celebration;
      case NotificationType.leaderboardUpdate:
        return Icons.leaderboard;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}