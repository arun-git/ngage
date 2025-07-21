import 'package:flutter/material.dart';
import '../../../models/models.dart';

/// Widget for displaying post media content
class PostMediaWidget extends StatelessWidget {
  final List<String> mediaUrls;
  final PostContentType contentType;

  const PostMediaWidget({
    super.key,
    required this.mediaUrls,
    required this.contentType,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaUrls.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _buildMediaContent(context),
    );
  }

  Widget _buildMediaContent(BuildContext context) {
    if (mediaUrls.length == 1) {
      return _buildSingleMedia(context, mediaUrls.first);
    } else if (mediaUrls.length <= 4) {
      return _buildMediaGrid(context);
    } else {
      return _buildMediaCarousel(context);
    }
  }

  Widget _buildSingleMedia(BuildContext context, String mediaUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _buildMediaItem(context, mediaUrl, 0),
      ),
    );
  }

  Widget _buildMediaGrid(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: mediaUrls.length == 2 ? 2 : 2,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 1,
        ),
        itemCount: mediaUrls.length,
        itemBuilder: (context, index) {
          return _buildMediaItem(context, mediaUrls[index], index);
        },
      ),
    );
  }

  Widget _buildMediaCarousel(BuildContext context) {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: mediaUrls.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildMediaItem(context, mediaUrls[index], index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMediaItem(BuildContext context, String mediaUrl, int index) {
    final isImage = _isImageUrl(mediaUrl);
    final isVideo = _isVideoUrl(mediaUrl);

    if (isImage) {
      return GestureDetector(
        onTap: () => _showMediaViewer(context, index),
        child: Image.network(
          mediaUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.broken_image, size: 48),
              ),
            );
          },
        ),
      );
    } else if (isVideo) {
      return GestureDetector(
        onTap: () => _showMediaViewer(context, index),
        child: Container(
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video thumbnail placeholder
              Container(
                color: Colors.grey[800],
                child: const Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              ),
              
              // Video duration overlay (placeholder)
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
                    '0:00',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Unknown media type
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.attachment, size: 48),
              SizedBox(height: 8),
              Text('Media file'),
            ],
          ),
        ),
      );
    }
  }

  void _showMediaViewer(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaViewerScreen(
          mediaUrls: mediaUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  bool _isImageUrl(String url) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    return imageExtensions.any((ext) => url.toLowerCase().endsWith(ext));
  }

  bool _isVideoUrl(String url) {
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];
    return videoExtensions.any((ext) => url.toLowerCase().endsWith(ext));
  }
}

/// Full-screen media viewer
class MediaViewerScreen extends StatefulWidget {
  final List<String> mediaUrls;
  final int initialIndex;

  const MediaViewerScreen({
    super.key,
    required this.mediaUrls,
    required this.initialIndex,
  });

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '${_currentIndex + 1} of ${widget.mediaUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.mediaUrls.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final mediaUrl = widget.mediaUrls[index];
          final isImage = _isImageUrl(mediaUrl);
          
          if (isImage) {
            return InteractiveViewer(
              child: Center(
                child: Image.network(
                  mediaUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 64, color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          } else {
            // Video or other media
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_outline, size: 64, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Video playback would be implemented here',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  bool _isImageUrl(String url) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    return imageExtensions.any((ext) => url.toLowerCase().endsWith(ext));
  }
}