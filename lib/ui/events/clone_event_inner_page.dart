import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/event_providers.dart';
import '../../providers/team_providers.dart';
import '../../providers/member_providers.dart';
import '../../providers/auth_providers.dart';
import '../widgets/breadcrumb_navigation.dart';

/// Inner page for cloning an event with advanced options
class CloneEventInnerPage extends ConsumerStatefulWidget {
  final Event originalEvent;
  final String groupName;
  final VoidCallback onBack;
  final Function(Event)? onEventCloned;

  const CloneEventInnerPage({
    super.key,
    required this.originalEvent,
    required this.groupName,
    required this.onBack,
    this.onEventCloned,
  });

  @override
  ConsumerState<CloneEventInnerPage> createState() => _CloneEventInnerPageState();
}

class _CloneEventInnerPageState extends ConsumerState<CloneEventInnerPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _preserveSchedule = false;
  bool _preserveAccessControl = true;
  bool _isLoading = false;
  String? _targetGroupId;
  List<String> _selectedTeamIds = [];
  
  @override
  void initState() {
    super.initState();
    
    // Initialize with original event data
    _titleController.text = '${widget.originalEvent.title} (Copy)';
    _descriptionController.text = widget.originalEvent.description;
    _targetGroupId = widget.originalEvent.groupId;
    _selectedTeamIds = widget.originalEvent.eligibleTeamIds ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Breadcrumb navigation
        Container(
          padding: const EdgeInsets.all(16),
          child: BreadcrumbNavigation(
            items: [
              BreadcrumbItem(
                title: widget.groupName,
                icon: Icons.group,
                onTap: widget.onBack,
              ),
              BreadcrumbItem(
                title: 'Events',
                onTap: widget.onBack,
              ),
              BreadcrumbItem(
                title: 'Clone Event',
              ),
            ],
          ),
        ),
        // Form content
        Expanded(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Original event info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cloning Event',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                _getEventTypeIcon(widget.originalEvent.eventType),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.originalEvent.title,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // New event details
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'New Event Title',
                      hintText: 'Enter title for the cloned event',
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
                  
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Modify description if needed',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Clone options
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Clone Options',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          SwitchListTile(
                            title: const Text('Preserve Schedule'),
                            subtitle: Text(_preserveSchedule 
                              ? 'Copy start time, end time, and deadlines'
                              : 'Create as draft without schedule'),
                            value: _preserveSchedule,
                            onChanged: (value) {
                              setState(() {
                                _preserveSchedule = value;
                              });
                            },
                          ),
                          
                          SwitchListTile(
                            title: const Text('Preserve Access Control'),
                            subtitle: Text(_preserveAccessControl 
                              ? 'Copy team eligibility settings'
                              : 'Reset to open event'),
                            value: _preserveAccessControl,
                            onChanged: (value) {
                              setState(() {
                                _preserveAccessControl = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Schedule preview (if preserving)
                  if (_preserveSchedule && widget.originalEvent.startTime != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Schedule to Copy',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            if (widget.originalEvent.startTime != null)
                              _buildScheduleItem(
                                context,
                                icon: Icons.play_arrow,
                                label: 'Start Time',
                                value: _formatDateTime(widget.originalEvent.startTime!),
                                color: Colors.green,
                              ),
                            
                            if (widget.originalEvent.endTime != null) ...[
                              const SizedBox(height: 8),
                              _buildScheduleItem(
                                context,
                                icon: Icons.stop,
                                label: 'End Time',
                                value: _formatDateTime(widget.originalEvent.endTime!),
                                color: Colors.red,
                              ),
                            ],
                            
                            if (widget.originalEvent.submissionDeadline != null) ...[
                              const SizedBox(height: 8),
                              _buildScheduleItem(
                                context,
                                icon: Icons.access_time,
                                label: 'Submission Deadline',
                                value: _formatDateTime(widget.originalEvent.submissionDeadline!),
                                color: Colors.orange,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Access control preview (if preserving)
                  if (_preserveAccessControl) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Access Control to Copy',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            Row(
                              children: [
                                Icon(
                                  widget.originalEvent.isOpenEvent ? Icons.public : Icons.group,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.originalEvent.isOpenEvent 
                                    ? 'Open Event - All teams can participate'
                                    : 'Restricted Event - ${widget.originalEvent.eligibleTeamIds?.length ?? 0} selected teams',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
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
                          onPressed: _isLoading ? null : _cloneEvent,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Clone Event'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _cloneEvent() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      final clonedEvent = await ref.read(eventServiceProvider).cloneEvent(
        widget.originalEvent.id,
        newTitle: _titleController.text.trim(),
        newDescription: _descriptionController.text.trim(),
        createdBy: currentUser.id,
        preserveSchedule: _preserveSchedule,
        preserveAccessControl: _preserveAccessControl,
        targetGroupId: _targetGroupId,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event cloned successfully')),
        );
        
        widget.onEventCloned?.call(clonedEvent);
        widget.onBack();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clone event: $e'),
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