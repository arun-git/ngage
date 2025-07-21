import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/scoring_rubric.dart';

/// Repository for managing scoring rubric data in Firestore
class ScoringRubricRepository {
  final FirebaseFirestore _firestore;

  ScoringRubricRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference for scoring rubrics
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('scoring_rubrics');

  /// Create a new scoring rubric
  Future<ScoringRubric> create(ScoringRubric rubric) async {
    final docRef = _collection.doc(rubric.id);
    await docRef.set(rubric.toJson());
    return rubric;
  }

  /// Get scoring rubric by ID
  Future<ScoringRubric?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    
    final data = doc.data()!;
    return ScoringRubric.fromJson(data);
  }

  /// Update an existing scoring rubric
  Future<ScoringRubric> update(ScoringRubric rubric) async {
    final updatedRubric = rubric.copyWith(updatedAt: DateTime.now());
    await _collection.doc(rubric.id).update(updatedRubric.toJson());
    return updatedRubric;
  }

  /// Delete a scoring rubric
  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }

  /// Get all rubrics for a specific event
  Future<List<ScoringRubric>> getByEventId(String eventId) async {
    final query = await _collection
        .where('eventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => ScoringRubric.fromJson(doc.data()))
        .toList();
  }

  /// Get all rubrics for a specific group
  Future<List<ScoringRubric>> getByGroupId(String groupId) async {
    final query = await _collection
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => ScoringRubric.fromJson(doc.data()))
        .toList();
  }

  /// Get all template rubrics (reusable across events/groups)
  Future<List<ScoringRubric>> getTemplates() async {
    final query = await _collection
        .where('isTemplate', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => ScoringRubric.fromJson(doc.data()))
        .toList();
  }

  /// Get rubrics created by a specific member
  Future<List<ScoringRubric>> getByCreator(String creatorId) async {
    final query = await _collection
        .where('createdBy', isEqualTo: creatorId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => ScoringRubric.fromJson(doc.data()))
        .toList();
  }

  /// Search rubrics by name
  Future<List<ScoringRubric>> searchByName(String searchTerm, {String? groupId}) async {
    // Note: Firestore doesn't support full-text search natively
    // This is a basic implementation that gets all rubrics and filters client-side
    // For production, consider using Algolia or similar search service
    
    Query<Map<String, dynamic>> query = _collection;
    
    if (groupId != null) {
      query = query.where('groupId', isEqualTo: groupId);
    }
    
    final allRubrics = await query.get();
    final searchTermLower = searchTerm.toLowerCase();
    
    return allRubrics.docs
        .map((doc) => ScoringRubric.fromJson(doc.data()))
        .where((rubric) {
          return rubric.name.toLowerCase().contains(searchTermLower) ||
                 rubric.description.toLowerCase().contains(searchTermLower);
        })
        .toList();
  }

  /// Clone a rubric (create a copy)
  Future<ScoringRubric> clone(String rubricId, {
    String? newName,
    String? newEventId,
    String? newGroupId,
    bool? isTemplate,
    required String createdBy,
  }) async {
    final originalRubric = await getById(rubricId);
    if (originalRubric == null) {
      throw Exception('Rubric not found');
    }

    final now = DateTime.now();
    final clonedRubric = originalRubric.copyWith(
      id: _generateRubricId(),
      name: newName ?? '${originalRubric.name} (Copy)',
      eventId: newEventId,
      groupId: newGroupId,
      isTemplate: isTemplate ?? originalRubric.isTemplate,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );

    return await create(clonedRubric);
  }

  /// Create rubric from template
  Future<ScoringRubric> createFromTemplate(
    String templateId, {
    required String name,
    String? eventId,
    String? groupId,
    required String createdBy,
  }) async {
    return await clone(
      templateId,
      newName: name,
      newEventId: eventId,
      newGroupId: groupId,
      isTemplate: false,
      createdBy: createdBy,
    );
  }

  /// Get rubrics with pagination
  Future<List<ScoringRubric>> getRubricsPaginated({
    String? eventId,
    String? groupId,
    bool? isTemplate,
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> query = _collection;

    if (eventId != null) {
      query = query.where('eventId', isEqualTo: eventId);
    }
    
    if (groupId != null) {
      query = query.where('groupId', isEqualTo: groupId);
    }
    
    if (isTemplate != null) {
      query = query.where('isTemplate', isEqualTo: isTemplate);
    }

    query = query.orderBy('createdAt', descending: true);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => ScoringRubric.fromJson(doc.data()))
        .toList();
  }

  /// Stream rubrics for real-time updates
  Stream<List<ScoringRubric>> streamByEventId(String eventId) {
    return _collection
        .where('eventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScoringRubric.fromJson(doc.data()))
            .toList());
  }

  /// Stream a specific rubric for real-time updates
  Stream<ScoringRubric?> streamById(String id) {
    return _collection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ScoringRubric.fromJson(doc.data()!);
    });
  }

  /// Check if rubric exists
  Future<bool> exists(String id) async {
    final doc = await _collection.doc(id).get();
    return doc.exists;
  }

  /// Get rubric count for a group
  Future<int> getGroupRubricCount(String groupId) async {
    final query = await _collection
        .where('groupId', isEqualTo: groupId)
        .count()
        .get();
    
    return query.count ?? 0;
  }

  /// Get template count
  Future<int> getTemplateCount() async {
    final query = await _collection
        .where('isTemplate', isEqualTo: true)
        .count()
        .get();
    
    return query.count ?? 0;
  }

  /// Delete all rubrics for an event
  Future<void> deleteByEventId(String eventId) async {
    final rubrics = await getByEventId(eventId);
    
    final batch = _firestore.batch();
    for (final rubric in rubrics) {
      batch.delete(_collection.doc(rubric.id));
    }
    
    await batch.commit();
  }

  /// Delete all rubrics for a group
  Future<void> deleteByGroupId(String groupId) async {
    final rubrics = await getByGroupId(groupId);
    
    // Delete in batches (Firestore batch limit is 500)
    for (int i = 0; i < rubrics.length; i += 500) {
      final batch = _firestore.batch();
      final batchRubrics = rubrics.skip(i).take(500);
      
      for (final rubric in batchRubrics) {
        batch.delete(_collection.doc(rubric.id));
      }
      
      await batch.commit();
    }
  }

  /// Validate rubric before saving
  Future<bool> validateRubric(ScoringRubric rubric) async {
    // Check for duplicate names within the same scope
    Query<Map<String, dynamic>> query = _collection
        .where('name', isEqualTo: rubric.name);

    if (rubric.eventId != null) {
      query = query.where('eventId', isEqualTo: rubric.eventId);
    } else if (rubric.groupId != null) {
      query = query.where('groupId', isEqualTo: rubric.groupId);
    } else if (rubric.isTemplate) {
      query = query.where('isTemplate', isEqualTo: true);
    }

    final existing = await query.get();
    
    // Allow if no duplicates or if it's the same rubric being updated
    return existing.docs.isEmpty || 
           (existing.docs.length == 1 && existing.docs.first.id == rubric.id);
  }

  /// Generate a unique rubric ID
  String _generateRubricId() {
    return 'rubric_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
  }

  /// Generate random string for ID
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(length, (index) => chars[random % chars.length]).join();
  }
}