import 'package:flutter/material.dart';
import '../../../models/event.dart';
import '../../../services/deadline_enforcement_service.dart';

/// Widget that shows deadline notifications and alerts
class DeadlineNotificationWidget extends StatelessWidget {
  final List<Event> events;
  final VoidCallback? onTap;

  const DeadlineNotificationWidget({
    super.key,
    required this.events,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final urgentEvents = _getUrgentEvents();
    
    if (urgentEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _getNotificationColor(urgentEvents).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getNotificationColor(urgentEvents).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getNotificationIcon(urgentEvents),
              color: _getNotificationColor(urgentEvents),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getNotificationTitle(urgentEvents),
                    style: TextStyle(
                      color: _getNotificationColor(urgentEvents),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getNotificationMessage(urgentEvents),
                    style: TextStyle(
                      color: _getNotificationColor(urgentEvents).withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: _getNotificationColor(urgentEvents),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  List<Event> _getUrgentEvents() {
    final now = DateTime.now();
    return events.where((event) {
      if (event.submissionDeadline == null) return false;
      
      final timeRemaining = event.submissionDeadline!.difference(now);
      if (timeRemaining.isNegative) return false;
      
      // Consider urgent if less than 4 hours remaining
      return timeRemaining.inHours <= 4;
    }).toList();
  }

  DeadlineStatus _getMostUrgentStatus(List<Event> urgentEvents) {
    if (urgentEvents.isEmpty) return DeadlineStatus.normal;
    
    final now = DateTime.now();
    DeadlineStatus mostUrgent = DeadlineStatus.normal;
    
    for (final event in urgentEvents) {
      if (event.submissionDeadline == null) continue;
      
      final timeRemaining = event.submissionDeadline!.difference(now);
      if (timeRemaining.isNegative) continue;
      
      DeadlineStatus status;
      if (timeRemaining.inMinutes <= 15) {
        status = DeadlineStatus.critical;
      } else if (timeRemaining.inHours <= 1) {
        status = DeadlineStatus.urgent;
      } else if (timeRemaining.inHours <= 4) {
        status = DeadlineStatus.warning;
      } else {
        status = DeadlineStatus.normal;
      }
      
      // Update most urgent status
      if (status.index > mostUrgent.index) {
        mostUrgent = status;
      }
    }
    
    return mostUrgent;
  }

  Color _getNotificationColor(List<Event> urgentEvents) {
    final status = _getMostUrgentStatus(urgentEvents);
    
    switch (status) {
      case DeadlineStatus.critical:
        return Colors.red;
      case DeadlineStatus.urgent:
        return Colors.deepOrange;
      case DeadlineStatus.warning:
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getNotificationIcon(List<Event> urgentEvents) {
    final status = _getMostUrgentStatus(urgentEvents);
    
    switch (status) {
      case DeadlineStatus.critical:
        return Icons.error;
      case DeadlineStatus.urgent:
        return Icons.warning_amber;
      case DeadlineStatus.warning:
        return Icons.warning;
      default:
        return Icons.schedule;
    }
  }

  String _getNotificationTitle(List<Event> urgentEvents) {
    final status = _getMostUrgentStatus(urgentEvents);
    final count = urgentEvents.length;
    
    switch (status) {
      case DeadlineStatus.critical:
        return count == 1 ? 'Critical Deadline!' : '$count Critical Deadlines!';
      case DeadlineStatus.urgent:
        return count == 1 ? 'Urgent Deadline' : '$count Urgent Deadlines';
      case DeadlineStatus.warning:
        return count == 1 ? 'Deadline Warning' : '$count Deadline Warnings';
      default:
        return count == 1 ? 'Upcoming Deadline' : '$count Upcoming Deadlines';
    }
  }

  String _getNotificationMessage(List<Event> urgentEvents) {
    if (urgentEvents.length == 1) {
      final event = urgentEvents.first;
      final timeRemaining = event.submissionDeadline!.difference(DateTime.now());
      return '${event.title} - ${_formatTimeRemaining(timeRemaining)} remaining';
    } else {
      return 'Multiple events have approaching deadlines';
    }
  }

  String _formatTimeRemaining(Duration timeRemaining) {
    if (timeRemaining.isNegative) return 'Passed';
    
    final hours = timeRemaining.inHours;
    final minutes = timeRemaining.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

/// Badge widget for showing deadline notification count
class DeadlineNotificationBadge extends StatelessWidget {
  final List<Event> events;
  final Widget child;

  const DeadlineNotificationBadge({
    super.key,
    required this.events,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final urgentCount = _getUrgentEventsCount();
    
    if (urgentCount == 0) {
      return child;
    }

    return Badge(
      label: Text(urgentCount.toString()),
      backgroundColor: Colors.red,
      child: child,
    );
  }

  int _getUrgentEventsCount() {
    final now = DateTime.now();
    return events.where((event) {
      if (event.submissionDeadline == null) return false;
      
      final timeRemaining = event.submissionDeadline!.difference(now);
      if (timeRemaining.isNegative) return false;
      
      // Consider urgent if less than 4 hours remaining
      return timeRemaining.inHours <= 4;
    }).length;
  }
}