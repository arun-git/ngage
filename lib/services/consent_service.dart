import '../models/consent.dart';
import '../models/enums.dart';
import '../repositories/consent_repository.dart';

/// Service for managing user consent and media usage rights
class ConsentService {
  final ConsentRepository _consentRepository;

  ConsentService({ConsentRepository? consentRepository})
      : _consentRepository = consentRepository ?? ConsentRepository();

  /// Grant consent for a specific type
  Future<Consent> grantConsent({
    required String memberId,
    required ConsentType consentType,
    String? purpose,
    String? description,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) async {
    // Check if there's already a valid consent for this type
    final existingConsent = await _consentRepository.getMemberConsentByType(
      memberId, 
      consentType
    );

    if (existingConsent != null && existingConsent.isValid) {
      throw Exception('Valid consent already exists for ${consentType.value}');
    }

    final data = CreateConsentData(
      memberId: memberId,
      consentType: consentType,
      granted: true,
      purpose: purpose,
      description: description,
      expiresAt: expiresAt,
      metadata: metadata,
    );

    return await _consentRepository.create(data);
  }

  /// Revoke consent for a specific type
  Future<List<Consent>> revokeConsent(String memberId, ConsentType consentType) async {
    return await _consentRepository.revokeMemberConsentsByType(memberId, consentType);
  }

  /// Get all consents for a member
  Future<List<Consent>> getMemberConsents(String memberId) async {
    return await _consentRepository.getMemberConsents(memberId);
  }

  /// Get valid consents for a member
  Future<List<Consent>> getMemberValidConsents(String memberId) async {
    return await _consentRepository.getMemberValidConsents(memberId);
  }

  /// Check if member has valid consent for specific type
  Future<bool> hasValidConsent(String memberId, ConsentType consentType) async {
    return await _consentRepository.hasValidConsent(memberId, consentType);
  }

  /// Get consent status summary for a member
  Future<Map<ConsentType, bool>> getMemberConsentStatus(String memberId) async {
    final consents = await getMemberValidConsents(memberId);
    final statusMap = <ConsentType, bool>{};

    // Initialize all consent types as false
    for (final type in ConsentType.values) {
      statusMap[type] = false;
    }

    // Update with actual consent status
    for (final consent in consents) {
      statusMap[consent.consentType] = consent.isValid;
    }

    return statusMap;
  }

  /// Grant media usage consent with specific terms
  Future<Consent> grantMediaUsageConsent({
    required String memberId,
    required String purpose,
    DateTime? expiresAt,
    bool allowCommercialUse = false,
    bool allowModification = false,
    bool allowRedistribution = false,
  }) async {
    final metadata = {
      'allowCommercialUse': allowCommercialUse,
      'allowModification': allowModification,
      'allowRedistribution': allowRedistribution,
    };

    return await grantConsent(
      memberId: memberId,
      consentType: ConsentType.mediaUsage,
      purpose: purpose,
      description: 'Media usage consent with specific terms',
      expiresAt: expiresAt,
      metadata: metadata,
    );
  }

  /// Check if member has granted media usage consent
  Future<bool> hasMediaUsageConsent(String memberId) async {
    return await hasValidConsent(memberId, ConsentType.mediaUsage);
  }

  /// Get media usage consent details
  Future<Consent?> getMediaUsageConsent(String memberId) async {
    return await _consentRepository.getMemberConsentByType(
      memberId, 
      ConsentType.mediaUsage
    );
  }

  /// Grant data processing consent for GDPR compliance
  Future<Consent> grantDataProcessingConsent({
    required String memberId,
    required String purpose,
    DateTime? expiresAt,
    List<String>? dataCategories,
    List<String>? processingActivities,
  }) async {
    final metadata = {
      'dataCategories': dataCategories ?? [],
      'processingActivities': processingActivities ?? [],
    };

    return await grantConsent(
      memberId: memberId,
      consentType: ConsentType.dataProcessing,
      purpose: purpose,
      description: 'Data processing consent for GDPR compliance',
      expiresAt: expiresAt,
      metadata: metadata,
    );
  }

  /// Grant marketing consent
  Future<Consent> grantMarketingConsent({
    required String memberId,
    DateTime? expiresAt,
    List<String>? marketingChannels,
  }) async {
    final metadata = {
      'marketingChannels': marketingChannels ?? ['email'],
    };

    return await grantConsent(
      memberId: memberId,
      consentType: ConsentType.marketing,
      purpose: 'Marketing communications',
      description: 'Consent for marketing communications',
      expiresAt: expiresAt,
      metadata: metadata,
    );
  }

  /// Grant analytics consent
  Future<Consent> grantAnalyticsConsent({
    required String memberId,
    DateTime? expiresAt,
    List<String>? analyticsTools,
  }) async {
    final metadata = {
      'analyticsTools': analyticsTools ?? ['internal'],
    };

    return await grantConsent(
      memberId: memberId,
      consentType: ConsentType.analytics,
      purpose: 'Analytics and performance tracking',
      description: 'Consent for analytics data collection',
      expiresAt: expiresAt,
      metadata: metadata,
    );
  }

  /// Grant third-party sharing consent
  Future<Consent> grantThirdPartyConsent({
    required String memberId,
    required List<String> thirdParties,
    DateTime? expiresAt,
  }) async {
    final metadata = {
      'thirdParties': thirdParties,
    };

    return await grantConsent(
      memberId: memberId,
      consentType: ConsentType.thirdPartySharing,
      purpose: 'Third-party data sharing',
      description: 'Consent for sharing data with third parties',
      expiresAt: expiresAt,
      metadata: metadata,
    );
  }

  /// Get consents expiring soon
  Future<List<Consent>> getExpiringConsents(int daysFromNow) async {
    return await _consentRepository.getExpiringConsents(daysFromNow);
  }

  /// Send consent renewal reminders
  Future<void> sendConsentRenewalReminders() async {
    final expiringConsents = await getExpiringConsents(30); // 30 days notice
    
    // Group by member
    final consentsByMember = <String, List<Consent>>{};
    for (final consent in expiringConsents) {
      consentsByMember.putIfAbsent(consent.memberId, () => []).add(consent);
    }

    // Send reminders (this would integrate with notification service)
    for (final entry in consentsByMember.entries) {
      final memberId = entry.key;
      final consents = entry.value;
      
      // TODO: Integrate with notification service to send renewal reminders
      print('Sending consent renewal reminder to member $memberId for ${consents.length} consents');
    }
  }

  /// Get consent statistics for admin dashboard
  Future<Map<String, dynamic>> getConsentStatistics() async {
    return await _consentRepository.getConsentStatistics();
  }

  /// Validate consent requirements for an action
  Future<bool> validateConsentForAction({
    required String memberId,
    required String action,
    Map<String, dynamic>? context,
  }) async {
    switch (action) {
      case 'upload_media':
        return await hasValidConsent(memberId, ConsentType.mediaUsage);
      case 'process_data':
        return await hasValidConsent(memberId, ConsentType.dataProcessing);
      case 'send_marketing':
        return await hasValidConsent(memberId, ConsentType.marketing);
      case 'collect_analytics':
        return await hasValidConsent(memberId, ConsentType.analytics);
      case 'share_with_third_party':
        return await hasValidConsent(memberId, ConsentType.thirdPartySharing);
      default:
        return true; // Default to allowing action if no specific consent required
    }
  }

  /// Bulk consent operations for GDPR compliance
  Future<void> deleteMemberConsents(String memberId) async {
    await _consentRepository.deleteMemberConsents(memberId);
  }

  /// Export member consent data for GDPR compliance
  Future<Map<String, dynamic>> exportMemberConsentData(String memberId) async {
    final consents = await getMemberConsents(memberId);
    
    return {
      'memberId': memberId,
      'exportedAt': DateTime.now().toIso8601String(),
      'consents': consents.map((consent) => consent.toJson()).toList(),
      'summary': {
        'totalConsents': consents.length,
        'validConsents': consents.where((c) => c.isValid).length,
        'revokedConsents': consents.where((c) => c.revokedAt != null).length,
      },
    };
  }
}