import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';

/// Service for handling Slack integration functionality
/// Provides OAuth authentication, channel messaging, and bot functionality
class SlackService {
  static const String _baseUrl = 'https://slack.com/api';
  static const String _oauthUrl = 'https://slack.com/oauth/v2/authorize';
  static const String _tokenUrl = 'https://slack.com/api/oauth.v2.access';
  
  // These should be configured via environment variables or Firebase Remote Config
  static const String _clientId = 'YOUR_SLACK_CLIENT_ID';
  static const String _clientSecret = 'YOUR_SLACK_CLIENT_SECRET';
  static const String _redirectUri = 'YOUR_REDIRECT_URI';
  
  final http.Client _httpClient;
  
  SlackService({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  /// Initiates Slack OAuth flow
  /// Returns the authorization URL that users should visit
  Future<String> initiateOAuth({
    required List<String> scopes,
    String? state,
  }) async {
    final scopeString = scopes.join(',');
    final params = {
      'client_id': _clientId,
      'scope': scopeString,
      'redirect_uri': _redirectUri,
      if (state != null) 'state': state,
    };
    
    final uri = Uri.parse(_oauthUrl).replace(queryParameters: params);
    return uri.toString();
  }

  /// Launches Slack OAuth in browser
  Future<bool> launchOAuth({
    required List<String> scopes,
    String? state,
  }) async {
    final authUrl = await initiateOAuth(scopes: scopes, state: state);
    final uri = Uri.parse(authUrl);
    
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Exchanges authorization code for access token
  Future<SlackOAuthResponse> exchangeCodeForToken(String code) async {
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
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return SlackOAuthResponse.fromJson(data);
      } else {
        return SlackOAuthResponse(
          ok: false,
          error: 'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      return SlackOAuthResponse(
        ok: false,
        error: 'OAuth exchange failed: $e',
      );
    }
  }

  /// Gets list of channels in a Slack workspace
  Future<List<SlackChannel>> getChannels(String accessToken) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/conversations.list'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['ok'] == true) {
          final channels = data['channels'] as List<dynamic>;
          return channels
              .map((channel) => SlackChannel.fromJson(channel as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception('Slack API error: ${data['error']}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get channels: $e');
    }
  }

  /// Sends a message to a Slack channel
  Future<bool> sendMessage({
    required String accessToken,
    required SlackMessage message,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/chat.postMessage'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(message.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['ok'] == true;
      }
      return false;
    } catch (e) {
      print('Failed to send Slack message: $e');
      return false;
    }
  }

  /// Sends event reminder to Slack channel
  Future<bool> sendEventReminder({
    required String accessToken,
    required String channelId,
    required Event event,
  }) async {
    final message = _buildEventReminderMessage(channelId, event);
    return await sendMessage(accessToken: accessToken, message: message);
  }

  /// Sends result announcement to Slack channel
  Future<bool> sendResultAnnouncement({
    required String accessToken,
    required String channelId,
    required Event event,
    required List<Leaderboard> leaderboard,
  }) async {
    final message = _buildResultAnnouncementMessage(channelId, event, leaderboard);
    return await sendMessage(accessToken: accessToken, message: message);
  }

  /// Sends leaderboard update to Slack channel
  Future<bool> sendLeaderboardUpdate({
    required String accessToken,
    required String channelId,
    required Event event,
    required List<Leaderboard> leaderboard,
  }) async {
    final message = _buildLeaderboardUpdateMessage(channelId, event, leaderboard);
    return await sendMessage(accessToken: accessToken, message: message);
  }

  /// Tests Slack integration by sending a test message
  Future<bool> testIntegration({
    required String accessToken,
    required String channelId,
  }) async {
    final message = SlackMessage(
      channel: channelId,
      text: '🎉 Ngage Slack integration is working!',
      messageType: SlackMessageType.general,
      blocks: [
        SlackBlock.header(text: 'Integration Test'),
        SlackBlock.section(text: 'Your Ngage platform is successfully connected to Slack!'),
        SlackBlock.divider(),
        SlackBlock.section(text: '_This is a test message to verify the integration._'),
      ],
    );

    return await sendMessage(accessToken: accessToken, message: message);
  }

  /// Builds event reminder message
  SlackMessage _buildEventReminderMessage(String channelId, Event event) {
    final startTime = event.startTime?.toLocal();
    final endTime = event.endTime?.toLocal();
    final submissionDeadline = event.submissionDeadline?.toLocal();

    final timeInfo = StringBuffer();
    if (startTime != null) {
      timeInfo.write('📅 *Start:* ${_formatDateTime(startTime)}\n');
    }
    if (endTime != null) {
      timeInfo.write('🏁 *End:* ${_formatDateTime(endTime)}\n');
    }
    if (submissionDeadline != null) {
      timeInfo.write('⏰ *Submission Deadline:* ${_formatDateTime(submissionDeadline)}\n');
    }

    return SlackMessage(
      channel: channelId,
      text: '📢 Event Reminder: ${event.title}',
      messageType: SlackMessageType.eventReminder,
      blocks: [
        SlackBlock.header(text: '📢 Event Reminder'),
        SlackBlock.section(text: '*${event.title}*\n${event.description}'),
        SlackBlock.section(text: timeInfo.toString()),
        SlackBlock.section(text: '_Event Type:_ ${event.eventType.value.toUpperCase()}'),
        SlackBlock.divider(),
        SlackBlock.section(text: '🚀 *Ready to participate?* Make sure you\'re prepared!'),
      ],
    );
  }

  /// Builds result announcement message
  SlackMessage _buildResultAnnouncementMessage(
    String channelId,
    Event event,
    List<Leaderboard> leaderboard,
  ) {
    final topEntries = leaderboard.take(3).toList();
    final resultsText = StringBuffer();
    
    for (int i = 0; i < topEntries.length; i++) {
      final entry = topEntries[i];
      final medal = i == 0 ? '🥇' : i == 1 ? '🥈' : '🥉';
      resultsText.write('$medal *${i + 1}.* ${entry.teamName} - ${entry.totalScore.toStringAsFixed(1)} points\n');
    }

    return SlackMessage(
      channel: channelId,
      text: '🎉 Results for ${event.title}',
      messageType: SlackMessageType.resultAnnouncement,
      blocks: [
        SlackBlock.header(text: '🎉 Results Announced!'),
        SlackBlock.section(text: '*${event.title}* results are now available!'),
        SlackBlock.divider(),
        SlackBlock.section(text: '*🏆 Top Performers:*\n${resultsText.toString()}'),
        SlackBlock.section(text: '🎊 *Congratulations to all participants!*'),
      ],
    );
  }

  /// Builds leaderboard update message
  SlackMessage _buildLeaderboardUpdateMessage(
    String channelId,
    Event event,
    List<Leaderboard> leaderboard,
  ) {
    final topEntries = leaderboard.take(5).toList();
    final leaderboardText = StringBuffer();
    
    for (int i = 0; i < topEntries.length; i++) {
      final entry = topEntries[i];
      final position = i + 1;
      final emoji = position <= 3 ? ['🥇', '🥈', '🥉'][i] : '🏅';
      leaderboardText.write('$emoji *$position.* ${entry.teamName} - ${entry.totalScore.toStringAsFixed(1)} pts\n');
    }

    return SlackMessage(
      channel: channelId,
      text: '📊 Leaderboard Update: ${event.title}',
      messageType: SlackMessageType.leaderboardUpdate,
      blocks: [
        SlackBlock.header(text: '📊 Leaderboard Update'),
        SlackBlock.section(text: '*${event.title}*\nCurrent standings:'),
        SlackBlock.divider(),
        SlackBlock.section(text: leaderboardText.toString()),
        SlackBlock.section(text: '_Keep up the great work! 💪_'),
      ],
    );
  }

  /// Formats DateTime for display
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Validates Slack access token
  Future<bool> validateToken(String accessToken) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/auth.test'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['ok'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Gets user information from Slack
  Future<SlackUser?> getUserInfo(String accessToken) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/users.identity'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['ok'] == true) {
          final user = data['user'] as Map<String, dynamic>;
          final team = data['team'] as Map<String, dynamic>;
          
          return SlackUser(
            id: user['id'] as String,
            name: user['name'] as String,
            email: user['email'] as String,
            avatar: user['image_192'] as String?,
            teamId: team['id'] as String,
            teamName: team['name'] as String,
          );
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Disposes resources
  void dispose() {
    _httpClient.close();
  }
}