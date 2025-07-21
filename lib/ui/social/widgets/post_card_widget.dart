import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/models.dart';
import '../../../providers/post_providers.dart';
import 'post_media_widget.dart';
import 'post_actions_widget.dart';
import 'post_comments_widget.dart';

/// Widget for displaying a single post in a card format
class PostCardWidget extends ConsumerStatefulWidget {
  final Post post;
  final String currentMemberId;
  final VoidCallback? onPostUpdated;
  final VoidCallback? onPostDeleted;
  final bool showComments;

  const PostCardWidget({
    super.key,
    required this.post,
    required this.currentMemberId,
    this.onPostUpdated,
    this.onPostDeleted,
    this.showComments = true,
  });

  @override
  ConsumerState<PostCardWidget> createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends ConsumerState<PostCardWidget> {
  bool _showComments = false;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header
          _buildPostHeader(),
          
          // Post content
          _buildPostContent(),
          
          // Post media
          if (widget.post.hasMedia) _buildPostMedia(),
          
          // Post actions (like, comment, share)
          _buildPostActions(),
          
          // Comments section
          if (_showComments && widget.showComments) _buildCommentsSection(),
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Author avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Text(
              _getAuthorInitials(),
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Author info and timestamp
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getAuthorName(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatTimestamp(widget.post.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Post menu
          _buildPostMenu(),
        ],
      ),
    );
  }

  Widget _buildPostContent() {
    if (widget.post.content.isEmpty) return const SizedBox();

    final isLongContent = widget.post.content.length > 300;
    final displayContent = _isExpanded || !isLongContent
        ? widget.post.content
        : '${widget.post.content.substring(0, 300)}...';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayContent,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (isLongContent) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Text(
                _isExpanded ? 'Show less' : 'Show more',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPostMedia() {
    return PostMediaWidget(
      mediaUrls: widget.post.mediaUrls,
      contentType: widget.post.contentType,
    );
  }

  Widget _buildPostActions() {
    return PostActionsWidget(
      post: widget.post,
      currentMemberId: widget.currentMemberId,
      onLikeToggled: () => widget.onPostUpdated?.call(),
      onCommentTapped: () => setState(() => _showComments = !_showComments),
      showCommentsCount: widget.showComments,
    );
  }

  Widget _buildCommentsSection() {
    return PostCommentsWidget(
      postId: widget.post.id,
      currentMemberId: widget.currentMemberId,
      onCommentAdded: () => widget.onPostUpdated?.call(),
    );
  }

  Widget _buildPostMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) => _handleMenuAction(value),
      itemBuilder: (context) => [
        if (widget.post.authorId == widget.currentMemberId) ...[
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit Post'),
              dense: true,
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete Post', style: TextStyle(color: Colors.red)),
              dense: true,
            ),
          ),
        ] else ...[
          const PopupMenuItem(
            value: 'report',
            child: ListTile(
              leading: Icon(Icons.flag),
              title: Text('Report Post'),
              dense: true,
            ),
          ),
        ],
        const PopupMenuItem(
          value: 'share',
          child: ListTile(
            leading: Icon(Icons.share),
            title: Text('Share Post'),
            dense: true,
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _showEditPostDialog();
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
      case 'report':
        _showReportDialog();
        break;
      case 'share':
        _sharePost();
        break;
    }
  }

  void _showEditPostDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Post'),
        content: const Text('Edit post functionality would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Implement edit functionality
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deletePost();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: const Text('Report post functionality would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post reported successfully')),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _sharePost() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality would be implemented here')),
    );
  }

  Future<void> _deletePost() async {
    try {
      final deletePost = ref.read(deletePostProvider);
      await deletePost(widget.post.id, widget.currentMemberId);
      
      widget.onPostDeleted?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete post: $e')),
        );
      }
    }
  }

  String _getAuthorName() {
    // In a real implementation, this would fetch the member name
    return 'Member ${widget.post.authorId.substring(0, 8)}';
  }

  String _getAuthorInitials() {
    final name = _getAuthorName();
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, 2).toUpperCase();
    }
    return 'U';
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