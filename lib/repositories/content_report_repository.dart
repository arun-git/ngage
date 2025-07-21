import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/content_report.dart';

class ContentReportRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'content_reports';

  ContentReportRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _reportsRef => _firestore.collection(_collection);

  /// Create a new content report
  Future<String> createReport(ContentReport report) async {
    try {
      final docRef = await _reportsRef.add(report.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create content report: $e');
    }
  }

  /// Get a content report by ID
  Future<ContentReport?> getReport(String reportId) async {
    try {
      final doc = await _reportsRef.doc(reportId).get();
      if (!doc.exists) return null;
      return ContentReport.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get content report: $e');
    }
  }

  /// Get all reports for a specific content item
  Future<List<ContentReport>> getReportsForContent(
    String contentId,
    ContentType contentType,
  ) async {
    try {
      final query = await _reportsRef
          .where('contentId', isEqualTo: contentId)
          .where('contentType', isEqualTo: contentType.name)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => ContentReport.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reports for content: $e');
    }
  }

  /// Get reports by status
  Future<List<ContentReport>> getReportsByStatus(
    ReportStatus status, {
    int? limit,
  }) async {
    try {
      Query query = _reportsRef
          .where('status', isEqualTo: status.name)
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ContentReport.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reports by status: $e');
    }
  }

  /// Get all pending reports for moderation dashboard
  Future<List<ContentReport>> getPendingReports({int? limit}) async {
    return getReportsByStatus(ReportStatus.pending, limit: limit);
  }

  /// Get reports created by a specific user
  Future<List<ContentReport>> getReportsByReporter(
    String reporterId, {
    int? limit,
  }) async {
    try {
      Query query = _reportsRef
          .where('reporterId', isEqualTo: reporterId)
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ContentReport.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reports by reporter: $e');
    }
  }

  /// Update report status and review information
  Future<void> updateReportStatus(
    String reportId,
    ReportStatus status, {
    String? reviewedBy,
    String? reviewNotes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
        'updatedAt': Timestamp.now(),
      };

      if (reviewedBy != null) {
        updateData['reviewedBy'] = reviewedBy;
        updateData['reviewedAt'] = Timestamp.now();
      }

      if (reviewNotes != null) {
        updateData['reviewNotes'] = reviewNotes;
      }

      await _reportsRef.doc(reportId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update report status: $e');
    }
  }

  /// Delete a content report
  Future<void> deleteReport(String reportId) async {
    try {
      await _reportsRef.doc(reportId).delete();
    } catch (e) {
      throw Exception('Failed to delete content report: $e');
    }
  }

  /// Get reports statistics for dashboard
  Future<Map<String, int>> getReportsStatistics() async {
    try {
      final pendingQuery = await _reportsRef
          .where('status', isEqualTo: ReportStatus.pending.name)
          .get();
      
      final underReviewQuery = await _reportsRef
          .where('status', isEqualTo: ReportStatus.underReview.name)
          .get();
      
      final resolvedQuery = await _reportsRef
          .where('status', isEqualTo: ReportStatus.resolved.name)
          .get();
      
      final dismissedQuery = await _reportsRef
          .where('status', isEqualTo: ReportStatus.dismissed.name)
          .get();

      return {
        'pending': pendingQuery.docs.length,
        'underReview': underReviewQuery.docs.length,
        'resolved': resolvedQuery.docs.length,
        'dismissed': dismissedQuery.docs.length,
        'total': pendingQuery.docs.length + 
                underReviewQuery.docs.length + 
                resolvedQuery.docs.length + 
                dismissedQuery.docs.length,
      };
    } catch (e) {
      throw Exception('Failed to get reports statistics: $e');
    }
  }

  /// Stream of pending reports for real-time updates
  Stream<List<ContentReport>> streamPendingReports() {
    return _reportsRef
        .where('status', isEqualTo: ReportStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ContentReport.fromFirestore(doc))
            .toList());
  }

  /// Check if content has been reported by a specific user
  Future<bool> hasUserReportedContent(
    String reporterId,
    String contentId,
    ContentType contentType,
  ) async {
    try {
      final query = await _reportsRef
          .where('reporterId', isEqualTo: reporterId)
          .where('contentId', isEqualTo: contentId)
          .where('contentType', isEqualTo: contentType.name)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check if user reported content: $e');
    }
  }
}