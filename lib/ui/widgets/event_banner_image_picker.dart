import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/image_service.dart';
import '../../providers/image_providers.dart';
import 'robust_network_image.dart';

/// Widget for picking and displaying event banner images
class EventBannerImagePicker extends ConsumerStatefulWidget {
  final String? currentImageUrl;
  final Function(String?) onImageChanged;
  final String? eventId;
  final String groupId;
  final bool enabled;

  const EventBannerImagePicker({
    super.key,
    this.currentImageUrl,
    required this.onImageChanged,
    this.eventId,
    required this.groupId,
    this.enabled = true,
  });

  @override
  ConsumerState<EventBannerImagePicker> createState() =>
      _EventBannerImagePickerState();
}

class _EventBannerImagePickerState
    extends ConsumerState<EventBannerImagePicker> {
  bool _isUploading = false;
  String? _tempImageUrl;

  String? get _displayImageUrl => _tempImageUrl ?? widget.currentImageUrl;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.image,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Event Banner Image',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),

          // Image display area
          Container(
            width: double.infinity,
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildImageDisplay(),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.enabled && !_isUploading
                        ? () => _pickImage(ImageSource.gallery)
                        : null,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choose from Gallery'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.enabled && !_isUploading
                        ? () => _pickImage(ImageSource.camera)
                        : null,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                  ),
                ),
              ],
            ),
          ),

          if (_displayImageUrl != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      widget.enabled && !_isUploading ? _removeImage : null,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove Image'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ),

          // Helper text
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Text(
              'Recommended size: 1200x600 pixels. The image may contain text and will be displayed as a banner.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageDisplay() {
    if (_isUploading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('Uploading image...'),
          ],
        ),
      );
    }

    if (_displayImageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: RobustNetworkImage(
          imageUrl: _displayImageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context) => _buildPlaceholder(hasError: true),
        ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder({bool hasError = false}) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasError ? Icons.broken_image : Icons.add_photo_alternate,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 8),
          Text(
            hasError ? 'Failed to load image' : 'No banner image selected',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          if (!hasError) ...[
            const SizedBox(height: 4),
            Text(
              'Tap a button below to add one',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!widget.enabled || _isUploading) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final imageService = ref.read(imageServiceProvider);

      String? imageUrl;
      if (widget.eventId != null) {
        // Event already exists, upload directly to final location
        imageUrl = await imageService.pickAndUploadEventBannerImage(
          eventId: widget.eventId!,
          groupId: widget.groupId,
          source: source,
        );
      } else {
        // Event doesn't exist yet, upload to temporary location in Firebase Storage
        imageUrl = await imageService.pickAndUploadTempEventBannerImage(
          groupId: widget.groupId,
          source: source,
        );
      }

      if (imageUrl != null) {
        setState(() {
          _tempImageUrl = imageUrl;
        });
        widget.onImageChanged(imageUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
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

  void _removeImage() {
    if (!widget.enabled || _isUploading) return;

    setState(() {
      _tempImageUrl = null;
    });
    widget.onImageChanged(null);
  }
}
