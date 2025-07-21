import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/consent.dart';
import '../models/enums.dart';

/// Repository for managing consent data in Firestore
class ConsentRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'consents';

  ConsentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a new consent record
  Future<Consent> create(CreateConsentData data) async {
    final now = DateTime.now();
    final docRef = _firestore.collection(_collection).doc();
    
    final consent = Consent(
      id: docRef.id,
      memberId: data.memberId,
      consentType: data.consentType,
      granted: data.granted,
      purpose: data.purpose,
      description: data.description,
      grantedAt: now,
      expiresAt: data.expiresAt,
      metadata: data.metadata,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(consent.toJson());
    return consent;
  }

  /// Get consent by ID
  Future<Consent?> getById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return Consent.fromJson(doc.data()!);
  }

  /// Get all consents for a member
  Future<List<Consent>> getMemberConsents(String memberId) async {
    final query = await _firestore
        .collection(_collection)
        .where('memberId', isEqualTo: memberId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => Consent.fromJson(doc.data()))
        .toList();
  }

  /// Get specific consent type for a member
  Future<Consent?> getMemberConsentByType(String memberId, ConsentType consentType) async {
    final query = await _firestore
        .collection(_collection)
        .where('memberId', isEqualTo: memberId)
        .where('consentType', isEqualTo: consentType.value)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return Consent.fromJson(query.docs.first.data());
  }

  /// Get all valid consents for a member
  Future<List<Consent>> getMemberValidConsents(String memberId) async {
    final consents = await getMemberConsents(memberId);
    return consents.where((consent) => consent.isValid).toList();
  }

  /// Update consent
  Future<Consent> update(Consent consent) async {
    final updatedConsent = consent.copyWith(updatedAt: DateTime.now());
    await _firestore
        .collection(_collection)
        .doc(consent.id)
        .update(updatedConsent.toJson());
    return updatedConsent;
  }

  /// Revoke consent
  Future<Consent> revoke(String consentId) async {
    final consent = await getById(consentId);
    if (consent == null) {
      throw Exception('Consent not found: $consentId');
    }

    final revokedConsent = consent.revoke();
    return await update(revokedConsent);
  }

  /// Revoke all consents of a specific type for a member
  Future<List<Consent>> revokeMemberConsentsByType(
    String memberId, 
    ConsentType consentType
  ) async {
    final consents = await _firestore
        .collection(_collection)
        .where('memberId', isEqualTo: memberId)
        .where('consentType', isEqualTo: consentType.value)
        .where('granted', isEqualTo: true)
        .where('revokedAt', isNull: true)
        .get();

    final List<Consent> revokedConsents = [];
    final batch = _firestore.batch();

    for (final doc in consents.docs) {
      final consent = Consent.fromJson(doc.data());
      final revokedConsent = consent.revoke();
      batch.update(doc.reference, revokedConsent.toJson());
      revokedConsents.add(revokedConsent);
    }

    await batch.commit();
    return revokedConsents;
  }

  /// Delete consent (for GDPR compliance)
  Future<void> delete(String consentId) async {
    await _firestore.collection(_collection).doc(consentId).delete();
  }

  /// Delete all consents for a member (for GDPR compliance)
  Future<void> deleteMemberConsents(String memberId) async {
    final query = await _firestore
        .collection(_collection)
        .where('memberId', isEqualTo: memberId)
        .get();

    final batch = _firestore.batch();
    for (final doc in query.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Check if member has valid consent for specific type
  Future<bool> hasValidConsent(String memberId, ConsentType consentType) async {
    final consent = await getMemberConsentByType(memberId, consentType);
    return consent?.isValid ?? false;
  }

  /// Get consents expiring soon (within specified days)
  Future<List<Consent>> getExpiringConsents(int daysFromNow) async {
    final expiryDate = DateTime.now().add(Duration(days: daysFromNow));
    
    final query = await _firestore
        .collection(_collection)
        .where('granted', isEqualTo: true)
        .where('revokedAt', isNull: true)
        .where('expiresAt', isLessThanOrEqualTo: expiryDate.toIso8601String())
        .where('expiresAt', isGreaterThan: DateTime.now().toIso8601String())
        .get();

    return query.docs
        .map((doc) => Consent.fromJson(doc.data()))
        .toList();
  }

  /// Get consent statistics for analytics
  Future<Map<String, dynamic>> getConsentStatistics() async {
    final allConsents = await _firestore.collection(_collection).get();
    
    final stats = <String, dynamic>{
      'total': allConsents.docs.length,
      'granted': 0,
      'revoked': 0,
      'expired': 0,
      'byType': <String, int>{},
    };

    final now = DateTime.now();
    
    for (final doc in allConsents.docs) {
      final consent = Consent.fromJson(doc.data());
      
      if (consent.granted && consent.revokedAt == null) {
        if (consent.expiresAt != null && now.isAfter(consent.expiresAt!)) {
          stats['expired']++;
        } else {
          stats['granted']++;
        }
      } else {
        stats['revoked']++;
      }

      final typeKey = consent.consentType.value;
      stats['byType'][typeKey] = (stats['byType'][typeKey] ?? 0) + 1;
    }

    return stats;
  }
}