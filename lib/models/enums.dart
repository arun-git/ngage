/// Enum definitions for the Ngage platform
/// 
/// This file contains all the enum types used throughout the application
/// for consistent type safety and validation.

/// Group types supported by the platform
enum GroupType {
  corporate('corporate'),
  educational('educational'),
  community('community'),
  social('social');

  const GroupType(this.value);
  final String value;

  static GroupType fromString(String value) {
    return GroupType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Invalid GroupType: $value'),
    );
  }
}

/// Event types supported by the platform
enum EventType {
  competition('competition'),
  challenge('challenge'),
  survey('survey');

  const EventType(this.value);
  final String value;

  static EventType fromString(String value) {
    return EventType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Invalid EventType: $value'),
    );
  }
}

/// Event status lifecycle
enum EventStatus {
  draft('draft'),
  scheduled('scheduled'),
  active('active'),
  completed('completed'),
  cancelled('cancelled');

  const EventStatus(this.value);
  final String value;

  static EventStatus fromString(String value) {
    return EventStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Invalid EventStatus: $value'),
    );
  }
}

/// Submission status lifecycle
enum SubmissionStatus {
  draft('draft'),
  submitted('submitted'),
  underReview('under_review'),
  approved('approved'),
  rejected('rejected');

  const SubmissionStatus(this.value);
  final String value;

  static SubmissionStatus fromString(String value) {
    return SubmissionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Invalid SubmissionStatus: $value'),
    );
  }
}

/// Group member roles
enum GroupRole {
  admin('admin'),
  judge('judge'),
  teamLead('team_lead'),
  member('member');

  const GroupRole(this.value);
  final String value;

  static GroupRole fromString(String value) {
    return GroupRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => throw ArgumentError('Invalid GroupRole: $value'),
    );
  }
}

/// Notification types
enum NotificationType {
  eventReminder('event_reminder'),
  deadlineAlert('deadline_alert'),
  resultAnnouncement('result_announcement'),
  leaderboardUpdate('leaderboard_update'),
  badgeAwarded('badge_awarded'),
  milestoneCompleted('milestone_completed'),
  general('general');

  const NotificationType(this.value);
  final String value;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Invalid NotificationType: $value'),
    );
  }
}

/// Types of scoring methods
enum ScoringType {
  numeric('numeric'),
  scale('scale'),
  boolean('boolean');

  const ScoringType(this.value);
  final String value;

  static ScoringType fromString(String value) {
    return ScoringType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ScoringType.numeric,
    );
  }
}

/// Judge comment types for categorizing comments
enum JudgeCommentType {
  general('general'),
  question('question'),
  concern('concern'),
  suggestion('suggestion'),
  clarification('clarification');

  const JudgeCommentType(this.value);
  final String value;

  static JudgeCommentType fromString(String value) {
    return JudgeCommentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => JudgeCommentType.general,
    );
  }
}

/// Judge roles for event assignments
enum JudgeRole {
  judge('judge'),
  leadJudge('lead_judge'),
  panelMember('panel_member');

  const JudgeRole(this.value);
  final String value;

  static JudgeRole fromString(String value) {
    return JudgeRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => JudgeRole.judge,
    );
  }
}

/// Slack integration configuration types
enum SlackIntegrationType {
  oauth('oauth'),
  webhook('webhook'),
  bot('bot');

  const SlackIntegrationType(this.value);
  final String value;

  static SlackIntegrationType fromString(String value) {
    return SlackIntegrationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => SlackIntegrationType.oauth,
    );
  }
}

/// Slack message types for different notifications
enum SlackMessageType {
  eventReminder('event_reminder'),
  resultAnnouncement('result_announcement'),
  leaderboardUpdate('leaderboard_update'),
  general('general');

  const SlackMessageType(this.value);
  final String value;

  static SlackMessageType fromString(String value) {
    return SlackMessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => SlackMessageType.general,
    );
  }
}

/// Badge types for categorizing different kinds of achievements
enum BadgeType {
  participation('participation'),
  performance('performance'),
  social('social'),
  milestone('milestone'),
  special('special');

  const BadgeType(this.value);
  final String value;

  static BadgeType fromString(String value) {
    return BadgeType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => BadgeType.participation,
    );
  }
}

/// Badge rarity levels
enum BadgeRarity {
  common('common'),
  uncommon('uncommon'),
  rare('rare'),
  epic('epic'),
  legendary('legendary');

  const BadgeRarity(this.value);
  final String value;

  static BadgeRarity fromString(String value) {
    return BadgeRarity.values.firstWhere(
      (rarity) => rarity.value == value,
      orElse: () => BadgeRarity.common,
    );
  }
}

/// Streak types for tracking different kinds of consecutive activities
enum StreakType {
  dailyLogin('daily_login'),
  eventParticipation('event_participation'),
  socialEngagement('social_engagement'),
  submissionStreak('submission_streak'),
  judgingStreak('judging_streak'),
  participation('participation'),
  submission('submission'),
  judging('judging'),
  social('social');

  const StreakType(this.value);
  final String value;

  static StreakType fromString(String value) {
    return StreakType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => StreakType.participation,
    );
  }
}

/// Consent types for different kinds of data usage
enum ConsentType {
  mediaUsage('media_usage'),
  dataProcessing('data_processing'),
  marketing('marketing'),
  analytics('analytics'),
  thirdPartySharing('third_party_sharing');

  const ConsentType(this.value);
  final String value;

  static ConsentType fromString(String value) {
    return ConsentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ConsentType.dataProcessing,
    );
  }
}

/// Privacy request types for GDPR compliance
enum PrivacyRequestType {
  dataExport('data_export'),
  dataCorrection('data_correction'),
  dataDeletion('data_deletion'),
  dataPortability('data_portability'),
  processingRestriction('processing_restriction');

  const PrivacyRequestType(this.value);
  final String value;

  static PrivacyRequestType fromString(String value) {
    return PrivacyRequestType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => PrivacyRequestType.dataExport,
    );
  }
}

/// Privacy request status
enum PrivacyRequestStatus {
  pending('pending'),
  inProgress('in_progress'),
  completed('completed'),
  rejected('rejected');

  const PrivacyRequestStatus(this.value);
  final String value;

  static PrivacyRequestStatus fromString(String value) {
    return PrivacyRequestStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PrivacyRequestStatus.pending,
    );
  }
}

/// Data visibility levels for role-based access control
enum DataVisibilityLevel {
  public('public'),
  group('group'),
  team('team'),
  private('private'),
  admin('admin');

  const DataVisibilityLevel(this.value);
  final String value;

  static DataVisibilityLevel fromString(String value) {
    return DataVisibilityLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => DataVisibilityLevel.private,
    );
  }
}

/// Permission types for role-based access control
enum PermissionType {
  read('read'),
  write('write'),
  delete('delete'),
  admin('admin'),
  judge('judge'),
  moderate('moderate');

  const PermissionType(this.value);
  final String value;

  static PermissionType fromString(String value) {
    return PermissionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => PermissionType.read,
    );
  }
}

/// Integration platform types
enum IntegrationType {
  slack('slack'),
  microsoftTeams('microsoft_teams'),
  email('email'),
  googleCalendar('google_calendar'),
  microsoftCalendar('microsoft_calendar');

  const IntegrationType(this.value);
  final String value;

  static IntegrationType fromString(String value) {
    return IntegrationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Invalid IntegrationType: $value'),
    );
  }
}

/// Calendar provider types
enum CalendarProvider {
  google('google'),
  microsoft('microsoft'),
  outlook('outlook');

  const CalendarProvider(this.value);
  final String value;

  static CalendarProvider fromString(String value) {
    return CalendarProvider.values.firstWhere(
      (provider) => provider.value == value,
      orElse: () => CalendarProvider.google,
    );
  }
}

/// Email provider types
enum EmailProvider {
  sendgrid('sendgrid'),
  mailgun('mailgun'),
  ses('ses'),
  smtp('smtp');

  const EmailProvider(this.value);
  final String value;

  static EmailProvider fromString(String value) {
    return EmailProvider.values.firstWhere(
      (provider) => provider.value == value,
      orElse: () => EmailProvider.smtp,
    );
  }
}

/// Integration status
enum IntegrationStatus {
  active('active'),
  inactive('inactive'),
  error('error'),
  pending('pending');

  const IntegrationStatus(this.value);
  final String value;

  static IntegrationStatus fromString(String value) {
    return IntegrationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => IntegrationStatus.inactive,
    );
  }
}

/// Calendar event types
enum CalendarEventType {
  eventReminder('event_reminder'),
  submissionDeadline('submission_deadline'),
  resultAnnouncement('result_announcement');

  const CalendarEventType(this.value);
  final String value;

  static CalendarEventType fromString(String value) {
    return CalendarEventType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => CalendarEventType.eventReminder,
    );
  }
}

/// Email template types
enum EmailTemplateType {
  eventReminder('event_reminder'),
  deadlineAlert('deadline_alert'),
  resultAnnouncement('result_announcement'),
  leaderboardUpdate('leaderboard_update'),
  welcome('welcome'),
  invitation('invitation');

  const EmailTemplateType(this.value);
  final String value;

  static EmailTemplateType fromString(String value) {
    return EmailTemplateType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => EmailTemplateType.eventReminder,
    );
  }
}

/// Badge categories for organizing different types of badges
enum BadgeCategory {
  participation('participation'),
  performance('performance'),
  social('social'),
  milestone('milestone'),
  special('special'),
  streak('streak'),
  achievement('achievement');

  const BadgeCategory(this.value);
  final String value;

  static BadgeCategory fromString(String value) {
    return BadgeCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => BadgeCategory.participation,
    );
  }
}

/// Achievement types for categorizing different kinds of achievements
enum AchievementType {
  milestone('milestone'),
  streak('streak'),
  performance('performance'),
  social('social'),
  event('event'),
  special('special');

  const AchievementType(this.value);
  final String value;

  static AchievementType fromString(String value) {
    return AchievementType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AchievementType.milestone,
    );
  }
}

/// Milestone types for tracking different kinds of progress
enum MilestoneType {
  totalPoints('total_points'),
  eventParticipation('event_participation'),
  socialPosts('social_posts'),
  badgesEarned('badges_earned'),
  streakDays('streak_days'),
  submissionsCount('submissions_count'),
  judgeScores('judge_scores');

  const MilestoneType(this.value);
  final String value;

  static MilestoneType fromString(String value) {
    return MilestoneType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MilestoneType.totalPoints,
    );
  }
}

/// Badge filter types for UI filtering
enum BadgeFilterType {
  all('all'),
  earned('earned'),
  unearned('unearned'),
  recent('recent');

  const BadgeFilterType(this.value);
  final String value;

  static BadgeFilterType fromString(String value) {
    return BadgeFilterType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => BadgeFilterType.all,
    );
  }
}

/// Moderation target types
enum ModerationTargetType {
  post('post'),
  comment('comment'),
  submission('submission'),
  user('user');

  const ModerationTargetType(this.value);
  final String value;

  static ModerationTargetType fromString(String value) {
    return ModerationTargetType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ModerationTargetType.post,
    );
  }
}

/// Authentication error types
enum AuthErrorType {
  invalidCredentials('invalid_credentials'),
  userNotFound('user_not_found'),
  userDisabled('user_disabled'),
  accountDisabled('account_disabled'),
  tooManyRequests('too_many_requests'),
  operationNotAllowed('operation_not_allowed'),
  weakPassword('weak_password'),
  emailAlreadyInUse('email_already_in_use'),
  invalidEmail('invalid_email'),
  tokenExpired('token_expired'),
  networkError('network_error'),
  unknown('unknown');

  const AuthErrorType(this.value);
  final String value;

  static AuthErrorType fromString(String value) {
    return AuthErrorType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AuthErrorType.unknown,
    );
  }
}

/// Network error types
enum NetworkErrorType {
  connectionTimeout('connection_timeout'),
  noConnection('no_connection'),
  serverError('server_error'),
  rateLimited('rate_limited'),
  unknown('unknown');

  const NetworkErrorType(this.value);
  final String value;

  static NetworkErrorType fromString(String value) {
    return NetworkErrorType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NetworkErrorType.unknown,
    );
  }
}

/// Database error types
enum DatabaseErrorType {
  connectionFailed('connection_failed'),
  queryTimeout('query_timeout'),
  permissionDenied('permission_denied'),
  documentNotFound('document_not_found'),
  unknown('unknown');

  const DatabaseErrorType(this.value);
  final String value;

  static DatabaseErrorType fromString(String value) {
    return DatabaseErrorType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DatabaseErrorType.unknown,
    );
  }
}

/// Integration error types
enum IntegrationErrorType {
  authenticationFailed('authentication_failed'),
  apiLimitExceeded('api_limit_exceeded'),
  serviceUnavailable('service_unavailable'),
  configurationError('configuration_error'),
  unknown('unknown');

  const IntegrationErrorType(this.value);
  final String value;

  static IntegrationErrorType fromString(String value) {
    return IntegrationErrorType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => IntegrationErrorType.unknown,
    );
  }
}