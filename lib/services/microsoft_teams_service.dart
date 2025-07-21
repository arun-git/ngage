import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/integration.dart';
import '../models/enums.dart';

/// Service for handling Microsoft Teams integration functionality
/// Provides OAuth authentication, channel messaging, and bot functionality
class MicrosoftTeamsService {
  static const String _baseUrl = 'https://graph.microsoft.com/v1.0';
  static const String _oauthUrl = 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize';
  static const String _tokenUrl = 'https://login.microsoftonline.com/common/oauth2/v2.0/token';
  
  // These should be configured via environment variables or Firebase Remote Config
  static const String _clientId = 'YOUR_TEAMS_CLIENT_ID';
  static const String _clientSecret = 'YOUR_TEAMS_CLIENT_SECRET';
  static const String _redirectUri = 'YOUR_REDIRECT_URI';
  
  final http.Client _httpClient;
  
  MicrosoftTeamsService({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  /// Initiates Microsoft Teams OAuth flow
  /// Returns the authorization URL that users should visit
  Future<String> initiateOAuth({
    required List<String> scopes,
    String? state,
  }) async {
    final scopeString = scopes.join(' ');
    final params = {
      'client_id': _clientId,
      'response_type': 'code',
      'redirect_uri': _redirectUri,
      'scope': scopeString,
      'response_mode': 'query',
      if (state != null) 'state': state,
    };
    
    final uri = Uri.parse(_oauthUrl).replace(queryParameters: params);
    return uri.toString();
  }

  /// Exchanges authorization code for access token
  Future<Map<String, dynamic>> exchangeCodeForToken(String code) async {
    try {
      final response = await _httpClient.post(
        Uri.parse(_tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'code': code,
          'redirect_uri': _redirectUri,
          'grant_type': 'authorization_code',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('OAuth exchange failed: $e');
    }
  }

  /// Refreshes access token using refresh token
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await _httpClient.post(
        Uri.parse(_tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Token refresh failed: $e');
    }
  }

  /// Gets list of teams the user is a member of
  Future<List<Map<String, dynamic>>> getTeams(String accessToken) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/me/joinedTeams'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['value'] as List);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get teams: $e');
    }
  }

  /// Gets list of channels in a team
  Future<List<TeamsChannel>> getChannels(String accessToken, String teamId) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/teams/$teamId/channels'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final channels = data['value'] as List<dynamic>;
        return channels
            .map((channel) => TeamsChannel.fromJson(channel as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get channels: $e');
    }
  }

  /// Sends a message to a Teams channel
  Future<bool> sendMessage({
    required String accessToken,
    required String teamId,
    required String channelId,
    required TeamsMessage message,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/teams/$teamId/channels/$channelId/messages'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(message.toJson()),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Failed to send Teams message: $e');
      return false;
    }
  }

  /// Sends event reminder to Teams channel
  Future<bool> sendEventReminder({
    required String accessToken,
    required String teamId,
    required String channelId,
    required Event event,
  }) async {
    final message = _buildEventReminderMessage(event);
    return await sendMessage(
      accessToken: accessToken,
      teamId: teamId,
      channelId: channelId,
      message: message,
    );
  }

  /// Sends result announcement to Teams channel
  Future<bool> sendResultAnnouncement({
    required String accessToken,
    required String teamId,
    required String channelId,
    required Event event,
    required List<Leaderboard> leaderboard,
  }) async {
    final message = _buildResultAnnouncementMessage(event, leaderboard);
    return await sendMessage(
      accessToken: accessToken,
      teamId: teamId,
      channelId: channelId,
      message: message,
    );
  }

  /// Sends leaderboard update to Teams channel
  Future<bool> sendLeaderboardUpdate({
    required String accessToken,
    required String teamId,
    required String channelId,
    required Event event,
    required List<Leaderboard> leaderboard,
  }) async {
    final message = _buildLeaderboardUpdateMessage(event, leaderboard);
    return await sendMessage(
      accessToken: accessToken,
      teamId: teamId,
      channelId: channelId,
      message: message,
    );
  }

  /// Tests Teams integration by sending a test message
  Future<bool> testIntegration({
    required String accessToken,
    required String teamId,
    required String channelId,
  }) async {
    final message = TeamsMessage(
      channelId: channelId,
      content: '''
        <h2>🎉 Ngage Teams Integration Test</h2>
        <p>Your Ngage platform is successfully connected to Microsoft Teams!</p>
        <p><em>This is a test message to verify the integration.</em></p>
      ''',
      subject: 'Integration Test',
    );

    return await sendMessage(
      accessToken: accessToken,
      teamId: teamId,
      channelId: channelId,
      message: message,
    );
  }

  /// Builds event reminder message
  TeamsMessage _buildEventReminderMessage(Event event) {
    final startTime = event.startTime?.toLocal();
    final endTime = event.endTime?.toLocal();
    final submissionDeadline = event.submissionDeadline?.toLocal();

    final timeInfo = StringBuffer();
    if (startTime != null) {
      timeInfo.write('<p><strong>📅 Start:</strong> ${_formatDateTime(startTime)}</p>');
    }
    if (endTime != null) {
      timeInfo.write('<p><strong>🏁 End:</strong> ${_formatDateTime(endTime)}</p>');
    }
    if (submissionDeadline != null) {
      timeInfo.write('<p><strong>⏰ Submission Deadline:</strong> ${_formatDateTime(submissionDeadline)}</p>');
    }

    final content = '''
      <h2>📢 Event Reminder</h2>
      <h3>${event.title}</h3>
      <p>${event.description}</p>
      ${timeInfo.toString()}
      <p><em>Event Type:</em> ${event.eventType.value.toUpperCase()}</p>
      <hr>
      <p><strong>🚀 Ready to participate?</strong> Make sure you're prepared!</p>
    ''';

    return TeamsMessage(
      channelId: '',
      content: content,
      subject: 'Event Reminder: ${event.title}',
    );
  }

  /// Builds result announcement message
  TeamsMessage _buildResultAnnouncementMessage(
    Event event,
    List<Leaderboard> leaderboard,
  ) {
    final topEntries = leaderboard.take(3).toList();
    final resultsHtml = StringBuffer();
    
    for (int i = 0; i < topEntries.length; i++) {
      final entry = topEntries[i];
      final medal = i == 0 ? '🥇' : i == 1 ? '🥈' : '🥉';
      resultsHtml.write('<p>$medal <strong>${i + 1}.</strong> ${entry.teamName} - ${entry.totalScore.toStringAsFixed(1)} points</p>');
    }

    final content = '''
      <h2>🎉 Results Announced!</h2>
      <h3>${event.title} results are now available!</h3>
      <hr>
      <h4>🏆 Top Performers:</h4>
      ${resultsHtml.toString()}
      <p><strong>🎊 Congratulations to all participants!</strong></p>
    ''';

    return TeamsMessage(
      channelId: '',
      content: content,
      subject: 'Results for ${event.title}',
    );
  }

  /// Builds leaderboard update message
  TeamsMessage _buildLeaderboardUpdateMessage(
    Event event,
    List<Leaderboard> leaderboard,
  ) {
    final topEntries = leaderboard.take(5).toList();
    final leaderboardHtml = StringBuffer();
    
    for (int i = 0; i < topEntries.length; i++) {
      final entry = topEntries[i];
      final position = i + 1;
      final emoji = position <= 3 ? ['🥇', '🥈', '🥉'][i] : '🏅';
      leaderboardHtml.write('<p>$emoji <strong>$position.</strong> ${entry.teamName} - ${entry.totalScore.toStringAsFixed(1)} pts</p>');
    }

    final content = '''
      <h2>📊 Leaderboard Update</h2>
      <h3>${event.title}</h3>
      <p>Current standings:</p>
      <hr>
      ${leaderboardHtml.toString()}
      <p><em>Keep up the great work! 💪</em></p>
    ''';

    return TeamsMessage(
      channelId: '',
      content: content,
      subject: 'Leaderboard Update: ${event.title}',
    );
  }

  /// Formats DateTime for display
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Validates Teams access token
  Future<bool> validateToken(String accessToken) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/me'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Gets user information from Teams
  Future<Map<String, dynamic>?> getUserInfo(String accessToken) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/me'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Creates a calendar event in Teams/Outlook
  Future<bool> createCalendarEvent({
    required String accessToken,
    required CalendarEvent event,
  }) async {
    try {
      final eventData = {
        'subject': event.title,
        'body': {
          'contentType': 'HTML',
          'content': event.description,
        },
        'start': {
          'dateTime': event.startTime.toIso8601String(),
          'timeZone': 'UTC',
        },
        'end': {
          'dateTime': event.endTime.toIso8601String(),
          'timeZone': 'UTC',
        },
        if (event.location != null) 'location': {
          'displayName': event.location,
        },
        if (event.attendees != null) 'attendees': event.attendees!.map((email) => {
          'emailAddress': {
            'address': email,
            'name': email,
          },
          'type': 'required',
        }).toList(),
      };

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/me/events'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(eventData),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Failed to create calendar event: $e');
      return false;
    }
  }

  /// Gets user's calendars
  Future<List<Map<String, dynamic>>> getCalendars(String accessToken) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/me/calendars'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['value'] as List);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get calendars: $e');
    }
  }

  /// Disposes resources
  void dispose() {
    _httpClient.close();
  }
}

// Placeholder classes for missing models
class Event {
  final String title;
  final String description;
  final EventType eventType;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? submissionDeadline;

  const Event({
    required this.title,
    required this.description,
    required this.eventType,
    this.startTime,
    this.endTime,
    this.submissionDeadline,
  });
}

class Leaderboard {
  final String teamName;
  final double totalScore;

  const Leaderboard({
    required this.teamName,
    required this.totalScore,
  });
}