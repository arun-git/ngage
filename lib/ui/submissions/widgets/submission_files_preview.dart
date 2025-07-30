import 'package:flutter/material.dart';
import '../../../models/submission.dart';
import 'file_preview_widget.dart';

/// Widget for displaying a preview of all files in a submission
class SubmissionFilesPreview extends StatelessWidget {
  final Submission submission;
  final bool showAllFiles;
  final int maxPreviewFiles;

  const SubmissionFilesPreview({
    super.key,
    required this.submission,
    this.showAllFiles = false,
    this.maxPreviewFiles = 6,
  });

  @override
  Widget build(BuildContext context) {
    final allFiles = _getAllFiles();

    if (allFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    final filesToShow =
        showAllFiles ? allFiles : allFiles.take(maxPreviewFiles).toList();

    final hasMoreFiles = allFiles.length > maxPreviewFiles && !showAllFiles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachments (${allFiles.length})',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: filesToShow.length + (hasMoreFiles ? 1 : 0),
          itemBuilder: (context, index) {
            if (hasMoreFiles && index == filesToShow.length) {
              return _buildMoreFilesIndicator(
                  context, allFiles.length - maxPreviewFiles);
            }

            final fileInfo = filesToShow[index];
            return FilePreviewWidget(
              fileUrl: fileInfo.url,
              fileType: fileInfo.type,
              fileName: fileInfo.name,
              showFileName: false,
            );
          },
        ),
      ],
    );
  }

  Widget _buildMoreFilesIndicator(BuildContext context, int remainingCount) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: InkWell(
        onTap: () => _showAllFiles(context),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.more_horiz,
              size: 32,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              '+$remainingCount',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllFiles(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            children: [
              // Header
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
                        'All Files (${_getAllFiles().length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SubmissionFilesPreview(
                    submission: submission,
                    showAllFiles: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<FileInfo> _getAllFiles() {
    final files = <FileInfo>[];

    // Add photos
    for (final photoUrl in submission.photoUrls) {
      files.add(FileInfo(
        url: photoUrl,
        type: 'photos',
        name: _extractFileName(photoUrl),
      ));
    }

    // Add videos
    for (final videoUrl in submission.videoUrls) {
      files.add(FileInfo(
        url: videoUrl,
        type: 'videos',
        name: _extractFileName(videoUrl),
      ));
    }

    // Add documents
    for (final documentUrl in submission.documentUrls) {
      files.add(FileInfo(
        url: documentUrl,
        type: 'documents',
        name: _extractFileName(documentUrl),
      ));
    }

    return files;
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
}

/// Helper class to store file information
class FileInfo {
  final String url;
  final String type;
  final String name;

  const FileInfo({
    required this.url,
    required this.type,
    required this.name,
  });
}
