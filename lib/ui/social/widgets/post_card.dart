import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/models.dart';
import '../../../providers/post_providers.dart';
import '../../../providers/member_providers.dart';
import 'post_comments_widget.dart';

/// Card widget for displaying a social post
/// 
/// Shows post content, media, engagement metrics, and interaction buttons.
/// Supports like/unlike functionality and comment viewing.
class PostCard extends ConsumerStatefulWidget {
  final Post post;
  final String currentMemberId;
  final VoidCallback? onPostUpdated;

  const PostCard({
    super.key,
    required this.post,
    required this.currentMemberId,
    this.onPostUpdated,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _showComments = false;
  bool _isLiking = false;

  Future<void> _toggleLike() async {
    if (_isLiking) return;

    setState(() {
      _isLiking = true;
    });

    try {
      final service = ref.read(postServiceProvider);
      final isLiked = await service.isPostLiked(
        postId: widget.post.id,
        memberId: widget.currentMemberId,
      );

      if (isLiked) {
        await service.unlikePost(
          postId: widget.post.id,
          memberId: widget.currentMemberId,
        );
      } else {
        await service.likePost(
          postId: widget.post.id,
          memberId: widget.currentMemberId,
        );
      }

      // Invalidate providers to refresh data
      ref.invalidate(isPostLikedProvider);
      widget.onPostUpdated?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating like: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLiking = false;
        });
      }
    }
  }

  void _toggleComments() {
    setState(() {
      _showComments = !_showComments;
    });
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

  @override
  Widget build(BuildContext context) {
    final authorAsync = ref.watch(memberProvider(widget.post.authorId));
    final isLikedAsync = ref.watch(isPostLikedProvider(
      PostLikeCheckParams(
        postId: widget.post.id,
        memberId: widget.currentMemberId,
      ),
    ));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: authorAsync.when(
                    data: (author) => author?.profilePhoto != null
                        ? NetworkImage(author!.profilePhoto!)
                        : null,
                    loading: () => null,
                    error: (_, __) => null,
                  ),
                  child: authorAsync.when(
                    data: (author) => author?.profilePhoto == null
                        ? Text(
                            author?.firstName.substring(0, 1).toUpperCase() ?? '?',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        : null,
                    loading: () => const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, __) => const Icon(Icons.person),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      authorAsync.when(
                        data: (author) => Text(
                          '${author?.firstName ?? 'Unknown'} ${author?.lastName ?? 'User'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        loading: () => const Text('Loading...'),
                        error: (_, __) => const Text('Unknown User'),
                      ),
                      Text(
                        _formatTimestamp(widget.post.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    // Handle post actions (edit, delete, report, etc.)
                    switch (value) {
                      case 'edit':
                        // TODO: Implement edit functionality
                        break;
                      case 'delete':
                        // TODO: Implement delete functionality
                        break;
                      case 'report':
                        // TODO: Implement report functionality
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (widget.post.authorId == widget.currentMemberId) ...[
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ] else ...[
                      const PopupMenuItem(
                        value: 'report',
                        child: Text('Report'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Post content
          if (widget.post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                widget.post.content,
                style: const TextStyle(fontSize: 16),
              ),
            ),

          // Media content
          if (widget.post.hasMedia) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: widget.post.mediaUrls.length,
                itemBuilder: (context, index) {
                  final mediaUrl = widget.post.mediaUrls[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        mediaUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.error, size: 48),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Engagement metrics
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                if (widget.post.likeCount > 0) ...[
                  Icon(Icons.favorite, size: 16, color: Colors.red[400]),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.post.likeCount}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
                if (widget.post.likeCount > 0 && widget.post.commentCount > 0)
                  const SizedBox(width: 16),
                if (widget.post.commentCount > 0) ...[
                  Icon(Icons.comment, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.post.commentCount}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                // Like button
                Expanded(
                  child: isLikedAsync.when(
                    data: (isLiked) => TextButton.icon(
                      onPressed: _isLiking ? null : _toggleLike,
                      icon: _isLiking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.grey[600],
                            ),
                      label: Text(
                        'Like',
                        style: TextStyle(
                          color: isLiked ? Colors.red : Colors.grey[600],
                        ),
                      ),
                    ),
                    loading: () => TextButton.icon(
                      onPressed: null,
                      icon: const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      label: const Text('Like'),
                    ),
                    error: (_, __) => TextButton.icon(
                      onPressed: _toggleLike,
                      icon: Icon(Icons.favorite_border, color: Colors.grey[600]),
                      label: Text('Like', style: TextStyle(color: Colors.grey[600])),
                    ),
                  ),
                ),

                // Comment button
                Expanded(
                  child: TextButton.icon(
                    onPressed: _toggleComments,
                    icon: Icon(Icons.comment, color: Colors.grey[600]),
                    label: Text(
                      'Comment',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),

                // Share button (placeholder)
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      // TODO: Implement share functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share functionality coming soon!')),
                      );
                    },
                    icon: Icon(Icons.share, color: Colors.grey[600]),
                    label: Text(
                      'Share',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Comments section
          if (_showComments) ...[
            const Divider(height: 1),
            PostCommentsWidget(
              postId: widget.post.id,
              currentMemberId: widget.currentMemberId,
              onCommentAdded: widget.onPostUpdated,
            ),
          ],
        ],
      ),
    );
  }
}