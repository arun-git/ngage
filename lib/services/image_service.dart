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

  /// Upload team logo with optimized settings
  Future<String> uploadTeamLogo({
    required XFile imageFile,
    required String teamId,
    required String groupId,
  }) async {
    return uploadImage(
      imageFile: imageFile,
      path: 'teams/$teamId/images',
      fileName: 'team_logo_${DateTime.now().millisecondsSinceEpoch}.jpg',
      metadata: {
        'teamId': teamId,
        'groupId': groupId,
        'type': 'team_logo',
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Upload event banner image with optimized settings
  Future<String> uploadEventBannerImage({
    required XFile imageFile,
    required String eventId,
    required String groupId,
  }) async {
    return uploadImage(
      imageFile: imageFile,
      path: 'events/$eventId/images',
      fileName: 'banner_${DateTime.now().millisecondsSinceEpoch}.jpg',
      metadata: {
        'eventId': eventId,
        'groupId': groupId,
        'type': 'event_banner',
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get optimized image picker settings for group images
  static const int groupImageMaxWidth = 800;
  static const int groupImageMaxHeight = 800;
  static const int groupImageQuality = 85;

  /// Get optimized image picker settings for team logos
  static const int teamLogoMaxWidth = 400;
  static const int teamLogoMaxHeight = 400;
  static const int teamLogoQuality = 90;

  /// Get optimized image picker settings for event banner images
  static const int eventBannerMaxWidth = 1200;
  static const int eventBannerMaxHeight = 600;
  static const int eventBannerQuality = 90;

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

  /// Pick and upload team logo in one operation
  Future<String?> pickAndUploadTeamLogo({
    required String teamId,
    required String groupId,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      // Pick image with optimized settings for team logo
      final XFile? imageFile = await pickImage(
        source: source,
        maxWidth: teamLogoMaxWidth,
        maxHeight: teamLogoMaxHeight,
        imageQuality: teamLogoQuality,
      );

      if (imageFile == null) {
        return null;
      }

      // Upload the logo
      return await uploadTeamLogo(
        imageFile: imageFile,
        teamId: teamId,
        groupId: groupId,
      );
    } catch (e) {
      throw Exception('Failed to pick and upload team logo: $e');
    }
  }

  /// Pick and upload event banner image in one operation
  Future<String?> pickAndUploadEventBannerImage({
    required String eventId,
    required String groupId,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      // Pick image with optimized settings for banner
      final XFile? imageFile = await pickImage(
        source: source,
        maxWidth: eventBannerMaxWidth,
        maxHeight: eventBannerMaxHeight,
        imageQuality: eventBannerQuality,
      );

      if (imageFile == null) {
        return null;
      }

      // Upload the image
      return await uploadEventBannerImage(
        imageFile: imageFile,
        eventId: eventId,
        groupId: groupId,
      );
    } catch (e) {
      throw Exception('Failed to pick and upload event banner image: $e');
    }
  }

  /// Upload temporary event banner image for new events (before event creation)
  Future<String> uploadTempEventBannerImage({
    required XFile imageFile,
    required String groupId,
  }) async {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    return uploadImage(
      imageFile: imageFile,
      path: 'temp/events/$groupId/banners',
      fileName: 'banner_$tempId.jpg',
      metadata: {
        'groupId': groupId,
        'type': 'temp_event_banner',
        'uploadedAt': DateTime.now().toIso8601String(),
        'tempId': tempId,
      },
    );
  }

  /// Pick and upload temporary event banner image
  Future<String?> pickAndUploadTempEventBannerImage({
    required String groupId,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      // Pick image with optimized settings for banner
      final XFile? imageFile = await pickImage(
        source: source,
        maxWidth: eventBannerMaxWidth,
        maxHeight: eventBannerMaxHeight,
        imageQuality: eventBannerQuality,
      );

      if (imageFile == null) {
        return null;
      }

      // Upload to temporary location
      return await uploadTempEventBannerImage(
        imageFile: imageFile,
        groupId: groupId,
      );
    } catch (e) {
      throw Exception(
          'Failed to pick and upload temporary event banner image: $e');
    }
  }

  /// Move temporary banner image to final event location
  Future<String?> moveTempBannerToEvent({
    required String tempImageUrl,
    required String eventId,
    required String groupId,
  }) async {
    try {
      // Get reference to temporary image
      final tempRef = _storage.refFromURL(tempImageUrl);

      // Download the temporary image data
      final Uint8List? imageDataNullable = await tempRef.getData();
      if (imageDataNullable == null) {
        throw Exception('Failed to download temporary image data');
      }
      final Uint8List imageData = imageDataNullable;

      // Create new reference for final location
      final finalRef = _storage.ref().child(
          'events/$eventId/images/banner_${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Upload to final location
      final uploadTask = finalRef.putData(
        imageData,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'eventId': eventId,
            'groupId': groupId,
            'type': 'event_banner',
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask;
      final finalUrl = await snapshot.ref.getDownloadURL();

      // Delete temporary image
      try {
        await tempRef.delete();
      } catch (e) {
        // Log but don't fail if temp cleanup fails
        if (kDebugMode) {
          print('Warning: Failed to delete temporary image: $e');
        }
      }

      return finalUrl;
    } catch (e) {
      throw Exception('Failed to move temporary banner to event: $e');
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

  /// Upload temporary team logo for new teams (before team creation)
  Future<String> uploadTempTeamLogo({
    required XFile imageFile,
    required String groupId,
  }) async {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    return uploadImage(
      imageFile: imageFile,
      path: 'temp/teams/$groupId/logos',
      fileName: 'logo_$tempId.jpg',
      metadata: {
        'groupId': groupId,
        'type': 'temp_team_logo',
        'uploadedAt': DateTime.now().toIso8601String(),
        'tempId': tempId,
      },
    );
  }

  /// Move temporary team logo to final team location
  Future<String?> moveTempLogoToTeam({
    required String tempLogoUrl,
    required String teamId,
    required String groupId,
  }) async {
    try {
      // Get reference to temporary logo
      final tempRef = _storage.refFromURL(tempLogoUrl);

      // Download the temporary logo data
      final Uint8List? logoDataNullable = await tempRef.getData();
      if (logoDataNullable == null) {
        throw Exception('Failed to download temporary logo data');
      }
      final Uint8List logoData = logoDataNullable;

      // Create new reference for final location
      final finalRef = _storage.ref().child(
          'teams/$teamId/images/team_logo_${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Upload to final location
      final uploadTask = finalRef.putData(
        logoData,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'teamId': teamId,
            'groupId': groupId,
            'type': 'team_logo',
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask;
      final finalUrl = await snapshot.ref.getDownloadURL();

      // Delete temporary logo
      try {
        await tempRef.delete();
      } catch (e) {
        // Log but don't fail if temp cleanup fails
        if (kDebugMode) {
          print('Warning: Failed to delete temporary logo: $e');
        }
      }

      return finalUrl;
    } catch (e) {
      throw Exception('Failed to move temporary logo to team: $e');
    }
  }

  /// Clean up temporary logo if team creation fails
  Future<void> cleanupTempLogo(String tempLogoUrl) async {
    try {
      final tempRef = _storage.refFromURL(tempLogoUrl);
      await tempRef.delete();
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Failed to cleanup temporary logo: $e');
      }
    }
  }

  /// Clean up temporary banner images older than specified duration
  Future<void> cleanupTempBannerImages({
    Duration maxAge = const Duration(hours: 24),
  }) async {
    try {
      final tempRef = _storage.ref().child('temp/events');
      final result = await tempRef.listAll();

      final cutoffTime = DateTime.now().subtract(maxAge);

      for (final item in result.items) {
        try {
          final metadata = await item.getMetadata();
          final uploadTime = metadata.timeCreated;

          if (uploadTime != null && uploadTime.isBefore(cutoffTime)) {
            await item.delete();
          }
        } catch (e) {
          // Continue with other items if one fails
          if (kDebugMode) {
            print('Failed to process temp image ${item.name}: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to cleanup temp banner images: $e');
      }
    }
  }

  /// Clean up temporary team logos older than specified duration
  Future<void> cleanupTempTeamLogos({
    Duration maxAge = const Duration(hours: 24),
  }) async {
    try {
      final tempRef = _storage.ref().child('temp/teams');
      final result = await tempRef.listAll();

      final cutoffTime = DateTime.now().subtract(maxAge);

      for (final item in result.items) {
        try {
          final metadata = await item.getMetadata();
          final uploadTime = metadata.timeCreated;

          if (uploadTime != null && uploadTime.isBefore(cutoffTime)) {
            await item.delete();
          }
        } catch (e) {
          // Continue with other items if one fails
          if (kDebugMode) {
            print('Failed to process temp logo ${item.name}: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to cleanup temp team logos: $e');
      }
    }
  }
}
