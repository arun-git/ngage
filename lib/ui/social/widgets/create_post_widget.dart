import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/models.dart';

/// Widget for creating new posts
class CreatePostWidget extends ConsumerStatefulWidget {
  final String authorId;
  final String groupId;
  final Function(Post)? onPostCreated;

  const CreatePostWidget({
    super.key,
    required this.authorId,
    required this.groupId,
    this.onPostCreated,
  });

  @override
  ConsumerState<CreatePostWidget> createState() => _CreatePostWidgetState();
}

class _CreatePostWidgetState extends ConsumerState<CreatePostWidget> {
  final TextEditingController _contentController = TextEditingController();
  final List<File> _selectedMedia = [];
  bool _isSubmitting = false;
  PostContentType _contentType = PostContentType.text;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitPost,
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Post'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author info
                  _buildAuthorInfo(),
                  
                  const SizedBox(height: 16),
                  
                  // Content input
                  _buildContentInput(),
                  
                  const SizedBox(height: 16),
                  
                  // Media preview
                  if (_selectedMedia.isNotEmpty) _buildMediaPreview(),
                  
                  const SizedBox(height: 16),
                  
                  // Content type selector
                  _buildContentTypeSelector(),
                ],
              ),
            ),
          ),
          
          // Bottom toolbar
          _buildBottomToolbar(),
        ],
      ),
    );
  }

  Widget _buildAuthorInfo() {
    return Row(
      children: [
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getAuthorName(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Posting to group',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContentInput() {
    return TextField(
      controller: _contentController,
      decoration: const InputDecoration(
        hintText: "What's on your mind?",
        border: InputBorder.none,
        hintStyle: TextStyle(fontSize: 18),
      ),
      style: const TextStyle(fontSize: 18),
      maxLines: null,
      minLines: 3,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildMediaPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Media (${_selectedMedia.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            TextButton(
              onPressed: () => setState(() => _selectedMedia.clear()),
              child: const Text('Clear All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedMedia.length,
            itemBuilder: (context, index) {
              final file = _selectedMedia[index];
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        file,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeMedia(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContentTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content Type',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: PostContentType.values.map((type) {
            final isSelected = _contentType == type;
            return FilterChip(
              label: Text(_getContentTypeLabel(type)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _contentType = type);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBottomToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // Media button
          IconButton(
            onPressed: _pickMedia,
            icon: const Icon(Icons.photo_library),
            tooltip: 'Add Photos/Videos',
          ),
          
          // Camera button
          IconButton(
            onPressed: _takePhoto,
            icon: const Icon(Icons.camera_alt),
            tooltip: 'Take Photo',
          ),
          
          const Spacer(),
          
          // Character count
          Text(
            '${_contentController.text.length}/5000',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _contentController.text.length > 4500 
                  ? Colors.red 
                  : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _pickMedia() {
    // In a real implementation, this would use image_picker or similar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Media picker would be implemented here')),
    );
  }

  void _takePhoto() {
    // In a real implementation, this would use camera functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera functionality would be implemented here')),
    );
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
    });
  }

  Future<void> _submitPost() async {
    final content = _contentController.text.trim();
    
    if (content.isEmpty && _selectedMedia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some content or media')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final createPost = ref.read(createPostProvider);
      final post = await createPost(CreatePostRequest(
        groupId: widget.groupId,
        authorId: widget.authorId,
        content: content,
        mediaFiles: _selectedMedia.isNotEmpty ? _selectedMedia : null,
        contentType: _contentType,
      ));

      widget.onPostCreated?.call(post);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create post: $e')),
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

  String _getAuthorName() {
    // In a real implementation, this would fetch the member name
    return 'Member ${widget.authorId.substring(0, 8)}';
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

  String _getContentTypeLabel(PostContentType type) {
    switch (type) {
      case PostContentType.text:
        return 'Text';
      case PostContentType.image:
        return 'Image';
      case PostContentType.video:
        return 'Video';
      case PostContentType.mixed:
        return 'Mixed';
    }
  }
}