import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/group.dart';
import '../../providers/group_providers.dart';
import '../../providers/image_providers.dart';
import 'group_avatar.dart';

/// Widget for picking and managing group images
class GroupImagePicker extends ConsumerStatefulWidget {
  final Group group;
  final double size;
  final bool showEditButton;
  final bool isSquare;
  final VoidCallback? onImageUpdated;

  const GroupImagePicker({
    super.key,
    required this.group,
    this.size = 120,
    this.showEditButton = true,
    this.isSquare = false,
    this.onImageUpdated,
  });

  @override
  ConsumerState<GroupImagePicker> createState() => _GroupImagePickerState();
}

class _GroupImagePickerState extends ConsumerState<GroupImagePicker> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            GroupAvatar(
              group: widget.group,
              radius: widget.size / 2,
              showBorder: true,
              isSquare: widget.isSquare,
            ),
            if (widget.showEditButton)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isUploading ? Icons.hourglass_empty : Icons.camera_alt,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20,
                    ),
                    onPressed: _isUploading ? null : _showImageOptions,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (_isUploading) ...[
          const SizedBox(height: 8),
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 4),
          Text(
            'Uploading...',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (widget.group.imageUrl != null &&
                widget.group.imageUrl!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Image'),
                onTap: () {
                  Navigator.pop(context);
                  _removeImage();
                },
              ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isUploading = true;
      });

      final imageService = ref.read(imageServiceProvider);
      final imageUrl = await imageService.pickAndUploadGroupImage(
        groupId: widget.group.id,
        source: source,
      );

      if (imageUrl != null) {
        await _updateGroupImage(imageUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _removeImage() async {
    try {
      setState(() {
        _isUploading = true;
      });

      // Delete the current image from storage if it exists
      if (widget.group.imageUrl != null && widget.group.imageUrl!.isNotEmpty) {
        final imageService = ref.read(imageServiceProvider);
        await imageService.deleteImage(widget.group.imageUrl!);
      }

      // Update group with null image URL
      await _updateGroupImage(null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _updateGroupImage(String? imageUrl) async {
    try {
      final groupNotifier = ref.read(groupNotifierProvider.notifier);
      await groupNotifier.updateGroupImage(
        groupId: widget.group.id,
        imageUrl: imageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              imageUrl != null
                  ? 'Group image updated successfully!'
                  : 'Group image removed successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        widget.onImageUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Simple group image display widget without editing capabilities
class GroupImageDisplay extends StatelessWidget {
  final Group group;
  final double size;
  final bool isSquare;
  final VoidCallback? onTap;

  const GroupImageDisplay({
    super.key,
    required this.group,
    this.size = 80,
    this.isSquare = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GroupAvatar(
      group: group,
      radius: size / 2,
      onTap: onTap,
      showBorder: true,
      isSquare: isSquare,
    );
  }
}
