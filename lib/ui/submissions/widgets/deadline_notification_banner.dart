import 'package:flutter/material.dart';
import '../../../models/event.dart';
import '../../../services/deadline_service.dart';
import 'deadline_countdown_widget.dart';

/// Banner widget that shows deadline notifications and warnings
class DeadlineNotificationBanner extends StatelessWidget {
  final Event event;
  final DeadlineService deadlineService;
  final VoidCallback? onSubmitPressed;
  final VoidCallback? onDismiss;
  final bool dismissible;

  const DeadlineNotificationBanner({
    super.key,
    required this.event,
    required this.deadlineService,
    this.onSubmitPressed,
    this.onDismiss,
    this.dismissible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (event.submissionDeadline == null) {
      return const SizedBox.shrink();
    }

    final status = deadlineService.getDeadlineStatus(event);
    
    // Only show banner for urgent statuses
    if (!status.requiresAttention && status != DeadlineStatus.passed) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getBackgroundColor(status, theme),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getBorderColor(status, theme),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    _getIcon(status),
                    color: _getIconColor(status, theme),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTitle(status),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: _getTextColor(status, theme),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getMessage(status, event.title),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _getTextColor(status, theme).withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (dismissible && onDismiss != null)
                    IconButton(
                      onPressed: onDismiss,
                      icon: Icon(
                        Icons.close,
                        color: _getTextColor(status, theme).withOpacity(0.6),
                      ),
                      iconSize: 20,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DeadlineCountdownWidget(
                      event: event,
                      deadlineService: deadlineService,
                      compact: true,
                      showIcon: false,
                      textStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: _getTextColor(status, theme),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (onSubmitPressed != null && status != DeadlineStatus.passed)
                    ElevatedButton(
                      onPressed: onSubmitPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getButtonColor(status, theme),
                        foregroundColor: _getButtonTextColor(status, theme),
                        elevation: 0,
                      ),
                      child: const Text('Submit Now'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(DeadlineStatus status) {
    switch (status) {
      case DeadlineStatus.passed:
        return Icons.error_outline;
      case DeadlineStatus.critical:
        return Icons.warning_amber_outlined;
      case DeadlineStatus.urgent:
        return Icons.access_time_outlined;
      case DeadlineStatus.warning:
        return Icons.schedule_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _getTitle(DeadlineStatus status) {
    switch (status) {
      case DeadlineStatus.passed:
        return 'Deadline Passed';
      case DeadlineStatus.critical:
        return 'Critical: Deadline Very Soon!';
      case DeadlineStatus.urgent:
        return 'Urgent: Deadline Approaching';
      case DeadlineStatus.warning:
        return 'Warning: Deadline Today';
      default:
        return 'Deadline Reminder';
    }
  }

  String _getMessage(DeadlineStatus status, String eventTitle) {
    switch (status) {
      case DeadlineStatus.passed:
        return 'The submission deadline for "$eventTitle" has passed. No more submissions will be accepted.';
      case DeadlineStatus.critical:
        return 'The submission deadline for "$eventTitle" is in less than 15 minutes. Submit your entry now!';
      case DeadlineStatus.urgent:
        return 'The submission deadline for "$eventTitle" is in less than 1 hour. Don\'t forget to submit!';
      case DeadlineStatus.warning:
        return 'The submission deadline for "$eventTitle" is in less than 4 hours. Make sure to submit your entry.';
      default:
        return 'Don\'t forget to submit your entry for "$eventTitle" before the deadline.';
    }
  }

  Color _getBackgroundColor(DeadlineStatus status, ThemeData theme) {
    switch (status) {
      case DeadlineStatus.passed:
        return theme.colorScheme.errorContainer.withOpacity(0.1);
      case DeadlineStatus.critical:
        return theme.colorScheme.errorContainer.withOpacity(0.1);
      case DeadlineStatus.urgent:
        return Colors.orange.withOpacity(0.1);
      case DeadlineStatus.warning:
        return Colors.amber.withOpacity(0.1);
      default:
        return theme.colorScheme.primaryContainer.withOpacity(0.1);
    }
  }

  Color _getBorderColor(DeadlineStatus status, ThemeData theme) {
    switch (status) {
      case DeadlineStatus.passed:
        return theme.colorScheme.error.withOpacity(0.3);
      case DeadlineStatus.critical:
        return theme.colorScheme.error.withOpacity(0.3);
      case DeadlineStatus.urgent:
        return Colors.orange.withOpacity(0.3);
      case DeadlineStatus.warning:
        return Colors.amber.withOpacity(0.3);
      default:
        return theme.colorScheme.primary.withOpacity(0.3);
    }
  }

  Color _getIconColor(DeadlineStatus status, ThemeData theme) {
    switch (status) {
      case DeadlineStatus.passed:
        return theme.colorScheme.error;
      case DeadlineStatus.critical:
        return theme.colorScheme.error;
      case DeadlineStatus.urgent:
        return Colors.orange;
      case DeadlineStatus.warning:
        return Colors.amber.shade700;
      default:
        return theme.colorScheme.primary;
    }
  }

  Color _getTextColor(DeadlineStatus status, ThemeData theme) {
    switch (status) {
      case DeadlineStatus.passed:
        return theme.colorScheme.error;
      case DeadlineStatus.critical:
        return theme.colorScheme.error;
      case DeadlineStatus.urgent:
        return Colors.orange.shade800;
      case DeadlineStatus.warning:
        return Colors.amber.shade800;
      default:
        return theme.colorScheme.primary;
    }
  }

  Color _getButtonColor(DeadlineStatus status, ThemeData theme) {
    switch (status) {
      case DeadlineStatus.critical:
        return theme.colorScheme.error;
      case DeadlineStatus.urgent:
        return Colors.orange;
      case DeadlineStatus.warning:
        return Colors.amber.shade700;
      default:
        return theme.colorScheme.primary;
    }
  }

  Color _getButtonTextColor(DeadlineStatus status, ThemeData theme) {
    switch (status) {
      case DeadlineStatus.critical:
        return theme.colorScheme.onError;
      case DeadlineStatus.urgent:
        return Colors.white;
      case DeadlineStatus.warning:
        return Colors.white;
      default:
        return theme.colorScheme.onPrimary;
    }
  }
}