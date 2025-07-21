import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Service for handling file uploads to Firebase Storage
class FileUploadService {
  final FirebaseStorage _storage;

  FileUploadService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Upload a file to Firebase Storage
  Future<String> uploadFile(File file, String fileName) async {
    try {
      final ref = _storage.ref().child(fileName);
      final uploadTask = ref.putFile(file);
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Upload multiple files
  Future<List<String>> uploadFiles(List<File> files, String basePath) async {
    final List<String> urls = [];
    
    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final fileName = '$basePath/${DateTime.now().millisecondsSinceEpoch}_$i.${_getFileExtension(file.path)}';
      final url = await uploadFile(file, fileName);
      urls.add(url);
    }
    
    return urls;
  }

  /// Delete a file from Firebase Storage
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Get file extension from path
  String _getFileExtension(String path) {
    return path.split('.').last.toLowerCase();
  }
}