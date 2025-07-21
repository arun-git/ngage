import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/error_types.dart';
import '../../services/error_reporting_service.dart';
import 'error_report_dialog.dart';

/// Generic error widget for displaying errors to users
class ErrorDisplayWidget extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final String? context;
  final VoidCallback? onRetry;
  final bool showReportButton;
  final bool showDetails;

  const ErrorDisplayWidget({
    super.key,
    required this.error,
    this.stackTrace,
    this.context,
    this.onRetry,
    this.showReportButton = true,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final errorInfo = _getErrorInfo(error);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              errorInfo.icon,
              size: 48,
              color: errorInfo.color,
            ),
            const SizedBox(height: 16),
            Text(
              errorInfo.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: errorInfo.color,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            SelectableText(
              errorInfo.message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (showDetails && error.toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('Technical Details'),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      error.toString(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onRetry != null) ...[
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  const SizedBox(width: 8),
                ],
                if (showReportButton)
                  Consumer(
                    builder: (context, ref, child) {
                      return OutlinedButton.icon(
                        onPressed: () => _showReportDialog(context, ref),
                        icon: const Icon(Icons.bug_report),
                        label: const Text('Report Issue'),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => ErrorReportDialog(
        error: error,
        stackTrace: stackTrace,
        context: this.context,
      ),
    );
  }

  _ErrorInfo _getErrorInfo(Object error) {
    if (error is NgageException) {
      return _getExceptionInfo(error);
    }

    return _ErrorInfo(
      icon: Icons.error_outline,
      color: Colors.red,
      title: 'Unexpected Error',
      message: 'An unexpected error occurred. Please try again later.',
    );
  }

  _ErrorInfo _getExceptionInfo(NgageException exception) {
    if (exception is AuthenticationException) {
      return _ErrorInfo(
        icon: Icons.lock_outline,
        color: Colors.orange,
        title: 'Authentication Error',
        message: exception.userMessage ??
            'Please check your credentials and try again.',
      );
    } else if (exception is AuthorizationException) {
      return _ErrorInfo(
        icon: Icons.security,
        color: Colors.red,
        title: 'Access Denied',
        message: exception.userMessage ??
            'You don\'t have permission to perform this action.',
      );
    } else if (exception is ValidationException) {
      return _ErrorInfo(
        icon: Icons.warning_outlined,
        color: Colors.amber,
        title: 'Validation Error',
        message:
            exception.userMessage ?? 'Please check your input and try again.',
      );
    } else if (exception is NetworkException) {
      return _ErrorInfo(
        icon: Icons.wifi_off,
        color: Colors.blue,
        title: 'Connection Error',
        message:
            exception.userMessage ?? 'Please check your internet connection.',
      );
    } else if (exception is StorageException) {
      return _ErrorInfo(
        icon: Icons.cloud_off,
        color: Colors.purple,
        title: 'Storage Error',
        message:
            exception.userMessage ?? 'File operation failed. Please try again.',
      );
    } else if (exception is DatabaseException) {
      return _ErrorInfo(
        icon: Icons.storage,
        color: Colors.indigo,
        title: 'Database Error',
        message:
            exception.userMessage ?? 'Data operation failed. Please try again.',
      );
    } else {
      return _ErrorInfo(
        icon: Icons.error_outline,
        color: Colors.red,
        title: 'Error',
        message: exception.userMessage ?? exception.message,
      );
    }
  }
}

class _ErrorInfo {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  _ErrorInfo({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });
}

/// Compact error widget for inline display
class CompactErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const CompactErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final message = _getErrorMessage(error);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              message,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 14,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              iconSize: 20,
              color: Colors.red[700],
              tooltip: 'Retry',
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
              iconSize: 20,
              color: Colors.red[700],
              tooltip: 'Dismiss',
            ),
          ],
        ],
      ),
    );
  }

  String _getErrorMessage(Object error) {
    if (error is NgageException && error.userMessage != null) {
      return error.userMessage!;
    }
    return 'An error occurred. Please try again.';
  }
}

/// Error boundary widget that catches and displays errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;
  final void Function(Object error, StackTrace stackTrace)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!, _stackTrace);
      }

      return ErrorDisplayWidget(
        error: _error!,
        stackTrace: _stackTrace,
        onRetry: () {
          setState(() {
            _error = null;
            _stackTrace = null;
          });
        },
      );
    }

    return widget.child;
  }

  void _handleError(Object error, StackTrace stackTrace) {
    setState(() {
      _error = error;
      _stackTrace = stackTrace;
    });

    widget.onError?.call(error, stackTrace);
  }
}

/// Snackbar for showing error messages
class ErrorSnackBar {
  static void show(
    BuildContext context,
    Object error, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onRetry,
  }) {
    final message = _getErrorMessage(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  static String _getErrorMessage(Object error) {
    if (error is NgageException && error.userMessage != null) {
      return error.userMessage!;
    }
    return 'An error occurred';
  }
}
