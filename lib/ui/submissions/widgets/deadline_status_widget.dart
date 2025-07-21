import 'package:flutter/material.dart';
import '../../../models/event.dart';
import '../../../services/deadline_enforcement_service.dart';

/// Widget that shows the deadline status with appropriate styling
class DeadlineStatusWidget extends StatelessWidget {
  final Event event;
  final bool showLabel;
  final bool showTime;

  const DeadlineStatusWidget({
    super.key,
    required this.event,
    this.showLabel = true,
    this.showTime = false,
  });

  @override
  Widget build(BuildContext context) {
    if (event.submissionDeadline == null) {
      return const SizedBox.shrink();
    }

    final status = _getDeadlineStatus();
    final statusInfo = _getStatusInfo(context, status);
    final timeRemaining = _getTimeRemaining();

    if (showLabel) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: statusInfo.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusInfo.color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              statusInfo.icon,
              size: 16,
              color: statusInfo.color,
            ),
            const SizedBox(width: 4),
            Text(
              showTime ? _formatTimeRemaining(timeRemaining) : statusInfo.label,
              style: TextStyle(
                color: statusInfo.color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    } else {
      return Icon(
        statusInfo.icon,
        color: statusInfo.color,
        size: 20,
      );
    }
  }

  DeadlineStatus _getDeadlineStatus() {
    if (event.submissionDeadline == null) {
      return DeadlineStatus.noDeadline;
    }

    final now = DateTime.now();
    final deadline = event.submissionDeadline!;
    
    if (now.isAfter(deadline)) {
      return DeadlineStatus.passed;
    }

    final timeRemaining = deadline.difference(now);
    
    if (timeRemaining.inMinutes <= 15) {
      return DeadlineStatus.critical;
    } else if (timeRemaining.inHours <= 1) {
      return DeadlineStatus.urgent;
    } else if (timeRemaining.inHours <= 4) {
      return DeadlineStatus.warning;
    } else if (timeRemaining.inHours <= 24) {
      return DeadlineStatus.approaching;
    } else {
      return DeadlineStatus.normal;
    }
  }

  Duration? _getTimeRemaining() {
    if (event.submissionDeadline == null) return null;
    
    final now = DateTime.now();
    final deadline = event.submissionDeadline!;
    
    if (now.isAfter(deadline)) return Duration.zero;
    
    return deadline.difference(now);
  }

  String _formatTimeRemaining(Duration? timeRemaining) {
    if (timeRemaining == null) return 'No deadline';
    if (timeRemaining.isNegative || timeRemaining == Duration.zero) {
      return 'Passed';
    }

    final days = timeRemaining.inDays;
    final hours = timeRemaining.inHours % 24;
    final minutes = timeRemaining.inMinutes % 60;

    if (days > 0) {
      return '${days}d ${hours}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  _StatusInfo _getStatusInfo(BuildContext context, DeadlineStatus status) {
    final theme = Theme.of(context);
    
    switch (status) {
      case DeadlineStatus.noDeadline:
        return _StatusInfo(
          label: 'No Deadline',
          icon: Icons.schedule,
          color: theme.colorScheme.outline,
        );
      case DeadlineStatus.normal:
        return _StatusInfo(
          label: 'On Track',
          icon: Icons.schedule,
          color: theme.colorScheme.primary,
        );
      case DeadlineStatus.approaching:
        return _StatusInfo(
          label: 'Approaching',
          icon: Icons.schedule,
          color: Colors.blue,
        );
      case DeadlineStatus.warning:
        return _StatusInfo(
          label: 'Warning',
          icon: Icons.warning,
          color: Colors.orange,
        );
      case DeadlineStatus.urgent:
        return _StatusInfo(
          label: 'Urgent',
          icon: Icons.warning_amber,
          color: Colors.deepOrange,
        );
      case DeadlineStatus.critical:
        return _StatusInfo(
          label: 'Critical',
          icon: Icons.error,
          color: Colors.red,
        );
      case DeadlineStatus.passed:
        return _StatusInfo(
          label: 'Passed',
          icon: Icons.block,
          color: Colors.grey,
        );
    }
  }
}

class _StatusInfo {
  final String label;
  final IconData icon;
  final Color color;

  _StatusInfo({
    required this.label,
    required this.icon,
    required this.color,
  });
}