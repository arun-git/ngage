import 'dart:convert';
import '../models/privacy_request.dart';
import '../models/enums.dart';
import '../repositories/privacy_request_repository.dart';
import '../services/consent_service.dart';

/// Service for handling GDPR compliance and privacy requests
class PrivacyService {
  final PrivacyRequestRepository _requestRepository;
  final ConsentService _consentService;

  PrivacyService({
    PrivacyRequestRepository? requestRepository,
    ConsentService? consentService,
  }) : _requestRepository = requestRepository ?? PrivacyRequestRepository(),
        _consentService = consentService ?? ConsentService();

  /// Submit a privacy request
  Future<PrivacyRequest> submitPrivacyRequest({
    required String memberId,
    required PrivacyRequestType requestType,
    String? description,
    String? reason,
    Map<String, dynamic>? requestData,
  }) async {
    // Check if there's already a pending request of the same type
    final memberRequests = await _requestRepository.getMemberRequests(memberId);
    final pendingRequest = memberRequests.where((request) => 
      request.requestType == requestType && 
      request.isPending
    ).firstOrNull;

    if (pendingRequest != null) {
      throw Exception('A pending ${requestType.value} request already exists');
    }

    final data = CreatePrivacyRequestData(
      memberId: memberId,
      requestType: requestType,
      description: description,
      reason: reason,
      requestData: requestData,
    );

    return await _requestRepository.create(data);
  }

  /// Submit data export request
  Future<PrivacyRequest> requestDataExport({
    required String memberId,
    String? reason,
    List<String>? dataCategories,
  }) async {
    return await submitPrivacyRequest(
      memberId: memberId,
      requestType: PrivacyRequestType.dataExport,
      description: 'Request for personal data export',
      reason: reason,
      requestData: {
        'dataCategories': dataCategories ?? ['all'],
        'format': 'json',
      },
    );
  }

  /// Submit data deletion request
  Future<PrivacyRequest> requestDataDeletion({
    required String memberId,
    String? reason,
    List<String>? dataCategories,
    bool deleteAccount = false,
  }) async {
    return await submitPrivacyRequest(
      memberId: memberId,
      requestType: PrivacyRequestType.dataDeletion,
      description: 'Request for personal data deletion',
      reason: reason,
      requestData: {
        'dataCategories': dataCategories ?? ['all'],
        'deleteAccount': deleteAccount,
      },
    );
  }

  /// Submit data correction request
  Future<PrivacyRequest> requestDataCorrection({
    required String memberId,
    required Map<String, dynamic> corrections,
    String? reason,
  }) async {
    return await submitPrivacyRequest(
      memberId: memberId,
      requestType: PrivacyRequestType.dataCorrection,
      description: 'Request for personal data correction',
      reason: reason,
      requestData: {
        'corrections': corrections,
      },
    );
  }

  /// Submit data portability request
  Future<PrivacyRequest> requestDataPortability({
    required String memberId,
    required String targetSystem,
    String? reason,
    List<String>? dataCategories,
  }) async {
    return await submitPrivacyRequest(
      memberId: memberId,
      requestType: PrivacyRequestType.dataPortability,
      description: 'Request for data portability',
      reason: reason,
      requestData: {
        'targetSystem': targetSystem,
        'dataCategories': dataCategories ?? ['all'],
        'format': 'json',
      },
    );
  }

  /// Submit processing restriction request
  Future<PrivacyRequest> requestProcessingRestriction({
    required String memberId,
    required List<String> processingActivities,
    String? reason,
  }) async {
    return await submitPrivacyRequest(
      memberId: memberId,
      requestType: PrivacyRequestType.processingRestriction,
      description: 'Request for processing restriction',
      reason: reason,
      requestData: {
        'processingActivities': processingActivities,
      },
    );
  }

  /// Get privacy requests for a member
  Future<List<PrivacyRequest>> getMemberRequests(String memberId) async {
    return await _requestRepository.getMemberRequests(memberId);
  }

  /// Get pending privacy requests (for admin)
  Future<List<PrivacyRequest>> getPendingRequests() async {
    return await _requestRepository.getPendingRequests();
  }

  /// Process a privacy request (admin function)
  Future<PrivacyRequest> processRequest({
    required String requestId,
    required String processedBy,
  }) async {
    final request = await _requestRepository.getById(requestId);
    if (request == null) {
      throw Exception('Privacy request not found: $requestId');
    }

    if (!request.isPending) {
      throw Exception('Request is not in pending status');
    }

    // Mark as in progress
    final inProgressRequest = await _requestRepository.markInProgress(requestId, processedBy);

    // Process based on request type
    String responseData;
    switch (request.requestType) {
      case PrivacyRequestType.dataExport:
        responseData = await _processDataExport(request);
        break;
      case PrivacyRequestType.dataDeletion:
        responseData = await _processDataDeletion(request);
        break;
      case PrivacyRequestType.dataCorrection:
        responseData = await _processDataCorrection(request);
        break;
      case PrivacyRequestType.dataPortability:
        responseData = await _processDataPortability(request);
        break;
      case PrivacyRequestType.processingRestriction:
        responseData = await _processProcessingRestriction(request);
        break;
    }

    // Mark as completed
    return await _requestRepository.markCompleted(requestId, responseData);
  }

  /// Reject a privacy request (admin function)
  Future<PrivacyRequest> rejectRequest({
    required String requestId,
    required String rejectionReason,
  }) async {
    return await _requestRepository.markRejected(requestId, rejectionReason);
  }

  /// Process data export request
  Future<String> _processDataExport(PrivacyRequest request) async {
    final memberId = request.memberId;
    final dataCategories = request.requestData?['dataCategories'] as List<String>? ?? ['all'];
    
    final exportData = <String, dynamic>{
      'memberId': memberId,
      'exportedAt': DateTime.now().toIso8601String(),
      'requestId': request.id,
      'dataCategories': dataCategories,
    };

    // Export consent data
    if (dataCategories.contains('all') || dataCategories.contains('consents')) {
      exportData['consents'] = await _consentService.exportMemberConsentData(memberId);
    }

    // TODO: Export other data categories (profile, submissions, etc.)
    // This would integrate with other services to collect all member data

    return jsonEncode(exportData);
  }

  /// Process data deletion request
  Future<String> _processDataDeletion(PrivacyRequest request) async {
    final memberId = request.memberId;
    final dataCategories = request.requestData?['dataCategories'] as List<String>? ?? ['all'];
    final deleteAccount = request.requestData?['deleteAccount'] as bool? ?? false;

    final deletionLog = <String, dynamic>{
      'memberId': memberId,
      'deletedAt': DateTime.now().toIso8601String(),
      'requestId': request.id,
      'dataCategories': dataCategories,
      'accountDeleted': deleteAccount,
      'deletedItems': <String, int>{},
    };

    // Delete consent data
    if (dataCategories.contains('all') || dataCategories.contains('consents')) {
      await _consentService.deleteMemberConsents(memberId);
      deletionLog['deletedItems']['consents'] = 1;
    }

    // TODO: Delete other data categories
    // This would integrate with other services to delete all member data

    return jsonEncode(deletionLog);
  }

  /// Process data correction request
  Future<String> _processDataCorrection(PrivacyRequest request) async {
    final corrections = request.requestData?['corrections'] as Map<String, dynamic>? ?? {};
    
    final correctionLog = <String, dynamic>{
      'memberId': request.memberId,
      'correctedAt': DateTime.now().toIso8601String(),
      'requestId': request.id,
      'corrections': corrections,
      'appliedCorrections': <String, dynamic>{},
    };

    // TODO: Apply corrections to member data
    // This would integrate with other services to update member data

    return jsonEncode(correctionLog);
  }

  /// Process data portability request
  Future<String> _processDataPortability(PrivacyRequest request) async {
    final targetSystem = request.requestData?['targetSystem'] as String? ?? 'unknown';
    final dataCategories = request.requestData?['dataCategories'] as List<String>? ?? ['all'];
    
    final portabilityData = <String, dynamic>{
      'memberId': request.memberId,
      'exportedAt': DateTime.now().toIso8601String(),
      'requestId': request.id,
      'targetSystem': targetSystem,
      'dataCategories': dataCategories,
      'format': 'json',
    };

    // Export data in portable format
    if (dataCategories.contains('all') || dataCategories.contains('consents')) {
      portabilityData['consents'] = await _consentService.exportMemberConsentData(request.memberId);
    }

    // TODO: Export other data in portable format

    return jsonEncode(portabilityData);
  }

  /// Process processing restriction request
  Future<String> _processProcessingRestriction(PrivacyRequest request) async {
    final processingActivities = request.requestData?['processingActivities'] as List<String>? ?? [];
    
    final restrictionLog = <String, dynamic>{
      'memberId': request.memberId,
      'restrictedAt': DateTime.now().toIso8601String(),
      'requestId': request.id,
      'processingActivities': processingActivities,
      'restrictedActivities': <String, bool>{},
    };

    // TODO: Implement processing restrictions
    // This would involve updating member settings to restrict certain processing activities

    return jsonEncode(restrictionLog);
  }

  /// Get overdue requests
  Future<List<PrivacyRequest>> getOverdueRequests(int daysOverdue) async {
    return await _requestRepository.getOverdueRequests(daysOverdue);
  }

  /// Get privacy request statistics
  Future<Map<String, dynamic>> getRequestStatistics() async {
    return await _requestRepository.getRequestStatistics();
  }

  /// Send overdue request notifications
  Future<void> sendOverdueRequestNotifications() async {
    final overdueRequests = await getOverdueRequests(30); // 30 days overdue
    
    // TODO: Integrate with notification service to send overdue notifications
    for (final request in overdueRequests) {
      print('Overdue privacy request: ${request.id} for member ${request.memberId}');
    }
  }

  /// Validate GDPR compliance for member
  Future<Map<String, dynamic>> validateGDPRCompliance(String memberId) async {
    final requests = await getMemberRequests(memberId);
    final consents = await _consentService.getMemberConsents(memberId);
    
    return {
      'memberId': memberId,
      'validatedAt': DateTime.now().toIso8601String(),
      'privacyRequests': {
        'total': requests.length,
        'pending': requests.where((r) => r.isPending).length,
        'completed': requests.where((r) => r.isCompleted).length,
        'overdue': requests.where((r) => 
          r.isPending && 
          DateTime.now().difference(r.createdAt).inDays > 30
        ).length,
      },
      'consents': {
        'total': consents.length,
        'valid': consents.where((c) => c.isValid).length,
        'expired': consents.where((c) => 
          c.expiresAt != null && 
          DateTime.now().isAfter(c.expiresAt!)
        ).length,
      },
      'complianceScore': _calculateComplianceScore(requests, consents),
    };
  }

  /// Calculate compliance score (0-100)
  double _calculateComplianceScore(List<PrivacyRequest> requests, List<Consent> consents) {
    double score = 100.0;
    
    // Deduct points for overdue requests
    final overdueRequests = requests.where((r) => 
      r.isPending && 
      DateTime.now().difference(r.createdAt).inDays > 30
    ).length;
    score -= (overdueRequests * 20); // -20 points per overdue request
    
    // Deduct points for expired consents that haven't been renewed
    final expiredConsents = consents.where((c) => 
      c.expiresAt != null && 
      DateTime.now().isAfter(c.expiresAt!)
    ).length;
    score -= (expiredConsents * 10); // -10 points per expired consent
    
    return score.clamp(0.0, 100.0);
  }
}