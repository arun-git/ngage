import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/models.dart';
import '../../../providers/post_providers.dart';

/// Widget for displaying and managing post comments
class PostCommentsWidget extends ConsumerStatefulWidget {
  final String postId;
  final String currentMemberId;
  final VoidCallback? onCommentAdded;

  const PostCommentsWidget({
    super.key,
    required this.postId,
    required this.currentMemberId,
    this.onCommentAdded,
  });

  @override
  ConsumerState<PostCommentsWidget> createState() => _PostCommentsWidgetState();
}

class _PostCommentsWidgetState extends ConsumerState<PostCommentsWidget> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  bool _isSubmitting = false;
  String? _replyingToCommentId;
  String? _replyingToAuthorName;

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsRequest = PostCommentsRequest(postId: widget.postId);
    final commentsAsync = ref.watch(postCommentsProvider(commentsRequest));

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          // Comments list
          commentsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error loading comments: $error'),
            ),
            data: (comments) => _buildCommentsList(comments),
          ),
          
          // Comment input
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentsList(List<PostComment> comments) {
    if (comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No comments yet. Be the first to comment!',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Group comments by parent (top-level vs replies)
    final topLevelComments = comments.where((c) => c.isTopLevel).toList();
    final repliesByParent = <String, List<PostComment>>{};
    
    for (final comment in comments.where((c) => c.isReply)) {
      final parentId = comment.parentCommentId!;
      repliesByParent.putIfAbsent(parentId, () => []).add(comment);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: topLevelComments.length,
      itemBuilder: (context, index) {
        final comment = topLevelComments[index];
        final replies = repliesByParent[comment.id] ?? [];
        
        return _buildCommentThread(comment, replies);
      },
    );
  }

  Widget _buildCommentThread(PostComment comment, List<PostComment> replies) {
    return Column(
      children: [
        _buildCommentItem(comment, isReply: false),
        
        // Replies
        if (replies.isNotEmpty) ...[
          ...replies.map((reply) => Padding(
            padding: const EdgeInsets.only(left: 32),
            child: _buildCommentItem(reply, isReply: true),
          )),
        ],
      ],
    );
  }

  Widget _buildCommentItem(PostComment comment, {required bool isReply}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author avatar
          CircleAvatar(
            radius: isReply ? 14 : 16,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Text(
              _getAuthorInitials(comment.authorId),
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: isReply ? 10 : 12,
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author name and timestamp
                Row(
                  children: [
                    Text(
                      _getAuthorName(comment.authorId),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimestamp(comment.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                // Comment text
                Text(
                  comment.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                
                const SizedBox(height: 8),
                
                // Comment actions
                Row(
                  children: [
                    // Like button
                    GestureDetector(
                      onTap: () => _likeComment(comment.id),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          if (comment.likeCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              comment.likeCount.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Reply button (only for top-level comments)
                    if (!isReply) ...[
                      GestureDetector(
                        onTap: () => _startReply(comment.id, comment.authorId),
                        child: Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    
                    const Spacer(),
                    
                    // More options
                    if (comment.authorId == widget.currentMemberId) ...[
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_horiz, size: 16, color: Colors.grey[600]),
                        onSelected: (value) => _handleCommentAction(value, comment),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          // Reply indicator
          if (_replyingToCommentId != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.reply,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Replying to $_replyingToAuthorName',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Comment input field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  decoration: InputDecoration(
                    hintText: _replyingToCommentId != null 
                        ? 'Write a reply...' 
                        : 'Write a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Send button
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isSubmitting ? null : _submitComment,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startReply(String commentId, String authorId) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToAuthorName = _getAuthorName(authorId);
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToAuthorName = null;
    });
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final addComment = ref.read(addCommentProvider);
      await addComment(AddCommentRequest(
        postId: widget.postId,
        authorId: widget.currentMemberId,
        content: content,
        parentCommentId: _replyingToCommentId,
      ));

      _commentController.clear();
      _cancelReply();
      widget.onCommentAdded?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add comment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _likeComment(String commentId) async {
    try {
      final likeComment = ref.read(likeCommentProvider);
      await likeComment(commentId, widget.currentMemberId);
    } catch (e) {
      debugPrint('Error liking comment: $e');
    }
  }

  void _handleCommentAction(String action, PostComment comment) {
    switch (action) {
      case 'edit':
        _showEditCommentDialog(comment);
        break;
      case 'delete':
        _showDeleteCommentDialog(comment);
        break;
    }
  }

  void _showEditCommentDialog(PostComment comment) {
    final controller = TextEditingController(text: comment.content);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Edit your comment...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty) {
                try {
                  final updateComment = ref.read(updateCommentProvider);
                  await updateComment(UpdateCommentRequest(
                    commentId: comment.id,
                    memberId: widget.currentMemberId,
                    content: newContent,
                  ));
                  
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Comment updated successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update comment: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCommentDialog(PostComment comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final deleteComment = ref.read(deleteCommentProvider);
                await deleteComment(comment.id, widget.currentMemberId);
                
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Comment deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete comment: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getAuthorName(String authorId) {
    // In a real implementation, this would fetch the member name
    return 'Member ${authorId.substring(0, 8)}';
  }

  String _getAuthorInitials(String authorId) {
    final name = _getAuthorName(authorId);
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
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}