import '../models/user.dart' as app_user;
import '../models/member.dart';

/// Authentication flow types
enum AuthFlow {
  emailPassword,
  phoneVerification,
  socialAuth,
  passwordReset,
}

/// Authentication status
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  emailEntered,
  phoneVerificationSent,
  passwordResetSent,
  error,
}

/// Enhanced authentication state that supports multi-step flows
class AuthenticationState {
  final AuthStatus status;
  final app_user.User? user;
  final List<Member>? memberProfiles;
  final Member? currentMember;
  final String? errorMessage;
  final AuthFlow? currentFlow;
  final Map<String, dynamic>? flowData;
  final bool isLoading;

  const AuthenticationState({
    required this.status,
    this.user,
    this.memberProfiles,
    this.currentMember,
    this.errorMessage,
    this.currentFlow,
    this.flowData,
    this.isLoading = false,
  });

  AuthenticationState copyWith({
    AuthStatus? status,
    app_user.User? user,
    List<Member>? memberProfiles,
    Member? currentMember,
    String? errorMessage,
    AuthFlow? currentFlow,
    Map<String, dynamic>? flowData,
    bool? isLoading,
  }) {
    return AuthenticationState(
      status: status ?? this.status,
      user: user ?? this.user,
      memberProfiles: memberProfiles ?? this.memberProfiles,
      currentMember: currentMember ?? this.currentMember,
      errorMessage: errorMessage ?? this.errorMessage,
      currentFlow: currentFlow ?? this.currentFlow,
      flowData: flowData ?? this.flowData,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get hasError => status == AuthStatus.error;
  bool get isInFlow => currentFlow != null;

  /// Get flow data for a specific key
  T? getFlowData<T>(String key) {
    return flowData?[key] as T?;
  }

  /// Set flow data
  AuthenticationState setFlowData(String key, dynamic value) {
    final newFlowData = Map<String, dynamic>.from(flowData ?? {});
    newFlowData[key] = value;
    return copyWith(flowData: newFlowData);
  }

  /// Clear flow data
  AuthenticationState clearFlow() {
    return copyWith(
      currentFlow: null,
      flowData: null,
    );
  }
}

/// Security event types for logging
enum SecurityEventType {
  signIn,
  signUp,
  signOut,
  passwordReset,
  failedAttempt,
  suspiciousActivity,
  tokenRefresh,
  sessionExpired,
}

/// Security event model
class SecurityEvent {
  final String userId;
  final SecurityEventType eventType;
  final DateTime timestamp;
  final String ipAddress;
  final String userAgent;
  final Map<String, dynamic> metadata;

  const SecurityEvent({
    required this.userId,
    required this.eventType,
    required this.timestamp,
    required this.ipAddress,
    required this.userAgent,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'eventType': eventType.name,
      'timestamp': timestamp.toIso8601String(),
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'metadata': metadata,
    };
  }

  factory SecurityEvent.fromJson(Map<String, dynamic> json) {
    return SecurityEvent(
      userId: json['userId'] as String,
      eventType: SecurityEventType.values.firstWhere(
        (e) => e.name == json['eventType'],
        orElse: () => SecurityEventType.signIn,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      ipAddress: json['ipAddress'] as String,
      userAgent: json['userAgent'] as String,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
    );
  }
}