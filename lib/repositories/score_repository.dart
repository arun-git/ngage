import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/score.dart';

/// Repository for managing score data in Firestore
class ScoreRepository {
  final FirebaseFirestore _firestore;

  ScoreRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference for scores
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('scores');

  /// Create a new score
  Future<Score> create(Score score) async {
    final docRef = _collection.doc(score.id);
    await docRef.set(score.toJson());
    return score;
  }

  /// Get score by ID
  Future<Score?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    
    final data = doc.data()!;
    return Score.fromJson(data);
  }

  /// Get scores by submission ID
  Future<List<Score>> getBySubmissionId(String submissionId) async {
    final query = await _collection
        .where('submissionId', isEqualTo: submissionId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => Score.fromJson(doc.data()))
        .toList();
  }

  /// Get scores by judge ID
  Future<List<Score>> getByJudgeId(String judgeId) async {
    final query = await _collection
        .where('judgeId', isEqualTo: judgeId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => Score.fromJson(doc.data()))
        .toList();
  }

  /// Get scores by event ID
  Future<List<Score>> getByEventId(String eventId) async {
    final query = await _collection
        .where('eventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => Score.fromJson(doc.data()))
        .toList();
  }

  /// Update an existing score
  Future<Score> update(Score score) async {
    final docRef = _collection.doc(score.id);
    await docRef.update(score.toJson());
    return score;
  }

  /// Delete a score
  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }

  /// Get scores for multiple submissions
  Future<Map<String, List<Score>>> getBySubmissionIds(List<String> submissionIds) async {
    if (submissionIds.isEmpty) {
      return {};
    }
    
    final result = <String, List<Score>>{};
    
    // Initialize empty lists for all submission IDs
    for (final id in submissionIds) {
      result[id] = [];
    }

    // Firestore 'in' query limit is 10, so we need to batch
    for (int i = 0; i < submissionIds.length; i += 10) {
      final batch = submissionIds.skip(i).take(10).toList();
      
      final query = await _collection
          .where('submissionId', whereIn: batch)
          .get();

      for (final doc in query.docs) {
        final score = Score.fromJson(doc.data());
        result[score.submissionId]!.add(score);
      }
    }

    // Sort scores by creation date for each submission
    for (final scores in result.values) {
      scores.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return result;
  }

  /// Stream scores for real-time updates
  Stream<List<Score>> streamBySubmissionId(String submissionId) {
    return _collection
        .where('submissionId', isEqualTo: submissionId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Score.fromJson(doc.data()))
            .toList());
  }

  /// Stream scores for an event for real-time updates
  Stream<List<Score>> streamByEventId(String eventId) {
    return _collection
        .where('eventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Score.fromJson(doc.data()))
            .toList());
  }

  /// Stream a specific score for real-time updates
  Stream<Score?> streamById(String id) {
    return _collection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Score.fromJson(doc.data()!);
    });
  }

  /// Get average score for a submission
  Future<double?> getAverageScore(String submissionId) async {
    final scores = await getBySubmissionId(submissionId);
    
    if (scores.isEmpty) {
      return null;
    }
    
    final totalScore = scores.fold<double>(
      0.0,
      (sum, score) => sum + score.totalScore,
    );
    
    return totalScore / scores.length;
  }
}