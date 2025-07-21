import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

/// Repository for managing judge comments in Firestore
class JudgeCommentRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'judge_comments';

  JudgeCommentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a new judge comment
  Future<JudgeComment> create(JudgeComment comment) async {
    final docRef = _firestore.collection(_collection).doc(comment.id);
    await docRef.set(comment.toJson());
    return comment;
  }

  /// Get judge comment by ID
  Future<JudgeComment?> getById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    
    return JudgeComment.fromJson({
      'id': doc.id,
      ...doc.data()!,
    });
  }

  /// Get all comments for a submission
  Future<List<JudgeComment>> getBySubmissionId(String submissionId) async {
    final query = await _firestore
        .collection(_collection)
        .where('submissionId', isEqualTo: submissionId)
        .orderBy('createdAt', descending: false)
        .get();

    return query.docs.map((doc) => JudgeComment.fromJson({
      'id': doc.id,
      ...doc.data(),
    })).toList();
  }

  /// Get comments by event ID
  Future<List<JudgeComment>> getByEventId(String eventId) async {
    final query = await _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: false)
        .get();

    return query.docs.map((doc) => JudgeComment.fromJson({
      'id': doc.id,
      ...doc.data(),
    })).toList();
  }

  /// Get comments by judge ID
  Future<List<JudgeComment>> getByJudgeId(String judgeId) async {
    final query = await _firestore
        .collection(_collection)
        .where('judgeId', isEqualTo: judgeId)
        .orderBy('createdAt', descending: false)
        .get();

    return query.docs.map((doc) => JudgeComment.fromJson({
      'id': doc.id,
      ...doc.data(),
    })).toList();
  }

  /// Get threaded comments (replies to a parent comment)
  Future<List<JudgeComment>> getReplies(String parentCommentId) async {
    final query = await _firestore
        .collection(_collection)
        .where('parentCommentId', isEqualTo: parentCommentId)
        .orderBy('createdAt', descending: false)
        .get();

    return query.docs.map((doc) => JudgeComment.fromJson({
      'id': doc.id,
      ...doc.data(),
    })).toList();
  }

  /// Get top-level comments for a submission (no parent)
  Future<List<JudgeComment>> getTopLevelComments(String submissionId) async {
    final query = await _firestore
        .collection(_collection)
        .where('submissionId', isEqualTo: submissionId)
        .where('parentCommentId', isNull: true)
        .orderBy('createdAt', descending: false)
        .get();

    return query.docs.map((doc) => JudgeComment.fromJson({
      'id': doc.id,
      ...doc.data(),
    })).toList();
  }

  /// Update an existing judge comment
  Future<JudgeComment> update(JudgeComment comment) async {
    final docRef = _firestore.collection(_collection).doc(comment.id);
    await docRef.update(comment.toJson());
    return comment;
  }

  /// Delete a judge comment
  Future<void> delete(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  /// Get comments with pagination
  Future<List<JudgeComment>> getCommentsPaginated({
    String? submissionId,
    String? eventId,
    String? judgeId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _firestore.collection(_collection);

    if (submissionId != null) {
      query = query.where('submissionId', isEqualTo: submissionId);
    }
    if (eventId != null) {
      query = query.where('eventId', isEqualTo: eventId);
    }
    if (judgeId != null) {
      query = query.where('judgeId', isEqualTo: judgeId);
    }

    query = query.orderBy('createdAt', descending: false).limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final querySnapshot = await query.get();
    return querySnapshot.docs.map((doc) => JudgeComment.fromJson({
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    })).toList();
  }

  /// Stream comments for real-time updates
  Stream<List<JudgeComment>> streamBySubmissionId(String submissionId) {
    return _firestore
        .collection(_collection)
        .where('submissionId', isEqualTo: submissionId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => JudgeComment.fromJson({
              'id': doc.id,
              ...doc.data(),
            })).toList());
  }

  /// Stream comments by event for real-time updates
  Stream<List<JudgeComment>> streamByEventId(String eventId) {
    return _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => JudgeComment.fromJson({
              'id': doc.id,
              ...doc.data(),
            })).toList());
  }

  /// Get comment count for a submission
  Future<int> getCommentCount(String submissionId) async {
    final query = await _firestore
        .collection(_collection)
        .where('submissionId', isEqualTo: submissionId)
        .count()
        .get();
    
    return query.count ?? 0;
  }

  /// Check if a judge has commented on a submission
  Future<bool> hasJudgeCommented(String submissionId, String judgeId) async {
    final query = await _firestore
        .collection(_collection)
        .where('submissionId', isEqualTo: submissionId)
        .where('judgeId', isEqualTo: judgeId)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }
}