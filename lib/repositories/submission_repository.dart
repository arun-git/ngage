import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/submission.dart';

/// Repository for managing submission data in Firestore and file storage
class SubmissionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  SubmissionRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  /// Collection reference for submissions
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('submissions');

  /// Storage reference for submission files
  Reference get _storageRef => _storage.ref().child('submissions');

  /// Create a new submission
  Future<Submission> create(Submission submission) async {
    final docRef = _collection.doc(submission.id);
    await docRef.set(submission.toJson());
    return submission;
  }

  /// Get submission by ID
  Future<Submission?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    
    final data = doc.data()!;
    return Submission.fromJson(data);
  }

  /// Update an existing submission
  Future<Submission> update(Submission submission) async {
    final updatedSubmission = submission.copyWith(updatedAt: DateTime.now());
    await _collection.doc(submission.id).update(updatedSubmission.toJson());
    return updatedSubmission;
  }

  /// Delete a submission
  Future<void> delete(String id) async {
    // First delete all associated files
    await _deleteSubmissionFiles(id);
    
    // Then delete the document
    await _collection.doc(id).delete();
  }

  /// Get submissions for a specific event
  Future<List<Submission>> getByEventId(String eventId) async {
    final query = await _collection
        .where('eventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => Submission.fromJson(doc.data()))
        .toList();
  }

  /// Get submissions for a specific team
  Future<List<Submission>> getByTeamId(String teamId) async {
    final query = await _collection
        .where('teamId', isEqualTo: teamId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => Submission.fromJson(doc.data()))
        .toList();
  }

  /// Get submissions by a specific member
  Future<List<Submission>> getByMemberId(String memberId) async {
    final query = await _collection
        .where('submittedBy', isEqualTo: memberId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => Submission.fromJson(doc.data()))
        .toList();
  }

  /// Upload a file and return the download URL
  Future<String> uploadFile(String submissionId, File file, String fileName) async {
    final fileRef = _storageRef.child(submissionId).child(fileName);
    
    final uploadTask = fileRef.putFile(file);
    final snapshot = await uploadTask;
    
    return await snapshot.ref.getDownloadURL();
  }

  /// Upload multiple files with progress tracking
  Future<List<String>> uploadFiles(
    String submissionId,
    List<File> files,
    List<String> fileNames,
    void Function(double progress)? onProgress,
  ) async {
    if (files.length != fileNames.length) {
      throw ArgumentError('Files and fileNames lists must have the same length');
    }

    final urls = <String>[];
    final totalFiles = files.length;
    
    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final fileName = fileNames[i];
      
      final url = await uploadFile(submissionId, file, fileName);
      urls.add(url);
      
      // Report progress
      if (onProgress != null) {
        final progress = (i + 1) / totalFiles;
        onProgress(progress);
      }
    }
    
    return urls;
  }

  /// Delete a specific file from storage
  Future<void> deleteFile(String submissionId, String fileName) async {
    final fileRef = _storageRef.child(submissionId).child(fileName);
    await fileRef.delete();
  }

  /// Delete all files for a submission
  Future<void> _deleteSubmissionFiles(String submissionId) async {
    try {
      final submissionRef = _storageRef.child(submissionId);
      final listResult = await submissionRef.listAll();
      
      // Delete all files in the submission folder
      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      // If the folder doesn't exist or is empty, that's fine
      // We don't want to fail the deletion because of missing files
    }
  }

  /// Stream submissions for real-time updates
  Stream<List<Submission>> streamByEventId(String eventId) {
    return _collection
        .where('eventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Submission.fromJson(doc.data()))
            .toList());
  }

  /// Stream a specific submission for real-time updates
  Stream<Submission?> streamById(String id) {
    return _collection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Submission.fromJson(doc.data()!);
    });
  }

  /// Get submissions with pagination
  Future<List<Submission>> getSubmissionsPaginated({
    String? eventId,
    String? teamId,
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> query = _collection;

    if (eventId != null) {
      query = query.where('eventId', isEqualTo: eventId);
    }
    
    if (teamId != null) {
      query = query.where('teamId', isEqualTo: teamId);
    }

    query = query.orderBy('createdAt', descending: true);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => Submission.fromJson(doc.data()))
        .toList();
  }

  /// Check if a team has already submitted for an event
  Future<bool> hasTeamSubmitted(String eventId, String teamId) async {
    final query = await _collection
        .where('eventId', isEqualTo: eventId)
        .where('teamId', isEqualTo: teamId)
        .where('status', whereNotIn: ['draft'])
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /// Get submission count for an event
  Future<int> getSubmissionCount(String eventId) async {
    final query = await _collection
        .where('eventId', isEqualTo: eventId)
        .where('status', whereNotIn: ['draft'])
        .get();

    return query.docs.length;
  }

  /// Get draft submissions for a specific event
  Future<List<Submission>> getDraftSubmissionsByEvent(String eventId) async {
    final query = await _collection
        .where('eventId', isEqualTo: eventId)
        .where('status', isEqualTo: 'draft')
        .get();

    return query.docs
        .map((doc) => Submission.fromJson(doc.data()))
        .toList();
  }
}