import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ngage/models/models.dart';
import 'package:ngage/services/slack_service.dart';

import 'slack_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('SlackService', () {
    late SlackService slackService;
    late MockClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockClient();
      slackService = SlackService(httpClient: mockHttpClient);
    });

    tearDown(() {
      slackService.dispose();
    });

    group('OAuth Flow', () {
      test('initiateOAuth returns correct authorization URL', () async {
        const scopes = ['chat:write', 'channels:read'];
        const state = 'test_state';

        final authUrl = await slackService.initiateOAuth(
          scopes: scopes,
          state: state,
        );

        expect(authUrl, contains('https://slack.com/oauth/v2/authorize'));
        expect(authUrl, contains('scope=chat%3Awrite%2Cchannels%3Aread'));
        expect(authUrl, contains('state=test_state'));
      });

      test('exchangeCodeForToken returns success response', () async {
        const code = 'test_code';
        final mockResponse = {
          'ok': true,
          'access_token': 'xoxb-test-token',
          'scope': 'chat:write,channels:read',
          'user_id': 'U123456',
          'team_id': 'T123456',
          'team_name': 'Test Team',
        };

        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        final result = await slackService.exchangeCodeForToken(code);

        expect(result.ok, isTrue);
        expect(result.accessToken, equals('xoxb-test-token'));
        expect(result.userId, equals('U123456'));
        expect(result.teamId, equals('T123456'));
        expect(result.teamName, equals('Test Team'));
      });

      test('exchangeCodeForToken handles error response', () async {
        const code = 'invalid_code';
        final mockResponse = {
          'ok': false,
          'error': 'invalid_code',
        };

        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        final result = await slackService.exchangeCodeForToken(code);

        expect(result.ok, isFalse);
        expect(result.error, equals('invalid_code'));
      });

      test('exchangeCodeForToken handles HTTP error', () async {
        const code = 'test_code';

        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('Server Error', 500));

        final result = await slackService.exchangeCodeForToken(code);

        expect(result.ok, isFalse);
        expect(result.error, contains('HTTP 500'));
      });
    });

    group('Channel Operations', () {
      test('getChannels returns list of channels', () async {
        const accessToken = 'xoxb-test-token';
        final mockResponse = {
          'ok': true,
          'channels': [
            {
              'id': 'C123456',
              'name': 'general',
              'is_private': false,
              'is_member': true,
            },
            {
              'id': 'C789012',
              'name': 'random',
              'is_private': false,
              'is_member': false,
            },
          ],
        };

        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        final channels = await slackService.getChannels(accessToken);

        expect(channels, hasLength(2));
        expect(channels[0].id, equals('C123456'));
        expect(channels[0].name, equals('general'));
        expect(channels[0].isPrivate, isFalse);
        expect(channels[0].isMember, isTrue);
      });

      test('getChannels handles API error', () async {
        const accessToken = 'invalid-token';
        final mockResponse = {
          'ok': false,
          'error': 'invalid_auth',
        };

        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        expect(
          () => slackService.getChannels(accessToken),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Message Sending', () {
      test('sendMessage sends message successfully', () async {
        const accessToken = 'xoxb-test-token';
        const message = SlackMessage(
          channel: 'C123456',
          text: 'Test message',
          messageType: SlackMessageType.general,
        );

        final mockResponse = {
          'ok': true,
          'ts': '1234567890.123456',
        };

        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        final result = await slackService.sendMessage(
          accessToken: accessToken,
          message: message,
        );

        expect(result, isTrue);
      });

      test('sendMessage handles failure', () async {
        const accessToken = 'xoxb-test-token';
        const message = SlackMessage(
          channel: 'C123456',
          text: 'Test message',
          messageType: SlackMessageType.general,
        );

        final mockResponse = {
          'ok': false,
          'error': 'channel_not_found',
        };

        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        final result = await slackService.sendMessage(
          accessToken: accessToken,
          message: message,
        );

        expect(result, isFalse);
      });
    });

    group('Event Notifications', () {
      test('sendEventReminder sends formatted event reminder', () async {
        const accessToken = 'xoxb-test-token';
        const channelId = 'C123456';
        final event = Event(
          id: 'event1',
          groupId: 'group1',
          title: 'Test Competition',
          description: 'A test competition event',
          eventType: EventType.competition,
          status: EventStatus.scheduled,
          startTime: DateTime(2024, 1, 15, 10, 0),
          endTime: DateTime(2024, 1, 15, 18, 0),
          submissionDeadline: DateTime(2024, 1, 15, 17, 0),
          eligibleTeamIds: null,
          judgingCriteria: {},
          createdBy: 'member1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final mockResponse = {
          'ok': true,
          'ts': '1234567890.123456',
        };

        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        final result = await slackService.sendEventReminder(
          accessToken: accessToken,
          channelId: channelId,
          event: event,
        );

        expect(result, isTrue);
        
        // Verify the request was made with correct data
        final capturedCall = verify(mockHttpClient.post(
          captureAny,
          headers: captureAnyNamed('headers'),
          body: captureAnyNamed('body'),
        )).captured;
        
        final requestBody = json.decode(capturedCall[2] as String) as Map<String, dynamic>;
        expect(requestBody['channel'], equals(channelId));
        expect(requestBody['text'], contains('Test Competition'));
        expect(requestBody['message_type'], equals('event_reminder'));
      });

      test('sendResultAnnouncement sends formatted result announcement', () async {
        const accessToken = 'xoxb-test-token';
        const channelId = 'C123456';
        final event = Event(
          id: 'event1',
          groupId: 'group1',
          title: 'Test Competition',
          description: 'A test competition event',
          eventType: EventType.competition,
          status: EventStatus.completed,
          startTime: DateTime(2024, 1, 15, 10, 0),
          endTime: DateTime(2024, 1, 15, 18, 0),
          submissionDeadline: DateTime(2024, 1, 15, 17, 0),
          eligibleTeamIds: null,
          judgingCriteria: {},
          createdBy: 'member1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final leaderboard = [
          Leaderboard(
            id: 'lb1',
            eventId: 'event1',
            teamId: 'team1',
            teamName: 'Team Alpha',
            totalScore: 95.5,
            rank: 1,
            submissionCount: 1,
            averageScore: 95.5,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Leaderboard(
            id: 'lb2',
            eventId: 'event1',
            teamId: 'team2',
            teamName: 'Team Beta',
            totalScore: 87.2,
            rank: 2,
            submissionCount: 1,
            averageScore: 87.2,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        final mockResponse = {
          'ok': true,
          'ts': '1234567890.123456',
        };

        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        final result = await slackService.sendResultAnnouncement(
          accessToken: accessToken,
          channelId: channelId,
          event: event,
          leaderboard: leaderboard,
        );

        expect(result, isTrue);
        
        // Verify the request was made with correct data
        final capturedCall = verify(mockHttpClient.post(
          captureAny,
          headers: captureAnyNamed('headers'),
          body: captureAnyNamed('body'),
        )).captured;
        
        final requestBody = json.decode(capturedCall[2] as String) as Map<String, dynamic>;
        expect(requestBody['channel'], equals(channelId));
        expect(requestBody['text'], contains('Results for Test Competition'));
        expect(requestBody['message_type'], equals('result_announcement'));
      });
    });

    group('Token Validation', () {
      test('validateToken returns true for valid token', () async {
        const accessToken = 'xoxb-valid-token';
        final mockResponse = {
          'ok': true,
          'user': 'test_user',
          'team': 'test_team',
        };

        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        final result = await slackService.validateToken(accessToken);

        expect(result, isTrue);
      });

      test('validateToken returns false for invalid token', () async {
        const accessToken = 'xoxb-invalid-token';
        final mockResponse = {
          'ok': false,
          'error': 'invalid_auth',
        };

        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        final result = await slackService.validateToken(accessToken);

        expect(result, isFalse);
      });

      test('validateToken handles HTTP error', () async {
        const accessToken = 'xoxb-test-token';

        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('Server Error', 500));

        final result = await slackService.validateToken(accessToken);

        expect(result, isFalse);
      });
    });

    group('User Information', () {
      test('getUserInfo returns user information', () async {
        const accessToken = 'xoxb-test-token';
        final mockResponse = {
          'ok': true,
          'user': {
            'id': 'U123456',
            'name': 'testuser',
            'email': 'test@example.com',
            'image_192': 'https://example.com/avatar.png',
          },
          'team': {
            'id': 'T123456',
            'name': 'Test Team',
          },
        };

        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        final user = await slackService.getUserInfo(accessToken);

        expect(user, isNotNull);
        expect(user!.id, equals('U123456'));
        expect(user.name, equals('testuser'));
        expect(user.email, equals('test@example.com'));
        expect(user.teamId, equals('T123456'));
        expect(user.teamName, equals('Test Team'));
      });

      test('getUserInfo returns null for invalid token', () async {
        const accessToken = 'xoxb-invalid-token';
        final mockResponse = {
          'ok': false,
          'error': 'invalid_auth',
        };

        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        final user = await slackService.getUserInfo(accessToken);

        expect(user, isNull);
      });
    });

    group('Integration Testing', () {
      test('testIntegration sends test message', () async {
        const accessToken = 'xoxb-test-token';
        const channelId = 'C123456';

        final mockResponse = {
          'ok': true,
          'ts': '1234567890.123456',
        };

        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        final result = await slackService.testIntegration(
          accessToken: accessToken,
          channelId: channelId,
        );

        expect(result, isTrue);
        
        // Verify the request was made with correct data
        final capturedCall = verify(mockHttpClient.post(
          captureAny,
          headers: captureAnyNamed('headers'),
          body: captureAnyNamed('body'),
        )).captured;
        
        final requestBody = json.decode(capturedCall[2] as String) as Map<String, dynamic>;
        expect(requestBody['channel'], equals(channelId));
        expect(requestBody['text'], contains('Ngage Slack integration is working'));
      });
    });
  });
}