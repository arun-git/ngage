import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/privacy_request.dart';
import '../models/enums.dart';

/// Repository for managing privacy requests in Firestore
class PrivacyRequestRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'privacy_requests';

  PrivacyRequestRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a new privacy request
  Future<PrivacyRequest> create(CreatePrivacyRequestData data) async {
    final now = DateTime.now();
    final docRef = _firestore.collection(_collection).doc();
    
    final request = PrivacyRequest(
      id: docRef.id,
      memberId: data.memberId,
      requestType: data.requestType,
      status: PrivacyRequestStatus.pending,
      description: data.description,
      reason: data.reason,
      requestData: data.requestData,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(request.toJson());
    return request;
  }

  /// Get privacy request by ID
  Future<PrivacyRequest?> getById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return PrivacyRequest.fromJson(doc.data()!);
  }

  /// Get all privacy requests for a member
  Future<List<PrivacyRequest>> getMemberRequests(String memberId) async {
    final query = await _firestore
        .collection(_collection)
        .where('memberId', isEqualTo: memberId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => PrivacyRequest.fromJson(doc.data()))
        .toList();
  }

  /// Get privacy requests by status
  Future<List<PrivacyRequest>> getRequestsByStatus(PrivacyRequestStatus status) async {
    final query = await _firestore
        .collection(_collection)
        .where('status', isEqualTo: status.value)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => PrivacyRequest.fromJson(doc.data()))
        .toList();
  }

  /// Get pending privacy requests
  Future<List<PrivacyRequest>> getPendingRequests() async {
    return await getRequestsByStatus(PrivacyRequestStatus.pending);
  }

  /// Get privacy requests by type
  Future<List<PrivacyRequest>> getRequestsByType(PrivacyRequestType requestType) async {
    final query = await _firestore
        .collection(_collection)
        .where('requestType', isEqualTo: requestType.value)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => PrivacyRequest.fromJson(doc.data()))
        .toList();
  }

  /// Update privacy request
  Future<PrivacyRequest> update(PrivacyRequest request) async {
    final updatedRequest = request.copyWith(updatedAt: DateTime.now());
    await _firestore
        .collection(_collection)
        .doc(request.id)
        .update(updatedRequest.toJson());
    return updatedRequest;
  }

  /// Mark request as in progress
  Future<PrivacyRequest> markInProgress(String requestId, String processedBy) async {
    final request = await getById(requestId);
    if (request == null) {
      throw Exception('Privacy request not found: $requestId');
    }

    final updatedRequest = request.markInProgress(processedBy);
    return await update(updatedRequest);
  }

  /// Mark request as completed
  Future<PrivacyRequest> markCompleted(String requestId, String responseData) async {
    final request = await getById(requestId);
    if (request == null) {
      throw Exception('Privacy request not found: $requestId');
    }

    final updatedRequest = request.markCompleted(responseData);
    return await update(updatedRequest);
  }

  /// Mark request as rejected
  Future<PrivacyRequest> markRejected(String requestId, String rejectionReason) async {
    final request = await getById(requestId);
    if (request == null) {
      throw Exception('Privacy request not found: $requestId');
    }

    final updatedRequest = request.markRejected(rejectionReason);
    return await update(updatedRequest);
  }

  /// Delete privacy request
  Future<void> delete(String requestId) async {
    await _firestore.collection(_collection).doc(requestId).delete();
  }

  /// Get overdue requests (pending for more than specified days)
  Future<List<PrivacyRequest>> getOverdueRequests(int daysOverdue) async {
    final overdueDate = DateTime.now().subtract(Duration(days: daysOverdue));
    
    final query = await _firestore
        .collection(_collection)
        .where('status', isEqualTo: PrivacyRequestStatus.pending.value)
        .where('createdAt', isLessThan: overdueDate.toIso8601String())
        .orderBy('createdAt')
        .get();

    return query.docs
        .map((doc) => PrivacyRequest.fromJson(doc.data()))
        .toList();
  }

  /// Get requests processed by a specific admin
  Future<List<PrivacyRequest>> getRequestsByProcessor(String processedBy) async {
    final query = await _firestore
        .collection(_collection)
        .where('processedBy', isEqualTo: processedBy)
        .orderBy('processedAt', descending: true)
        .get();

    return query.docs
        .map((doc) => PrivacyRequest.fromJson(doc.data()))
        .toList();
  }

  /// Get privacy request statistics
  Future<Map<String, dynamic>> getRequestStatistics() async {
    final allRequests = await _firestore.collection(_collection).get();
    
    final stats = <String, dynamic>{
      'total': allRequests.docs.length,
      'pending': 0,
      'inProgress': 0,
      'completed': 0,
      'rejected': 0,
      'byType': <String, int>{},
      'averageProcessingTime': 0.0,
    };

    final List<int> processingTimes = [];
    
    for (final doc in allRequests.docs) {
      final request = PrivacyRequest.fromJson(doc.data());
      
      // Count by status
      switch (request.status) {
        case PrivacyRequestStatus.pending:
          stats['pending']++;
          break;
        case PrivacyRequestStatus.inProgress:
          stats['inProgress']++;
          break;
        case PrivacyRequestStatus.completed:
          stats['completed']++;
          break;
        case PrivacyRequestStatus.rejected:
          stats['rejected']++;
          break;
      }

      // Count by type
      final typeKey = request.requestType.value;
      stats['byType'][typeKey] = (stats['byType'][typeKey] ?? 0) + 1;

      // Calculate processing time for completed requests
      if (request.isCompleted && request.processedAt != null) {
        final processingTime = request.processedAt!.difference(request.createdAt).inHours;
        processingTimes.add(processingTime);
      }
    }

    // Calculate average processing time
    if (processingTimes.isNotEmpty) {
      stats['averageProcessingTime'] = 
          processingTimes.reduce((a, b) => a + b) / processingTimes.length;
    }

    return stats;
  }

  /// Search requests by member email or name (for admin use)
  Future<List<PrivacyRequest>> searchRequests(String searchTerm) async {
    // Note: This is a simplified search. In production, you might want to use
    // a more sophisticated search solution like Algolia or Elasticsearch
    final query = await _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .get();

    final requests = query.docs
        .map((doc) => PrivacyRequest.fromJson(doc.data()))
        .toList();

    // Filter by search term (this would be more efficient with proper search indexing)
    return requests.where((request) {
      return request.memberId.toLowerCase().contains(searchTerm.toLowerCase()) ||
             (request.description?.toLowerCase().contains(searchTerm.toLowerCase()) ?? false) ||
             (request.reason?.toLowerCase().contains(searchTerm.toLowerCase()) ?? false);
    }).toList();
  }
}