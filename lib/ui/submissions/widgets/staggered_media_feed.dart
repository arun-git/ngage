import 'package:flutter/material.dart';
import '../../../models/submission.dart';
import 'file_preview_widget.dart';

/// A staggered media feed for displaying submission files
class StaggeredMediaFeed extends StatelessWidget {
  final List<Submission> submissions;
  final VoidCallback? onTap;

  const StaggeredMediaFeed({
    super.key,
    required this.submissions,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final allMediaFiles = _extractAllMediaFiles(submissions);

    if (allMediaFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _buildMediaGrid(context, allMediaFiles),
      ],
    );
  }

  Widget _buildMediaGrid(BuildContext context, List<MediaFile> mediaFiles) {
    if (mediaFiles.isEmpty) return const SizedBox.shrink();

    // Different layouts based on number of files
    if (mediaFiles.length == 1) {
      return _buildSingleMedia(context, mediaFiles[0]);
    } else if (mediaFiles.length == 2) {
      return _buildTwoMediaLayout(context, mediaFiles);
    } else if (mediaFiles.length == 3) {
      return _buildThreeMediaLayout(context, mediaFiles);
    } else if (mediaFiles.length == 4) {
      return _buildFourMediaLayout(context, mediaFiles);
    } else {
      return _buildFiveOrMoreMediaLayout(context, mediaFiles);
    }
  }

  Widget _buildSingleMedia(BuildContext context, MediaFile media) {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 400,
        maxWidth: double.infinity,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildMediaWidget(context, media, BoxFit.cover),
      ),
    );
  }

  Widget _buildTwoMediaLayout(
      BuildContext context, List<MediaFile> mediaFiles) {
    return SizedBox(
      height: 250,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: _buildMediaWidget(context, mediaFiles[0], BoxFit.cover),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: _buildMediaWidget(context, mediaFiles[1], BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreeMediaLayout(
      BuildContext context, List<MediaFile> mediaFiles) {
    return SizedBox(
      height: 250,
      child: Row(
        children: [
          // First image takes 2/3 of the width
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: _buildMediaWidget(context, mediaFiles[0], BoxFit.cover),
            ),
          ),
          const SizedBox(width: 2),
          // Right column with 2 images
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                    ),
                    child:
                        _buildMediaWidget(context, mediaFiles[1], BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(12),
                    ),
                    child:
                        _buildMediaWidget(context, mediaFiles[2], BoxFit.cover),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFourMediaLayout(
      BuildContext context, List<MediaFile> mediaFiles) {
    return SizedBox(
      height: 250,
      child: Column(
        children: [
          // Top row with 2 images
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                    ),
                    child:
                        _buildMediaWidget(context, mediaFiles[0], BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                    ),
                    child:
                        _buildMediaWidget(context, mediaFiles[1], BoxFit.cover),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          // Bottom row with 2 images
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                    ),
                    child:
                        _buildMediaWidget(context, mediaFiles[2], BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(12),
                    ),
                    child:
                        _buildMediaWidget(context, mediaFiles[3], BoxFit.cover),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiveOrMoreMediaLayout(
      BuildContext context, List<MediaFile> mediaFiles) {
    final remainingCount = mediaFiles.length - 4;

    return SizedBox(
      height: 250,
      child: Column(
        children: [
          // Top row with 2 images
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                    ),
                    child:
                        _buildMediaWidget(context, mediaFiles[0], BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                    ),
                    child:
                        _buildMediaWidget(context, mediaFiles[1], BoxFit.cover),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          // Bottom row with 2 images + overlay
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                    ),
                    child:
                        _buildMediaWidget(context, mediaFiles[2], BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(12),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildMediaWidget(context, mediaFiles[3], BoxFit.cover),
                        // Overlay with remaining count
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '+$remainingCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaWidget(BuildContext context, MediaFile media, BoxFit fit) {
    return GestureDetector(
      onTap: () => _showMediaModal(context, media),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: FilePreviewWidget(
          fileUrl: media.url,
          fileType: media.type,
          fileName: media.fileName,
          showFileName: false,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }

  void _showMediaModal(BuildContext context, MediaFile media) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: FilePreviewWidget(
            fileUrl: media.url,
            fileType: media.type,
            fileName: media.fileName,
          ),
        ),
      ),
    );
  }

  List<MediaFile> _extractAllMediaFiles(List<Submission> submissions) {
    final List<MediaFile> allFiles = [];

    for (final submission in submissions) {
      // Add photos
      for (final photoUrl in submission.photoUrls) {
        allFiles.add(MediaFile(
          url: photoUrl,
          type: 'photos',
          fileName: _extractFileName(photoUrl),
          submissionId: submission.id,
        ));
      }

      // Add videos
      for (final videoUrl in submission.videoUrls) {
        allFiles.add(MediaFile(
          url: videoUrl,
          type: 'videos',
          fileName: _extractFileName(videoUrl),
          submissionId: submission.id,
        ));
      }

      // Add documents (PDFs only for visual appeal)
      for (final documentUrl in submission.documentUrls) {
        if (documentUrl.toLowerCase().contains('.pdf')) {
          allFiles.add(MediaFile(
            url: documentUrl,
            type: 'documents',
            fileName: _extractFileName(documentUrl),
            submissionId: submission.id,
          ));
        }
      }
    }

    return allFiles;
  }

  String _extractFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        String fileName = pathSegments.last;
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

/// Helper class to represent a media file
class MediaFile {
  final String url;
  final String type;
  final String fileName;
  final String submissionId;

  const MediaFile({
    required this.url,
    required this.type,
    required this.fileName,
    required this.submissionId,
  });
}
