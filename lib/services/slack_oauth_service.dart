import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ngage/services/auth_config_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Slack OAuth service for handling Slack authentication
class SlackOAuthService {
  final SlackOAuthConfig _config;

  SlackOAuthService(this._config);

  /// Generate Slack OAuth authorization URL
  Uri generateAuthorizationUrl({String? state}) {
    final queryParams = {
      'client_id': _config.clientId,
      'scope': _config.scopes.join(','),
      'redirect_uri': _config.redirectUri,
      'response_type': 'code',
      if (state != null) 'state': state,
    };

    return Uri.https('slack.com', '/oauth/v2/authorize', queryParams);
  }

  /// Launch Slack OAuth flow in browser
  Future<bool> launchOAuthFlow({String? state}) async {
    final authUrl = generateAuthorizationUrl(state: state);

    try {
      if (await canLaunchUrl(authUrl)) {
        return await launchUrl(
          authUrl,
          mode: LaunchMode.externalApplication,
        );
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Exchange authorization code for access token
  Future<SlackOAuthTokenResponse?> exchangeCodeForToken(String code) async {
    try {
      final response = await http.post(
        Uri.parse('https://slack.com/api/oauth.v2.access'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'client_id': _config.clientId,
          'client_secret': _config.clientSecret,
          'code': code,
          'redirect_uri': _config.redirectUri,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['ok'] == true) {
          return SlackOAuthTokenResponse.fromJson(data);
        } else {
          throw SlackOAuthException(
            'Token exchange failed: ${data['error'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw SlackOAuthException(
          'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      if (e is SlackOAuthException) rethrow;
      throw SlackOAuthException('Token exchange failed: $e');
    }
  }

  /// Get user identity information from Slack
  Future<SlackUserIdentity?> getUserIdentity(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://slack.com/api/users.identity'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['ok'] == true) {
          return SlackUserIdentity.fromJson(data);
        } else {
          throw SlackOAuthException(
            'Failed to get user identity: ${data['error'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw SlackOAuthException(
          'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      if (e is SlackOAuthException) rethrow;
      throw SlackOAuthException('Failed to get user identity: $e');
    }
  }

  /// Complete OAuth flow by exchanging code and getting user info
  Future<SlackAuthResult> completeOAuthFlow(String code) async {
    final tokenResponse = await exchangeCodeForToken(code);
    if (tokenResponse == null) {
      throw const SlackOAuthException('Failed to exchange code for token');
    }

    final userIdentity = await getUserIdentity(tokenResponse.accessToken);
    if (userIdentity == null) {
      throw const SlackOAuthException('Failed to get user identity');
    }

    return SlackAuthResult(
      tokenResponse: tokenResponse,
      userIdentity: userIdentity,
    );
  }
}

/// Slack OAuth token response
class SlackOAuthTokenResponse {
  final String accessToken;
  final String tokenType;
  final String scope;
  final String? botUserId;
  final String appId;
  final SlackTeamInfo team;
  final SlackUserInfo? authedUser;

  const SlackOAuthTokenResponse({
    required this.accessToken,
    required this.tokenType,
    required this.scope,
    this.botUserId,
    required this.appId,
    required this.team,
    this.authedUser,
  });

  factory SlackOAuthTokenResponse.fromJson(Map<String, dynamic> json) {
    return SlackOAuthTokenResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
      scope: json['scope'] as String,
      botUserId: json['bot_user_id'] as String?,
      appId: json['app_id'] as String,
      team: SlackTeamInfo.fromJson(json['team'] as Map<String, dynamic>),
      authedUser: json['authed_user'] != null
          ? SlackUserInfo.fromJson(json['authed_user'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Slack team information
class SlackTeamInfo {
  final String id;
  final String name;

  const SlackTeamInfo({
    required this.id,
    required this.name,
  });

  factory SlackTeamInfo.fromJson(Map<String, dynamic> json) {
    return SlackTeamInfo(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

/// Slack user information from OAuth
class SlackUserInfo {
  final String id;
  final String? accessToken;
  final String? scope;

  const SlackUserInfo({
    required this.id,
    this.accessToken,
    this.scope,
  });

  factory SlackUserInfo.fromJson(Map<String, dynamic> json) {
    return SlackUserInfo(
      id: json['id'] as String,
      accessToken: json['access_token'] as String?,
      scope: json['scope'] as String?,
    );
  }
}

/// Slack user identity from users.identity API
class SlackUserIdentity {
  final SlackUser user;
  final SlackTeamInfo team;

  const SlackUserIdentity({
    required this.user,
    required this.team,
  });

  factory SlackUserIdentity.fromJson(Map<String, dynamic> json) {
    return SlackUserIdentity(
      user: SlackUser.fromJson(json['user'] as Map<String, dynamic>),
      team: SlackTeamInfo.fromJson(json['team'] as Map<String, dynamic>),
    );
  }
}

/// Slack user details
class SlackUser {
  final String id;
  final String name;
  final String email;
  final String? image24;
  final String? image32;
  final String? image48;
  final String? image72;
  final String? image192;
  final String? image512;

  const SlackUser({
    required this.id,
    required this.name,
    required this.email,
    this.image24,
    this.image32,
    this.image48,
    this.image72,
    this.image192,
    this.image512,
  });

  factory SlackUser.fromJson(Map<String, dynamic> json) {
    return SlackUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      image24: json['image_24'] as String?,
      image32: json['image_32'] as String?,
      image48: json['image_48'] as String?,
      image72: json['image_72'] as String?,
      image192: json['image_192'] as String?,
      image512: json['image_512'] as String?,
    );
  }
}

/// Complete Slack authentication result
class SlackAuthResult {
  final SlackOAuthTokenResponse tokenResponse;
  final SlackUserIdentity userIdentity;

  const SlackAuthResult({
    required this.tokenResponse,
    required this.userIdentity,
  });

  /// Get the user's email from the identity
  String get email => userIdentity.user.email;

  /// Get the user's name from the identity
  String get name => userIdentity.user.name;

  /// Get the user's Slack ID
  String get slackUserId => userIdentity.user.id;

  /// Get the team ID
  String get teamId => userIdentity.team.id;

  /// Get the team name
  String get teamName => userIdentity.team.name;
}

/// Slack OAuth exception
class SlackOAuthException implements Exception {
  final String message;

  const SlackOAuthException(this.message);

  @override
  String toString() => 'SlackOAuthException: $message';
}
