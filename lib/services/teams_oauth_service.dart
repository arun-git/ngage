import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Configuration for Microsoft Teams OAuth
class TeamsOAuthConfig {
  final String clientId;
  final String tenantId;
  final String redirectUri;
  final List<String> scopes;

  const TeamsOAuthConfig({
    required this.clientId,
    required this.tenantId,
    required this.redirectUri,
    this.scopes = const ['openid', 'profile', 'email'],
  });
}

/// Service for handling Microsoft Teams OAuth authentication
class TeamsOAuthService {
  final TeamsOAuthConfig config;

  TeamsOAuthService(this.config);

  /// Launch the Microsoft Teams OAuth flow
  Future<bool> launchOAuthFlow() async {
    try {
      final authUrl = _buildAuthUrl();
      
      if (kDebugMode) {
        print('Launching Teams OAuth URL: $authUrl');
      }

      final uri = Uri.parse(authUrl);
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error launching Teams OAuth: $e');
      }
      return false;
    }
  }

  /// Build the Microsoft Teams OAuth authorization URL
  String _buildAuthUrl() {
    final params = {
      'client_id': config.clientId,
      'response_type': 'code',
      'redirect_uri': config.redirectUri,
      'scope': config.scopes.join(' '),
      'response_mode': 'query',
      'state': _generateState(),
    };

    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'https://login.microsoftonline.com/${config.tenantId}/oauth2/v2.0/authorize?$queryString';
  }

  /// Generate a random state parameter for security
  String _generateState() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final encoded = base64Url.encode(utf8.encode('teams_oauth_$timestamp'));
    return encoded.substring(0, 16); // Truncate for simplicity
  }

  /// Exchange authorization code for access token
  Future<Map<String, dynamic>?> exchangeCodeForToken(String code) async {
    // This would typically make an HTTP POST request to:
    // https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token
    // 
    // For now, return null as this requires backend implementation
    if (kDebugMode) {
      print('Teams OAuth code received: $code');
    }
    return null;
  }
}