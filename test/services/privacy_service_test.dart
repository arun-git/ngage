import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/services/privacy_service.dart';
import '../../lib/services/consent_service.dart';
import '../../lib/repositories/privacy_request_repository.dart';
import '../../lib/models/privacy_request.dart';
import '../../lib/models/consent.dart';
import '../../lib/models/enums.dart';

import 'privacy_service_test.mocks.dart';

@GenerateMocks([PrivacyRequestRepository, ConsentService])
void main() {
  group('PrivacyService', () {
    late PrivacyService privacyService;
    late MockPrivacyRequestRepository mockRepository;
    late MockConsentService mockConsentService;

    setUp(() {
      mockRepository = MockPrivacyRequestRepository();
      mockConsentService = MockConsentService();
      privacyService = PrivacyService(
        requestRepository: mockRepository,
        consentService: mockConsentService,
      );
    });

    group('Privacy Request Submission', () {
      test('should submit data export request successfully', () async {
        // Arrange
        final request = PrivacyRequest(
          id: 'req_1',
          memberId: 'member_1',
          requestType: PrivacyRequestType.dataExport,
          status: PrivacyRequestStatus.pending,
          description: 'Request for personal data export',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockRepository.getMemberRequests('member_1'))
            .thenAnswer((_) async => []);
        when(mockRepository.create(any))
            .thenAnswer((_) async => request);

        // Act
        final result = await privacyService.requestDataExport(
          memberId: 'member_1',
          reason: 'Need my data',
        );

        // Assert
        expect(result.requestType, equals(PrivacyRequestType.dataExport));
        expect(result.memberId, equals('member_1'));
        expect(result.status, equals(PrivacyRequestStatus.pending));
        verify(mockRepository.create(any)).called(1);
      });

      test('should submit data deletion request successfully', () async {
        // Arrange
        final request = PrivacyRequest(
          id: 'req_1',
          memberId: 'member_1',
          requestType: PrivacyRequestType.dataDeletion,
          status: PrivacyRequestStatus.pending,
          description: 'Request for personal data deletion',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockRepository.getMemberRequests('member_1'))
            .thenAnswer((_) async => []);
        when(mockRepository.create(any))
            .thenAnswer((_) async => request);

        // Act
        final result = await privacyService.requestDataDeletion(
          memberId: 'member_1',
          reason: 'Delete my account',
          deleteAccount: true,
        );

        // Assert
        expect(result.requestType, equals(PrivacyRequestType.dataDeletion));
        expect(result.memberId, equals('member_1'));
        verify(mockRepository.create(any)).called(1);
      });

      test('should prevent duplicate pending requests', () async {
        // Arrange
        final existingRequest = PrivacyRequest(
          id: 'req_1',
          memberId: 'member_1',
          requestType: PrivacyRequestType.dataExport,
          status: PrivacyRequestStatus.pending,
          description: 'Existing request',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockRepository.getMemberRequests('member_1'))
            .thenAnswer((_) async => [existingRequest]);

        // Act & Assert
        expect(
          () => privacyService.requestDataExport(memberId: 'member_1'),
          throwsException,
        );
      });

      test('should submit data correction request with corrections', () async {
        // Arrange
        final corrections = {
          'firstName': 'John',
          'lastName': 'Doe',
          'email': 'john.doe@example.com',
        };

        final request = PrivacyRequest(
          id: 'req_1',
          memberId: 'member_1',
          requestType: PrivacyRequestType.dataCorrection,
          status: PrivacyRequestStatus.pending,
          description: 'Request for personal data correction',
          requestData: {'corrections': corrections},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockRepository.getMemberRequests('member_1'))
            .thenAnswer((_) async => []);
        when(mockRepository.create(any))
            .thenAnswer((_) async => request);

        // Act
        final result = await privacyService.requestDataCorrection(
          memberId: 'member_1',
          corrections: corrections,
          reason: 'Update my information',
        );

        // Assert
        expect(result.requestType, equals(PrivacyRequestType.dataCorrection));
        expect(result.requestData?['corrections'], equals(corrections));
        verify(mockRepository.create(any)).called(1);
      });
    });

    group('Privacy Request Processing', () {
      test('should process data export request successfully', () async {
        // Arrange
        final request = PrivacyRequest(
          id: 'req_1',
          memberId: 'member_1',
          requestType: PrivacyRequestType.dataExport,
          status: PrivacyRequestStatus.pending,
          description: 'Request for personal data export',
          requestData: {'dataCategories': ['all']},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final inProgressRequest = request.markInProgress('admin_1');
        final completedRequest = inProgressRequest.markCompleted('export_data');

        when(mockRepository.getById('req_1'))
            .thenAnswer((_) async => request);
        when(mockRepository.markInProgress('req_1', 'admin_1'))
            .thenAnswer((_) async => inProgressRequest);
        when(mockRepository.markCompleted('req_1', any))
            .thenAnswer((_) async => completedRequest);
        when(mockConsentService.exportMemberConsentData('member_1'))
            .thenAnswer((_) async => {'consents': []});

        // Act
        final result = await privacyService.processRequest(
          requestId: 'req_1',
          processedBy: 'admin_1',
        );

        // Assert
        expect(result.status, equals(PrivacyRequestStatus.completed));
        verify(mockRepository.markInProgress('req_1', 'admin_1')).called(1);
        verify(mockRepository.markCompleted('req_1', any)).called(1);
        verify(mockConsentService.exportMemberConsentData('member_1')).called(1);
      });

      test('should process data deletion request successfully', () async {
        // Arrange
        final request = PrivacyRequest(
          id: 'req_1',
          memberId: 'member_1',
          requestType: PrivacyRequestType.dataDeletion,
          status: PrivacyRequestStatus.pending,
          description: 'Request for personal data deletion',
          requestData: {'dataCategories': ['all'], 'deleteAccount': true},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final inProgressRequest = request.markInProgress('admin_1');
        final completedRequest = inProgressRequest.markCompleted('deletion_log');

        when(mockRepository.getById('req_1'))
            .thenAnswer((_) async => request);
        when(mockRepository.markInProgress('req_1', 'admin_1'))
            .thenAnswer((_) async => inProgressRequest);
        when(mockRepository.markCompleted('req_1', any))
            .thenAnswer((_) async => completedRequest);
        when(mockConsentService.deleteMemberConsents('member_1'))
            .thenAnswer((_) async {});

        // Act
        final result = await privacyService.processRequest(
          requestId: 'req_1',
          processedBy: 'admin_1',
        );

        // Assert
        expect(result.status, equals(PrivacyRequestStatus.completed));
        verify(mockConsentService.deleteMemberConsents('member_1')).called(1);
      });

      test('should reject privacy request with reason', () async {
        // Arrange
        final rejectedRequest = PrivacyRequest(
          id: 'req_1',
          memberId: 'member_1',
          requestType: PrivacyRequestType.dataExport,
          status: PrivacyRequestStatus.rejected,
          description: 'Request for personal data export',
          rejectionReason: 'Invalid request',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockRepository.markRejected('req_1', 'Invalid request'))
            .thenAnswer((_) async => rejectedRequest);

        // Act
        final result = await privacyService.rejectRequest(
          requestId: 'req_1',
          rejectionReason: 'Invalid request',
        );

        // Assert
        expect(result.status, equals(PrivacyRequestStatus.rejected));
        expect(result.rejectionReason, equals('Invalid request'));
        verify(mockRepository.markRejected('req_1', 'Invalid request')).called(1);
      });

      test('should throw exception when processing non-pending request', () async {
        // Arrange
        final completedRequest = PrivacyRequest(
          id: 'req_1',
          memberId: 'member_1',
          requestType: PrivacyRequestType.dataExport,
          status: PrivacyRequestStatus.completed,
          description: 'Request for personal data export',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockRepository.getById('req_1'))
            .thenAnswer((_) async => completedRequest);

        // Act & Assert
        expect(
          () => privacyService.processRequest(
            requestId: 'req_1',
            processedBy: 'admin_1',
          ),
          throwsException,
        );
      });
    });

    group('Privacy Request Queries', () {
      test('should get member privacy requests', () async {
        // Arrange
        final requests = [
          PrivacyRequest(
            id: 'req_1',
            memberId: 'member_1',
            requestType: PrivacyRequestType.dataExport,
            status: PrivacyRequestStatus.pending,
            description: 'Export request',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          PrivacyRequest(
            id: 'req_2',
            memberId: 'member_1',
            requestType: PrivacyRequestType.dataDeletion,
            status: PrivacyRequestStatus.completed,
            description: 'Deletion request',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockRepository.getMemberRequests('member_1'))
            .thenAnswer((_) async => requests);

        // Act
        final result = await privacyService.getMemberRequests('member_1');

        // Assert
        expect(result, hasLength(2));
        expect(result.every((r) => r.memberId == 'member_1'), isTrue);
        verify(mockRepository.getMemberRequests('member_1')).called(1);
      });

      test('should get pending privacy requests', () async {
        // Arrange
        final pendingRequests = [
          PrivacyRequest(
            id: 'req_1',
            memberId: 'member_1',
            requestType: PrivacyRequestType.dataExport,
            status: PrivacyRequestStatus.pending,
            description: 'Export request',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockRepository.getPendingRequests())
            .thenAnswer((_) async => pendingRequests);

        // Act
        final result = await privacyService.getPendingRequests();

        // Assert
        expect(result, hasLength(1));
        expect(result.first.status, equals(PrivacyRequestStatus.pending));
        verify(mockRepository.getPendingRequests()).called(1);
      });

      test('should get overdue requests', () async {
        // Arrange
        final overdueRequests = [
          PrivacyRequest(
            id: 'req_1',
            memberId: 'member_1',
            requestType: PrivacyRequestType.dataExport,
            status: PrivacyRequestStatus.pending,
            description: 'Old export request',
            createdAt: DateTime.now().subtract(const Duration(days: 35)),
            updatedAt: DateTime.now().subtract(const Duration(days: 35)),
          ),
        ];

        when(mockRepository.getOverdueRequests(30))
            .thenAnswer((_) async => overdueRequests);

        // Act
        final result = await privacyService.getOverdueRequests(30);

        // Assert
        expect(result, hasLength(1));
        expect(result.first.isPending, isTrue);
        verify(mockRepository.getOverdueRequests(30)).called(1);
      });
    });

    group('GDPR Compliance Validation', () {
      test('should validate GDPR compliance for member', () async {
        // Arrange
        final requests = [
          PrivacyRequest(
            id: 'req_1',
            memberId: 'member_1',
            requestType: PrivacyRequestType.dataExport,
            status: PrivacyRequestStatus.completed,
            description: 'Export request',
            createdAt: DateTime.now().subtract(const Duration(days: 10)),
            updatedAt: DateTime.now().subtract(const Duration(days: 10)),
          ),
        ];

        final consents = [
          Consent(
            id: 'consent_1',
            memberId: 'member_1',
            consentType: ConsentType.dataProcessing,
            granted: true,
            grantedAt: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockRepository.getMemberRequests('member_1'))
            .thenAnswer((_) async => requests);
        when(mockConsentService.getMemberConsents('member_1'))
            .thenAnswer((_) async => consents);

        // Act
        final result = await privacyService.validateGDPRCompliance('member_1');

        // Assert
        expect(result['memberId'], equals('member_1'));
        expect(result['privacyRequests']['total'], equals(1));
        expect(result['privacyRequests']['completed'], equals(1));
        expect(result['consents']['total'], equals(1));
        expect(result['consents']['valid'], equals(1));
        expect(result['complianceScore'], equals(100.0));
      });

      test('should calculate lower compliance score for overdue requests', () async {
        // Arrange
        final requests = [
          PrivacyRequest(
            id: 'req_1',
            memberId: 'member_1',
            requestType: PrivacyRequestType.dataExport,
            status: PrivacyRequestStatus.pending,
            description: 'Overdue export request',
            createdAt: DateTime.now().subtract(const Duration(days: 35)),
            updatedAt: DateTime.now().subtract(const Duration(days: 35)),
          ),
        ];

        final consents = <Consent>[];

        when(mockRepository.getMemberRequests('member_1'))
            .thenAnswer((_) async => requests);
        when(mockConsentService.getMemberConsents('member_1'))
            .thenAnswer((_) async => consents);

        // Act
        final result = await privacyService.validateGDPRCompliance('member_1');

        // Assert
        expect(result['complianceScore'], equals(80.0)); // 100 - 20 for overdue request
        expect(result['privacyRequests']['overdue'], equals(1));
      });
    });

    group('Error Handling', () {
      test('should throw exception when request not found for processing', () async {
        // Arrange
        when(mockRepository.getById('nonexistent'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => privacyService.processRequest(
            requestId: 'nonexistent',
            processedBy: 'admin_1',
          ),
          throwsException,
        );
      });
    });
  });
}