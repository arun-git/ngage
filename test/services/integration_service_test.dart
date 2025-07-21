import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../lib/models/models.dart';
import '../../lib/services/integration_service.dart';
import '../../lib/services/microsoft_teams_service.dart';
import '../../lib/services/email_service.dart';
import '../../lib/services/calendar_service.dart';
import '../../lib/services/slack_service.dart';
import '../../lib/repositories/integration_repository.dart';

import 'integration_service_test.mocks.dart';

@GenerateMocks([
  IntegrationRepository,
  MicrosoftTeamsService,
  EmailService,
  CalendarService,
  SlackService,
])
void main() {
  group('IntegrationService', () {
    late IntegrationService service;
    late MockIntegrationRepository mockRepository;
    late MockMicrosoftTeamsService mockTeamsService;
    late MockEmailService mockEmailService;
    late MockCalendarService mockCalendarService;
    late MockSlackService mockSlackService;

    setUp(() {
      mockRepository = MockIntegrationRepository();
      mockTeamsService = MockMicrosoftTeamsService();
      mockEmailService = MockEmailService();
      mockCalendarService = MockCalendarService();
      mockSlackService = MockSlackService();

      service = IntegrationService(
        repository: mockRepository,
        teamsService: mockTeamsService,
        emailService: mockEmailService,
        calendarService: mockCalendarService,
        slackService: mockSlackService,
      );
    });

    group('createIntegration', () {
      test('should create integration with correct parameters', () async {
        // Arrange
        const groupId = 'group123';
        const type = IntegrationType.slack;
        final settings = {'botToken': 'token123', 'channelId': 'channel123'};
        final channelMappings = {'event_reminder': 'general'};

        when(mockRepository.createIntegration(any))
            .thenAnswer((_) async => {});
        when(mockSlackService.testIntegration(
          accessToken: anyNamed('accessToken'),
          channelId: anyNamed('channelId'),
        )).thenAnswer((_) async => true);
        when(mockRepository.updateIntegrationStatus(any, any))
            .thenAnswer((_) async => {});

        // Act
        final result = await service.createIntegration(
          groupId: groupId,
          type: type,
          settings: settings,
          channelMappings: channelMappings,
        );

        // Assert
        expect(result.groupId, equals(groupId));
        expect(result.type, equals(type));
        expect(result.settings, equals(settings));
        expect(result.channelMappings, equals(channelMappings));
        verify(mockRepository.createIntegration(any)).called(1);
      });
    });

    group('testIntegration', () {
      test('should test Slack integration successfully', () async {
        // Arrange
        const integrationId = 'integration123';
        final integration = IntegrationConfig(
          id: integrationId,
          groupId: 'group123',
          type: IntegrationType.slack,
          status: IntegrationStatus.pending,
          settings: {'botToken': 'token123', 'channelId': 'channel123'},
          channelMappings: {},
          isActive: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockRepository.getIntegrationById(integrationId))
            .thenAnswer((_) async => integration);
        when(mockSlackService.testIntegration(
          accessToken: anyNamed('accessToken'),
          channelId: anyNamed('channelId'),
        )).thenAnswer((_) async => true);
        when(mockRepository.updateIntegrationStatus(integrationId, IntegrationStatus.active))
            .thenAnswer((_) async => {});

        // Act
        final result = await service.testIntegration(integrationId);

        // Assert
        expect(result, isTrue);
        verify(mockSlackService.testIntegration(
          accessToken: 'token123',
          channelId: 'channel123',
        )).called(1);
        verify(mockRepository.updateIntegrationStatus(integrationId, IntegrationStatus.active)).called(1);
      });

      test('should test Teams integration successfully', () async {
        // Arrange
        const integrationId = 'integration123';
        final integration = IntegrationConfig(
          id: integrationId,
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

        when(mockRepository.getIntegrationById(integrationId))
            .thenAnswer((_) async => integration);
        when(mockTeamsService.testIntegration(integration))
            .thenAnswer((_) async => true);
        when(mockRepository.updateIntegrationStatus(integrationId, IntegrationStatus.active))
            .thenAnswer((_) async => {});

        // Act
        final result = await service.testIntegration(integrationId);

        // Assert
        expect(result, isTrue);
        verify(mockTeamsService.testIntegration(integration)).called(1);
        verify(mockRepository.updateIntegrationStatus(integrationId, IntegrationStatus.active)).called(1);
      });

      test('should handle integration test failure', () async {
        // Arrange
        const integrationId = 'integration123';
        final integration = IntegrationConfig(
          id: integrationId,
          groupId: 'group123',
          type: IntegrationType.email,
          status: IntegrationStatus.pending,
          settings: {
            'smtpHost': 'smtp.example.com',
            'smtpPort': 587,
            'username': 'user@example.com',
            'password': 'password123',
            'fromEmail': 'noreply@example.com',
            'fromName': 'Ngage Platform',
            'templates': {},
          },
          channelMappings: {},
          isActive: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockRepository.getIntegrationById(integrationId))
            .thenAnswer((_) async => integration);
        when(mockEmailService.testConnection(integration))
            .thenAnswer((_) async => false);
        when(mockRepository.updateIntegrationStatus(integrationId, IntegrationStatus.error))
            .thenAnswer((_) async => {});

        // Act
        final result = await service.testIntegration(integrationId);

        // Assert
        expect(result, isFalse);
        verify(mockEmailService.testConnection(integration)).called(1);
        verify(mockRepository.updateIntegrationStatus(integrationId, IntegrationStatus.error)).called(1);
      });
    });

    group('sendNotification', () {
      test('should send notification to all active integrations', () async {
        // Arrange
        const groupId = 'group123';
        const notificationType = NotificationType.eventReminder;
        const title = 'Event Reminder';
        const message = 'Don\'t forget about the event!';

        final slackIntegration = IntegrationConfig(
          id: 'slack123',
          groupId: groupId,
          type: IntegrationType.slack,
          status: IntegrationStatus.active,
          settings: {'botToken': 'token123'},
          channelMappings: {'event_reminder': 'general'},
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final teamsIntegration = IntegrationConfig(
          id: 'teams123',
          groupId: groupId,
          type: IntegrationType.microsoftTeams,
          status: IntegrationStatus.active,
          settings: {
            'tenantId': 'tenant123',
            'clientId': 'client123',
            'clientSecret': 'secret123',
            'teamId': 'team123',
            'channelId': 'channel123',
          },
          channelMappings: {'event_reminder': 'announcements'},
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockRepository.getActiveGroupIntegrations(groupId))
            .thenAnswer((_) async => [slackIntegration, teamsIntegration]);
        when(mockSlackService.sendMessage(
          accessToken: anyNamed('accessToken'),
          channelId: anyNamed('channelId'),
          message: anyNamed('message'),
          title: anyNamed('title'),
        )).thenAnswer((_) async => {});
        when(mockTeamsService.sendMessage(
          integration: anyNamed('integration'),
          channelId: anyNamed('channelId'),
          title: anyNamed('title'),
          message: anyNamed('message'),
          data: anyNamed('data'),
        )).thenAnswer((_) async => {});

        // Act
        await service.sendNotification(
          groupId: groupId,
          notificationType: notificationType,
          title: title,
          message: message,
        );

        // Assert
        verify(mockSlackService.sendMessage(
          accessToken: 'token123',
          channelId: 'general',
          message: message,
          title: title,
        )).called(1);
        verify(mockTeamsService.sendMessage(
          integration: teamsIntegration,
          channelId: 'announcements',
          title: title,
          message: message,
          data: null,
        )).called(1);
      });

      test('should skip integrations without channel mapping', () async {
        // Arrange
        const groupId = 'group123';
        const notificationType = NotificationType.eventReminder;
        const title = 'Event Reminder';
        const message = 'Don\'t forget about the event!';

        final integration = IntegrationConfig(
          id: 'slack123',
          groupId: groupId,
          type: IntegrationType.slack,
          status: IntegrationStatus.active,
          settings: {'botToken': 'token123'},
          channelMappings: {}, // No mapping for event_reminder
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockRepository.getActiveGroupIntegrations(groupId))
            .thenAnswer((_) async => [integration]);

        // Act
        await service.sendNotification(
          groupId: groupId,
          notificationType: notificationType,
          title: title,
          message: message,
        );

        // Assert
        verifyNever(mockSlackService.sendMessage(
          accessToken: anyNamed('accessToken'),
          channelId: anyNamed('channelId'),
          message: anyNamed('message'),
          title: anyNamed('title'),
        ));
      });
    });

    group('sendCalendarEvent', () {
      test('should send calendar event to calendar integrations', () async {
        // Arrange
        const groupId = 'group123';
        final calendarEvent = CalendarEvent(
          id: 'event123',
          title: 'Team Meeting',
          description: 'Weekly team sync',
          startTime: DateTime.now().add(const Duration(hours: 1)),
          endTime: DateTime.now().add(const Duration(hours: 2)),
          attendees: ['user1@example.com', 'user2@example.com'],
          eventType: CalendarEventType.eventReminder,
          metadata: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final googleCalendarIntegration = IntegrationConfig(
          id: 'gcal123',
          groupId: groupId,
          type: IntegrationType.googleCalendar,
          status: IntegrationStatus.active,
          settings: {
            'calendarId': 'primary',
            'accessToken': 'token123',
            'refreshToken': 'refresh123',
            'tokenExpiry': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
            'eventTypes': {'event_reminder': true},
          },
          channelMappings: {},
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockRepository.getGroupIntegrationsByType(groupId, IntegrationType.googleCalendar))
            .thenAnswer((_) async => [googleCalendarIntegration]);
        when(mockRepository.getGroupIntegrationsByType(groupId, IntegrationType.microsoftCalendar))
            .thenAnswer((_) async => []);
        when(mockCalendarService.createEvent(googleCalendarIntegration, calendarEvent))
            .thenAnswer((_) async => {});

        // Act
        await service.sendCalendarEvent(
          groupId: groupId,
          calendarEvent: calendarEvent,
        );

        // Assert
        verify(mockCalendarService.createEvent(googleCalendarIntegration, calendarEvent)).called(1);
      });
    });

    group('getIntegrationStats', () {
      test('should return correct integration statistics', () async {
        // Arrange
        const groupId = 'group123';
        final expectedStats = {
          'total': 3,
          'active': 2,
          'inactive': 0,
          'error': 1,
        };

        when(mockRepository.getIntegrationStats(groupId))
            .thenAnswer((_) async => expectedStats);

        // Act
        final result = await service.getIntegrationStats(groupId);

        // Assert
        expect(result, equals(expectedStats));
        verify(mockRepository.getIntegrationStats(groupId)).called(1);
      });
    });
  });
}