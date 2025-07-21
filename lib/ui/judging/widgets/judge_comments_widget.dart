import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/models.dart';
import '../../../providers/judging_providers.dart';

/// Widget for displaying and managing judge comments on submissions
class JudgeCommentsWidget extends ConsumerStatefulWidget {
  final String submissionId;
  final String eventId;
  final String currentJudgeId;

  const JudgeCommentsWidget({
    super.key,
    required this.submissionId,
    required this.eventId,
    required this.currentJudgeId,
  });

  @override
  ConsumerState<JudgeCommentsWidget> createState() => _JudgeCommentsWidgetState();
}

class _JudgeCommentsWidgetState extends ConsumerState<JudgeCommentsWidget> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  JudgeCommentType _selectedType = JudgeCommentType.general;
  String? _replyToCommentId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(submissionCommentsProvider(widget.submissionId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.comment, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Judge Discussion',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Chip(
                  label: const Text('Private'),
                  backgroundColor: Colors.orange.shade100,
                  side: BorderSide(color: Colors.orange.shade300),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Comments list
            Expanded(
              child: commentsAsync.when(
                data: (comments) => _buildCommentsList(comments),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Error loading comments: $error'),
                ),
              ),
            ),
            
            const Divider(),
            
            // Comment input
            _buildCommentInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsList(List<JudgeComment> comments) {
    if (comments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No comments yet',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            Text(
              'Start the discussion by adding a comment',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Group comments by thread
    final topLevelComments = comments.where((c) => c.isTopLevel).toList();
    final repliesByParent = <String, List<JudgeComment>>{};
    
    for (final comment in comments.where((c) => c.isReply)) {
      repliesByParent.putIfAbsent(comment.parentCommentId!, () => []).add(comment);
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: topLevelComments.length,
      itemBuilder: (context, index) {
        final comment = topLevelComments[index];
        final replies = repliesByParent[comment.id] ?? [];
        
        return _buildCommentThread(comment, replies);
      },
    );
  }

  Widget _buildCommentThread(JudgeComment comment, List<JudgeComment> replies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommentCard(comment, isReply: false),
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: Column(
              children: replies.map((reply) => _buildCommentCard(reply, isReply: true)).toList(),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCommentCard(JudgeComment comment, {required bool isReply}) {
    final isOwnComment = comment.judgeId == widget.currentJudgeId;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isReply ? Colors.grey.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    comment.judgeId.substring(0, 1).toUpperCase(),
                    style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Judge ${comment.judgeId.substring(0, 8)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          _buildCommentTypeChip(comment.type),
                        ],
                      ),
                      Text(
                        _formatDateTime(comment.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (isOwnComment)
                  PopupMenuButton<String>(
                    onSelected: (action) => _handleCommentAction(action, comment),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(comment.content),
            const SizedBox(height: 8),
            Row(
              children: [
                if (!isReply)
                  TextButton.icon(
                    onPressed: () => _startReply(comment.id),
                    icon: const Icon(Icons.reply, size: 16),
                    label: const Text('Reply'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                if (comment.createdAt != comment.updatedAt)
                  Text(
                    'Edited',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentTypeChip(JudgeCommentType type) {
    Color color;
    switch (type) {
      case JudgeCommentType.question:
        color = Colors.blue;
        break;
      case JudgeCommentType.concern:
        color = Colors.orange;
        break;
      case JudgeCommentType.suggestion:
        color = Colors.green;
        break;
      case JudgeCommentType.clarification:
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        type.value.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(fontSize: 10),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildCommentInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_replyToCommentId != null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.reply, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('Replying to comment'),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _replyToCommentId = null),
                  icon: const Icon(Icons.close, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<JudgeCommentType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Comment Type',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: JudgeCommentType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.value.replaceAll('_', ' ').toUpperCase()),
                  );
                }).toList(),
                onChanged: (type) => setState(() => _selectedType = type!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _commentController,
          decoration: InputDecoration(
            hintText: _replyToCommentId != null 
                ? 'Write your reply...' 
                : 'Add a comment for judge discussion...',
            border: const OutlineInputBorder(),
            suffixIcon: _isSubmitting
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    onPressed: _submitComment,
                    icon: const Icon(Icons.send),
                  ),
          ),
          maxLines: 3,
          minLines: 1,
          onSubmitted: (_) => _submitComment(),
        ),
      ],
    );
  }

  void _startReply(String commentId) {
    setState(() {
      _replyToCommentId = commentId;
    });
    _commentController.clear();
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(judgingServiceProvider).createJudgeComment(
        submissionId: widget.submissionId,
        eventId: widget.eventId,
        judgeId: widget.currentJudgeId,
        content: _commentController.text.trim(),
        type: _selectedType,
        parentCommentId: _replyToCommentId,
      );

      _commentController.clear();
      setState(() {
        _replyToCommentId = null;
        _selectedType = JudgeCommentType.general;
      });

      // Scroll to bottom to show new comment
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting comment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _handleCommentAction(String action, JudgeComment comment) {
    switch (action) {
      case 'edit':
        _editComment(comment);
        break;
      case 'delete':
        _deleteComment(comment);
        break;
    }
  }

  void _editComment(JudgeComment comment) {
    showDialog(
      context: context,
      builder: (context) => _EditCommentDialog(
        comment: comment,
        onSave: (content, type) async {
          try {
            await ref.read(judgingServiceProvider).updateJudgeComment(
              commentId: comment.id,
              judgeId: widget.currentJudgeId,
              content: content,
              type: type,
            );
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error updating comment: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _deleteComment(JudgeComment comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(judgingServiceProvider).deleteJudgeComment(
                  comment.id,
                  widget.currentJudgeId,
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting comment: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

class _EditCommentDialog extends StatefulWidget {
  final JudgeComment comment;
  final Function(String content, JudgeCommentType type) onSave;

  const _EditCommentDialog({
    required this.comment,
    required this.onSave,
  });

  @override
  State<_EditCommentDialog> createState() => _EditCommentDialogState();
}

class _EditCommentDialogState extends State<_EditCommentDialog> {
  late TextEditingController _controller;
  late JudgeCommentType _selectedType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.comment.content);
    _selectedType = widget.comment.type;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Comment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<JudgeCommentType>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Comment Type',
              border: OutlineInputBorder(),
            ),
            items: JudgeCommentType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.value.replaceAll('_', ' ').toUpperCase()),
              );
            }).toList(),
            onChanged: (type) => setState(() => _selectedType = type!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Comment',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveComment,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _saveComment() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isSaving = true);

    try {
      await widget.onSave(_controller.text.trim(), _selectedType);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving comment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}