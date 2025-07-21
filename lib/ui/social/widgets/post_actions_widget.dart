import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/models.dart';

/// Widget for post actions (like, comment, share)
class PostActionsWidget extends ConsumerWidget {
  final Post post;
  final String currentMemberId;
  final VoidCallback? onLikeToggled;
  final VoidCallback? onCommentTapped;
  final bool showCommentsCount;

  const PostActionsWidget({
    super.key,
    required this.post,
    required this.currentMemberId,
    this.onLikeToggled,
    this.onCommentTapped,
    this.showCommentsCount = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likeCheckRequest = LikeCheckRequest(
      postId: post.id,
      memberId: currentMemberId,
    );
    
    final hasLikedAsync = ref.watch(hasLikedPostProvider(likeCheckRequest));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Engagement stats
          if (post.likeCount > 0 || post.commentCount > 0) ...[
            _buildEngagementStats(context),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
          ],
          
          // Action buttons
          Row(
            children: [
              // Like button
              Expanded(
                child: hasLikedAsync.when(
                  loading: () => _buildActionButton(
                    context,
                    icon: Icons.favorite_border,
                    label: 'Like',
                    count: post.likeCount,
                    isActive: false,
                    onTap: null,
                  ),
                  error: (_, __) => _buildActionButton(
                    context,
                    icon: Icons.favorite_border,
                    label: 'Like',
                    count: post.likeCount,
                    isActive: false,
                    onTap: () => _toggleLike(ref),
                  ),
                  data: (hasLiked) => _buildActionButton(
                    context,
                    icon: hasLiked ? Icons.favorite : Icons.favorite_border,
                    label: 'Like',
                    count: post.likeCount,
                    isActive: hasLiked,
                    onTap: () => _toggleLike(ref),
                  ),
                ),
              ),
              
              // Comment button
              if (showCommentsCount)
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.comment_outlined,
                    label: 'Comment',
                    count: post.commentCount,
                    isActive: false,
                    onTap: onCommentTapped,
                  ),
                ),
              
              // Share button
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.share_outlined,
                  label: 'Share',
                  count: null,
                  isActive: false,
                  onTap: () => _sharePost(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementStats(BuildContext context) {
    return Row(
      children: [
        // Like count
        if (post.likeCount > 0) ...[
          const Icon(
            Icons.favorite,
            size: 16,
            color: Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            _formatCount(post.likeCount),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
        
        const Spacer(),
        
        // Comment count
        if (post.commentCount > 0) ...[
          Text(
            '${_formatCount(post.commentCount)} ${post.commentCount == 1 ? 'comment' : 'comments'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int? count,
    required bool isActive,
    required VoidCallback? onTap,
  }) {
    final color = isActive 
        ? Theme.of(context).primaryColor 
        : Colors.grey[600];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              count != null && count > 0 ? '$label (${_formatCount(count)})' : label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLike(WidgetRef ref) async {
    try {
      final likeCheckRequest = LikeCheckRequest(
        postId: post.id,
        memberId: currentMemberId,
      );
      
      final hasLiked = await ref.read(hasLikedPostProvider(likeCheckRequest).future);
      
      if (hasLiked) {
        final unlikePost = ref.read(unlikePostProvider);
        await unlikePost(post.id, currentMemberId);
      } else {
        final likePost = ref.read(likePostProvider);
        await likePost(post.id, currentMemberId);
      }
      
      onLikeToggled?.call();
    } catch (e) {
      // Handle error silently or show a subtle indicator
      debugPrint('Error toggling like: $e');
    }
  }

  void _sharePost(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share Post',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Link'),
              onTap: () {
                Navigator.of(context).pop();
                _copyPostLink(context);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Externally'),
              onTap: () {
                Navigator.of(context).pop();
                _shareExternally(context);
              },
            ),
            
            const SizedBox(height: 16),
            
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _copyPostLink(BuildContext context) {
    // In a real implementation, this would copy the post URL to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post link copied to clipboard')),
    );
  }

  void _shareExternally(BuildContext context) {
    // In a real implementation, this would use the share plugin
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('External sharing would be implemented here')),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
}