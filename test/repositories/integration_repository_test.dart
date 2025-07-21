import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ngage/models/models.dart';
import 'package:ngage/repositories/integration_repository.dart';

void main() {
  group('IntegrationRepository', () {
    late IntegrationRepository repository;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = IntegrationRepository(firestore: fakeFirestore);
    });

    group('createIntegration', () {
      test('should create integration in Firestore', () async {
        // Arrange
        final integration = IntegrationConfig(
          id: 'integration123',
          groupId: 'group123',
          type: IntegrationType.slack,
          status: IntegrationStatus.pending,
          settings: {'botToken': 'token123', 'channelId': 'channel123'},
          channelMappings: {'event_reminder': 'general'},
          isActive: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        await repository.createIntegration(integration);

        // Assert
        final doc = await fakeFirestore
            .collection('integrations')
            .doc(integration.id)
            .get();
        
        expect(doc.exists, isTrue);
        expect(doc.data()!['groupId'], equals('group123'));
        expect(doc.data()!['type'], equals('slack'));
      });

      test('should throw exception when creation fails', () async {
        // Arrange
        final integration = IntegrationConfig(
          id: '', // Invalid ID to cause failure
          groupId: 'group123',
          type: IntegrationType.slack,
          status: IntegrationStatus.pending,
          settings: {},
          channelMappings: {},
          isActive: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act & Assert
        expect(
          () => repository.createIntegration(integration),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getIntegrationById', () {
      test('should return integration when it exists', () async {
        // Arrange
        final integration = IntegrationConfig(
          id: 'integration123',
          groupId: 'group123',
          type: IntegrationType.slack,
          status: IntegrationStatus.active,
          settings: {'botToken': 'token123', 'channelId': 'channel123'},
          channelMappings: {'event_reminder': 'general'},
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await fakeFirestore
            .collection('integrations')
            .doc(integration.id)
            .set(integration.toJson());

        // Act
        final result = await repository.getIntegrationById('integration123');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals('integration123'));
        expect(result.groupId, equals('group123'));
        expect(result.type, equals(IntegrationType.slack));
      });

      test('should return null when integration does not exist', () async {
        // Act
        final result = await repository.getIntegrationById('nonexistent');

        // Assert
        expect(result, isNull);
      });
    });

    group('getGroupIntegrations', () {
      test('should return all integrations for a group', () async {
        // Arrange
        final integration1 = IntegrationConfig(
          id: 'integration1',
          groupId: 'group123',
          type: IntegrationType.slack,
          status: IntegrationStatus.active,
          settings: {},
          channelMappings: {},
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          updatedAt: DateTime.now(),
        );

        final integration2 = IntegrationConfig(
          id: 'integration2',
          groupId: 'group123',
          type: IntegrationType.email,
          status: IntegrationStatus.inactive,
          settings: {},
          channelMappings: {},
          isActive: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          updatedAt: DateTime.now(),
        );

        final integration3 = IntegrationConfig(
          id: 'integration3',
          groupId: 'group456', // Different group
          type: IntegrationType.microsoftTeams,
          status: IntegrationStatus.active,
          settings: {},
          channelMappings: {},
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await fakeFirestore.collection('integrations').doc('integration1').set(integration1.toJson());
        await fakeFirestore.collection('integrations').doc('integration2').set(integration2.toJson());
        await fakeFirestore.collection('integrations').doc('integration3').set(integration3.toJson());

        // Act
        final result = await repository.getGroupIntegrations('group123');

        // Assert
        expect(result.length, equals(2));
        expect(result.map((i) => i.id), containsAll(['integration1', 'integration2']));
        expect(result.map((i) => i.id), isNot(contains('integration3')));
        
        // Should be ordered by createdAt descending (newest first)
        expect(result[0].id, equals('integration2'));
        expect(result[1].id, equals('integration1'));
      });

      test('should return empty list when no integrations exist for group', () async {
        // Act
        final result = await repository.getGroupIntegrations('nonexistent_group');

        // Assert
        expect(result, isEmpty);
      });
    });

    group('getGroupIntegrationsByType', () {
      test('should return integrations filtered by type', () async {
        // Arrange
        final slackIntegration = IntegrationConfig(
          id: 'slack1',
          groupId: 'group123',
          type: IntegrationType.slack,
          status: IntegrationStatus.active,
          settings: {},
          channelMappings: {},
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final emailIntegration = IntegrationConfig(
          id: 'email1',
          groupId: 'group123',
          type: IntegrationType.email,
          status: IntegrationStatus.active,
          settings: {},
          channelMappings: {},
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await fakeFirestore.collection('integrations').doc('slack1').set(slackIntegration.toJson());
        await fakeFirestore.collection('integrations').doc('email1').set(emailIntegration.toJson());

        // Act
        final result = await repository.getGroupIntegrationsByType('group123', IntegrationType.slack);

        // Assert
        expect(result.length, equals(1));
        expect(result[0].type, equals(IntegrationType.slack));
        expect(result[0].id, equals('slack1'));
      });
    });

    group('getActiveGroupIntegrations', () {
      test('should return only active integrations', () async {
        // Arrange
        final activeIntegration = IntegrationConfig(
          id: 'active1',
          groupId: 'group123',
          type: IntegrationType.slack,
          status: IntegrationStatus.active,
          settings: {},
          channelMappings: {},
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final inactiveIntegration = IntegrationConfig(
          id: 'inactive1',
          groupId: 'group123',
          type: IntegrationType.email,
          status: IntegrationStatus.inactive,
          settings: {},
          channelMappings: {},
          isActive: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final errorIntegration = IntegrationConfig(
          id: 'error1',
          groupId: 'group123',
          type: IntegrationType.microsoftTeams,
          status: IntegrationStatus.error,
          settings: {},
          channelMappings: {},
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await fakeFirestore.collection('integrations').doc('active1').set(activeIntegration.toJson());
        await fakeFirestore.collection('integrations').doc('inactive1').set(inactiveIntegration.toJson());
        await fakeFirestore.collection('integrations').doc('error1').set(errorIntegration.toJson());

        // Act
        final result = await repository.getActiveGroupIntegrations('group123');

        // Assert
        expect(result.length, equals(1));
        expect(result[0].id, equals('active1'));
        expect(result[0].isActive, isTrue);
        expect(result[0].status, equals(IntegrationStatus.active));
      });
    });

    group('updateIntegration', () {
      test('should update existing integration', () async {
        // Arrange
        final originalIntegration = IntegrationConfig(
          id: 'integration123',
          groupId: 'group123',
          type: IntegrationType.slack,
          status: IntegrationStatus.pending,
          settings: {'botToken': 'old_token'},
          channelMappings: {},
          isActive: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await fakeFirestore
            .collection('integrations')
            .doc(originalIntegration.id)
            .set(originalIntegration.toJson());

        final updatedIntegration = originalIntegration.copyWith(
          settings: {'botToken': 'new_token'},
          status: IntegrationStatus.active,
          isActive: true,
        );

        // Act
        await repository.updateIntegration(updatedIntegration);

        // Assert
        final doc = await fakeFirestore
            .collection('integrations')
            .doc('integration123')
            .get();
        
        final data = doc.data()!;
        expect(data['settings']['botToken'], equals('new_token'));
        expect(data['status'], equals('active'));
        expect(data['isActive'], isTrue);
      });
    });

    group('updateIntegrationStatus', () {
      test('should update integration status', () async {
        // Arrange
        final integration = IntegrationConfig(
          id: 'integration123',
          groupId: 'group123',
          type: IntegrationType.slack,
          status: IntegrationStatus.pending,
          settings: {},
          channelMappings: {},
          isActive: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await fakeFirestore
            .collection('integrations')
            .doc(integration.id)
            .set(integration.toJson());

        // Act
        await repository.updateIntegrationStatus('integration123', IntegrationStatus.active);

        // Assert
        final doc = await fakeFirestore
            .collection('integrations')
            .doc('integration123')
            .get();
        
        expect(doc.data()!['status'], equals('active'));
      });
    });

    group('toggleIntegrationActive', () {
      test('should toggle integration active status', () async {
        // Arrange
        final integration = IntegrationConfig(
          id: 'integration123',
          groupId: 'group123',
          type: IntegrationType.slack,
          status: IntegrationStatus.active,
          settings: {},
          channelMappings: {},
          isActive: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await fakeFirestore
            .collection('integrations')
            .doc(integration.id)
            .set(integration.toJson());

        // Act
        await repository.toggleIntegrationActive('integration123', true);

        // Assert
        final doc = await fakeFirestore
            .collection('integrations')
            .doc('integration123')
            .get();
        
        expect(doc.data()!['isActive'], isTrue);
      });
    });

    group('deleteIntegration', () {
      test('should delete integration from Firestore', () async {
        // Arrange
        final integration = IntegrationConfig(
          id: 'integration123',
          groupId: 'group123',
          type: IntegrationType.slack,
          status: IntegrationStatus.active,
          settings: {},
          channelMappings: {},
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await fakeFirestore
            .collection('integrations')
            .doc(integration.id)
            .set(integration.toJson());

        // Verify it exists
        var doc = await fakeFirestore
            .collection('integrations')
            .doc('integration123')
            .get();
        expect(doc.exists, isTrue);

        // Act
        await repository.deleteIntegration('integration123');

        // Assert
        doc = await fakeFirestore
            .collection('integrations')
            .doc('integration123')
            .get();
        expect(doc.exists, isFalse);
      });
    });

    group('getIntegrationStats', () {
      test('should return correct integration statistics', () async {
        // Arrange
        final integrations = [
          IntegrationConfig(
            id: 'active1',
            groupId: 'group123',
            type: IntegrationType.slack,
            status: IntegrationStatus.active,
            settings: {},
            channelMappings: {},
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          IntegrationConfig(
            id: 'active2',
            groupId: 'group123',
            type: IntegrationType.email,
            status: IntegrationStatus.active,
            settings: {},
            channelMappings: {},
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          IntegrationConfig(
            id: 'inactive1',
            groupId: 'group123',
            type: IntegrationType.microsoftTeams,
            status: IntegrationStatus.inactive,
            settings: {},
            channelMappings: {},
            isActive: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          IntegrationConfig(
            id: 'error1',
            groupId: 'group123',
            type: IntegrationType.googleCalendar,
            status: IntegrationStatus.error,
            settings: {},
            channelMappings: {},
            isActive: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        for (final integration in integrations) {
          await fakeFirestore
              .collection('integrations')
              .doc(integration.id)
              .set(integration.toJson());
        }

        // Act
        final stats = await repository.getIntegrationStats('group123');

        // Assert
        expect(stats['total'], equals(4));
        expect(stats['active'], equals(2));
        expect(stats['inactive'], equals(1));
        expect(stats['error'], equals(1));
      });

      test('should return zero stats for group with no integrations', () async {
        // Act
        final stats = await repository.getIntegrationStats('empty_group');

        // Assert
        expect(stats['total'], equals(0));
        expect(stats['active'], equals(0));
        expect(stats['inactive'], equals(0));
        expect(stats['error'], equals(0));
      });
    });

    group('streamGroupIntegrations', () {
      test('should stream integration changes', () async {
        // Arrange
        final integration = IntegrationConfig(
          id: 'integration123',
          groupId: 'group123',
          type: IntegrationType.slack,
          status: IntegrationStatus.active,
          settings: {},
          channelMappings: {},
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final stream = repository.streamGroupIntegrations('group123');
        
        // Add integration after creating stream
        await fakeFirestore
            .collection('integrations')
            .doc(integration.id)
            .set(integration.toJson());

        // Assert
        await expectLater(
          stream,
          emits(predicate<List<IntegrationConfig>>((integrations) {
            return integrations.length == 1 && integrations[0].id == 'integration123';
          })),
        );
      });
    });
  });
}