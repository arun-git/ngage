import 'package:flutter_test/flutter_test.dart';
import 'package:ngage/models/consent.dart';
import 'package:ngage/models/enums.dart';

void main() {
  group('Consent Model', () {
    test('should create consent with all fields', () {
      // Arrange
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 365));
      final revokedAt = now.add(const Duration(days: 30));
      
      // Act
      final consent = Consent(
        id: 'consent_1',
        memberId: 'member_1',
        consentType: ConsentType.mediaUsage,
        granted: true,
        purpose: 'Event photography',
        description: 'Consent for using photos in events',
        grantedAt: now,
        revokedAt: revokedAt,
        expiresAt: expiresAt,
        metadata: {'allowCommercialUse': false},
        createdAt: now,
        updatedAt: now,
      );

      // Assert
      expect(consent.id, equals('consent_1'));
      expect(consent.memberId, equals('member_1'));
      expect(consent.consentType, equals(ConsentType.mediaUsage));
      expect(consent.granted, isTrue);
      expect(consent.purpose, equals('Event photography'));
      expect(consent.description, equals('Consent for using photos in events'));
      expect(consent.grantedAt, equals(now));
      expect(consent.revokedAt, equals(revokedAt));
      expect(consent.expiresAt, equals(expiresAt));
      expect(consent.metadata?['allowCommercialUse'], isFalse);
      expect(consent.createdAt, equals(now));
      expect(consent.updatedAt, equals(now));
    });

    test('should create consent copy with updated fields', () {
      // Arrange
      final original = Consent(
        id: 'consent_1',
        memberId: 'member_1',
        consentType: ConsentType.mediaUsage,
        granted: true,
        purpose: 'Original purpose',
        grantedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final updated = original.copyWith(
        purpose: 'Updated purpose',
        granted: false,
        revokedAt: DateTime.now(),
      );

      // Assert
      expect(updated.id, equals(original.id));
      expect(updated.memberId, equals(original.memberId));
      expect(updated.consentType, equals(original.consentType));
      expect(updated.purpose, equals('Updated purpose'));
      expect(updated.granted, isFalse);
      expect(updated.revokedAt, isNotNull);
      expect(updated.grantedAt, equals(original.grantedAt));
      expect(updated.createdAt, equals(original.createdAt));
    });

    test('should validate active consent correctly', () {
      // Arrange
      final activeConsent = Consent(
        id: 'consent_1',
        memberId: 'member_1',
        consentType: ConsentType.mediaUsage,
        granted: true,
        grantedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert
      expect(activeConsent.isValid, isTrue);
    });

    test('should validate revoked consent correctly', () {
      // Arrange
      final revokedConsent = Consent(
        id: 'consent_1',
        memberId: 'member_1',
        consentType: ConsentType.mediaUsage,
        granted: false,
        grantedAt: DateTime.now().subtract(const Duration(days: 10)),
        revokedAt: DateTime.now().subtract(const Duration(days: 5)),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      );

      // Act & Assert
      expect(revokedConsent.isValid, isFalse);
    });

    test('should validate expired consent correctly', () {
      // Arrange
      final expiredConsent = Consent(
        id: 'consent_1',
        memberId: 'member_1',
        consentType: ConsentType.mediaUsage,
        granted: true,
        grantedAt: DateTime.now().subtract(const Duration(days: 40)),
        expiresAt: DateTime.now().subtract(const Duration(days: 10)),
        createdAt: DateTime.now().subtract(const Duration(days: 40)),
        updatedAt: DateTime.now().subtract(const Duration(days: 40)),
      );

      // Act & Assert
      expect(expiredConsent.isValid, isFalse);
    });

    test('should validate consent without expiration correctly', () {
      // Arrange
      final permanentConsent = Consent(
        id: 'consent_1',
        memberId: 'member_1',
        consentType: ConsentType.dataProcessing,
        granted: true,
        grantedAt: DateTime.now(),
        expiresAt: null, // No expiration
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert
      expect(permanentConsent.isValid, isTrue);
    });

    test('should revoke consent correctly', () {
      // Arrange
      final consent = Consent(
        id: 'consent_1',
        memberId: 'member_1',
        consentType: ConsentType.mediaUsage,
        granted: true,
        grantedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final revokedConsent = consent.revoke();

      // Assert
      expect(revokedConsent.granted, isFalse);
      expect(revokedConsent.revokedAt, isNotNull);
      expect(revokedConsent.updatedAt, isNotNull);
      expect(revokedConsent.isValid, isFalse);
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 365));
      final consent = Consent(
        id: 'consent_1',
        memberId: 'member_1',
        consentType: ConsentType.mediaUsage,
        granted: true,
        purpose: 'Event photography',
        description: 'Consent for using photos in events',
        grantedAt: now,
        expiresAt: expiresAt,
        metadata: {
          'allowCommercialUse': false,
          'allowModification': true,
        },
        createdAt: now,
        updatedAt: now,
      );

      // Act
      final json = consent.toJson();

      // Assert
      expect(json['id'], equals('consent_1'));
      expect(json['memberId'], equals('member_1'));
      expect(json['consentType'], equals('media_usage'));
      expect(json['granted'], isTrue);
      expect(json['purpose'], equals('Event photography'));
      expect(json['description'], equals('Consent for using photos in events'));
      expect(json['grantedAt'], equals(now.toIso8601String()));
      expect(json['revokedAt'], isNull);
      expect(json['expiresAt'], equals(expiresAt.toIso8601String()));
      expect(json['metadata']['allowCommercialUse'], isFalse);
      expect(json['metadata']['allowModification'], isTrue);
      expect(json['createdAt'], equals(now.toIso8601String()));
      expect(json['updatedAt'], equals(now.toIso8601String()));
    });

    test('should deserialize from JSON correctly', () {
      // Arrange
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 365));
      final revokedAt = now.add(const Duration(days: 30));
      final json = {
        'id': 'consent_1',
        'memberId': 'member_1',
        'consentType': 'media_usage',
        'granted': false,
        'purpose': 'Event photography',
        'description': 'Consent for using photos in events',
        'grantedAt': now.toIso8601String(),
        'revokedAt': revokedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'metadata': {
          'allowCommercialUse': false,
          'allowModification': true,
        },
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      // Act
      final consent = Consent.fromJson(json);

      // Assert
      expect(consent.id, equals('consent_1'));
      expect(consent.memberId, equals('member_1'));
      expect(consent.consentType, equals(ConsentType.mediaUsage));
      expect(consent.granted, isFalse);
      expect(consent.purpose, equals('Event photography'));
      expect(consent.description, equals('Consent for using photos in events'));
      expect(consent.grantedAt, equals(now));
      expect(consent.revokedAt, equals(revokedAt));
      expect(consent.expiresAt, equals(expiresAt));
      expect(consent.metadata?['allowCommercialUse'], isFalse);
      expect(consent.metadata?['allowModification'], isTrue);
      expect(consent.createdAt, equals(now));
      expect(consent.updatedAt, equals(now));
    });

    test('should handle null optional fields in JSON', () {
      // Arrange
      final json = {
        'id': 'consent_1',
        'memberId': 'member_1',
        'consentType': 'data_processing',
        'granted': true,
        'purpose': null,
        'description': null,
        'grantedAt': DateTime.now().toIso8601String(),
        'revokedAt': null,
        'expiresAt': null,
        'metadata': null,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Act
      final consent = Consent.fromJson(json);

      // Assert
      expect(consent.purpose, isNull);
      expect(consent.description, isNull);
      expect(consent.revokedAt, isNull);
      expect(consent.expiresAt, isNull);
      expect(consent.metadata, isNull);
    });

    test('should handle equality correctly', () {
      // Arrange
      final consent1 = Consent(
        id: 'consent_1',
        memberId: 'member_1',
        consentType: ConsentType.mediaUsage,
        granted: true,
        grantedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final consent2 = Consent(
        id: 'consent_1',
        memberId: 'different_member',
        consentType: ConsentType.dataProcessing,
        granted: false,
        grantedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final consent3 = Consent(
        id: 'consent_2',
        memberId: 'member_1',
        consentType: ConsentType.mediaUsage,
        granted: true,
        grantedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert
      expect(consent1, equals(consent2)); // Same ID
      expect(consent1, isNot(equals(consent3))); // Different ID
      expect(consent1.hashCode, equals(consent2.hashCode));
      expect(consent1.hashCode, isNot(equals(consent3.hashCode)));
    });

    test('should validate different consent types', () {
      // Arrange
      final consentTypes = [
        ConsentType.mediaUsage,
        ConsentType.dataProcessing,
        ConsentType.marketing,
        ConsentType.analytics,
        ConsentType.thirdPartySharing,
      ];

      // Act & Assert
      for (final type in consentTypes) {
        final consent = Consent(
          id: 'consent_${type.value}',
          memberId: 'member_1',
          consentType: type,
          granted: true,
          grantedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(consent.consentType, equals(type));
        expect(consent.isValid, isTrue);
      }
    });
  });

  group('CreateConsentData', () {
    test('should create data object with all fields', () {
      // Arrange
      final expiresAt = DateTime.now().add(const Duration(days: 365));
      
      // Act
      final data = CreateConsentData(
        memberId: 'member_1',
        consentType: ConsentType.mediaUsage,
        granted: true,
        purpose: 'Event photography',
        description: 'Consent for using photos',
        expiresAt: expiresAt,
        metadata: {'allowCommercialUse': false},
      );

      // Assert
      expect(data.memberId, equals('member_1'));
      expect(data.consentType, equals(ConsentType.mediaUsage));
      expect(data.granted, isTrue);
      expect(data.purpose, equals('Event photography'));
      expect(data.description, equals('Consent for using photos'));
      expect(data.expiresAt, equals(expiresAt));
      expect(data.metadata?['allowCommercialUse'], isFalse);
    });

    test('should create data object with minimal fields', () {
      // Act
      const data = CreateConsentData(
        memberId: 'member_1',
        consentType: ConsentType.dataProcessing,
        granted: true,
      );

      // Assert
      expect(data.memberId, equals('member_1'));
      expect(data.consentType, equals(ConsentType.dataProcessing));
      expect(data.granted, isTrue);
      expect(data.purpose, isNull);
      expect(data.description, isNull);
      expect(data.expiresAt, isNull);
      expect(data.metadata, isNull);
    });

    test('should create revocation data object', () {
      // Act
      const data = CreateConsentData(
        memberId: 'member_1',
        consentType: ConsentType.marketing,
        granted: false,
        purpose: 'Revoke marketing consent',
      );

      // Assert
      expect(data.memberId, equals('member_1'));
      expect(data.consentType, equals(ConsentType.marketing));
      expect(data.granted, isFalse);
      expect(data.purpose, equals('Revoke marketing consent'));
    });
  });
}