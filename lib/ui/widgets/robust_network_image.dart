import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A robust network image widget that avoids DWDS errors by using FadeInImage
class RobustNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext context)? errorBuilder;
  final Widget Function(
          BuildContext context, Widget child, ImageChunkEvent? loadingProgress)?
      loadingBuilder;
  final Map<String, String>? headers;

  const RobustNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    this.loadingBuilder,
    this.headers,
  });

  @override
  Widget build(BuildContext context) {
    // Use FadeInImage which is more stable and less prone to DWDS issues
    return FadeInImage.memoryNetwork(
      placeholder: _createPlaceholderImage(),
      image: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
      placeholderErrorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder();
      },
      imageErrorBuilder: (context, error, stackTrace) {
        // Handle errors without complex logging to avoid DWDS issues
        if (kDebugMode && !kIsWeb) {
          debugPrint('Image load error: $error');
        }

        if (errorBuilder != null) {
          return errorBuilder!(context);
        }

        return _buildErrorWidget();
      },
    );
  }

  Widget _buildPlaceholder() {
    return SizedBox(
      width: width,
      height: height,
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return SizedBox(
      width: width,
      height: height,
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey,
        ),
      ),
    );
  }

  // Create a simple 1x1 transparent PNG as placeholder
  Uint8List _createPlaceholderImage() {
    // Simple 1x1 transparent PNG
    return Uint8List.fromList([
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x06,
      0x00,
      0x00,
      0x00,
      0x1F,
      0x15,
      0xC4,
      0x89,
      0x00,
      0x00,
      0x00,
      0x0A,
      0x49,
      0x44,
      0x41,
      0x54,
      0x78,
      0x9C,
      0x63,
      0x00,
      0x01,
      0x00,
      0x00,
      0x05,
      0x00,
      0x01,
      0x0D,
      0x0A,
      0x2D,
      0xB4,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4E,
      0x44,
      0xAE,
      0x42,
      0x60,
      0x82
    ]);
  }
}
