import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'file_preview_widget.dart';

/// Widget for handling file uploads with preview and progress tracking
class FileUploadWidget extends StatelessWidget {
  final String title;
  final String fileType;
  final List<String> files;
  final bool canEdit;
  final bool isUploading;
  final double uploadProgress;
  final VoidCallback onUpload;
  final void Function(String url) onRemove;

  const FileUploadWidget({
    super.key,
    required this.title,
    required this.fileType,
    required this.files,
    required this.canEdit,
    required this.isUploading,
    required this.uploadProgress,
    required this.onUpload,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (canEdit)
                  ElevatedButton.icon(
                    onPressed: isUploading ? null : onUpload,
                    icon: const Icon(Icons.upload_file),
                    label: Text('Add $title'),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Upload progress indicator
            if (isUploading) ...[
              LinearProgressIndicator(value: uploadProgress),
              const SizedBox(height: 8),
              Text(
                'Uploading... ${(uploadProgress * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
            ],

            // File list
            if (files.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.5),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getFileTypeIcon(),
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No $title uploaded',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              )
            else
              _buildFileList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFileList(BuildContext context) {
    // For small number of files, show grid preview
    if (files.length <= 6) {
      return _buildGridPreview(context);
    } else {
      // For many files, show list view
      return _buildListPreview(context);
    }
  }

  Widget _buildGridPreview(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final fileUrl = files[index];
        final fileName = _extractFileName(fileUrl);

        return Stack(
          children: [
            FilePreviewWidget(
              fileUrl: fileUrl,
              fileType: fileType,
              fileName: fileName,
              showFileName: false,
            ),
            // Remove button overlay
            if (canEdit)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 16),
                    onPressed: () => _confirmRemove(context, fileUrl, fileName),
                    tooltip: 'Remove file',
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildListPreview(BuildContext context) {
    return Column(
      children: files.asMap().entries.map((entry) {
        final index = entry.key;
        final fileUrl = entry.value;
        final fileName = _extractFileName(fileUrl);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: SizedBox(
              width: 56,
              height: 56,
              child: FilePreviewWidget(
                fileUrl: fileUrl,
                fileType: fileType,
                fileName: fileName,
                showFileName: false,
              ),
            ),
            title: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('File ${index + 1}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () => _openFile(fileUrl),
                  tooltip: 'Open file',
                ),
                if (canEdit)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _confirmRemove(context, fileUrl, fileName),
                    tooltip: 'Remove file',
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getFileTypeIcon() {
    switch (fileType) {
      case 'photos':
        return Icons.photo;
      case 'videos':
        return Icons.video_file;
      case 'documents':
        return Icons.description;
      default:
        return Icons.attach_file;
    }
  }

  String _extractFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        String fileName = pathSegments.last;
        // Remove Firebase Storage tokens and decode
        if (fileName.contains('?')) {
          fileName = fileName.split('?').first;
        }
        return Uri.decodeComponent(fileName);
      }
    } catch (e) {
      // If parsing fails, return a generic name
    }
    return 'File';
  }

  Future<void> _openFile(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error silently or show a message
    }
  }

  Future<void> _confirmRemove(
      BuildContext context, String fileUrl, String fileName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove File'),
        content: Text('Are you sure you want to remove "$fileName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onRemove(fileUrl);
    }
  }
}
