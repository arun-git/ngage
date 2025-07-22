import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/event_status_manager.dart';

/// Widget that provides action buttons for event status transitions
class EventStatusActions extends StatelessWidget {
  final Event event;
  final VoidCallback? onStatusChanged;

  const EventStatusActions({
    super.key,
    required this.event,
    this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (event.status != EventStatus.draft) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (event.startTime != null && event.endTime != null) ...[
          _buildPromoteButton(context),
          const SizedBox(width: 8),
        ],
        _buildScheduleButton(context),
      ],
    );
  }

  Widget _buildPromoteButton(BuildContext context) {
    final statusManager = EventStatusManager();
    final appropriateStatus = statusManager.determineAppropriateStatus(event);
    
    String buttonText;
    IconData icon;
    Color color;
    
    switch (appropriateStatus) {
      case EventStatus.scheduled:
        buttonText = 'Schedule';
        icon = Icons.schedule;
        color = Colors.blue;
        break;
      case EventStatus.active:
        buttonText = 'Activate';
        icon = Icons.play_arrow;
        color = Colors.green;
        break;
      case EventStatus.completed:
        buttonText = 'Complete';
        icon = Icons.check_circle;
        color = Colors.grey;
        break;
      default:
        return const SizedBox.shrink();
    }

    return ElevatedButton.icon(
      onPressed: () => _promoteEvent(context),
      icon: Icon(icon, size: 16),
      label: Text(buttonText),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildScheduleButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _showScheduleDialog(context),
      icon: const Icon(Icons.edit_calendar, size: 16),
      label: const Text('Set Schedule'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Future<void> _promoteEvent(BuildContext context) async {
    try {
      final statusManager = EventStatusManager();
      await statusManager.promoteDraftEvent(event.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event "${event.title}" status updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        onStatusChanged?.call();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update event status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showScheduleDialog(BuildContext context) async {
    DateTime? startTime = event.startTime;
    DateTime? endTime = event.endTime;
    DateTime? submissionDeadline = event.submissionDeadline;

    final result = await showDialog<Map<String, DateTime?>>(
      context: context,
      builder: (context) => _ScheduleEventDialog(
        initialStartTime: startTime,
        initialEndTime: endTime,
        initialSubmissionDeadline: submissionDeadline,
      ),
    );

    if (result != null && context.mounted) {
      try {
        final statusManager = EventStatusManager();
        await statusManager.scheduleDraftEvent(
          event.id,
          startTime: result['startTime']!,
          endTime: result['endTime']!,
          submissionDeadline: result['submissionDeadline'],
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Event "${event.title}" scheduled successfully'),
              backgroundColor: Colors.green,
            ),
          );
          onStatusChanged?.call();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to schedule event: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _ScheduleEventDialog extends StatefulWidget {
  final DateTime? initialStartTime;
  final DateTime? initialEndTime;
  final DateTime? initialSubmissionDeadline;

  const _ScheduleEventDialog({
    this.initialStartTime,
    this.initialEndTime,
    this.initialSubmissionDeadline,
  });

  @override
  State<_ScheduleEventDialog> createState() => _ScheduleEventDialogState();
}

class _ScheduleEventDialogState extends State<_ScheduleEventDialog> {
  late DateTime startTime;
  late DateTime endTime;
  DateTime? submissionDeadline;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    startTime = widget.initialStartTime ?? now.add(const Duration(hours: 1));
    endTime = widget.initialEndTime ?? startTime.add(const Duration(hours: 2));
    submissionDeadline = widget.initialSubmissionDeadline;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Schedule Event'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDateTimeField(
              label: 'Start Time',
              value: startTime,
              onChanged: (value) => setState(() => startTime = value),
            ),
            const SizedBox(height: 16),
            _buildDateTimeField(
              label: 'End Time',
              value: endTime,
              onChanged: (value) => setState(() => endTime = value),
            ),
            const SizedBox(height: 16),
            _buildOptionalDateTimeField(
              label: 'Submission Deadline (Optional)',
              value: submissionDeadline,
              onChanged: (value) => setState(() => submissionDeadline = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isValidSchedule() ? _saveSchedule : null,
          child: const Text('Schedule'),
        ),
      ],
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required DateTime value,
    required ValueChanged<DateTime> onChanged,
  }) {
    return ListTile(
      title: Text(label),
      subtitle: Text(_formatDateTime(value)),
      trailing: const Icon(Icons.edit),
      onTap: () => _selectDateTime(context, value, onChanged),
    );
  }

  Widget _buildOptionalDateTimeField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value != null ? _formatDateTime(value) : 'Not set'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => onChanged(null),
            ),
          const Icon(Icons.edit),
        ],
      ),
      onTap: () => _selectDateTime(
        context,
        value ?? startTime.add(const Duration(hours: 1)),
        (newValue) => onChanged(newValue),
      ),
    );
  }

  Future<void> _selectDateTime(
    BuildContext context,
    DateTime initialValue,
    ValueChanged<DateTime> onChanged,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialValue,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialValue),
      );

      if (time != null) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        onChanged(dateTime);
      }
    }
  }

  bool _isValidSchedule() {
    if (endTime.isBefore(startTime)) return false;
    if (submissionDeadline != null) {
      if (submissionDeadline!.isBefore(startTime) ||
          submissionDeadline!.isAfter(endTime)) {
        return false;
      }
    }
    return true;
  }

  void _saveSchedule() {
    Navigator.of(context).pop({
      'startTime': startTime,
      'endTime': endTime,
      'submissionDeadline': submissionDeadline,
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}