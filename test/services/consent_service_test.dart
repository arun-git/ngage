import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:ngage/services/consent_service.dart';
import 'package:ngage/repositories/consent_repository.dart';
import 'package:ngage/models/consent.dart';
import 'package:ngage/models/enums.dart';

import 'consent_service_test.mocks.dart';

@GenerateMocks([ConsentRepository])
void main() {
  group('ConsentService', () {
    late ConsentService consentService;
    late MockConsentRepository mockRepository;

    setUp(() {
      mockRepository = MockConsentRepository();
      consentService = ConsentService(consentRepository: mockRepository);
    });

    group('Consent Granting', () {
      test('should grant consent successfully', () async {
        // Arrange
        final consent = Consent(
          id: 'consent_1',
          memberId: 'member_1',
          consentType: ConsentType.mediaUsage,
          granted: true,
          purpose: 'Media usage for events',
          grantedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockRepository.getMemberConsentByType('member_1', ConsentType.mediaUsage))
            .thenAnswer((_) async => null);
        when(mockRepository.create(any))
            .thenAnswer((_) async => consent);

        // Act
        final result = await consentService.grantConsent(
          memberId: 'member_1',
          consentType: ConsentType.mediaUsage,
          purpose: 'Media usage for events',
        );

        // Assert
        expect(result.memberId, equals('member_1'));
        expect(result.consentType, equals(ConsentType.mediaUsage));
        expect(result.granted, isTrue);
        verify(mockRepository.create(any)).called(1);
      });

      test('should throw exception when valid consent already exists', () async {
        // Arrange
        final existingConsent = Consent(
          id: 'consent_1',
          memberId: 'member_1',
          consentType: ConsentType.mediaUsage,
          granted: true,
          purpose: 'Existing consent',
          grantedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockRepository.getMemberConsentByType('member_1', ConsentType.mediaUsage))
            .thenAnswer((_) async => existingConsent);

        // Act & Assert
        expect(
          () => consentService.grantConsent(
            memberId: 'member_1',
            consentType: ConsentType.mediaUsage,
            purpose: 'New consent',
          ),
          throwsException,
        );
      });

      test('should grant media usage consent with specific terms', () async {
        // Arrange
        final consent = Consent(
          id: 'consent_1',
          memberId: 'member_1',
          consentType: ConsentType.mediaUsage,
          granted: true,
          purpose: 'Event photography',
          metadata: {
            'allowCommercialUse': false,
            'allowModification': true,
            'allowRedistribution': false,
          },
          grantedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockRepository.getMemberConsentByType('member_1', ConsentType.mediaUsage))
            .thenAnswer((_) async => null);
        when(mockRepository.create(any))
            .thenAnswer((_) async => consent);

        // Act
        final result = await consentService.grantMediaUsageConsent(
          memberId: 'member_1',
          purpose: 'Event photography',
          allowCommercialUse: false,
          allowModification: true,
          allowRedistribution: false,
        );

        // Assert
        expect(result.consentType, equals(ConsentType.mediaUsage));
        expect(result.metadata?['allowCommercialUse'], isFalse);
        expect(result.metadata?['allowModification'], isTrue);
        expect(result.metadata?['allowRedistribution'], isFalse);
        verify(mockRepository.create(any)).called(1);
      });

      test('should grant data processing consent with categories', () async {
        // Arrange
        final consent = Consent(
          id: 'consent_1',
          memberId: 'member_1',
          consentType: ConsentType.dataProcessing,
          granted: true,
          purpose: 'Platform functionality',
          metadata: {
            'dataCategories': ['profile', 'submissions'],
            'processingActivities': ['storage', 'analysis'],
          },
          grantedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockRepository.getMemberConsentByType('member_1', ConsentType.dataProcessing))
            .thenAnswer((_) async => null);
        when(mockRepository.create(any))
            .thenAnswer((_) async => consent);

        // Act
        final result = await consentService.grantDataProcessingConsent(
          memberId: 'member_1',
          purpose: 'Platform functionality',
          dataCategories: ['profile', 'submissions'],
          processingActivities: ['storage', 'analysis'],
        );

        // Assert
        expect(result.consentType, equals(ConsentType.dataProcessing));
        expect(result.metadata?['dataCategories'], contains('profile'));
        expect(result.metadata?['processingActivities'], contains('storage'));
        verify(mockRepository.create(any)).called(1);
      });
    });

    group('Consent Revocation', () {
      test('should revoke consent successfully', () async {
        // Arrange
        final revokedConsents = [
          Consent(
            id: 'consent_1',
            memberId: 'member_1',
            consentType: ConsentType.mediaUsage,
            granted: false,
            purpose: 'Media usage',
            grantedAt: DateTime.now().subtract(const Duration(days: 1)),
            revokedAt: DateTime.now(),
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockRepository.revokeMemberConsentsByType('member_1', ConsentType.mediaUsage))
            .thenAnswer((_) async => revokedConsents);

        // Act
        final result = await consentService.revokeConsent('member_1', ConsentType.mediaUsage);

        // Assert
        expect(result, hasLength(1));
        expect(result.first.granted, isFalse);
        expect(result.first.revokedAt, isNotNull);
        verify(mockRepository.revokeMemberConsentsByType('member_1', ConsentType.mediaUsage)).called(1);
      });
    });

    group('Consent Queries', () {
      test('should get member consents', () async {
        // Arrange
        final consents = [
          Consent(
            id: 'consent_1',
            memberId: 'member_1',
            consentType: ConsentType.mediaUsage,
            granted: true,
            purpose: 'Media usage',
            grantedAt: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Consent(
            id: 'consent_2',
            memberId: 'member_1',
            consentType: ConsentType.dataProcessing,
            granted: true,
            purpose: 'Data processing',
            grantedAt: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockRepository.getMemberConsents('member_1'))
            .thenAnswer((_) async => consents);

        // Act
        final result = await consentService.getMemberConsents('member_1');

        // Assert
        expect(result, hasLength(2));
        expect(result.every((c) => c.memberId == 'member_1'), isTrue);
        verify(mockRepository.getMemberConsents('member_1')).called(1);
      });

      test('should get valid consents only', () async {
        // Arrange
        final validConsents = [
          Consent(
            id: 'consent_1',
            memberId: 'member_1',
            consentType: ConsentType.mediaUsage,
            granted: true,
            purpose: 'Media usage',
            grantedAt: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockRepository.getMemberValidConsents('member_1'))
            .thenAnswer((_) async => validConsents);

        // Act
        final result = await consentService.getMemberValidConsents('member_1');

        // Assert
        expect(result, hasLength(1));
        expect(result.first.isValid, isTrue);
        verify(mockRepository.getMemberValidConsents('member_1')).called(1);
      });

      test('should check if member has valid consent', () async {
        // Arrange
        when(mockRepository.hasValidConsent('member_1', ConsentType.mediaUsage))
            .thenAnswer((_) async => true);

        // Act
        final result = await consentService.hasValidConsent('member_1', ConsentType.mediaUsage);

        // Assert
        expect(result, isTrue);
        verify(mockRepository.hasValidConsent('member_1', ConsentType.mediaUsage)).called(1);
      });

      test('should get member consent status summary', () async {
        // Arrange
        final validConsents = [
          Consent(
            id: 'consent_1',
            memberId: 'member_1',
            consentType: ConsentType.mediaUsage,
            granted: true,
            purpose: 'Media usage',
            grantedAt: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockRepository.getMemberValidConsents('member_1'))
            .thenAnswer((_) async => validConsents);

        // Act
        final result = await consentService.getMemberConsentStatus('member_1');

        // Assert
        expect(result[ConsentType.mediaUsage], isTrue);
        expect(result[ConsentType.dataProcessing], isFalse);
        expect(result[ConsentType.marketing], isFalse);
        expect(result[ConsentType.analytics], isFalse);
        expect(result[ConsentType.thirdPartySharing], isFalse);
      });
    });

    group('Consent Validation', () {
      test('should validate consent for media upload action', () async {
        // Arrange
        when(mockRepository.hasValidConsent('member_1', ConsentType.mediaUsage))
            .thenAnswer((_) async => true);

        // Act
        final result = await consentService.validateConsentForAction(
          memberId: 'member_1',
          action: 'upload_media',
        );

        // Assert
        expect(result, isTrue);
        verify(mockRepository.hasValidConsent('member_1', ConsentType.mediaUsage)).called(1);
      });

      test('should validate consent for data processing action', () async {
        // Arrange
        when(mockRepository.hasValidConsent('member_1', ConsentType.dataProcessing))
            .thenAnswer((_) async => true);

        // Act
        final result = await consentService.validateConsentForAction(
          memberId: 'member_1',
          action: 'process_data',
        );

        // Assert
        expect(result, isTrue);
        verify(mockRepository.hasValidConsent('member_1', ConsentType.dataProcessing)).called(1);
      });

      test('should allow unknown actions by default', () async {
        // Act
        final result = await consentService.validateConsentForAction(
          memberId: 'member_1',
          action: 'unknown_action',
        );

        // Assert
        expect(result, isTrue);
        verifyNever(mockRepository.hasValidConsent(any, any));
      });
    });

    group('Consent Expiration', () {
      test('should get expiring consents', () async {
        // Arrange
        final expiringConsents = [
          Consent(
            id: 'consent_1',
            memberId: 'member_1',
            consentType: ConsentType.mediaUsage,
            granted: true,
            purpose: 'Media usage',
            grantedAt: DateTime.now().subtract(const Duration(days: 300)),
            expiresAt: DateTime.now().add(const Duration(days: 20)),
            createdAt: DateTime.now().subtract(const Duration(days: 300)),
            updatedAt: DateTime.now().subtract(const Duration(days: 300)),
          ),
        ];

        when(mockRepository.getExpiringConsents(30))
            .thenAnswer((_) async => expiringConsents);

        // Act
        final result = await consentService.getExpiringConsents(30);

        // Assert
        expect(result, hasLength(1));
        expect(result.first.expiresAt, isNotNull);
        verify(mockRepository.getExpiringConsents(30)).called(1);
      });
    });

    group('GDPR Compliance', () {
      test('should delete member consents for GDPR compliance', () async {
        // Arrange
        when(mockRepository.deleteMemberConsents('member_1'))
            .thenAnswer((_) async {});

        // Act
        await consentService.deleteMemberConsents('member_1');

        // Assert
        verify(mockRepository.deleteMemberConsents('member_1')).called(1);
      });

      test('should export member consent data', () async {
        // Arrange
        final consents = [
          Consent(
            id: 'consent_1',
            memberId: 'member_1',
            consentType: ConsentType.mediaUsage,
            granted: true,
            purpose: 'Media usage',
            grantedAt: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockRepository.getMemberConsents('member_1'))
            .thenAnswer((_) async => consents);

        // Act
        final result = await consentService.exportMemberConsentData('member_1');

        // Assert
        expect(result['memberId'], equals('member_1'));
        expect(result['consents'], hasLength(1));
        expect(result['summary']['totalConsents'], equals(1));
        expect(result['summary']['validConsents'], equals(1));
        verify(mockRepository.getMemberConsents('member_1')).called(1);
      });
    });

    group('Statistics', () {
      test('should get consent statistics', () async {
        // Arrange
        final stats = {
          'total': 100,
          'granted': 80,
          'revoked': 15,
          'expired': 5,
          'byType': {
            'media_usage': 30,
            'data_processing': 25,
            'marketing': 20,
            'analytics': 15,
            'third_party_sharing': 10,
          },
        };

        when(mockRepository.getConsentStatistics())
            .thenAnswer((_) async => stats);

        // Act
        final result = await consentService.getConsentStatistics();

        // Assert
        expect(result['total'], equals(100));
        expect(result['granted'], equals(80));
        expect(result['byType']['media_usage'], equals(30));
        verify(mockRepository.getConsentStatistics()).called(1);
      });
    });
  });
}