import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'network_image_widget.dart';
import 'video_player_modal.dart';
import 'pdf_viewer_modal.dart';

/// Widget for previewing different file types with modal expansion
class FilePreviewWidget extends StatelessWidget {
  final String fileUrl;
  final String fileType;
  final String fileName;
  final bool showFileName;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const FilePreviewWidget({
    super.key,
    required this.fileUrl,
    required this.fileType,
    required this.fileName,
    this.showFileName = true,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _showExpandedPreview(context),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
                child: _buildPreview(context),
              ),
            ),
            if (showFileName)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(8)),
                ),
                child: Text(
                  fileName,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    switch (fileType) {
      case 'photos':
        return _buildImagePreview(context);
      case 'videos':
        return _buildVideoThumbnail(context);
      case 'documents':
        return _buildDocumentPreview(context);
      default:
        return _buildGenericFilePreview(context);
    }
  }

  Widget _buildImagePreview(BuildContext context) {
    return NetworkImageWidget(
      imageUrl: fileUrl,
      fit: BoxFit.cover,
    );
  }

  Widget _buildVideoThumbnail(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.video_library,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'VIDEO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(12),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPreview(BuildContext context) {
    final isPdf = fileName.toLowerCase().endsWith('.pdf');

    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPdf ? Icons.picture_as_pdf : Icons.description,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          if (isPdf)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Text(
                'PDF',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGenericFilePreview(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.attach_file,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'FILE',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showExpandedPreview(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => FilePreviewModal(
        fileUrl: fileUrl,
        fileType: fileType,
        fileName: fileName,
      ),
    );
  }
}

/// Modal dialog for expanded file preview
class FilePreviewModal extends StatefulWidget {
  final String fileUrl;
  final String fileType;
  final String fileName;

  const FilePreviewModal({
    super.key,
    required this.fileUrl,
    required this.fileType,
    required this.fileName,
  });

  @override
  State<FilePreviewModal> createState() => _FilePreviewModalState();
}

class _FilePreviewModalState extends State<FilePreviewModal> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          children: [
            // Header with file name and close button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.fileName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            // Content area
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: _buildExpandedContent(context),
              ),
            ),
            // Footer with actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _openExternally(),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Externally'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    switch (widget.fileType) {
      case 'photos':
        return _buildExpandedImage(context);
      case 'videos':
        return _buildExpandedVideo(context);
      case 'documents':
        return _buildExpandedDocument(context);
      default:
        return _buildExpandedGeneric(context);
    }
  }

  Widget _buildExpandedImage(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3.0,
      child: NetworkImageWidget(
        imageUrl: widget.fileUrl,
        fit: BoxFit.contain,
        placeholder: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        errorWidget: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load image',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedVideo(BuildContext context) {
    return VideoPlayerModal(videoUrl: widget.fileUrl);
  }

  Widget _buildExpandedDocument(BuildContext context) {
    final isPdf = widget.fileName.toLowerCase().endsWith('.pdf');

    if (isPdf) {
      return PDFViewerModal(pdfUrl: widget.fileUrl);
    } else {
      return _buildExpandedGeneric(context);
    }
  }

  Widget _buildExpandedGeneric(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.description,
            color: Colors.white,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            widget.fileName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Preview not available for this file type',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openExternally(),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open Externally'),
          ),
        ],
      ),
    );
  }

  Future<void> _openExternally() async {
    try {
      final uri = Uri.parse(widget.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open file: $e')),
        );
      }
    }
  }
}
