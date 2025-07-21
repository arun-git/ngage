import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ngage/repositories/slack_integration_repository.dart';
import '../models/models.dart';
import '../repositories/repository_providers.dart';
import '../services/slack_service.dart';

/// Provider for SlackService
final slackServiceProvider = Provider<SlackService>((ref) {
  return SlackService();
});

/// Provider for Slack integration by group ID
final slackIntegrationProvider = FutureProvider.family<SlackIntegration?, String>((ref, groupId) async {
  final repository = ref.watch(slackIntegrationRepositoryProvider);
  return await repository.getIntegrationByGroupId(groupId);
});

/// Provider for streaming Slack integration by group ID
final slackIntegrationStreamProvider = StreamProvider.family<SlackIntegration?, String>((ref, groupId) {
  final repository = ref.watch(slackIntegrationRepositoryProvider);
  return repository.streamIntegrationByGroupId(groupId);
});

/// Provider for all active Slack integrations
final activeSlackIntegrationsProvider = FutureProvider<List<SlackIntegration>>((ref) async {
  final repository = ref.watch(slackIntegrationRepositoryProvider);
  return await repository.getActiveIntegrations();
});

/// Provider for streaming all active Slack integrations
final activeSlackIntegrationsStreamProvider = StreamProvider<List<SlackIntegration>>((ref) {
  final repository = ref.watch(slackIntegrationRepositoryProvider);
  return repository.streamActiveIntegrations();
});

/// Provider for checking if a group has active Slack integration
final hasActiveSlackIntegrationProvider = FutureProvider.family<bool, String>((ref, groupId) async {
  final repository = ref.watch(slackIntegrationRepositoryProvider);
  return await repository.hasActiveIntegration(groupId);
});

/// Provider for Slack channels (requires access token)
final slackChannelsProvider = FutureProvider.family<List<SlackChannel>, String>((ref, accessToken) async {
  final service = ref.watch(slackServiceProvider);
  return await service.getChannels(accessToken);
});

/// Provider for Slack user info (requires access token)
final slackUserInfoProvider = FutureProvider.family<SlackUser?, String>((ref, accessToken) async {
  final service = ref.watch(slackServiceProvider);
  return await service.getUserInfo(accessToken);
});

/// Provider for validating Slack token
final validateSlackTokenProvider = FutureProvider.family<bool, String>((ref, accessToken) async {
  final service = ref.watch(slackServiceProvider);
  return await service.validateToken(accessToken);
});

/// State notifier for managing Slack OAuth flow
class SlackOAuthNotifier extends StateNotifier<AsyncValue<SlackOAuthResponse?>> {
  final SlackService _service;

  SlackOAuthNotifier(this._service) : super(const AsyncValue.data(null));

  /// Initiate OAuth flow
  Future<String> initiateOAuth({
    required List<String> scopes,
    String? state,
  }) async {
    try {
      return await _service.initiateOAuth(scopes: scopes, state: state);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace) as String?;
      rethrow;
    }
  }

  /// Launch OAuth in browser
  Future<bool> launchOAuth({
    required List<String> scopes,
    String? state,
  }) async {
    try {
      return await _service.launchOAuth(scopes: scopes, state: state);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace) as String?;
      return false;
    }
  }

  /// Exchange authorization code for token
  Future<void> exchangeCodeForToken(String code) async {
    state = const AsyncValue.loading();
    try {
      final response = await _service.exchangeCodeForToken(code);
      state = AsyncValue.data(response);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Reset OAuth state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for Slack OAuth state notifier
final slackOAuthNotifierProvider = StateNotifierProvider<SlackOAuthNotifier, AsyncValue<SlackOAuthResponse?>>((ref) {
  final service = ref.watch(slackServiceProvider);
  return SlackOAuthNotifier(service);
});

/// State notifier for managing Slack integration configuration
class SlackIntegrationNotifier extends StateNotifier<AsyncValue<SlackIntegration?>> {
  final SlackIntegrationRepository _repository;
  final SlackService _service;

  SlackIntegrationNotifier(this._repository, this._service) : super(const AsyncValue.data(null));

  /// Load integration by group ID
  Future<void> loadIntegration(String groupId) async {
    state = const AsyncValue.loading();
    try {
      final integration = await _repository.getIntegrationByGroupId(groupId);
      state = AsyncValue.data(integration);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Create new Slack integration
  Future<void> createIntegration(SlackIntegration integration) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createIntegration(integration);
      state = AsyncValue.data(integration);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update existing integration
  Future<void> updateIntegration(SlackIntegration integration) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateIntegration(integration);
      state = AsyncValue.data(integration);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update channel mappings
  Future<void> updateChannelMappings(String integrationId, Map<String, String> channelMappings) async {
    try {
      await _repository.updateChannelMappings(integrationId, channelMappings);
      final currentIntegration = state.value;
      if (currentIntegration != null) {
        final updatedIntegration = currentIntegration.copyWith(
          channelMappings: channelMappings,
          updatedAt: DateTime.now(),
        );
        state = AsyncValue.data(updatedIntegration);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Toggle integration active status
  Future<void> toggleActive(String integrationId, bool isActive) async {
    try {
      await _repository.setIntegrationActive(integrationId, isActive);
      final currentIntegration = state.value;
      if (currentIntegration != null) {
        final updatedIntegration = currentIntegration.copyWith(
          isActive: isActive,
          updatedAt: DateTime.now(),
        );
        state = AsyncValue.data(updatedIntegration);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Test integration by sending a test message
  Future<bool> testIntegration(String channelId) async {
    final integration = state.value;
    if (integration == null) return false;

    try {
      return await _service.testIntegration(
        accessToken: integration.botToken,
        channelId: channelId,
      );
    } catch (error) {
      return false;
    }
  }

  /// Send event reminder
  Future<bool> sendEventReminder(Event event, String channelId) async {
    final integration = state.value;
    if (integration == null) return false;

    try {
      return await _service.sendEventReminder(
        accessToken: integration.botToken,
        channelId: channelId,
        event: event,
      );
    } catch (error) {
      return false;
    }
  }

  /// Send result announcement
  Future<bool> sendResultAnnouncement(Event event, List<Leaderboard> leaderboard, String channelId) async {
    final integration = state.value;
    if (integration == null) return false;

    try {
      return await _service.sendResultAnnouncement(
        accessToken: integration.botToken,
        channelId: channelId,
        event: event,
        leaderboard: leaderboard,
      );
    } catch (error) {
      return false;
    }
  }

  /// Send leaderboard update
  Future<bool> sendLeaderboardUpdate(Event event, List<Leaderboard> leaderboard, String channelId) async {
    final integration = state.value;
    if (integration == null) return false;

    try {
      return await _service.sendLeaderboardUpdate(
        accessToken: integration.botToken,
        channelId: channelId,
        event: event,
        leaderboard: leaderboard,
      );
    } catch (error) {
      return false;
    }
  }

  /// Delete integration
  Future<void> deleteIntegration(String integrationId) async {
    try {
      await _repository.deleteIntegration(integrationId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider for Slack integration state notifier
final slackIntegrationNotifierProvider = StateNotifierProvider.family<SlackIntegrationNotifier, AsyncValue<SlackIntegration?>, String>((ref, groupId) {
  final repository = ref.watch(slackIntegrationRepositoryProvider);
  final service = ref.watch(slackServiceProvider);
  final notifier = SlackIntegrationNotifier(repository, service);
  
  // Load integration on creation
  notifier.loadIntegration(groupId);
  
  return notifier;
});

/// Provider for sending Slack notifications based on notification type
final sendSlackNotificationProvider = FutureProvider.family<bool, ({String groupId, NotificationType type, Map<String, dynamic> data})>((ref, params) async {
  final repository = ref.watch(slackIntegrationRepositoryProvider);
  final service = ref.watch(slackServiceProvider);
  
  try {
    final integration = await repository.getIntegrationByGroupId(params.groupId);
    if (integration == null || !integration.isActive) {
      return false;
    }

    final channelId = integration.channelMappings[params.type.value];
    if (channelId == null) {
      return false;
    }

    // Build message based on notification type
    SlackMessage message;
    switch (params.type) {
      case NotificationType.eventReminder:
        final event = params.data['event'] as Event;
        return await service.sendEventReminder(
          accessToken: integration.botToken,
          channelId: channelId,
          event: event,
        );
      
      case NotificationType.resultAnnouncement:
        final event = params.data['event'] as Event;
        final leaderboard = params.data['leaderboard'] as List<Leaderboard>;
        return await service.sendResultAnnouncement(
          accessToken: integration.botToken,
          channelId: channelId,
          event: event,
          leaderboard: leaderboard,
        );
      
      case NotificationType.leaderboardUpdate:
        final event = params.data['event'] as Event;
        final leaderboard = params.data['leaderboard'] as List<Leaderboard>;
        return await service.sendLeaderboardUpdate(
          accessToken: integration.botToken,
          channelId: channelId,
          event: event,
          leaderboard: leaderboard,
        );
      
      default:
        message = SlackMessage(
          channel: channelId,
          text: params.data['message'] as String? ?? 'Notification from Ngage',
          messageType: SlackMessageType.general,
        );
        return await service.sendMessage(
          accessToken: integration.botToken,
          message: message,
        );
    }
  } catch (error) {
    return false;
  }
});