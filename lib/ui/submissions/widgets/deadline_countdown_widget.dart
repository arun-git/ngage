import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/event.dart';
import '../../../services/deadline_enforcement_service.dart';

/// Widget that displays a countdown timer to submission deadline
class DeadlineCountdownWidget extends StatefulWidget {
  final Event event;
  final bool showIcon;
  final bool compact;

  const DeadlineCountdownWidget({
    super.key,
    required this.event,
    this.showIcon = true,
    this.compact = false,
  });

  @override
  State<DeadlineCountdownWidget> createState() =>
      _DeadlineCountdownWidgetState();
}

class _DeadlineCountdownWidgetState extends State<DeadlineCountdownWidget> {
  Timer? _timer;
  Duration? _timeRemaining;
  DeadlineStatus _status = DeadlineStatus.normal;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    if (widget.event.submissionDeadline == null) {
      setState(() {
        _timeRemaining = null;
        _status = DeadlineStatus.noDeadline;
      });
      return;
    }

    final now = DateTime.now();
    final deadline = widget.event.submissionDeadline!;

    if (now.isAfter(deadline)) {
      setState(() {
        _timeRemaining = Duration.zero;
        _status = DeadlineStatus.passed;
      });
      _timer?.cancel();
      return;
    }

    final timeRemaining = deadline.difference(now);

    setState(() {
      _timeRemaining = timeRemaining;
      _status = _getDeadlineStatus(timeRemaining);
    });
  }

  DeadlineStatus _getDeadlineStatus(Duration timeRemaining) {
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

  @override
  Widget build(BuildContext context) {
    if (_status == DeadlineStatus.noDeadline) {
      return const SizedBox.shrink();
    }

    final statusInfo = _getStatusInfo(context);

    if (widget.compact) {
      return _buildCompactView(statusInfo);
    } else {
      return _buildFullView(statusInfo);
    }
  }

  Widget _buildCompactView(_StatusInfo statusInfo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusInfo.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusInfo.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showIcon) ...[
            Icon(
              statusInfo.icon,
              size: 14,
              color: statusInfo.color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            _formatTimeRemaining(),
            style: TextStyle(
              color: statusInfo.color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullView(_StatusInfo statusInfo) {
    return Card(
      color: statusInfo.color.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.showIcon) ...[
                  Icon(
                    statusInfo.icon,
                    color: statusInfo.color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  'Submission Deadline',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: statusInfo.color,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatTimeRemaining(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: statusInfo.color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Until ${_formatDeadlineDate()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: statusInfo.color.withOpacity(0.8),
                  ),
            ),
            if (_status == DeadlineStatus.critical ||
                _status == DeadlineStatus.urgent) ...[
              const SizedBox(height: 8),
              Text(
                statusInfo.message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: statusInfo.color,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimeRemaining() {
    if (_timeRemaining == null) return 'No deadline';
    if (_timeRemaining!.isNegative || _timeRemaining == Duration.zero) {
      return 'Deadline passed';
    }

    final days = _timeRemaining!.inDays;
    final hours = _timeRemaining!.inHours % 24;
    final minutes = _timeRemaining!.inMinutes % 60;
    final seconds = _timeRemaining!.inSeconds % 60;

    if (days > 0) {
      return '$days day${days == 1 ? '' : 's'}, $hours hour${hours == 1 ? '' : 's'}';
    } else if (hours > 0) {
      return '$hours hour${hours == 1 ? '' : 's'}, $minutes minute${minutes == 1 ? '' : 's'}';
    } else if (minutes > 0) {
      return '$minutes minute${minutes == 1 ? '' : 's'}';
    } else {
      return '$seconds second${seconds == 1 ? '' : 's'}';
    }
  }

  String _formatDeadlineDate() {
    if (widget.event.submissionDeadline == null) return '';

    final deadline = widget.event.submissionDeadline!;
    final now = DateTime.now();

    // Format based on how far away the deadline is
    if (deadline.day == now.day &&
        deadline.month == now.month &&
        deadline.year == now.year) {
      // Same day - show time only
      return '${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}';
    } else {
      // Different day - show date and time
      return '${deadline.day}/${deadline.month} at ${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}';
    }
  }

  _StatusInfo _getStatusInfo(BuildContext context) {
    final theme = Theme.of(context);

    switch (_status) {
      case DeadlineStatus.noDeadline:
        return _StatusInfo(
          icon: Icons.schedule,
          color: theme.colorScheme.outline,
          message: 'No deadline set',
        );
      case DeadlineStatus.normal:
        return _StatusInfo(
          icon: Icons.schedule,
          color: theme.colorScheme.primary,
          message: 'Plenty of time remaining',
        );
      case DeadlineStatus.approaching:
        return _StatusInfo(
          icon: Icons.schedule,
          color: Colors.blue,
          message: 'Deadline approaching',
        );
      case DeadlineStatus.warning:
        return _StatusInfo(
          icon: Icons.warning,
          color: Colors.orange,
          message: 'Submit soon to avoid missing the deadline',
        );
      case DeadlineStatus.urgent:
        return _StatusInfo(
          icon: Icons.warning_amber,
          color: Colors.deepOrange,
          message: 'Urgent: Submit immediately!',
        );
      case DeadlineStatus.critical:
        return _StatusInfo(
          icon: Icons.error,
          color: Colors.red,
          message: 'Critical: Only minutes remaining!',
        );
      case DeadlineStatus.passed:
        return _StatusInfo(
          icon: Icons.block,
          color: Colors.grey,
          message: 'Deadline has passed',
        );
    }
  }
}

class _StatusInfo {
  final IconData icon;
  final Color color;
  final String message;

  _StatusInfo({
    required this.icon,
    required this.color,
    required this.message,
  });
}
