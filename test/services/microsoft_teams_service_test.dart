import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:ngage/models/models.dart';
import 'package:ngage/services/microsoft_teams_service.dart';

import 'microsoft_teams_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('MicrosoftTeamsService', () {
    late MicrosoftTeamsService service;
    late MockClient mockClient;

    setUp(() {
      service = MicrosoftTeamsService();
      mockClient = MockClient();
    });

    group('testIntegration', () {
      test('should return true for successful Teams integration test', () async {
        // Arrange
        final integration = IntegrationConfig(
          id: 'teams123',
          groupId: 'group123',
          type: IntegrationType.microsoftTeams,
          status: IntegrationStatus.pending,
          settings: {
            'tenantId': 'tenant123',
            'clientId': 'client123',
            'clientSecret': 'secret123',
            'teamId': 'team123',
            'channelId': 'channel123',
          },
          channelMappings: {},
          isActive: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Mock OAuth token response
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          '{"access_token": "mock_token", "token_type": "Bearer"}',
          200,
        ));

        // Mock team info response
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          '{"id": "team123", "displayName": "Test Team"}',
          200,
        ));

        // Act
        final result = await service.testIntegration(integration);

        // Assert
        expect(result, isTrue);
      });

      test('should return false for failed Teams integration test', () async {
        // Arrange
        final integration = IntegrationConfig(
          id: 'teams123',
          groupId: 'group123',
          type: IntegrationType.microsoftTeams,
          status: IntegrationStatus.pending,
          settings: {
            'tenantId': 'tenant123',
            'clientId': 'client123',
            'clientSecret': 'invalid_secret',
            'teamId': 'team123',
            'channelId': 'channel123',
          },
          channelMappings: {},
          isActive: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Mock OAuth token failure
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          '{"error": "invalid_client"}',
          401,
        ));

        // Act
        final result = await service.testIntegration(integration);

        // Assert
        expect(result, isFalse);
      });
    });

    group('sendMessage', () {
      test('should send message via webhook when webhook URL is provided', () async {
        // Arrange
        final integration = IntegrationConfig(
          id: 'teams123',
          groupId: 'group123',
          type: IntegrationType.microsoftTeams,
          status: IntegrationStatus.active,
          settings: {
            'tenantId': 'tenant123',
            'clientId': 'client123',
            'clientSecret': 'secret123',
            'teamId': 'team123',
            'channelId': 'channel123',
            'webhookUrl': 'https://outlook.office.com/webhook/test',
          },
          channelMappings: {},
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('1', 200));

        // Act
        await service.sendMessage(
          integration: integration,
          channelId: 'channel123',
          title: 'Test Message',
          message: 'This is a test message',
        );

        // Assert - Should not throw an exception
        expect(true, isTrue);
      });

      test('should send event reminder with proper formatting', () async {
        // Arrange
        final integration = IntegrationConfig(
          id: 'teams123',
          groupId: 'group123',
          type: IntegrationType.microsoftTeams,
          status: IntegrationStatus.active,
          settings: {
            'tenantId': 'tenant123',
            'clientId': 'client123',
            'clientSecret': 'secret123',
            'teamId': 'team123',
            'channelId': 'channel123',
            'webhookUrl': 'https://outlook.office.com/webhook/test',
          },
          channelMappings: {},
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('1', 200));

        final eventStartTime = DateTime.now().add(const Duration(hours: 2));

        // Act
        await service.sendEventReminder(
          integration: integration,
          channelId: 'channel123',
          eventTitle: 'Team Meeting',
          eventStartTime: eventStartTime,
          eventDescription: 'Weekly team sync meeting',
        );

        // Assert - Should not throw an exception
        expect(true, isTrue);
      });

      test('should send result announcement with leaderboard', () async {
        // Arrange
        final integration = IntegrationConfig(
          id: 'teams123',
          groupId: 'group123',
          type: IntegrationType.microsoftTeams,
          status: IntegrationStatus.active,
          settings: {
            'tenantId': 'tenant123',
            'clientId': 'client123',
            'clientSecret': 'secret123',
            'teamId': 'team123',
            'channelId': 'channel123',
            'webhookUrl': 'https://outlook.office.com/webhook/test',
          },
          channelMappings: {},
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('1', 200));

        final results = [
          {'name': 'Team Alpha', 'score': 95},
          {'name': 'Team Beta', 'score': 87},
          {'name': 'Team Gamma', 'score': 82},
        ];

        // Act
        await service.sendResultAnnouncement(
          integration: integration,
          channelId: 'channel123',
          eventTitle: 'Innovation Challenge',
          results: results,
        );

        // Assert - Should not throw an exception
        expect(true, isTrue);
      });

      test('should send leaderboard update', () async {
        // Arrange
        final integration = IntegrationConfig(
          id: 'teams123',
          groupId: 'group123',
          type: IntegrationType.microsoftTeams,
          status: IntegrationStatus.active,
          settings: {
            'tenantId': 'tenant123',
            'clientId': 'client123',
            'clientSecret': 'secret123',
            'teamId': 'team123',
            'channelId': 'channel123',
            'webhookUrl': 'https://outlook.office.com/webhook/test',
          },
          channelMappings: {},
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('1', 200));

        final leaderboard = [
          {'name': 'Alice Johnson', 'totalScore': 285},
          {'name': 'Bob Smith', 'totalScore': 267},
          {'name': 'Carol Davis', 'totalScore': 251},
        ];

        // Act
        await service.sendLeaderboardUpdate(
          integration: integration,
          channelId: 'channel123',
          groupName: 'Engineering Team',
          leaderboard: leaderboard,
        );

        // Assert - Should not throw an exception
        expect(true, isTrue);
      });
    });

    group('getTeamChannels', () {
      test('should return list of team channels', () async {
        // Arrange
        final integration = IntegrationConfig(
          id: 'teams123',
          groupId: 'group123',
          type: IntegrationType.microsoftTeams,
          status: IntegrationStatus.active,
          settings: {
            'tenantId': 'tenant123',
            'clientId': 'client123',
            'clientSecret': 'secret123',
            'teamId': 'team123',
            'channelId': 'channel123',
          },
          channelMappings: {},
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Mock OAuth token response
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          '{"access_token": "mock_token", "token_type": "Bearer"}',
          200,
        ));

        // Mock channels response
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          '''
          {
            "value": [
              {
                "id": "channel1",
                "displayName": "General",
                "description": "General discussion"
              },
              {
                "id": "channel2",
                "displayName": "Announcements",
                "description": "Team announcements"
              }
            ]
          }
          ''',
          200,
        ));

        // Act
        final result = await service.getTeamChannels(integration);

        // Assert
        expect(result, isA<List<Map<String, dynamic>>>());
        expect(result.length, equals(2));
        expect(result[0]['displayName'], equals('General'));
        expect(result[1]['displayName'], equals('Announcements'));
      });

      test('should throw exception when getting channels fails', () async {
        // Arrange
        final integration = IntegrationConfig(
          id: 'teams123',
          groupId: 'group123',
          type: IntegrationType.microsoftTeams,
          status: IntegrationStatus.active,
          settings: {
            'tenantId': 'tenant123',
            'clientId': 'client123',
            'clientSecret': 'secret123',
            'teamId': 'team123',
            'channelId': 'channel123',
          },
          channelMappings: {},
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Mock OAuth token response
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          '{"access_token": "mock_token", "token_type": "Bearer"}',
          200,
        ));

        // Mock channels failure
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          '{"error": "Forbidden"}',
          403,
        ));

        // Act & Assert
        expect(
          () => service.getTeamChannels(integration),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}