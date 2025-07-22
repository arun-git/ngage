import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/event_providers.dart';
import '../../providers/auth_providers.dart';

/// Screen for creating a new event
class CreateEventScreen extends ConsumerStatefulWidget {
  final String groupId;
  final Event? eventToEdit;

  const CreateEventScreen({
    super.key,
    required this.groupId,
    this.eventToEdit,
  });

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  EventType _selectedEventType = EventType.competition;
  DateTime? _startTime;
  DateTime? _endTime;
  DateTime? _submissionDeadline;
  List<String> _eligibleTeamIds = [];
  bool _isOpenEvent = true;
  
  @override
  void initState() {
    super.initState();
    
    // If editing, populate form with existing data
    if (widget.eventToEdit != null) {
      final event = widget.eventToEdit!;
      _titleController.text = event.title;
      _descriptionController.text = event.description;
      _selectedEventType = event.eventType;
      _startTime = event.startTime;
      _endTime = event.endTime;
      _submissionDeadline = event.submissionDeadline;
      _eligibleTeamIds = event.eligibleTeamIds ?? [];
      _isOpenEvent = event.isOpenEvent;
      
      // Load event into form provider
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(eventFormProvider.notifier).loadEvent(event);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(eventFormProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventToEdit != null ? 'Edit Event' : 'Create Event'),
        actions: [
          TextButton(
            onPressed: formState.isLoading ? null : _saveEvent,
            child: formState.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Section
              _buildSectionHeader('Basic Information'),
              const SizedBox(height: 16),
              
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Event Title *',
                  hintText: 'Enter event title',
                  border: const OutlineInputBorder(),
                  errorText: formState.errors['title'],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Event title is required';
                  }
                  if (value.trim().length > 200) {
                    return 'Event title must not exceed 200 characters';
                  }
                  return null;
                },
                onChanged: (value) {
                  ref.read(eventFormProvider.notifier).updateField('title', value);
                },
              ),
              
              const SizedBox(height: 16),
              
              // Event Type dropdown
              DropdownButtonFormField<EventType>(
                value: _selectedEventType,
                decoration: InputDecoration(
                  labelText: 'Event Type *',
                  border: const OutlineInputBorder(),
                  errorText: formState.errors['eventType'],
                ),
                items: EventType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(_getEventTypeIcon(type)),
                        const SizedBox(width: 8),
                        Text(_getEventTypeLabel(type)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedEventType = value;
                    });
                    ref.read(eventFormProvider.notifier).updateField('eventType', value);
                  }
                },
              ),
              
              const SizedBox(height: 16),
              
              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Describe your event',
                  border: const OutlineInputBorder(),
                  errorText: formState.errors['description'],
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Event description is required';
                  }
                  if (value.trim().length > 2000) {
                    return 'Description must not exceed 2000 characters';
                  }
                  return null;
                },
                onChanged: (value) {
                  ref.read(eventFormProvider.notifier).updateField('description', value);
                },
              ),
              
              const SizedBox(height: 32),
              
              // Scheduling Section
              _buildSectionHeader('Scheduling'),
              const SizedBox(height: 16),
              
              // Start time
              _buildDateTimeField(
                label: 'Start Time',
                value: _startTime,
                onChanged: (dateTime) {
                  setState(() {
                    _startTime = dateTime;
                  });
                  ref.read(eventFormProvider.notifier).updateField('startTime', dateTime);
                },
                errorText: formState.errors['startTime'],
              ),
              
              const SizedBox(height: 16),
              
              // End time
              _buildDateTimeField(
                label: 'End Time',
                value: _endTime,
                onChanged: (dateTime) {
                  setState(() {
                    _endTime = dateTime;
                  });
                  ref.read(eventFormProvider.notifier).updateField('endTime', dateTime);
                },
                errorText: formState.errors['endTime'],
              ),
              
              const SizedBox(height: 16),
              
              // Submission deadline
              _buildDateTimeField(
                label: 'Submission Deadline',
                value: _submissionDeadline,
                onChanged: (dateTime) {
                  setState(() {
                    _submissionDeadline = dateTime;
                  });
                  ref.read(eventFormProvider.notifier).updateField('submissionDeadline', dateTime);
                },
                errorText: formState.errors['submissionDeadline'],
                optional: true,
              ),
              
              const SizedBox(height: 32),
              
              // Access Control Section
              _buildSectionHeader('Access Control'),
              const SizedBox(height: 16),
              
              // Open/Restricted toggle
              SwitchListTile(
                title: const Text('Open to all teams'),
                subtitle: Text(_isOpenEvent 
                    ? 'All teams in the group can participate'
                    : 'Only selected teams can participate'),
                value: _isOpenEvent,
                onChanged: (value) {
                  setState(() {
                    _isOpenEvent = value;
                    if (value) {
                      _eligibleTeamIds.clear();
                    }
                  });
                  ref.read(eventFormProvider.notifier).updateField('eligibleTeamIds', 
                      value ? null : _eligibleTeamIds);
                },
              ),
              
              // Team selection (if restricted)
              if (!_isOpenEvent) ...[
                const SizedBox(height: 16),
                _buildTeamSelection(),
              ],
              
              const SizedBox(height: 32),
              
              // Error display
              if (formState.errors['general'] != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formState.errors['general']!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
    String? errorText,
    bool optional = false,
  }) {
    return InkWell(
      onTap: () => _selectDateTime(context, value, onChanged),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: optional ? label : '$label *',
          border: const OutlineInputBorder(),
          errorText: errorText,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => onChanged(null),
                ),
              const Icon(Icons.access_time),
            ],
          ),
        ),
        child: Text(
          value != null ? _formatDateTime(value) : 'Select date and time',
          style: TextStyle(
            color: value != null 
                ? Theme.of(context).textTheme.bodyLarge?.color
                : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }

  Widget _buildTeamSelection() {
    // This would typically show a list of teams to select from
    // For now, we'll show a placeholder
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Teams',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          if (_eligibleTeamIds.isEmpty)
            Text(
              'No teams selected. Tap to select teams.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            )
          else
            Wrap(
              spacing: 8,
              children: _eligibleTeamIds.map((teamId) {
                return Chip(
                  label: Text('Team $teamId'), // Would show actual team name
                  onDeleted: () {
                    setState(() {
                      _eligibleTeamIds.remove(teamId);
                    });
                    ref.read(eventFormProvider.notifier).updateField('eligibleTeamIds', _eligibleTeamIds);
                  },
                );
              }).toList(),
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _selectTeams,
            icon: const Icon(Icons.add),
            label: const Text('Select Teams'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateTime(BuildContext context, DateTime? currentValue, ValueChanged<DateTime?> onChanged) async {
    final now = DateTime.now();
    final initialDate = currentValue ?? now;
    
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    
    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
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

  void _selectTeams() {
    // This would open a team selection dialog
    // For now, we'll show a placeholder
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Teams'),
        content: const Text('Team selection dialog would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if user is authenticated first
    final authState = ref.read(authStateProvider);
    if (!authState.isAuthenticated || authState.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to create events')),
      );
      return;
    }

    // Get current member from auth state
    final currentMember = authState.currentMember;
    if (currentMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No member profile found. Please create a member profile first.')),
      );
      return;
    }

    // Update form data
    ref.read(eventFormProvider.notifier).updateField('title', _titleController.text);
    ref.read(eventFormProvider.notifier).updateField('description', _descriptionController.text);
    ref.read(eventFormProvider.notifier).updateField('eventType', _selectedEventType);
    ref.read(eventFormProvider.notifier).updateField('startTime', _startTime);
    ref.read(eventFormProvider.notifier).updateField('endTime', _endTime);
    ref.read(eventFormProvider.notifier).updateField('submissionDeadline', _submissionDeadline);
    ref.read(eventFormProvider.notifier).updateField('eligibleTeamIds', _isOpenEvent ? null : _eligibleTeamIds);

    Event? result;
    if (widget.eventToEdit != null) {
      result = await ref.read(eventFormProvider.notifier).updateEvent();
    } else {
      result = await ref.read(eventFormProvider.notifier).createEvent(widget.groupId, currentMember.id);
    }

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.eventToEdit != null 
              ? 'Event updated successfully' 
              : 'Event created successfully'),
        ),
      );
      Navigator.of(context).pop(result);
    }
  }

  IconData _getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.competition:
        return Icons.emoji_events;
      case EventType.challenge:
        return Icons.flag;
      case EventType.survey:
        return Icons.poll;
    }
  }

  String _getEventTypeLabel(EventType type) {
    switch (type) {
      case EventType.competition:
        return 'Competition';
      case EventType.challenge:
        return 'Challenge';
      case EventType.survey:
        return 'Survey';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${_formatTime(dateTime)}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$displayHour:$minute $period';
  }
}