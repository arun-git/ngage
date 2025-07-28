import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/deadline_enforcement_service.dart';
import '../services/notification_service.dart';
import '../repositories/repository_providers.dart';

/// Provider for the notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Provider for the deadline enforcement service
final deadlineEnforcementServiceProvider =
    Provider<DeadlineEnforcementService>((ref) {
  final eventRepository = ref.watch(eventRepositoryProvider);
  final submissionRepository = ref.watch(submissionRepositoryProvider);
  final notificationService = ref.watch(notificationServiceProvider);

  return DeadlineEnforcementService(
    eventRepository,
    submissionRepository,
    notificationService,
  );
});

/// Provider to get deadline status for a specific event
final eventDeadlineStatusProvider =
    Provider.family<DeadlineStatus, String>((ref, eventId) {
  // This would need to be implemented with proper state management
  // For now, returning a default value
  return DeadlineStatus.normal;
});

/// Provider to get time remaining for a specific event
final eventTimeRemainingProvider =
    Provider.family<Duration?, String>((ref, eventId) {
  // This would need to be implemented with proper state management
  // For now, returning null
  return null;
});

/// Provider to start/stop deadline monitoring
final deadlineMonitoringProvider =
    StateNotifierProvider<DeadlineMonitoringNotifier, DeadlineMonitoringState>(
        (ref) {
  final deadlineService = ref.watch(deadlineEnforcementServiceProvider);
  return DeadlineMonitoringNotifier(deadlineService);
});

/// State notifier for deadline monitoring
class DeadlineMonitoringNotifier
    extends StateNotifier<DeadlineMonitoringState> {
  final DeadlineEnforcementService _deadlineService;

  DeadlineMonitoringNotifier(this._deadlineService)
      : super(DeadlineMonitoringState.initial());

  /// Start deadline monitoring
  Future<void> startMonitoring() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _deadlineService.startDeadlineMonitoring();
      state = state.copyWith(
        isLoading: false,
        isMonitoring: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Stop deadline monitoring
  void stopMonitoring() {
    _deadlineService.stopDeadlineMonitoring();
    state = state.copyWith(isMonitoring: false);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _deadlineService.dispose();
    super.dispose();
  }
}

/// State class for deadline monitoring
class DeadlineMonitoringState {
  final bool isLoading;
  final bool isMonitoring;
  final String? error;

  const DeadlineMonitoringState({
    required this.isLoading,
    required this.isMonitoring,
    this.error,
  });

  factory DeadlineMonitoringState.initial() {
    return const DeadlineMonitoringState(
      isLoading: false,
      isMonitoring: false,
    );
  }

  DeadlineMonitoringState copyWith({
    bool? isLoading,
    bool? isMonitoring,
    String? error,
  }) {
    return DeadlineMonitoringState(
      isLoading: isLoading ?? this.isLoading,
      isMonitoring: isMonitoring ?? this.isMonitoring,
      error: error ?? this.error,
    );
  }
}
