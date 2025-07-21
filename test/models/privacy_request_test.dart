import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/privacy_request.dart';
import '../../lib/models/enums.dart';

void main() {
  group('PrivacyRequest Model', () {
    test('should create privacy request with all fields', () {
      // Arrange
      final now = DateTime.now();
      final processedAt = now.add(const Duration(hours: 1));
      
      // Act
      final request = PrivacyRequest(
        id: 'req_1',
        memberId: 'member_1',
        requestType: PrivacyRequestType.dataExport,
        status: PrivacyRequestStatus.pending,
        description: 'Request for data export',
        reason: 'Need my data',
        requestData: {'format': 'json'},
        processedBy: 'admin_1',
        processedAt: processedAt,
        responseData: 'export_data',
        rejectionReason: null,
        createdAt: now,
        updatedAt: now,
      );

      // Assert
      expect(request.id, equals('req_1'));
      expect(request.memberId, equals('member_1'));
      expect(request.requestType, equals(PrivacyRequestType.dataExport));
      expect(request.status, equals(PrivacyRequestStatus.pending));
      expect(request.description, equals('Request for data export'));
      expect(request.reason, equals('Need my data'));
      expect(request.requestData?['format'], equals('json'));
      expect(request.processedBy, equals('admin_1'));
      expect(request.processedAt, equals(processedAt));
      expect(request.responseData, equals('export_data'));
      expect(request.rejectionReason, isNull);
      expect(request.createdAt, equals(now));
      expect(request.updatedAt, equals(now));
    });

    test('should create privacy request copy with updated fields', () {
      // Arrange
      final original = PrivacyRequest(
        id: 'req_1',
        memberId: 'member_1',
        requestType: PrivacyRequestType.dataExport,
        status: PrivacyRequestStatus.pending,
        description: 'Original description',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final updated = original.copyWith(
        status: PrivacyRequestStatus.inProgress,
        description: 'Updated description',
        processedBy: 'admin_1',
      );

      // Assert
      expect(updated.id, equals(original.id));
      expect(updated.memberId, equals(original.memberId));
      expect(updated.requestType, equals(original.requestType));
      expect(updated.status, equals(PrivacyRequestStatus.inProgress));
      expect(updated.description, equals('Updated description'));
      expect(updated.processedBy, equals('admin_1'));
      expect(updated.createdAt, equals(original.createdAt));
    });

    test('should check status correctly', () {
      // Arrange
      final pendingRequest = PrivacyRequest(
        id: 'req_1',
        memberId: 'member_1',
        requestType: PrivacyRequestType.dataExport,
        status: PrivacyRequestStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final inProgressRequest = pendingRequest.copyWith(
        status: PrivacyRequestStatus.inProgress,
      );

      final completedRequest = pendingRequest.copyWith(
        status: PrivacyRequestStatus.completed,
      );

      final rejectedRequest = pendingRequest.copyWith(
        status: PrivacyRequestStatus.rejected,
      );

      // Act & Assert
      expect(pendingRequest.isPending, isTrue);
      expect(pendingRequest.isInProgress, isFalse);
      expect(pendingRequest.isCompleted, isFalse);
      expect(pendingRequest.isRejected, isFalse);

      expect(inProgressRequest.isPending, isFalse);
      expect(inProgressRequest.isInProgress, isTrue);
      expect(inProgressRequest.isCompleted, isFalse);
      expect(inProgressRequest.isRejected, isFalse);

      expect(completedRequest.isPending, isFalse);
      expect(completedRequest.isInProgress, isFalse);
      expect(completedRequest.isCompleted, isTrue);
      expect(completedRequest.isRejected, isFalse);

      expect(rejectedRequest.isPending, isFalse);
      expect(rejectedRequest.isInProgress, isFalse);
      expect(rejectedRequest.isCompleted, isFalse);
      expect(rejectedRequest.isRejected, isTrue);
    });

    test('should mark request as in progress', () {
      // Arrange
      final request = PrivacyRequest(
        id: 'req_1',
        memberId: 'member_1',
        requestType: PrivacyRequestType.dataExport,
        status: PrivacyRequestStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final inProgressRequest = request.markInProgress('admin_1');

      // Assert
      expect(inProgressRequest.status, equals(PrivacyRequestStatus.inProgress));
      expect(inProgressRequest.processedBy, equals('admin_1'));
      expect(inProgressRequest.processedAt, isNotNull);
      expect(inProgressRequest.updatedAt, isNotNull);
    });

    test('should mark request as completed', () {
      // Arrange
      final request = PrivacyRequest(
        id: 'req_1',
        memberId: 'member_1',
        requestType: PrivacyRequestType.dataExport,
        status: PrivacyRequestStatus.inProgress,
        processedBy: 'admin_1',
        processedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final completedRequest = request.markCompleted('export_data_json');

      // Assert
      expect(completedRequest.status, equals(PrivacyRequestStatus.completed));
      expect(completedRequest.responseData, equals('export_data_json'));
      expect(completedRequest.updatedAt, isNotNull);
    });

    test('should mark request as rejected', () {
      // Arrange
      final request = PrivacyRequest(
        id: 'req_1',
        memberId: 'member_1',
        requestType: PrivacyRequestType.dataExport,
        status: PrivacyRequestStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final rejectedRequest = request.markRejected('Invalid request format');

      // Assert
      expect(rejectedRequest.status, equals(PrivacyRequestStatus.rejected));
      expect(rejectedRequest.rejectionReason, equals('Invalid request format'));
      expect(rejectedRequest.updatedAt, isNotNull);
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      final now = DateTime.now();
      final processedAt = now.add(const Duration(hours: 1));
      final request = PrivacyRequest(
        id: 'req_1',
        memberId: 'member_1',
        requestType: PrivacyRequestType.dataExport,
        status: PrivacyRequestStatus.completed,
        description: 'Data export request',
        reason: 'Need my data',
        requestData: {'format': 'json', 'categories': ['all']},
        processedBy: 'admin_1',
        processedAt: processedAt,
        responseData: 'export_data_json',
        createdAt: now,
        updatedAt: now,
      );

      // Act
      final json = request.toJson();

      // Assert
      expect(json['id'], equals('req_1'));
      expect(json['memberId'], equals('member_1'));
      expect(json['requestType'], equals('data_export'));
      expect(json['status'], equals('completed'));
      expect(json['description'], equals('Data export request'));
      expect(json['reason'], equals('Need my data'));
      expect(json['requestData']['format'], equals('json'));
      expect(json['requestData']['categories'], equals(['all']));
      expect(json['processedBy'], equals('admin_1'));
      expect(json['processedAt'], equals(processedAt.toIso8601String()));
      expect(json['responseData'], equals('export_data_json'));
      expect(json['rejectionReason'], isNull);
      expect(json['createdAt'], equals(now.toIso8601String()));
      expect(json['updatedAt'], equals(now.toIso8601String()));
    });

    test('should deserialize from JSON correctly', () {
      // Arrange
      final now = DateTime.now();
      final processedAt = now.add(const Duration(hours: 1));
      final json = {
        'id': 'req_1',
        'memberId': 'member_1',
        'requestType': 'data_export',
        'status': 'completed',
        'description': 'Data export request',
        'reason': 'Need my data',
        'requestData': {'format': 'json', 'categories': ['all']},
        'processedBy': 'admin_1',
        'processedAt': processedAt.toIso8601String(),
        'responseData': 'export_data_json',
        'rejectionReason': null,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      // Act
      final request = PrivacyRequest.fromJson(json);

      // Assert
      expect(request.id, equals('req_1'));
      expect(request.memberId, equals('member_1'));
      expect(request.requestType, equals(PrivacyRequestType.dataExport));
      expect(request.status, equals(PrivacyRequestStatus.completed));
      expect(request.description, equals('Data export request'));
      expect(request.reason, equals('Need my data'));
      expect(request.requestData?['format'], equals('json'));
      expect(request.requestData?['categories'], equals(['all']));
      expect(request.processedBy, equals('admin_1'));
      expect(request.processedAt, equals(processedAt));
      expect(request.responseData, equals('export_data_json'));
      expect(request.rejectionReason, isNull);
      expect(request.createdAt, equals(now));
      expect(request.updatedAt, equals(now));
    });

    test('should handle null optional fields in JSON', () {
      // Arrange
      final json = {
        'id': 'req_1',
        'memberId': 'member_1',
        'requestType': 'data_export',
        'status': 'pending',
        'description': null,
        'reason': null,
        'requestData': null,
        'processedBy': null,
        'processedAt': null,
        'responseData': null,
        'rejectionReason': null,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Act
      final request = PrivacyRequest.fromJson(json);

      // Assert
      expect(request.description, isNull);
      expect(request.reason, isNull);
      expect(request.requestData, isNull);
      expect(request.processedBy, isNull);
      expect(request.processedAt, isNull);
      expect(request.responseData, isNull);
      expect(request.rejectionReason, isNull);
    });

    test('should handle equality correctly', () {
      // Arrange
      final request1 = PrivacyRequest(
        id: 'req_1',
        memberId: 'member_1',
        requestType: PrivacyRequestType.dataExport,
        status: PrivacyRequestStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final request2 = PrivacyRequest(
        id: 'req_1',
        memberId: 'different_member',
        requestType: PrivacyRequestType.dataDeletion,
        status: PrivacyRequestStatus.completed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final request3 = PrivacyRequest(
        id: 'req_2',
        memberId: 'member_1',
        requestType: PrivacyRequestType.dataExport,
        status: PrivacyRequestStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert
      expect(request1, equals(request2)); // Same ID
      expect(request1, isNot(equals(request3))); // Different ID
      expect(request1.hashCode, equals(request2.hashCode));
      expect(request1.hashCode, isNot(equals(request3.hashCode)));
    });
  });

  group('CreatePrivacyRequestData', () {
    test('should create data object with all fields', () {
      // Act
      final data = CreatePrivacyRequestData(
        memberId: 'member_1',
        requestType: PrivacyRequestType.dataExport,
        description: 'Export request',
        reason: 'Need my data',
        requestData: {'format': 'json'},
      );

      // Assert
      expect(data.memberId, equals('member_1'));
      expect(data.requestType, equals(PrivacyRequestType.dataExport));
      expect(data.description, equals('Export request'));
      expect(data.reason, equals('Need my data'));
      expect(data.requestData?['format'], equals('json'));
    });

    test('should create data object with minimal fields', () {
      // Act
      final data = CreatePrivacyRequestData(
        memberId: 'member_1',
        requestType: PrivacyRequestType.dataDeletion,
      );

      // Assert
      expect(data.memberId, equals('member_1'));
      expect(data.requestType, equals(PrivacyRequestType.dataDeletion));
      expect(data.description, isNull);
      expect(data.reason, isNull);
      expect(data.requestData, isNull);
    });
  });
}