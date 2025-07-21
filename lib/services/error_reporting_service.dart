import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/logger.dart';
import '../utils/error_types.dart';

/// User error report model
class ErrorReport {
  final String id;
  final String userId;
  final String? memberId;
  final String title;
  final String description;
  final ErrorReportType type;
  final ErrorReportPriority priority;
  final Map<String, dynamic>? technicalDetails;
  final List<String>? attachments;
  final ErrorReportStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? assignedTo;
  final String? resolution;

  ErrorReport({
    required this.id,
    required this.userId,
    this.memberId,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    this.technicalDetails,
    this.attachments,
    this.status = ErrorReportStatus.open,
    required this.createdAt,
    required this.updatedAt,
    this.assignedTo,
    this.resolution,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'memberId': memberId,
      'title': title,
      'description': description,
      'type': type.name,
      'priority': priority.name,
      'technicalDetails': technicalDetails,
      'attachments': attachments,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'assignedTo': assignedTo,
      'resolution': resolution,
    };
  }

  factory ErrorReport.fromJson(Map<String, dynamic> json) {
    return ErrorReport(
      id: json['id'],
      userId: json['userId'],
      memberId: json['memberId'],
      title: json['title'],
      description: json['description'],
      type: ErrorReportType.values.firstWhere((t) => t.name == json['type']),
      priority: ErrorReportPriority.values.firstWhere((p) => p.name == json['priority']),
      technicalDetails: json['technicalDetails']?.cast<String, dynamic>(),
      attachments: json['attachments']?.cast<String>(),
      status: ErrorReportStatus.values.firstWhere((s) => s.name == json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      assignedTo: json['assignedTo'],
      resolution: json['resolution'],
    );
  }

  ErrorReport copyWith({
    String? title,
    String? description,
    ErrorReportType? type,
    ErrorReportPriority? priority,
    Map<String, dynamic>? technicalDetails,
    List<String>? attachments,
    ErrorReportStatus? status,
    DateTime? updatedAt,
    String? assignedTo,
    String? resolution,
  }) {
    return ErrorReport(
      id: id,
      userId: userId,
      memberId: memberId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      technicalDetails: technicalDetails ?? this.technicalDetails,
      attachments: attachments ?? this.attachments,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      resolution: resolution ?? this.resolution,
    );
  }
}

/// Error report types
enum ErrorReportType {
  bug,
  crash,
  performance,
  ui,
  feature,
  other,
}

/// Error report priorities
enum ErrorReportPriority {
  low,
  medium,
  high,
  critical,
}

/// Error report status
enum ErrorReportStatus {
  open,
  inProgress,
  resolved,
  closed,
  duplicate,
}

/// Service for handling user error reports and feedback
class ErrorReportingService {
  final FirebaseFirestore _firestore;
  final Logger _logger;

  ErrorReportingService({
    FirebaseFirestore? firestore,
    Logger? logger,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _logger = logger ?? Logger();

  /// Submit a new error report
  Future<ErrorReport> submitErrorReport({
    required String userId,
    String? memberId,
    required String title,
    required String description,
    required ErrorReportType type,
    ErrorReportPriority priority = ErrorReportPriority.medium,
    Map<String, dynamic>? technicalDetails,
    List<String>? attachments,
  }) async {
    try {
      final now = DateTime.now();
      final reportId = _generateReportId();

      final report = ErrorReport(
        id: reportId,
        userId: userId,
        memberId: memberId,
        title: title,
        description: description,
        type: type,
        priority: priority,
        technicalDetails: technicalDetails,
        attachments: attachments,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('error_reports')
          .doc(reportId)
          .set(report.toJson());

      _logger.info(
        'Error report submitted',
        category: 'ErrorReporting',
        context: {
          'reportId': reportId,
          'userId': userId,
          'type': type.name,
          'priority': priority.name,
        },
      );

      return report;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to submit error report',
        category: 'ErrorReporting',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Submit automatic error report from exception
  Future<ErrorReport?> submitAutomaticErrorReport({
    required String userId,
    String? memberId,
    required Object error,
    required StackTrace stackTrace,
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final errorType = _categorizeErrorForReport(error);
      final priority = _determinePriority(error);
      
      final technicalDetails = {
        'error': error.toString(),
        'stackTrace': stackTrace.toString(),
        'context': context,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': defaultTargetPlatform.name,
        'additionalData': additionalData,
      };

      return await submitErrorReport(
        userId: userId,
        memberId: memberId,
        title: 'Automatic Error Report: ${error.runtimeType}',
        description: 'An error occurred automatically: ${error.toString()}',
        type: errorType,
        priority: priority,
        technicalDetails: technicalDetails,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to submit automatic error report',
        category: 'ErrorReporting',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Get error reports for a user
  Future<List<ErrorReport>> getUserErrorReports(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('error_reports')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ErrorReport.fromJson(doc.data()))
          .toList();
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to get user error reports',
        category: 'ErrorReporting',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Get error report by ID
  Future<ErrorReport?> getErrorReport(String reportId) async {
    try {
      final doc = await _firestore
          .collection('error_reports')
          .doc(reportId)
          .get();

      if (doc.exists) {
        return ErrorReport.fromJson(doc.data()!);
      }
      return null;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to get error report',
        category: 'ErrorReporting',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Update error report status
  Future<void> updateErrorReportStatus(
    String reportId,
    ErrorReportStatus status, {
    String? resolution,
    String? assignedTo,
  }) async {
    try {
      final updateData = {
        'status': status.name,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (resolution != null) {
        updateData['resolution'] = resolution;
      }

      if (assignedTo != null) {
        updateData['assignedTo'] = assignedTo;
      }

      await _firestore
          .collection('error_reports')
          .doc(reportId)
          .update(updateData);

      _logger.info(
        'Error report status updated',
        category: 'ErrorReporting',
        context: {
          'reportId': reportId,
          'status': status.name,
          'assignedTo': assignedTo,
        },
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to update error report status',
        category: 'ErrorReporting',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get error reports by status
  Stream<List<ErrorReport>> getErrorReportsByStatus(ErrorReportStatus status) {
    return _firestore
        .collection('error_reports')
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ErrorReport.fromJson(doc.data()))
            .toList());
  }

  /// Get error report statistics
  Future<Map<String, dynamic>> getErrorReportStatistics() async {
    try {
      final querySnapshot = await _firestore
          .collection('error_reports')
          .get();

      final reports = querySnapshot.docs
          .map((doc) => ErrorReport.fromJson(doc.data()))
          .toList();

      final stats = <String, dynamic>{
        'total': reports.length,
        'byStatus': <String, int>{},
        'byType': <String, int>{},
        'byPriority': <String, int>{},
      };

      for (final report in reports) {
        // Count by status
        final statusKey = report.status.name;
        stats['byStatus'][statusKey] = (stats['byStatus'][statusKey] ?? 0) + 1;

        // Count by type
        final typeKey = report.type.name;
        stats['byType'][typeKey] = (stats['byType'][typeKey] ?? 0) + 1;

        // Count by priority
        final priorityKey = report.priority.name;
        stats['byPriority'][priorityKey] = (stats['byPriority'][priorityKey] ?? 0) + 1;
      }

      return stats;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to get error report statistics',
        category: 'ErrorReporting',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  /// Categorize error for report type
  ErrorReportType _categorizeErrorForReport(Object error) {
    if (error is NgageException) {
      return ErrorReportType.bug;
    } else if (error.toString().toLowerCase().contains('crash')) {
      return ErrorReportType.crash;
    } else if (error.toString().toLowerCase().contains('performance')) {
      return ErrorReportType.performance;
    } else {
      return ErrorReportType.bug;
    }
  }

  /// Determine priority based on error
  ErrorReportPriority _determinePriority(Object error) {
    if (error is NgageException) {
      if (error is AuthenticationException || error is DatabaseException) {
        return ErrorReportPriority.high;
      } else if (error is NetworkException || error is StorageException) {
        return ErrorReportPriority.medium;
      }
    }
    
    return ErrorReportPriority.medium;
  }

  /// Generate unique report ID
  String _generateReportId() {
    return 'error_${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// Provider for error reporting service
final errorReportingServiceProvider = Provider<ErrorReportingService>((ref) {
  return ErrorReportingService();
});