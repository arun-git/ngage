import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/event.dart';
import '../../../services/deadline_service.dart';

/// Widget that displays a countdown timer for submission deadlines
class DeadlineCountdownWidget extends StatefulWidget {
  final Event event;
  final DeadlineService deadlineService;
  final TextStyle? textStyle;
  final bool showIcon;
  final bool compact;

  const DeadlineCountdownWidget({
    super.key,
    required this.event,
    required this.deadlineService,
    this.textStyle,
    this.showIcon = true,
    this.compact = false,
  });

  @override
  State<DeadlineCountdownWidget> createState() => _DeadlineCountdownWidgetState();
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
    if (mounted) {
      setState(() {
        _timeRemaining = widget.deadlineService.getTimeUntilDeadline(widget.event);
        _status = widget.deadlineService.getDeadlineStatus(widget.event);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.event.submissionDeadline == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final countdownText = widget.deadlineService.formatTimeRemaining(_timeRemaining);
    
    Color textColor;
    IconData icon;
    
    switch (_status) {
      case DeadlineStatus.passed:
        textColor = theme.colorScheme.error;
        icon = Icons.schedule_outlined;
        break;
      case DeadlineStatus.critical:
        textColor = theme.colorScheme.error;
        icon = Icons.warning_amber_outlined;
        break;
      case DeadlineStatus.urgent:
        textColor = Colors.orange;
        icon = Icons.access_time_outlined;
        break;
      case DeadlineStatus.warning:
        textColor = Colors.amber.shade700;
        icon = Icons.schedule_outlined;
        break;
      case DeadlineStatus.approaching:
        textColor = theme.colorScheme.primary;
        icon = Icons.schedule_outlined;
        break;
      default:
        textColor = theme.colorScheme.onSurface;
        icon = Icons.schedule_outlined;
    }

    if (widget.compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showIcon) ...[
            Icon(
              icon,
              size: 16,
              color: textColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            countdownText,
            style: widget.textStyle?.copyWith(color: textColor) ??
                theme.textTheme.bodySmall?.copyWith(color: textColor),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getBackgroundColor(theme),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: textColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showIcon) ...[
            Icon(
              icon,
              size: 20,
              color: textColor,
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Submission Deadline',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: textColor.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                countdownText,
                style: widget.textStyle?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ) ?? theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(ThemeData theme) {
    switch (_status) {
      case DeadlineStatus.passed:
        return theme.colorScheme.errorContainer.withOpacity(0.1);
      case DeadlineStatus.critical:
        return theme.colorScheme.errorContainer.withOpacity(0.1);
      case DeadlineStatus.urgent:
        return Colors.orange.withOpacity(0.1);
      case DeadlineStatus.warning:
        return Colors.amber.withOpacity(0.1);
      case DeadlineStatus.approaching:
        return theme.colorScheme.primaryContainer.withOpacity(0.1);
      default:
        return theme.colorScheme.surfaceVariant.withOpacity(0.3);
    }
  }
}

/// Simple text-only countdown widget
class SimpleCountdownText extends StatefulWidget {
  final Event event;
  final DeadlineService deadlineService;
  final TextStyle? style;

  const SimpleCountdownText({
    super.key,
    required this.event,
    required this.deadlineService,
    this.style,
  });

  @override
  State<SimpleCountdownText> createState() => _SimpleCountdownTextState();
}

class _SimpleCountdownTextState extends State<SimpleCountdownText> {
  Timer? _timer;
  String _countdownText = '';

  @override
  void initState() {
    super.initState();
    _updateText();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateText();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateText() {
    if (mounted) {
      setState(() {
        _countdownText = widget.deadlineService.getCountdownText(widget.event);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _countdownText,
      style: widget.style,
    );
  }
}

/// Deadline status indicator chip
class DeadlineStatusChip extends StatelessWidget {
  final Event event;
  final DeadlineService deadlineService;

  const DeadlineStatusChip({
    super.key,
    required this.event,
    required this.deadlineService,
  });

  @override
  Widget build(BuildContext context) {
    if (event.submissionDeadline == null) {
      return const SizedBox.shrink();
    }

    final status = deadlineService.getDeadlineStatus(event);
    final theme = Theme.of(context);

    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case DeadlineStatus.passed:
        backgroundColor = theme.colorScheme.errorContainer;
        textColor = theme.colorScheme.onErrorContainer;
        label = 'Deadline Passed';
        break;
      case DeadlineStatus.critical:
        backgroundColor = theme.colorScheme.errorContainer;
        textColor = theme.colorScheme.onErrorContainer;
        label = 'Critical';
        break;
      case DeadlineStatus.urgent:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        label = 'Urgent';
        break;
      case DeadlineStatus.warning:
        backgroundColor = Colors.amber.shade100;
        textColor = Colors.amber.shade800;
        label = 'Warning';
        break;
      case DeadlineStatus.approaching:
        backgroundColor = theme.colorScheme.primaryContainer;
        textColor = theme.colorScheme.onPrimaryContainer;
        label = 'Approaching';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Chip(
      label: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: backgroundColor,
      side: BorderSide.none,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}