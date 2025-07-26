import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/image_service.dart';

/// Provider for ImageService
final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService();
});
