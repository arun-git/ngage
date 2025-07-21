/// Authentication configuration service for managing auth settings
class AuthConfigService {
  /// Default configuration for authentication
  static const AuthConfig defaultConfig = AuthConfig(
    enableEmailAuth: true,
    enablePhoneAuth: true,
    enableGoogleAuth: true,
    enableSlackAuth: true,
    requireEmailVerification: false,
    allowedEmailDomains: null,
    passwordMinLength: 8,
    requireStrongPasswords: true,
    enableBiometricAuth: false,
    sessionTimeoutMinutes: 60 * 24, // 24 hours
  );

  /// Get authentication configuration
  /// In production, this could be loaded from remote config or local storage
  static AuthConfig getConfig() {
    return defaultConfig;
  }

  /// Check if authentication method is enabled
  static bool isAuthMethodEnabled(AuthMethod method) {
    final config = getConfig();
    switch (method) {
      case AuthMethod.email:
        return config.enableEmailAuth;
      case AuthMethod.phone:
        return config.enablePhoneAuth;
      case AuthMethod.google:
        return config.enableGoogleAuth;
      case AuthMethod.slack:
        return config.enableSlackAuth;
      case AuthMethod.biometric:
        return config.enableBiometricAuth;
    }
  }

  /// Get Slack OAuth configuration
  /// In production, these should be loaded from environment variables or secure config
  static SlackOAuthConfig? getSlackConfig() {
    // Return null if Slack auth is disabled
    if (!isAuthMethodEnabled(AuthMethod.slack)) {
      return null;
    }

    // In production, load these from environment variables
    const clientId = String.fromEnvironment('SLACK_CLIENT_ID', defaultValue: '');
    const clientSecret = String.fromEnvironment('SLACK_CLIENT_SECRET', defaultValue: '');
    const redirectUri = String.fromEnvironment('SLACK_REDIRECT_URI', defaultValue: '');

    if (clientId.isEmpty || clientSecret.isEmpty || redirectUri.isEmpty) {
      return null; // Configuration not complete
    }

    return SlackOAuthConfig(
      clientId: clientId,
      clientSecret: clientSecret,
      redirectUri: redirectUri,
      scopes: ['identity.basic', 'identity.email'],
    );
  }
}

/// Authentication configuration model
class AuthConfig {
  final bool enableEmailAuth;
  final bool enablePhoneAuth;
  final bool enableGoogleAuth;
  final bool enableSlackAuth;
  final bool requireEmailVerification;
  final List<String>? allowedEmailDomains;
  final int passwordMinLength;
  final bool requireStrongPasswords;
  final bool enableBiometricAuth;
  final int sessionTimeoutMinutes;

  const AuthConfig({
    required this.enableEmailAuth,
    required this.enablePhoneAuth,
    required this.enableGoogleAuth,
    required this.enableSlackAuth,
    required this.requireEmailVerification,
    this.allowedEmailDomains,
    required this.passwordMinLength,
    required this.requireStrongPasswords,
    required this.enableBiometricAuth,
    required this.sessionTimeoutMinutes,
  });

  /// Create configuration from JSON
  factory AuthConfig.fromJson(Map<String, dynamic> json) {
    return AuthConfig(
      enableEmailAuth: json['enableEmailAuth'] as bool? ?? true,
      enablePhoneAuth: json['enablePhoneAuth'] as bool? ?? true,
      enableGoogleAuth: json['enableGoogleAuth'] as bool? ?? true,
      enableSlackAuth: json['enableSlackAuth'] as bool? ?? true,
      requireEmailVerification: json['requireEmailVerification'] as bool? ?? false,
      allowedEmailDomains: (json['allowedEmailDomains'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      passwordMinLength: json['passwordMinLength'] as int? ?? 8,
      requireStrongPasswords: json['requireStrongPasswords'] as bool? ?? true,
      enableBiometricAuth: json['enableBiometricAuth'] as bool? ?? false,
      sessionTimeoutMinutes: json['sessionTimeoutMinutes'] as int? ?? 60 * 24,
    );
  }

  /// Convert configuration to JSON
  Map<String, dynamic> toJson() {
    return {
      'enableEmailAuth': enableEmailAuth,
      'enablePhoneAuth': enablePhoneAuth,
      'enableGoogleAuth': enableGoogleAuth,
      'enableSlackAuth': enableSlackAuth,
      'requireEmailVerification': requireEmailVerification,
      'allowedEmailDomains': allowedEmailDomains,
      'passwordMinLength': passwordMinLength,
      'requireStrongPasswords': requireStrongPasswords,
      'enableBiometricAuth': enableBiometricAuth,
      'sessionTimeoutMinutes': sessionTimeoutMinutes,
    };
  }
}

/// Authentication methods enum
enum AuthMethod {
  email,
  phone,
  google,
  slack,
  biometric,
}

/// Slack OAuth configuration (imported from slack_oauth_service.dart)
class SlackOAuthConfig {
  final String clientId;
  final String clientSecret;
  final String redirectUri;
  final List<String> scopes;

  const SlackOAuthConfig({
    required this.clientId,
    required this.clientSecret,
    required this.redirectUri,
    this.scopes = const ['identity.basic', 'identity.email'],
  });
}