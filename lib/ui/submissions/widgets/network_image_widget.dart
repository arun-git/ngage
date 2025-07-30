import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Conditional import for cached_network_image
import 'package:cached_network_image/cached_network_image.dart'
    if (dart.library.html) 'network_image_web_stub.dart';

/// A widget that displays network images with proper fallbacks for web
class NetworkImageWidget extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const NetworkImageWidget({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Use Flutter's built-in Image.network for web
      return Image.network(
        imageUrl,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              Container(
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              Container(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load image',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
        },
      );
    } else {
      // Use CachedNetworkImage for mobile platforms
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        placeholder: (context, url) =>
            placeholder ??
            Container(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        errorWidget: (context, url, error) =>
            errorWidget ??
            Container(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
      );
    }
  }
}
