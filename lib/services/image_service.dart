import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

/// Service for handling image operations
///
/// Provides functionality for picking, uploading, and managing images
/// with Firebase Storage integration.
class ImageService {
  final FirebaseStorage _storage;
  final ImagePicker _imagePicker;

  ImageService({
    FirebaseStorage? storage,
    ImagePicker? imagePicker,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _imagePicker = imagePicker ?? ImagePicker();

  /// Pick an image from gallery or camera
  Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
      );

      return image;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Upload image to Firebase Storage
  Future<String> uploadImage({
    required XFile imageFile,
    required String path,
    String? fileName,
    Map<String, String>? metadata,
  }) async {
    try {
      // Generate filename if not provided
      final String finalFileName = fileName ??
          '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';

      // Create storage reference
      final Reference ref = _storage.ref().child('$path/$finalFileName');

      // Prepare upload task
      UploadTask uploadTask;

      if (kIsWeb) {
        // For web, read as bytes
        final Uint8List imageData = await imageFile.readAsBytes();
        uploadTask = ref.putData(
          imageData,
          SettableMetadata(
            contentType: _getContentType(imageFile.name),
            customMetadata: metadata,
          ),
        );
      } else {
        // For mobile/desktop, use file
        final File file = File(imageFile.path);
        uploadTask = ref.putFile(
          file,
          SettableMetadata(
            contentType: _getContentType(imageFile.name),
            customMetadata: metadata,
          ),
        );
      }

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Delete image from Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract path from URL and delete
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Upload group image with optimized settings
  Future<String> uploadGroupImage({
    required XFile imageFile,
    required String groupId,
  }) async {
    return uploadImage(
      imageFile: imageFile,
      path: 'groups/$groupId/images',
      fileName: 'group_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
      metadata: {
        'groupId': groupId,
        'type': 'group_image',
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get optimized image picker settings for group images
  static const int groupImageMaxWidth = 800;
  static const int groupImageMaxHeight = 800;
  static const int groupImageQuality = 85;

  /// Pick and upload group image in one operation
  Future<String?> pickAndUploadGroupImage({
    required String groupId,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      // Pick image with optimized settings
      final XFile? imageFile = await pickImage(
        source: source,
        maxWidth: groupImageMaxWidth,
        maxHeight: groupImageMaxHeight,
        imageQuality: groupImageQuality,
      );

      if (imageFile == null) {
        return null;
      }

      // Upload the image
      return await uploadGroupImage(
        imageFile: imageFile,
        groupId: groupId,
      );
    } catch (e) {
      throw Exception('Failed to pick and upload group image: $e');
    }
  }

  /// Get content type from file extension
  String _getContentType(String fileName) {
    final String extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Validate image file
  bool isValidImageFile(XFile file) {
    final String extension = file.name.toLowerCase().split('.').last;
    const List<String> validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    return validExtensions.contains(extension);
  }

  /// Get file size in MB
  Future<double> getFileSizeInMB(XFile file) async {
    final int bytes = await file.length();
    return bytes / (1024 * 1024);
  }

  /// Validate image file size (max 5MB for group images)
  Future<bool> isValidImageSize(XFile file, {double maxSizeMB = 5.0}) async {
    final double sizeMB = await getFileSizeInMB(file);
    return sizeMB <= maxSizeMB;
  }
}
