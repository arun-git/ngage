import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/event_providers.dart';
import '../../providers/team_providers.dart';
import '../../providers/member_providers.dart';

/// Screen for cloning an event with advanced options
class CloneEventScreen extends ConsumerStatefulWidget {
  final Event originalEvent;

  const CloneEventScreen({
    super.key,
    required this.originalEvent,
  });

  @override
  ConsumerState<CloneEventScreen> createState() => _CloneEventScreenState();
}

class _CloneEventScreenState extends ConsumerState<CloneEventScreen> {
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
    final teamsAsync = ref.watch(groupTeamsProvider(_targetGroupId ?? widget.originalEvent.groupId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clone Event'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _cloneEvent,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Clone'),
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
              // Original Event Info
              _buildOriginalEventCard(),
              
              const SizedBox(height: 24),
              
              // Clone Options
              _buildSectionHeader('Clone Options'),
              const SizedBox(height: 16),
              
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'New Event Title *',
                  hintText: 'Enter title for cloned event',
                  border: OutlineInputBorder(),
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
              ),
              
              const SizedBox(height: 16),
              
              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Modify description if needed',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value != null && value.trim().length > 2000) {
                    return 'Description must not exceed 2000 characters';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Clone Settings
              _buildSectionHeader('Clone Settings'),
              const SizedBox(height: 16),
              
              // Preserve Schedule Option
              SwitchListTile(
                title: const Text('Preserve Schedule'),
                subtitle: Text(_preserveSchedule 
                    ? 'Keep original start time, end time, and submission deadline'
                    : 'Create as draft without scheduling'),
                value: _preserveSchedule,
                onChanged: (value) {
                  setState(() {
                    _preserveSchedule = value;
                  });
                },
              ),
              
              const Divider(),
              
              // Access Control Options
              _buildAccessControlSection(teamsAsync),
              
              const SizedBox(height: 24),
              
              // What will be cloned info
              _buildCloneInfoCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOriginalEventCard() {
    final event = widget.originalEvent;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getEventTypeIcon(event.eventType),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Original Event',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              event.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatusChip(event),
                const SizedBox(width: 8),
                Icon(
                  event.isOpenEvent ? Icons.public : Icons.group,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  event.isOpenEvent ? 'Open Event' : '${event.eligibleTeamIds?.length ?? 0} teams',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessControlSection(AsyncValue<List<Team>> teamsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Access Control',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        // Preserve Access Control Option
        SwitchListTile(
          title: const Text('Preserve Access Control'),
          subtitle: Text(_preserveAccessControl 
              ? 'Keep original team restrictions'
              : 'Reset to open event or select new teams'),
          value: _preserveAccessControl,
          onChanged: (value) {
            setState(() {
              _preserveAccessControl = value;
              if (!value) {
                _selectedTeamIds.clear();
              } else {
                _selectedTeamIds = widget.originalEvent.eligibleTeamIds ?? [];
              }
            });
          },
        ),
        
        // Team Selection (if not preserving access control)
        if (!_preserveAccessControl) ...[
          const SizedBox(height: 16),
          _buildTeamSelectionSection(teamsAsync),
        ],
      ],
    );
  }

  Widget _buildTeamSelectionSection(AsyncValue<List<Team>> teamsAsync) {
    return teamsAsync.when(
      data: (teams) => _buildTeamSelection(teams),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Error loading teams: $error'),
    );
  }

  Widget _buildTeamSelection(List<Team> teams) {
    final isOpenEvent = _selectedTeamIds.isEmpty;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Event Access',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Switch(
                value: !isOpenEvent,
                onChanged: (value) {
                  setState(() {
                    if (value) {
                      // Switch to restricted - don't auto-select teams
                      _selectedTeamIds = [];
                    } else {
                      // Switch to open
                      _selectedTeamIds.clear();
                    }
                  });
                },
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            isOpenEvent 
                ? 'Open to all teams in the group'
                : 'Restricted to selected teams',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          
          if (!isOpenEvent) ...[
            const SizedBox(height: 16),
            
            // Selected teams display
            if (_selectedTeamIds.isNotEmpty) ...[
              Text(
                'Selected Teams (${_selectedTeamIds.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _selectedTeamIds.map((teamId) {
                  final team = teams.firstWhere(
                    (t) => t.id == teamId,
                    orElse: () => Team(
                      id: teamId,
                      groupId: '',
                      name: 'Unknown Team',
                      description: '',
                      teamLeadId: '',
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
                  );
                  
                  return Chip(
                    label: Text(team.name),
                    onDeleted: () {
                      setState(() {
                        _selectedTeamIds.remove(teamId);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            
            // Add teams button
            OutlinedButton.icon(
              onPressed: () => _showTeamSelectionDialog(teams),
              icon: const Icon(Icons.add),
              label: Text(_selectedTeamIds.isEmpty ? 'Select Teams' : 'Add More Teams'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCloneInfoCard() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'What will be cloned',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            _buildCloneInfoItem(Icons.check, 'Event type and judging criteria'),
            _buildCloneInfoItem(Icons.check, 'Title and description (as modified)'),
            _buildCloneInfoItem(
              _preserveSchedule ? Icons.check : Icons.close,
              'Schedule (start time, end time, deadline)',
            ),
            _buildCloneInfoItem(
              _preserveAccessControl ? Icons.check : Icons.close,
              'Team access restrictions',
            ),
            _buildCloneInfoItem(Icons.close, 'Submissions and results'),
            _buildCloneInfoItem(Icons.close, 'Event status (will be draft)'),
          ],
        ),
      ),
    );
  }

  Widget _buildCloneInfoItem(IconData icon, String text) {
    final isIncluded = icon == Icons.check;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isIncluded 
                ? Colors.green 
                : Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isIncluded 
                    ? null 
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        ],
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

  Widget _buildStatusChip(Event event) {
    final (color, backgroundColor) = _getStatusColors(event);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusLabel(event.status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showTeamSelectionDialog(List<Team> allTeams) {
    final availableTeams = allTeams.where((team) => !_selectedTeamIds.contains(team.id)).toList();
    final tempSelected = <String>[];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Teams'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: availableTeams.isEmpty
                ? const Center(child: Text('All teams are already selected'))
                : ListView.builder(
                    itemCount: availableTeams.length,
                    itemBuilder: (context, index) {
                      final team = availableTeams[index];
                      final isSelected = tempSelected.contains(team.id);
                      
                      return CheckboxListTile(
                        title: Text(team.name),
                        subtitle: Text('${team.memberCount} members'),
                        value: isSelected,
                        onChanged: (value) {
                          setDialogState(() {
                            if (value == true) {
                              tempSelected.add(team.id);
                            } else {
                              tempSelected.remove(team.id);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: tempSelected.isEmpty
                  ? null
                  : () {
                      setState(() {
                        _selectedTeamIds.addAll(tempSelected);
                      });
                      Navigator.of(context).pop();
                    },
              child: Text('Add ${tempSelected.length} Team${tempSelected.length == 1 ? '' : 's'}'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cloneEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentMemberAsync = ref.read(activeMemberProvider);
    final currentMember = currentMemberAsync.value;
    if (currentMember == null) {
      _showError('No current member found');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final clonedEvent = await ref.read(eventServiceProvider).cloneEvent(
        widget.originalEvent.id,
        newTitle: _titleController.text.trim(),
        newDescription: _descriptionController.text.trim(),
        createdBy: currentMember.id,
        preserveSchedule: _preserveSchedule,
        preserveAccessControl: _preserveAccessControl,
        newEligibleTeamIds: _preserveAccessControl ? null : (_selectedTeamIds.isEmpty ? null : _selectedTeamIds),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event cloned successfully')),
        );
        Navigator.of(context).pop(clonedEvent);
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to clone event: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
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

  String _getStatusLabel(EventStatus status) {
    switch (status) {
      case EventStatus.draft:
        return 'Draft';
      case EventStatus.scheduled:
        return 'Scheduled';
      case EventStatus.active:
        return 'Active';
      case EventStatus.completed:
        return 'Completed';
      case EventStatus.cancelled:
        return 'Cancelled';
    }
  }

  (Color, Color) _getStatusColors(Event event) {
    final colorScheme = Theme.of(context).colorScheme;
    
    switch (event.status) {
      case EventStatus.draft:
        return (colorScheme.outline, colorScheme.outline.withOpacity(0.1));
      case EventStatus.scheduled:
        return (Colors.blue, Colors.blue.withOpacity(0.1));
      case EventStatus.active:
        return (Colors.green, Colors.green.withOpacity(0.1));
      case EventStatus.completed:
        return (colorScheme.primary, colorScheme.primary.withOpacity(0.1));
      case EventStatus.cancelled:
        return (colorScheme.error, colorScheme.error.withOpacity(0.1));
    }
  }
}