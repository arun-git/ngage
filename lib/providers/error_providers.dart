import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/error_handler.dart';
import '../utils/logger.dart';
import '../services/error_reporting_service.dart';

/// Provider for the error handler instance
final errorHandlerProvider = Provider<ErrorHandler>((ref) {
  return ErrorHandler();
});

/// Provider for the logger instance
final loggerProvider = Provider<Logger>((ref) {
  return Logger();
});

/// Provider for the error reporting service
final errorReportingServiceProvider = Provider<ErrorReportingService>((ref) {
  return ErrorReportingService();
});

/// Provider for recent log entries
final recentLogsProvider = Provider<List<LogEntry>>((ref) {
  final logger = ref.watch(loggerProvider);
  return logger.recentLogs;
});

/// Provider for log stream
final logStreamProvider = StreamProvider<LogEntry>((ref) {
  final logger = ref.watch(loggerProvider);
  return logger.logStream;
});

/// Provider for error report statistics
final errorReportStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final errorReportingService = ref.watch(errorReportingServiceProvider);
  return await errorReportingService.getErrorReportStatistics();
});

/// Provider for user error reports
final userErrorReportsProvider = FutureProvider.family<List<ErrorReport>, String>((ref, userId) async {
  final errorReportingService = ref.watch(errorReportingServiceProvider);
  return await errorReportingService.getUserErrorReports(userId);
});

/// Provider for error reports by status
final errorReportsByStatusProvider = StreamProvider.family<List<ErrorReport>, ErrorReportStatus>((ref, status) {
  final errorReportingService = ref.watch(errorReportingServiceProvider);
  return errorReportingService.getErrorReportsByStatus(status);
});

/// State notifier for managing application-wide error state
class ErrorStateNotifier extends StateNotifier<ErrorState> {
  final ErrorHandler _errorHandler;
  final Logger _logger;

  ErrorStateNotifier(this._errorHandler, this._logger) : super(const ErrorState());

  /// Handle an error and update state
  Future<void> handleError(
    Object error,
    StackTrace stackTrace, {
    String? context,
    Map<String, dynamic>? additionalData,
    bool showUserMessage = true,
  }) async {
    state = state.copyWith(
      hasError: true,
      lastError: error,
      lastErrorTime: DateTime.now(),
      errorContext: context,
    );

    await _errorHandler.handleError(
      error,
      stackTrace,
      context: context,
      additionalData: additionalData,
      showUserMessage: showUserMessage,
    );
  }

  /// Clear error state
  void clearError() {
    state = const ErrorState();
  }

  /// Get error statistics
  Map<String, dynamic> getErrorStatistics() {
    return {
      'hasError': state.hasError,
      'lastErrorTime': state.lastErrorTime?.toIso8601String(),
      'errorContext': state.errorContext,
      'totalErrors': state.errorCount,
    };
  }
}

/// Error state model
class ErrorState {
  final bool hasError;
  final Object? lastError;
  final DateTime? lastErrorTime;
  final String? errorContext;
  final int errorCount;

  const ErrorState({
    this.hasError = false,
    this.lastError,
    this.lastErrorTime,
    this.errorContext,
    this.errorCount = 0,
  });

  ErrorState copyWith({
    bool? hasError,
    Object? lastError,
    DateTime? lastErrorTime,
    String? errorContext,
    int? errorCount,
  }) {
    return ErrorState(
      hasError: hasError ?? this.hasError,
      lastError: lastError ?? this.lastError,
      lastErrorTime: lastErrorTime ?? this.lastErrorTime,
      errorContext: errorContext ?? this.errorContext,
      errorCount: errorCount ?? (this.errorCount + (hasError == true ? 1 : 0)),
    );
  }
}

/// Provider for error state notifier
final errorStateProvider = StateNotifierProvider<ErrorStateNotifier, ErrorState>((ref) {
  final errorHandler = ref.watch(errorHandlerProvider);
  final logger = ref.watch(loggerProvider);
  return ErrorStateNotifier(errorHandler, logger);
});

/// Provider for checking if there are any active errors
final hasActiveErrorProvider = Provider<bool>((ref) {
  final errorState = ref.watch(errorStateProvider);
  return errorState.hasError;
});

/// Provider for the last error message
final lastErrorMessageProvider = Provider<String?>((ref) {
  final errorState = ref.watch(errorStateProvider);
  if (errorState.lastError != null) {
    return errorState.lastError.toString();
  }
  return null;
});