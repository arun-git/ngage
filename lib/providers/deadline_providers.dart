import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/deadline_service.dart';
import '../services/notification_service.dart';
import '../repositories/event_repository.dart';
import '../repositories/submission_repository.dart';
import '../repositories/member_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/repository_providers.dart';
import '../models/event.dart';
import 'notification_providers.dart';

/// Provider for the notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final notificationRepository = ref.watch(notificationRepositoryProvider);
  return NotificationService(repository: notificationRepository);
});

/// Provider for the deadline service
final deadlineServiceProvider = Provider<DeadlineService>((ref) {
  final eventRepository = ref.watch(eventRepositoryProvider);
  final submissionRepository = ref.watch(submissionRepositoryProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  
  return DeadlineService(
    eventRepository,
    submissionRepository,
    notificationService,
  );
});

/// Provider for event repository
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository();
});

/// Provider for submission repository
final submissionRepositoryProvider = Provider<SubmissionRepository>((ref) {
  return SubmissionRepository();
});

/// Provider for member repository
final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository();
});

/// Provider to get deadline status for a specific event
final eventDeadlineStatusProvider = Provider.family<DeadlineStatus, String>((ref, eventId) {
  final deadlineService = ref.watch(deadlineServiceProvider);
  // This would need to be implemented with proper state management
  // For now, returning a default value
  return DeadlineStatus.normal;
});

/// Provider to get time remaining for a specific event
final eventTimeRemainingProvider = Provider.family<Duration?, String>((ref, eventId) {
  final deadlineService = ref.watch(deadlineServiceProvider);
  // This would need to be implemented with proper state management
  // For now, returning null
  return null;
});

/// Provider to start/stop deadline monitoring
final deadlineMonitoringProvider = StateNotifierProvider<DeadlineMonitoringNotifier, bool>((ref) {
  final deadlineService = ref.watch(deadlineServiceProvider);
  return DeadlineMonitoringNotifier(deadlineService);
});

/// State notifier for deadline monitoring
class DeadlineMonitoringNotifier extends StateNotifier<bool> {
  final DeadlineService _deadlineService;

  DeadlineMonitoringNotifier(this._deadlineService) : super(false);

  /// Start deadline monitoring
  void startMonitoring() {
    if (!state) {
      _deadlineService.startDeadlineMonitoring();
      state = true;
    }
  }

  /// Stop deadline monitoring
  void stopMonitoring() {
    if (state) {
      _deadlineService.stopDeadlineMonitoring();
      state = false;
    }
  }

  /// Schedule deadline enforcement for an event
  Future<void> scheduleEventDeadline(Event event) async {
    await _deadlineService.scheduleEventDeadlineEnforcement(event);
  }

  /// Cancel deadline enforcement for an event
  void cancelEventDeadline(String eventId) {
    _deadlineService.cancelEventDeadlineEnforcement(eventId);
  }

  @override
  void dispose() {
    _deadlineService.dispose();
    super.dispose();
  }
}

/// Provider for deadline countdown text
final deadlineCountdownProvider = Provider.family<String, Event>((ref, event) {
  final deadlineService = ref.watch(deadlineServiceProvider);
  return deadlineService.getCountdownText(event);
});

/// Provider for deadline status
final deadlineStatusProvider = Provider.family<DeadlineStatus, Event>((ref, event) {
  final deadlineService = ref.watch(deadlineServiceProvider);
  return deadlineService.getDeadlineStatus(event);
});

/// Provider to check if deadline has passed
final hasDeadlinePassedProvider = Provider.family<bool, Event>((ref, event) {
  final deadlineService = ref.watch(deadlineServiceProvider);
  return deadlineService.hasDeadlinePassed(event);
});