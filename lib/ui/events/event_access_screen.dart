import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/event_providers.dart';
import '../../providers/team_providers.dart';

/// Screen for managing event access control and team eligibility
class EventAccessScreen extends ConsumerStatefulWidget {
  final Event event;

  const EventAccessScreen({
    super.key,
    required this.event,
  });

  @override
  ConsumerState<EventAccessScreen> createState() => _EventAccessScreenState();
}

class _EventAccessScreenState extends ConsumerState<EventAccessScreen> {
  late bool _isOpenEvent;
  late List<String> _eligibleTeamIds;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _isOpenEvent = widget.event.isOpenEvent;
    _eligibleTeamIds = List.from(widget.event.eligibleTeamIds ?? []);
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(groupTeamsProvider(widget.event.groupId));
    final accessibleTeamsAsync = ref.watch(eventAccessibleTeamsProvider(widget.event.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Access Control'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Info Card
            _buildEventInfoCard(),
            
            const SizedBox(height: 24),
            
            // Access Control Settings
            _buildAccessControlSection(teamsAsync),
            
            const SizedBox(height: 24),
            
            // Current Access Status
            _buildCurrentAccessSection(accessibleTeamsAsync),
            
            const SizedBox(height: 24),
            
            // Prerequisites Section (if any)
            _buildPrerequisitesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getEventTypeIcon(widget.event.eventType),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.event.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.event.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessControlSection(AsyncValue<List<Team>> teamsAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Access Control',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Open/Restricted Toggle
            SwitchListTile(
              title: const Text('Open to all teams'),
              subtitle: Text(_isOpenEvent 
                  ? 'All teams in the group can participate'
                  : 'Only selected teams can participate'),
              value: _isOpenEvent,
              onChanged: (value) {
                setState(() {
                  _isOpenEvent = value;
                  _hasChanges = true;
                  if (value) {
                    _eligibleTeamIds.clear();
                  }
                });
              },
            ),
            
            // Team Selection (if restricted)
            if (!_isOpenEvent) ...[
              const Divider(),
              const SizedBox(height: 16),
              teamsAsync.when(
                data: (teams) => _buildTeamSelection(teams),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text('Error loading teams: $error'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSelection(List<Team> teams) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Eligible Teams',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            Text(
              '${_eligibleTeamIds.length} of ${teams.length} selected',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Quick Actions
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _eligibleTeamIds = teams.map((t) => t.id).toList();
                  _hasChanges = true;
                });
              },
              icon: const Icon(Icons.select_all),
              label: const Text('Select All'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _eligibleTeamIds.isEmpty ? null : () {
                setState(() {
                  _eligibleTeamIds.clear();
                  _hasChanges = true;
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear All'),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Team List
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: teams.map((team) {
              final isSelected = _eligibleTeamIds.contains(team.id);
              
              return CheckboxListTile(
                title: Text(team.name),
                subtitle: Text('${team.memberCount} members • Lead: ${team.teamLeadId}'),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _eligibleTeamIds.add(team.id);
                    } else {
                      _eligibleTeamIds.remove(team.id);
                    }
                    _hasChanges = true;
                  });
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentAccessSection(AsyncValue<List<String>> accessibleTeamsAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Access Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            accessibleTeamsAsync.when(
              data: (accessibleTeamIds) => _buildAccessStatusContent(accessibleTeamIds),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error loading access status: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessStatusContent(List<String> accessibleTeamIds) {
    final teamsAsync = ref.watch(groupTeamsProvider(widget.event.groupId));
    
    return teamsAsync.when(
      data: (allTeams) {
        final accessibleTeams = allTeams.where((team) => accessibleTeamIds.contains(team.id)).toList();
        final restrictedTeams = allTeams.where((team) => !accessibleTeamIds.contains(team.id)).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.event.isOpenEvent ? Icons.public : Icons.group,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.event.isOpenEvent
                          ? 'Open event - all ${allTeams.length} teams can participate'
                          : '${accessibleTeams.length} of ${allTeams.length} teams can participate',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            if (!widget.event.isOpenEvent && restrictedTeams.isNotEmpty) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: Text('Restricted Teams (${restrictedTeams.length})'),
                subtitle: const Text('These teams cannot access this event'),
                leading: Icon(
                  Icons.block,
                  color: Theme.of(context).colorScheme.error,
                ),
                children: restrictedTeams.map((team) {
                  return ListTile(
                    title: Text(team.name),
                    subtitle: Text('${team.memberCount} members'),
                    leading: const Icon(Icons.group_off),
                    dense: true,
                  );
                }).toList(),
              ),
            ],
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }

  Widget _buildPrerequisitesSection() {
    final prerequisites = widget.event.getJudgingCriterion<List<dynamic>>('prerequisites');
    
    if (prerequisites == null || prerequisites.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Prerequisites',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(
              'Teams must complete the following events before accessing this event:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            
            const SizedBox(height: 12),
            
            ...prerequisites.map((prereqId) {
              if (prereqId is String) {
                return FutureBuilder<Event?>(
                  future: ref.read(eventServiceProvider).getEventById(prereqId),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      final prereqEvent = snapshot.data!;
                      return ListTile(
                        leading: Icon(
                          _getEventTypeIcon(prereqEvent.eventType),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(prereqEvent.title),
                        subtitle: Text(_getStatusLabel(prereqEvent.status)),
                        dense: true,
                      );
                    }
                    return ListTile(
                      leading: const Icon(Icons.event),
                      title: Text('Event $prereqId'),
                      subtitle: const Text('Loading...'),
                      dense: true,
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    final (color, backgroundColor) = _getStatusColors();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusLabel(widget.event.status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(eventServiceProvider).updateEventAccess(
        widget.event.id,
        eligibleTeamIds: _isOpenEvent ? null : _eligibleTeamIds,
      );

      if (mounted) {
        setState(() {
          _hasChanges = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access control updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update access control: $e'),
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

  (Color, Color) _getStatusColors() {
    final colorScheme = Theme.of(context).colorScheme;
    
    switch (widget.event.status) {
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