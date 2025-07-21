import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

/// Repository for managing judge assignments in Firestore
class JudgeAssignmentRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'judge_assignments';

  JudgeAssignmentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a new judge assignment
  Future<JudgeAssignment> create(JudgeAssignment assignment) async {
    final docRef = _firestore.collection(_collection).doc(assignment.id);
    await docRef.set(assignment.toJson());
    return assignment;
  }

  /// Get judge assignment by ID
  Future<JudgeAssignment?> getById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    
    return JudgeAssignment.fromJson({
      'id': doc.id,
      ...doc.data()!,
    });
  }

  /// Get all assignments for an event
  Future<List<JudgeAssignment>> getByEventId(String eventId) async {
    final query = await _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .orderBy('assignedAt', descending: false)
        .get();

    return query.docs.map((doc) => JudgeAssignment.fromJson({
      'id': doc.id,
      ...doc.data(),
    })).toList();
  }

  /// Get active assignments for an event
  Future<List<JudgeAssignment>> getActiveByEventId(String eventId) async {
    final query = await _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .where('isActive', isEqualTo: true)
        .orderBy('assignedAt', descending: false)
        .get();

    return query.docs.map((doc) => JudgeAssignment.fromJson({
      'id': doc.id,
      ...doc.data(),
    })).toList();
  }

  /// Get assignments for a specific judge
  Future<List<JudgeAssignment>> getByJudgeId(String judgeId) async {
    final query = await _firestore
        .collection(_collection)
        .where('judgeId', isEqualTo: judgeId)
        .orderBy('assignedAt', descending: false)
        .get();

    return query.docs.map((doc) => JudgeAssignment.fromJson({
      'id': doc.id,
      ...doc.data(),
    })).toList();
  }

  /// Get active assignments for a specific judge
  Future<List<JudgeAssignment>> getActiveByJudgeId(String judgeId) async {
    final query = await _firestore
        .collection(_collection)
        .where('judgeId', isEqualTo: judgeId)
        .where('isActive', isEqualTo: true)
        .orderBy('assignedAt', descending: false)
        .get();

    return query.docs.map((doc) => JudgeAssignment.fromJson({
      'id': doc.id,
      ...doc.data(),
    })).toList();
  }

  /// Check if a judge is assigned to an event
  Future<JudgeAssignment?> getAssignment(String eventId, String judgeId) async {
    final query = await _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .where('judgeId', isEqualTo: judgeId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    return JudgeAssignment.fromJson({
      'id': doc.id,
      ...doc.data(),
    });
  }

  /// Check if a judge is actively assigned to an event
  Future<JudgeAssignment?> getActiveAssignment(String eventId, String judgeId) async {
    final query = await _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .where('judgeId', isEqualTo: judgeId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    return JudgeAssignment.fromJson({
      'id': doc.id,
      ...doc.data(),
    });
  }

  /// Update an existing judge assignment
  Future<JudgeAssignment> update(JudgeAssignment assignment) async {
    final docRef = _firestore.collection(_collection).doc(assignment.id);
    await docRef.update(assignment.toJson());
    return assignment;
  }

  /// Delete a judge assignment
  Future<void> delete(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  /// Get assignments with pagination
  Future<List<JudgeAssignment>> getAssignmentsPaginated({
    String? eventId,
    String? judgeId,
    bool? isActive,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _firestore.collection(_collection);

    if (eventId != null) {
      query = query.where('eventId', isEqualTo: eventId);
    }
    if (judgeId != null) {
      query = query.where('judgeId', isEqualTo: judgeId);
    }
    if (isActive != null) {
      query = query.where('isActive', isEqualTo: isActive);
    }

    query = query.orderBy('assignedAt', descending: false).limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final querySnapshot = await query.get();
    return querySnapshot.docs.map((doc) => JudgeAssignment.fromJson({
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    })).toList();
  }

  /// Stream assignments for real-time updates
  Stream<List<JudgeAssignment>> streamByEventId(String eventId) {
    return _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .orderBy('assignedAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => JudgeAssignment.fromJson({
              'id': doc.id,
              ...doc.data(),
            })).toList());
  }

  /// Stream active assignments for an event
  Stream<List<JudgeAssignment>> streamActiveByEventId(String eventId) {
    return _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .where('isActive', isEqualTo: true)
        .orderBy('assignedAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => JudgeAssignment.fromJson({
              'id': doc.id,
              ...doc.data(),
            })).toList());
  }

  /// Get assignment count for an event
  Future<int> getAssignmentCount(String eventId) async {
    final query = await _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .count()
        .get();
    
    return query.count ?? 0;
  }

  /// Get active assignment count for an event
  Future<int> getActiveAssignmentCount(String eventId) async {
    final query = await _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .where('isActive', isEqualTo: true)
        .count()
        .get();
    
    return query.count ?? 0;
  }

  /// Check if a judge is assigned to an event
  Future<bool> isJudgeAssigned(String eventId, String judgeId) async {
    final assignment = await getAssignment(eventId, judgeId);
    return assignment != null;
  }

  /// Check if a judge is actively assigned to an event
  Future<bool> isJudgeActivelyAssigned(String eventId, String judgeId) async {
    final assignment = await getActiveAssignment(eventId, judgeId);
    return assignment != null;
  }

  /// Get assignments by role
  Future<List<JudgeAssignment>> getByRole(String eventId, JudgeRole role) async {
    final query = await _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .where('role', isEqualTo: role.value)
        .where('isActive', isEqualTo: true)
        .orderBy('assignedAt', descending: false)
        .get();

    return query.docs.map((doc) => JudgeAssignment.fromJson({
      'id': doc.id,
      ...doc.data(),
    })).toList();
  }

  /// Get lead judges for an event
  Future<List<JudgeAssignment>> getLeadJudges(String eventId) async {
    return await getByRole(eventId, JudgeRole.leadJudge);
  }

  /// Get regular judges for an event
  Future<List<JudgeAssignment>> getRegularJudges(String eventId) async {
    return await getByRole(eventId, JudgeRole.judge);
  }
}