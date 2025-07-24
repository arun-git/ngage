import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/event_providers.dart';
import '../../providers/team_providers.dart';
import '../widgets/breadcrumb_navigation.dart';

/// Inner page for managing event access control and team eligibility
class EventAccessInnerPage extends ConsumerStatefulWidget {
  final Event event;
  final String groupName;
  final VoidCallback onBack;

  const EventAccessInnerPage({
    super.key,
    required this.event,
    required this.groupName,
    required this.onBack,
  });

  @override
  ConsumerState<EventAccessInnerPage> createState() =>
      _EventAccessInnerPageState();
}

class _EventAccessInnerPageState extends ConsumerState<EventAccessInnerPage> {
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
    final accessibleTeamsAsync =
        ref.watch(eventAccessibleTeamsProvider(widget.event.id));

    return Column(
      children: [
        // Breadcrumb navigation
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
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
                      title: widget.event.title,
                      onTap: widget.onBack,
                    ),
                    BreadcrumbItem(
                      title: 'Access Control',
                    ),
                  ],
                ),
              ),
              if (_hasChanges)
                FilledButton(
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
        ),
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event info
                Card(
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
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getEventTypeLabel(widget.event.eventType),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Access control settings
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
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Open Event'),
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
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Team selection (if restricted)
                if (!_isOpenEvent) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Eligible Teams',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select which teams can participate in this event',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                          const SizedBox(height: 16),
                          teamsAsync.when(
                            data: (teams) =>
                                _buildTeamSelection(context, teams),
                            loading: () => const Center(
                                child: CircularProgressIndicator()),
                            error: (error, stack) =>
                                _buildErrorWidget(context, error),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Current access summary
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Access Summary',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        teamsAsync.when(
                          data: (allTeams) =>
                              _buildAccessSummary(context, allTeams),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, stack) =>
                              _buildErrorWidget(context, error),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSelection(BuildContext context, List<Team> teams) {
    if (teams.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.group_off,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              'No teams available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: teams.map((team) {
        final isSelected = _eligibleTeamIds.contains(team.id);

        return CheckboxListTile(
          title: Text(team.name),
          subtitle: Text('${team.memberIds.length} members'),
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
    );
  }

  Widget _buildAccessSummary(BuildContext context, List<Team> allTeams) {
    if (_isOpenEvent) {
      return Row(
        children: [
          Icon(
            Icons.public,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Open Event',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  'All ${allTeams.length} teams in the group can participate',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final selectedTeams =
        allTeams.where((team) => _eligibleTeamIds.contains(team.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.group,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Restricted Event',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${selectedTeams.length} of ${allTeams.length} teams can participate',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        if (selectedTeams.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...selectedTeams.map((team) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${team.name} (${team.memberIds.length} members)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildErrorWidget(BuildContext context, Object error) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(
            'Error loading data',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
        ],
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
}
