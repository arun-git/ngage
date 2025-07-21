import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/integration_models.dart';
import '../services/integration_service.dart';

/// Provider for the integration service
final integrationServiceProvider = Provider<IntegrationService>((ref) {
  final service = IntegrationService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for available integrations
final availableIntegrationsProvider = Provider<List<IntegrationType>>((ref) {
  final service = ref.watch(integrationServiceProvider);
  return service.getAvailableIntegrations();
});

/// Provider for integration statuses
final integrationStatusesProvider = FutureProvider<Map<IntegrationType, IntegrationStatus>>((ref) async {
  final service = ref.watch(integrationServiceProvider);
  await service.initialize();
  return service.getAllIntegrationStatuses();
});

/// Provider for a specific integration status
final integrationStatusProvider = Provider.family<IntegrationStatus, IntegrationType>((ref, type) {
  final statuses = ref.watch(integrationStatusesProvider);
  return statuses.when(
    data: (data) => data[type] ?? IntegrationStatus.notSupported,
    loading: () => IntegrationStatus.disconnected,
    error: (_, __) => IntegrationStatus.error,
  );
});

/// Provider for checking if an integration is enabled
final integrationEnabledProvider = Provider.family<bool, IntegrationType>((ref, type) {
  final service = ref.watch(integrationServiceProvider);
  return service.isIntegrationEnabled(type);
});

/// Provider for integration configuration
final integrationConfigProvider = Provider.family<IntegrationConfig?, IntegrationType>((ref, type) {
  final service = ref.watch(integrationServiceProvider);
  return service.getIntegrationConfig(type);
});

/// Notifier for managing integration operations
class IntegrationNotifier extends StateNotifier<AsyncValue<void>> {
  final IntegrationService _service;
  
  IntegrationNotifier(this._service) : super(const AsyncValue.data(null));
  
  Future<void> enableIntegration(IntegrationType type, Map<String, dynamic> config) async {
    state = const AsyncValue.loading();
    try {
      await _service.enableIntegration(type, config);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  Future<void> disableIntegration(IntegrationType type) async {
    state = const AsyncValue.loading();
    try {
      await _service.disableIntegration(type);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  Future<void> updateIntegrationConfig(IntegrationType type, Map<String, dynamic> config) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateIntegrationConfig(type, config);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  Future<bool> testIntegration(IntegrationType type) async {
    try {
      return await _service.testIntegration(type);
    } catch (e) {
      return false;
    }
  }
  
  Future<void> sendNotification(NotificationMessage message) async {
    try {
      await _service.sendNotification(message);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  Future<void> sendCalendarEvent(CalendarEvent event) async {
    try {
      await _service.sendCalendarEvent(event);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

/// Provider for integration operations
final integrationNotifierProvider = StateNotifierProvider<IntegrationNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(integrationServiceProvider);
  return IntegrationNotifier(service);
});

/// Provider for sending notifications through integrations
final notificationSenderProvider = Provider<Future<void> Function(NotificationMessage)>((ref) {
  final notifier = ref.read(integrationNotifierProvider.notifier);
  return (message) => notifier.sendNotification(message);
});

/// Provider for sending calendar events through integrations
final calendarEventSenderProvider = Provider<Future<void> Function(CalendarEvent)>((ref) {
  final notifier = ref.read(integrationNotifierProvider.notifier);
  return (event) => notifier.sendCalendarEvent(event);
});

/// Provider for integration platform information
final integrationPlatformInfoProvider = Provider<Map<IntegrationType, Map<String, dynamic>>>((ref) {
  return {
    IntegrationType.slack: {
      'name': 'Slack',
      'description': 'Send notifications to Slack channels',
      'icon': 'slack',
      'color': '#4A154B',
      'features': ['Notifications', 'Channel messaging', 'Bot integration'],
    },
    IntegrationType.microsoftTeams: {
      'name': 'Microsoft Teams',
      'description': 'Send notifications to Teams channels',
      'icon': 'teams',
      'color': '#6264A7',
      'features': ['Notifications', 'Channel messaging', 'Bot integration'],
    },
    IntegrationType.googleCalendar: {
      'name': 'Google Calendar',
      'description': 'Create and manage calendar events',
      'icon': 'calendar',
      'color': '#4285F4',
      'features': ['Event creation', 'Event updates', 'Calendar sync'],
    },
    IntegrationType.microsoftCalendar: {
      'name': 'Microsoft Calendar',
      'description': 'Create and manage Outlook calendar events',
      'icon': 'calendar',
      'color': '#0078D4',
      'features': ['Event creation', 'Event updates', 'Calendar sync'],
    },
    IntegrationType.email: {
      'name': 'Email',
      'description': 'Send email notifications',
      'icon': 'email',
      'color': '#EA4335',
      'features': ['Email notifications', 'HTML templates', 'Attachments'],
    },
  };
});

/// Provider for integration statistics
final integrationStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final statuses = await ref.watch(integrationStatusesProvider.future);
  
  final enabledCount = statuses.values.where((status) => 
    status == IntegrationStatus.connected || status == IntegrationStatus.disconnected
  ).length;
  
  final connectedCount = statuses.values.where((status) => 
    status == IntegrationStatus.connected
  ).length;
  
  return {
    'total': statuses.length,
    'enabled': enabledCount,
    'connected': connectedCount,
    'disabled': statuses.length - enabledCount,
  };
});

/// Provider for checking if any chat integration is enabled
final chatIntegrationEnabledProvider = Provider<bool>((ref) {
  final slackEnabled = ref.watch(integrationEnabledProvider(IntegrationType.slack));
  final teamsEnabled = ref.watch(integrationEnabledProvider(IntegrationType.microsoftTeams));
  return slackEnabled || teamsEnabled;
});

/// Provider for checking if any calendar integration is enabled
final calendarIntegrationEnabledProvider = Provider<bool>((ref) {
  final googleEnabled = ref.watch(integrationEnabledProvider(IntegrationType.googleCalendar));
  final microsoftEnabled = ref.watch(integrationEnabledProvider(IntegrationType.microsoftCalendar));
  return googleEnabled || microsoftEnabled;
});

/// Provider for checking if email integration is enabled
final emailIntegrationEnabledProvider = Provider<bool>((ref) {
  return ref.watch(integrationEnabledProvider(IntegrationType.email));
});