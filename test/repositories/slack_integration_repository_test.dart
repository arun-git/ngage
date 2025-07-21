import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ngage/models/models.dart';
import 'package:ngage/repositories/slack_integration_repository.dart';

void main() {
  group('SlackIntegrationRepository', () {
    late SlackIntegrationRepository repository;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = SlackIntegrationRepository(firestore: fakeFirestore);
    });

    group('CRUD Operations', () {
      test('createIntegration creates integration document', () async {
        final integration = SlackIntegration(
          id: 'integration1',
          groupId: 'group1',
          workspaceId: 'T123456',
          workspaceName: 'Test Workspace',
          botToken: 'xoxb-test-token',
          userToken: 'xoxp-user-token',
          integrationType: SlackIntegrationType.oauth,
          channelMappings: {
            'event_reminder': 'C123456',
            'result_announcement': 'C789012',
          },
          isActive: true,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        await repository.createIntegration(integration);

        final doc = await fakeFirestore
            .collection('slack_integrations')
            .doc('integration1')
            .get();

        expect(doc.exists, isTrue);
        expect(doc.data()!['groupId'], equals('group1'));
        expect(doc.data()!['workspaceId'], equals('T123456'));
        expect(doc.data()!['isActive'], isTrue);
      });

      test('getIntegrationById returns integration when exists', () async {
        final integrationData = {
          'id': 'integration1',
          'groupId': 'group1',
          'workspaceId': 'T123456',
          'workspaceName': 'Test Workspace',
          'botToken': 'xoxb-test-token',
          'userToken': 'xoxp-user-token',
          'integrationType': 'oauth',
          'channelMappings': {
            'event_reminder': 'C123456',
          },
          'isActive': true,
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-01T00:00:00.000Z',
        };

        await fakeFirestore
            .collection('slack_integrations')
            .doc('integration1')
            .set(integrationData);

        final result = await repository.getIntegrationById('integration1');

        expect(result, isNotNull);
        expect(result!.id, equals('integration1'));
        expect(result.groupId, equals('group1'));
        expect(result.workspaceId, equals('T123456'));
        expect(result.isActive, isTrue);
      });

      test('getIntegrationById returns null when not exists', () async {
        final result = await repository.getIntegrationById('nonexistent');

        expect(result, isNull);
      });

      test('updateIntegration updates existing integration', () async {
        final originalData = {
          'id': 'integration1',
          'groupId': 'group1',
          'workspaceId': 'T123456',
          'workspaceName': 'Test Workspace',
          'botToken': 'xoxb-test-token',
          'userToken': null,
          'integrationType': 'oauth',
          'channelMappings': {},
          'isActive': false,
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-01T00:00:00.000Z',
        };

        await fakeFirestore
            .collection('slack_integrations')
            .doc('integration1')
            .set(originalData);

        final updatedIntegration = SlackIntegration(
          id: 'integration1',
          groupId: 'group1',
          workspaceId: 'T123456',
          workspaceName: 'Test Workspace',
          botToken: 'xoxb-updated-token',
          userToken: 'xoxp-user-token',
          integrationType: SlackIntegrationType.oauth,
          channelMappings: {
            'event_reminder': 'C123456',
          },
          isActive: true,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
        );

        await repository.updateIntegration(updatedIntegration);

        final doc = await fakeFirestore
            .collection('slack_integrations')
            .doc('integration1')
            .get();

        expect(doc.data()!['botToken'], equals('xoxb-updated-token'));
        expect(doc.data()!['userToken'], equals('xoxp-user-token'));
        expect(doc.data()!['isActive'], isTrue);
        expect(doc.data()!['channelMappings']['event_reminder'], equals('C123456'));
      });

      test('deleteIntegration removes integration document', () async {
        await fakeFirestore
            .collection('slack_integrations')
            .doc('integration1')
            .set({'test': 'data'});

        await repository.deleteIntegration('integration1');

        final doc = await fakeFirestore
            .collection('slack_integrations')
            .doc('integration1')
            .get();

        expect(doc.exists, isFalse);
      });
    });

    group('Query Operations', () {
      setUp(() async {
        // Set up test data
        final integrations = [
          {
            'id': 'integration1',
            'groupId': 'group1',
            'workspaceId': 'T123456',
            'workspaceName': 'Workspace 1',
            'botToken': 'xoxb-token1',
            'userToken': null,
            'integrationType': 'oauth',
            'channelMappings': {
              'event_reminder': 'C123456',
            },
            'isActive': true,
            'createdAt': '2024-01-01T00:00:00.000Z',
            'updatedAt': '2024-01-01T00:00:00.000Z',
          },
          {
            'id': 'integration2',
            'groupId': 'group2',
            'workspaceId': 'T789012',
            'workspaceName': 'Workspace 2',
            'botToken': 'xoxb-token2',
            'userToken': null,
            'integrationType': 'oauth',
            'channelMappings': {},
            'isActive': false,
            'createdAt': '2024-01-02T00:00:00.000Z',
            'updatedAt': '2024-01-02T00:00:00.000Z',
          },
          {
            'id': 'integration3',
            'groupId': 'group3',
            'workspaceId': 'T123456',
            'workspaceName': 'Workspace 1',
            'botToken': 'xoxb-token3',
            'userToken': null,
            'integrationType': 'oauth',
            'channelMappings': {
              'result_announcement': 'C789012',
            },
            'isActive': true,
            'createdAt': '2024-01-03T00:00:00.000Z',
            'updatedAt': '2024-01-03T00:00:00.000Z',
          },
        ];

        for (final integration in integrations) {
          await fakeFirestore
              .collection('slack_integrations')
              .doc(integration['id'] as String)
              .set(integration);
        }
      });

      test('getIntegrationByGroupId returns active integration for group', () async {
        final result = await repository.getIntegrationByGroupId('group1');

        expect(result, isNotNull);
        expect(result!.id, equals('integration1'));
        expect(result.groupId, equals('group1'));
        expect(result.isActive, isTrue);
      });

      test('getIntegrationByGroupId returns null for inactive integration', () async {
        final result = await repository.getIntegrationByGroupId('group2');

        expect(result, isNull);
      });

      test('getActiveIntegrations returns only active integrations', () async {
        final result = await repository.getActiveIntegrations();

        expect(result, hasLength(2));
        expect(result.every((integration) => integration.isActive), isTrue);
        expect(result.map((i) => i.id), containsAll(['integration1', 'integration3']));
      });

      test('getIntegrationsByWorkspaceId returns integrations for workspace', () async {
        final result = await repository.getIntegrationsByWorkspaceId('T123456');

        expect(result, hasLength(2));
        expect(result.map((i) => i.id), containsAll(['integration1', 'integration3']));
        expect(result.every((i) => i.workspaceId == 'T123456'), isTrue);
      });

      test('hasActiveIntegration returns true when active integration exists', () async {
        final result = await repository.hasActiveIntegration('group1');

        expect(result, isTrue);
      });

      test('hasActiveIntegration returns false when no active integration exists', () async {
        final result = await repository.hasActiveIntegration('group2');

        expect(result, isFalse);
      });

      test('hasActiveIntegration returns false when group has no integration', () async {
        final result = await repository.hasActiveIntegration('nonexistent');

        expect(result, isFalse);
      });
    });

    group('Update Operations', () {
      setUp(() async {
        final integrationData = {
          'id': 'integration1',
          'groupId': 'group1',
          'workspaceId': 'T123456',
          'workspaceName': 'Test Workspace',
          'botToken': 'xoxb-test-token',
          'userToken': null,
          'integrationType': 'oauth',
          'channelMappings': {
            'event_reminder': 'C123456',
          },
          'isActive': true,
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-01T00:00:00.000Z',
        };

        await fakeFirestore
            .collection('slack_integrations')
            .doc('integration1')
            .set(integrationData);
      });

      test('updateChannelMappings updates channel mappings', () async {
        final newMappings = {
          'event_reminder': 'C111111',
          'result_announcement': 'C222222',
          'leaderboard_update': 'C333333',
        };

        await repository.updateChannelMappings('integration1', newMappings);

        final doc = await fakeFirestore
            .collection('slack_integrations')
            .doc('integration1')
            .get();

        final data = doc.data()!;
        expect(data['channelMappings'], equals(newMappings));
        expect(data['updatedAt'], isNot(equals('2024-01-01T00:00:00.000Z')));
      });

      test('setIntegrationActive updates active status', () async {
        await repository.setIntegrationActive('integration1', false);

        final doc = await fakeFirestore
            .collection('slack_integrations')
            .doc('integration1')
            .get();

        expect(doc.data()!['isActive'], isFalse);
      });

      test('updateBotToken updates bot token', () async {
        const newToken = 'xoxb-new-token';

        await repository.updateBotToken('integration1', newToken);

        final doc = await fakeFirestore
            .collection('slack_integrations')
            .doc('integration1')
            .get();

        expect(doc.data()!['botToken'], equals(newToken));
      });

      test('updateUserToken updates user token', () async {
        const newToken = 'xoxp-new-user-token';

        await repository.updateUserToken('integration1', newToken);

        final doc = await fakeFirestore
            .collection('slack_integrations')
            .doc('integration1')
            .get();

        expect(doc.data()!['userToken'], equals(newToken));
      });
    });

    group('Notification Type Queries', () {
      setUp(() async {
        final integrations = [
          {
            'id': 'integration1',
            'groupId': 'group1',
            'workspaceId': 'T123456',
            'workspaceName': 'Workspace 1',
            'botToken': 'xoxb-token1',
            'userToken': null,
            'integrationType': 'oauth',
            'channelMappings': {
              'event_reminder': 'C123456',
              'result_announcement': 'C789012',
            },
            'isActive': true,
            'createdAt': '2024-01-01T00:00:00.000Z',
            'updatedAt': '2024-01-01T00:00:00.000Z',
          },
          {
            'id': 'integration2',
            'groupId': 'group2',
            'workspaceId': 'T789012',
            'workspaceName': 'Workspace 2',
            'botToken': 'xoxb-token2',
            'userToken': null,
            'integrationType': 'oauth',
            'channelMappings': {
              'event_reminder': 'C111111',
            },
            'isActive': true,
            'createdAt': '2024-01-02T00:00:00.000Z',
            'updatedAt': '2024-01-02T00:00:00.000Z',
          },
          {
            'id': 'integration3',
            'groupId': 'group3',
            'workspaceId': 'T333333',
            'workspaceName': 'Workspace 3',
            'botToken': 'xoxb-token3',
            'userToken': null,
            'integrationType': 'oauth',
            'channelMappings': {
              'leaderboard_update': 'C222222',
            },
            'isActive': false, // Inactive
            'createdAt': '2024-01-03T00:00:00.000Z',
            'updatedAt': '2024-01-03T00:00:00.000Z',
          },
        ];

        for (final integration in integrations) {
          await fakeFirestore
              .collection('slack_integrations')
              .doc(integration['id'] as String)
              .set(integration);
        }
      });

      test('getIntegrationsForNotificationType returns integrations with specific notification type', () async {
        final result = await repository.getIntegrationsForNotificationType('event_reminder');

        expect(result, hasLength(2));
        expect(result.map((i) => i.id), containsAll(['integration1', 'integration2']));
        expect(result.every((i) => i.channelMappings.containsKey('event_reminder')), isTrue);
        expect(result.every((i) => i.isActive), isTrue);
      });

      test('getIntegrationsForNotificationType returns empty list when no integrations have notification type', () async {
        final result = await repository.getIntegrationsForNotificationType('nonexistent_type');

        expect(result, isEmpty);
      });

      test('getIntegrationsForNotificationType excludes inactive integrations', () async {
        final result = await repository.getIntegrationsForNotificationType('leaderboard_update');

        expect(result, isEmpty); // integration3 has this type but is inactive
      });
    });

    group('Batch Operations', () {
      test('batchUpdateIntegrations updates multiple integrations', () async {
        // Set up initial data
        final initialIntegrations = [
          {
            'id': 'integration1',
            'groupId': 'group1',
            'workspaceId': 'T123456',
            'workspaceName': 'Workspace 1',
            'botToken': 'xoxb-token1',
            'userToken': null,
            'integrationType': 'oauth',
            'channelMappings': {},
            'isActive': false,
            'createdAt': '2024-01-01T00:00:00.000Z',
            'updatedAt': '2024-01-01T00:00:00.000Z',
          },
          {
            'id': 'integration2',
            'groupId': 'group2',
            'workspaceId': 'T789012',
            'workspaceName': 'Workspace 2',
            'botToken': 'xoxb-token2',
            'userToken': null,
            'integrationType': 'oauth',
            'channelMappings': {},
            'isActive': false,
            'createdAt': '2024-01-02T00:00:00.000Z',
            'updatedAt': '2024-01-02T00:00:00.000Z',
          },
        ];

        for (final integration in initialIntegrations) {
          await fakeFirestore
              .collection('slack_integrations')
              .doc(integration['id'] as String)
              .set(integration);
        }

        // Create updated integrations
        final updatedIntegrations = [
          SlackIntegration(
            id: 'integration1',
            groupId: 'group1',
            workspaceId: 'T123456',
            workspaceName: 'Workspace 1',
            botToken: 'xoxb-updated-token1',
            userToken: null,
            integrationType: SlackIntegrationType.oauth,
            channelMappings: {'event_reminder': 'C123456'},
            isActive: true,
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 3),
          ),
          SlackIntegration(
            id: 'integration2',
            groupId: 'group2',
            workspaceId: 'T789012',
            workspaceName: 'Workspace 2',
            botToken: 'xoxb-updated-token2',
            userToken: null,
            integrationType: SlackIntegrationType.oauth,
            channelMappings: {'result_announcement': 'C789012'},
            isActive: true,
            createdAt: DateTime(2024, 1, 2),
            updatedAt: DateTime(2024, 1, 3),
          ),
        ];

        await repository.batchUpdateIntegrations(updatedIntegrations);

        // Verify updates
        final doc1 = await fakeFirestore
            .collection('slack_integrations')
            .doc('integration1')
            .get();
        final doc2 = await fakeFirestore
            .collection('slack_integrations')
            .doc('integration2')
            .get();

        expect(doc1.data()!['botToken'], equals('xoxb-updated-token1'));
        expect(doc1.data()!['isActive'], isTrue);
        expect(doc1.data()!['channelMappings']['event_reminder'], equals('C123456'));

        expect(doc2.data()!['botToken'], equals('xoxb-updated-token2'));
        expect(doc2.data()!['isActive'], isTrue);
        expect(doc2.data()!['channelMappings']['result_announcement'], equals('C789012'));
      });
    });
  });
}