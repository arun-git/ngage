import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Cross-platform file upload service that handles both web and mobile platforms
class FileUploadService {
  final FirebaseStorage _storage;

  FileUploadService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Upload a single file from PlatformFile to Firebase Storage
  Future<String> uploadPlatformFile({
    required PlatformFile file,
    required String storagePath,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref().child(storagePath);

    final metadata = SettableMetadata(
      contentType: _getContentType(file.extension),
      customMetadata: {
        'originalName': file.name,
        'size': file.size.toString(),
      },
    );

    // Get file bytes
    Uint8List? bytes = file.bytes;

    // If bytes are not available, try to read from file path (mobile only)
    if (bytes == null && file.path != null) {
      if (kIsWeb) {
        throw Exception('File bytes are null on web platform');
      } else {
        // For mobile platforms, we need to read the file
        // This is a simplified approach - in practice, file_picker usually provides bytes
        throw Exception(
            'File bytes not available and path reading not implemented');
      }
    }

    if (bytes == null) {
      throw Exception('Unable to get file bytes');
    }

    // Use putData for all platforms since we have bytes
    final uploadTask = ref.putData(bytes, metadata);

    // Track upload progress
    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Upload multiple files with progress tracking
  Future<List<String>> uploadMultiplePlatformFiles({
    required List<PlatformFile> files,
    required String baseStoragePath,
    void Function(double progress)? onProgress,
  }) async {
    final urls = <String>[];
    final totalFiles = files.length;

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final fileName = _generateUniqueFileName(file.name);
      final storagePath = '$baseStoragePath/$fileName';

      final url = await uploadPlatformFile(
        file: file,
        storagePath: storagePath,
      );

      urls.add(url);

      // Report overall progress
      if (onProgress != null) {
        final progress = (i + 1) / totalFiles;
        onProgress(progress);
      }
    }

    return urls;
  }

  /// Delete a file from Firebase Storage
  Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      // File might not exist, which is fine
      if (kDebugMode) {
        print('Warning: Could not delete file: $e');
      }
    }
  }

  /// Get content type based on file extension
  String? _getContentType(String? extension) {
    if (extension == null) return null;

    final ext = extension.toLowerCase();
    switch (ext) {
      // Images
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'svg':
        return 'image/svg+xml';

      // Videos
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'webm':
        return 'video/webm';

      // Documents
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'rtf':
        return 'application/rtf';

      default:
        return 'application/octet-stream';
    }
  }

  /// Generate a unique filename to avoid conflicts
  String _generateUniqueFileName(String originalName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = originalName.contains('.')
        ? originalName.substring(originalName.lastIndexOf('.'))
        : '';
    final nameWithoutExt = originalName.contains('.')
        ? originalName.substring(0, originalName.lastIndexOf('.'))
        : originalName;

    return '${nameWithoutExt}_$timestamp$extension';
  }
}
