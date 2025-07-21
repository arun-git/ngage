import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/repository_providers.dart';
import '../services/notification_service.dart';

/// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  final service = NotificationService(repository: repository);
  
  // Register default channel handlers
  service.registerChannelHandler(NotificationChannel.inApp, InAppNotificationHandler());
  service.registerChannelHandler(NotificationChannel.email, EmailNotificationHandler());
  service.registerChannelHandler(NotificationChannel.push, PushNotificationHandler());
  
  return service;
});

/// Provider for member notifications stream
final memberNotificationsProvider = StreamProvider.family<List<Notification>, String>((ref, memberId) {
  final service = ref.watch(notificationServiceProvider);
  return service.streamNotifications(memberId);
});

/// Provider for unread notifications count
final unreadNotificationsCountProvider = FutureProvider.family<int, String>((ref, memberId) async {
  final service = ref.watch(notificationServiceProvider);
  return await service.getUnreadCount(memberId);
});

/// Provider for notification preferences
final notificationPreferencesProvider = FutureProvider.family<NotificationPreferences, String>((ref, memberId) async {
  final service = ref.watch(notificationServiceProvider);
  return await service.getNotificationPreferences(memberId);
});

/// State notifier for managing notification preferences
class NotificationPreferencesNotifier extends StateNotifier<AsyncValue<NotificationPreferences>> {
  final NotificationService _service;
  final String _memberId;

  NotificationPreferencesNotifier(this._service, this._memberId) : super(const AsyncValue.loading()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final preferences = await _service.getNotificationPreferences(_memberId);
      state = AsyncValue.data(preferences);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updatePreferences(NotificationPreferences preferences) async {
    state = const AsyncValue.loading();
    try {
      await _service.saveNotificationPreferences(preferences);
      state = AsyncValue.data(preferences);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> toggleEventReminders(bool enabled) async {
    final currentPrefs = state.value;
    if (currentPrefs != null) {
      final updatedPrefs = currentPrefs.copyWith(
        eventReminders: enabled,
        updatedAt: DateTime.now(),
      );
      await updatePreferences(updatedPrefs);
    }
  }

  Future<void> toggleDeadlineAlerts(bool enabled) async {
    final currentPrefs = state.value;
    if (currentPrefs != null) {
      final updatedPrefs = currentPrefs.copyWith(
        deadlineAlerts: enabled,
        updatedAt: DateTime.now(),
      );
      await updatePreferences(updatedPrefs);
    }
  }

  Future<void> toggleResultAnnouncements(bool enabled) async {
    final currentPrefs = state.value;
    if (currentPrefs != null) {
      final updatedPrefs = currentPrefs.copyWith(
        resultAnnouncements: enabled,
        updatedAt: DateTime.now(),
      );
      await updatePreferences(updatedPrefs);
    }
  }

  Future<void> toggleLeaderboardUpdates(bool enabled) async {
    final currentPrefs = state.value;
    if (currentPrefs != null) {
      final updatedPrefs = currentPrefs.copyWith(
        leaderboardUpdates: enabled,
        updatedAt: DateTime.now(),
      );
      await updatePreferences(updatedPrefs);
    }
  }

  Future<void> updatePreferredChannels(List<NotificationChannel> channels) async {
    final currentPrefs = state.value;
    if (currentPrefs != null) {
      final updatedPrefs = currentPrefs.copyWith(
        preferredChannels: channels,
        updatedAt: DateTime.now(),
      );
      await updatePreferences(updatedPrefs);
    }
  }
}

/// Provider for notification preferences state notifier
final notificationPreferencesNotifierProvider = StateNotifierProvider.family<NotificationPreferencesNotifier, AsyncValue<NotificationPreferences>, String>((ref, memberId) {
  final service = ref.watch(notificationServiceProvider);
  return NotificationPreferencesNotifier(service, memberId);
});

/// Provider for marking notifications as read
final markNotificationAsReadProvider = FutureProvider.family<void, String>((ref, notificationId) async {
  final service = ref.watch(notificationServiceProvider);
  await service.markAsRead(notificationId);
  
  // Invalidate related providers to refresh UI
  ref.invalidate(unreadNotificationsCountProvider);
});

/// Provider for marking all notifications as read
final markAllNotificationsAsReadProvider = FutureProvider.family<void, String>((ref, memberId) async {
  final service = ref.watch(notificationServiceProvider);
  await service.markAllAsRead(memberId);
  
  // Invalidate related providers to refresh UI
  ref.invalidate(unreadNotificationsCountProvider);
  ref.invalidate(memberNotificationsProvider);
});

/// Provider for processing scheduled notifications (for background tasks)
final processScheduledNotificationsProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  await service.processScheduledNotifications();
});