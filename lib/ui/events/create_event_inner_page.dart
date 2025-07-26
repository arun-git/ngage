import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/event_providers.dart';
import '../../providers/auth_providers.dart';
import '../widgets/event_banner_image_picker.dart';

/// Inner page for creating or editing an event
class CreateEventInnerPage extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;
  final Event? eventToEdit;
  final VoidCallback onBack;
  final Function(Event)? onEventCreated;

  const CreateEventInnerPage({
    super.key,
    required this.groupId,
    required this.groupName,
    this.eventToEdit,
    required this.onBack,
    this.onEventCreated,
  });

  @override
  ConsumerState<CreateEventInnerPage> createState() =>
      _CreateEventInnerPageState();
}

class _CreateEventInnerPageState extends ConsumerState<CreateEventInnerPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  EventType _selectedEventType = EventType.competition;
  String? _bannerImageUrl;
  DateTime? _startTime;
  DateTime? _endTime;
  DateTime? _submissionDeadline;
  List<String> _eligibleTeamIds = [];
  bool _isOpenEvent = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // If editing, populate form with existing data
    if (widget.eventToEdit != null) {
      final event = widget.eventToEdit!;
      _titleController.text = event.title;
      _descriptionController.text = event.description;
      _selectedEventType = event.eventType;
      _bannerImageUrl = event.bannerImageUrl;
      _startTime = event.startTime;
      _endTime = event.endTime;
      _submissionDeadline = event.submissionDeadline;
      _eligibleTeamIds = event.eligibleTeamIds ?? [];
      _isOpenEvent = event.isOpenEvent;
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
    final isEditing = widget.eventToEdit != null;

    return Material(
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  hintText: 'Enter a descriptive title for your event',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an event title';
                  }
                  if (value.trim().length < 3) {
                    return 'Title must be at least 3 characters long';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe what this event is about',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.trim().length < 10) {
                    return 'Description must be at least 10 characters long';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Banner image picker
              EventBannerImagePicker(
                currentImageUrl: _bannerImageUrl,
                onImageChanged: (imageUrl) {
                  setState(() {
                    _bannerImageUrl = imageUrl;
                  });
                },
                eventId: widget.eventToEdit?.id,
                groupId: widget.groupId,
                enabled: !_isLoading,
              ),

              const SizedBox(height: 16),

              // Event type selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Event Type',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      ...EventType.values.map((type) {
                        return RadioListTile<EventType>(
                          title: Text(_getEventTypeLabel(type)),
                          subtitle: Text(_getEventTypeDescription(type)),
                          value: type,
                          groupValue: _selectedEventType,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedEventType = value;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Access control
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Access Control',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Open Event'),
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
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : widget.onBack,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isLoading ? null : _saveEvent,
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isEditing ? 'Update Event' : 'Create Event'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      Event savedEvent;
      if (widget.eventToEdit != null) {
        // Update existing event
        final updatedEvent = widget.eventToEdit!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          eventType: _selectedEventType,
          bannerImageUrl: _bannerImageUrl,
          eligibleTeamIds: _isOpenEvent ? null : _eligibleTeamIds,
          startTime: _startTime,
          endTime: _endTime,
          submissionDeadline: _submissionDeadline,
        );

        savedEvent =
            await ref.read(eventServiceProvider).updateEvent(updatedEvent);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event updated successfully')),
          );
        }
      } else {
        // Create new event
        savedEvent = await ref.read(eventServiceProvider).createEvent(
          groupId: widget.groupId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          eventType: _selectedEventType,
          createdBy: currentUser.id,
          bannerImageUrl: _bannerImageUrl,
          startTime: _startTime,
          endTime: _endTime,
          submissionDeadline: _submissionDeadline,
          eligibleTeamIds: _isOpenEvent ? null : _eligibleTeamIds,
          judgingCriteria: <String, dynamic>{},
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event created successfully')),
          );
        }
      }

      if (mounted) {
        widget.onEventCreated?.call(savedEvent);
        widget.onBack();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save event: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  String _getEventTypeDescription(EventType type) {
    switch (type) {
      case EventType.competition:
        return 'Teams compete against each other with rankings and winners';
      case EventType.challenge:
        return 'Teams work on tasks or objectives without direct competition';
      case EventType.survey:
        return 'Collect feedback or information from participants';
    }
  }
}
