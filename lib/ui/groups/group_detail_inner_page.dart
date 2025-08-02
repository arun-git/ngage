import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/group_providers.dart';
import '../../providers/event_providers.dart';
import '../../ui/widgets/selectable_error_message.dart';
import '../../ui/widgets/breadcrumb_navigation.dart';
import '../../ui/leaderboard/leaderboard_screen.dart';
import '../../ui/events/events_list_screen.dart';
import '../../ui/teams/teams_list_screen.dart';
import '../../utils/firebase_error_handler.dart';
import 'group_settings_inner_page.dart';
import 'manage_members_inner_page.dart';
import 'manage_teams_inner_page.dart';
import '../events/event_detail_inner_page.dart';
import '../events/create_event_inner_page.dart';
import '../events/clone_event_screen.dart';
import '../events/event_access_screen.dart';
import '../events/event_prerequisites_screen.dart';

/// Inner page showing group details that replaces the groups list
class GroupDetailInnerPage extends ConsumerStatefulWidget {
  final String groupId;
  final String memberId;
  final VoidCallback onBack;

  const GroupDetailInnerPage({
    super.key,
    required this.groupId,
    required this.memberId,
    required this.onBack,
  });

  @override
  ConsumerState<GroupDetailInnerPage> createState() =>
      _GroupDetailInnerPageState();
}

class _GroupDetailInnerPageState extends ConsumerState<GroupDetailInnerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _currentSubPage; // 'settings', 'members', 'teams'
  String? _selectedEventId;
  bool _isCreatingEvent = false;
  Event? _eventToEdit;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupProvider(widget.groupId));
    final isAdminAsync = ref.watch(isGroupAdminProvider((
      groupId: widget.groupId,
      memberId: widget.memberId,
    )));

    return groupAsync.when(
      data: (group) {
        if (group == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Group Not Found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Group not found or you don\'t have access to it.'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: widget.onBack,
                  child: const Text('Back to Groups'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Breadcrumb navigation with admin menu
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade50,
              child: Row(
                children: [
                  Expanded(
                    child: BreadcrumbNavigation(
                      items: _buildBreadcrumbItems(group),
                    ),
                  ),
                  _selectedEventId != null
                      ? _buildEventPopupMenu(group)
                      : isAdminAsync.when(
                          data: (isAdmin) => isAdmin
                              ? PopupMenuButton<String>(
                                  onSelected: (value) {
                                    setState(() {
                                      _currentSubPage = value;
                                    });
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'settings',
                                      child: ListTile(
                                        leading: Icon(Icons.settings),
                                        title: Text('Group Settings'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'manage_members',
                                      child: ListTile(
                                        leading: Icon(Icons.people),
                                        title: Text('Manage Members'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'manage_teams',
                                      child: ListTile(
                                        leading: Icon(Icons.groups),
                                        title: Text('Manage Teams'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                ],
              ),
            ),

            // Content based on current sub-page, selected event, or creating event
            Expanded(
              child: _isCreatingEvent
                  ? _buildCreateEvent(group)
                  : _selectedEventId != null
                      ? _buildEventDetail(group)
                      : _currentSubPage != null
                          ? _buildSubPage(group)
                          : _buildMainContent(group),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading group',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SelectableErrorMessage(
                message: error.toString(),
                title: 'Error Details',
                backgroundColor:
                    FirebaseErrorHandler.isFirebaseIndexError(error.toString())
                        ? Colors.orange
                        : Colors.red,
                onRetry: () {
                  ref.invalidate(groupProvider(widget.groupId));
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: widget.onBack,
                child: const Text('Back to Groups'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubPage(Group group) {
    switch (_currentSubPage) {
      case 'settings':
        return GroupSettingsInnerPage(
          group: group,
          onBack: () {
            setState(() {
              _currentSubPage = null;
            });
          },
        );
      case 'manage_members':
        return ManageMembersInnerPage(
          groupId: widget.groupId,
          currentMemberId: widget.memberId,
          groupName: group.name,
          onBack: () {
            setState(() {
              _currentSubPage = null;
            });
          },
        );
      case 'manage_teams':
        return ManageTeamsInnerPage(
          groupId: widget.groupId,
          groupName: group.name,
          onBack: () {
            setState(() {
              _currentSubPage = null;
            });
          },
        );
      default:
        return _buildMainContent(group);
    }
  }

  List<BreadcrumbItem> _buildBreadcrumbItems(Group group) {
    final items = [
      BreadcrumbItem(
        title: '',
        icon: Icons.home_filled,
        onTap: widget.onBack,
      ),
    ];

    if (_isCreatingEvent) {
      // When creating event, show: Groups > Group Name > Create Event
      // Make group name clickable to return to group detail
      items.add(
        BreadcrumbItem(
          title: group.name,
          onTap: () {
            setState(() {
              _isCreatingEvent = false;
              _eventToEdit = null;
              _currentSubPage = null;
            });
          },
        ),
      );
      items.add(
        BreadcrumbItem(
          title: _eventToEdit != null ? 'Edit Event' : 'Create Event',
          icon: _eventToEdit != null ? Icons.edit : Icons.add,
        ),
      );
    } else if (_selectedEventId != null) {
      // When viewing event detail, show: Groups > Group Name > Event Title
      // Group name becomes clickable to return to group detail
      items.add(
        BreadcrumbItem(
          title: group.name,
          onTap: () {
            setState(() {
              _selectedEventId = null;
              _currentSubPage = null;
            });
          },
        ),
      );

      // Add event title from the selected event
      final eventAsync = ref.watch(eventStreamProvider(_selectedEventId!));
      eventAsync.whenData((event) {
        if (event != null) {
          items.add(
            BreadcrumbItem(
              title: event.title,
              icon: Icons.event,
            ),
          );
        }
      });

      return items;
    } else if (_currentSubPage != null) {
      // Add group name as clickable item when in sub-page
      items.add(
        BreadcrumbItem(
          title: group.name,
          onTap: () {
            setState(() {
              _currentSubPage = null;
            });
          },
        ),
      );

      // Add current sub-page
      switch (_currentSubPage) {
        case 'settings':
          items.add(
            const BreadcrumbItem(
              title: 'Settings',
              icon: Icons.settings,
            ),
          );
          break;
        case 'manage_members':
          items.add(
            const BreadcrumbItem(
              title: 'Manage Members',
              icon: Icons.people,
            ),
          );
          break;
        case 'manage_teams':
          items.add(
            const BreadcrumbItem(
              title: 'Manage Teams',
              icon: Icons.groups,
            ),
          );
          break;
      }
    } else {
      // Just show group name when in main view
      items.add(
        BreadcrumbItem(
          title: group.name,
          //icon: Icons.group_work,
        ),
      );
    }

    return items;
  }

  Widget _buildEventDetail(Group group) {
    return EventDetailInnerPage(
      eventId: _selectedEventId!,
      groupName: group.name,
      onBack: () {
        setState(() {
          _selectedEventId = null;
        });
      },
    );
  }

  Widget _buildCreateEvent(Group group) {
    return CreateEventInnerPage(
      groupId: widget.groupId,
      groupName: group.name,
      eventToEdit: _eventToEdit,
      onBack: () {
        setState(() {
          _isCreatingEvent = false;
          _eventToEdit = null;
        });
      },
      onEventCreated: (event) {
        // Refresh events list after creation
        ref.invalidate(groupEventsStreamProvider(widget.groupId));
      },
    );
  }

  Widget _buildEventPopupMenu(Group group) {
    final eventAsync = ref.watch(eventStreamProvider(_selectedEventId!));
    final isAdminAsync = ref.watch(isGroupAdminProvider((
      groupId: widget.groupId,
      memberId: widget.memberId,
    )));

    return eventAsync.when(
      data: (event) {
        if (event == null) return const SizedBox.shrink();

        return isAdminAsync.when(
          data: (isAdmin) {
            // Only show event menu to admin users
            if (!isAdmin) return const SizedBox.shrink();

            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Event Actions (Admin)',
              onSelected: (value) =>
                  _handleEventMenuAction(context, ref, event, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit, color: Colors.red),
                    title: Text('Edit Event'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (event.status == EventStatus.draft)
                  const PopupMenuItem(
                    value: 'schedule',
                    child: ListTile(
                      leading: Icon(Icons.schedule, color: Colors.blue),
                      title: Text('Schedule Event'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (event.status == EventStatus.scheduled)
                  const PopupMenuItem(
                    value: 'activate',
                    child: ListTile(
                      leading: Icon(Icons.play_arrow, color: Colors.green),
                      title: Text('Activate Event'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (event.status == EventStatus.active)
                  const PopupMenuItem(
                    value: 'complete',
                    child: ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text('Complete Event'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                const PopupMenuItem(
                  value: 'clone',
                  child: ListTile(
                    leading: Icon(Icons.copy, color: Colors.blue),
                    title: Text('Clone Event'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'access',
                  child: ListTile(
                    leading: Icon(Icons.security, color: Colors.orange),
                    title: Text('Manage Access'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'prerequisites',
                  child: ListTile(
                    leading: Icon(Icons.lock_outline, color: Colors.purple),
                    title: Text('Prerequisites'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (event.status == EventStatus.draft) const PopupMenuDivider(),
                if (event.status == EventStatus.draft)
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete Event',
                          style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _handleEventMenuAction(
      BuildContext context, WidgetRef ref, Event event, String action) {
    switch (action) {
      case 'edit':
        _navigateToEditEvent(context, event);
        break;
      case 'schedule':
        _scheduleEvent(context, ref, event);
        break;
      case 'activate':
        _activateEvent(context, ref, event);
        break;
      case 'complete':
        _completeEvent(context, ref, event);
        break;
      case 'clone':
        _navigateToCloneEvent(context, event);
        break;
      case 'access':
        _navigateToManageAccess(context, event);
        break;
      case 'prerequisites':
        _navigateToManagePrerequisites(context, event);
        break;
      case 'delete':
        _deleteEvent(context, ref, event);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unknown action: $action')),
        );
    }
  }

  Widget _buildMainContent(Group group) {
    return Column(
      children: [
        // Tab bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Leaderboard'),
              Tab(text: 'Events'),
              Tab(text: 'Teams'),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _GroupLeaderboardTab(
                groupId: widget.groupId,
                memberId: widget.memberId,
              ),
              _GroupEventsTab(
                groupId: widget.groupId,
                memberId: widget.memberId,
                onEventSelected: (eventId) {
                  setState(() {
                    _selectedEventId = eventId;
                  });
                },
                onCreateEvent: () {
                  setState(() {
                    _isCreatingEvent = true;
                    _eventToEdit = null;
                  });
                },
              ),
              _GroupTeamsTab(
                groupId: widget.groupId,
                memberId: widget.memberId,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Navigation methods for event actions
  void _navigateToEditEvent(BuildContext context, Event event) {
    setState(() {
      _isCreatingEvent = true;
      _eventToEdit = event;
      _selectedEventId = null;
    });
  }

  void _navigateToCloneEvent(BuildContext context, Event event) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => CloneEventScreen(originalEvent: event),
      ),
    )
        .then((clonedEvent) {
      if (clonedEvent != null) {
        // Refresh events list after cloning
        ref.invalidate(groupEventsStreamProvider(widget.groupId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event cloned successfully')),
        );
      }
    });
  }

  void _navigateToManageAccess(BuildContext context, Event event) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => EventAccessScreen(event: event),
      ),
    )
        .then((_) {
      // Refresh event data after access changes
      ref.invalidate(eventStreamProvider(event.id));
    });
  }

  void _navigateToManagePrerequisites(BuildContext context, Event event) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => EventPrerequisitesScreen(event: event),
      ),
    )
        .then((_) {
      // Refresh event data after prerequisites changes
      ref.invalidate(eventStreamProvider(event.id));
    });
  }

  void _scheduleEvent(BuildContext context, WidgetRef ref, Event event) {
    showDialog(
      context: context,
      builder: (context) => _ScheduleEventDialog(
        event: event,
        onScheduled: () {
          // Refresh the event data after scheduling
          ref.invalidate(eventStreamProvider(event.id));
        },
      ),
    );
  }

  Future<void> _activateEvent(
      BuildContext context, WidgetRef ref, Event event) async {
    final confirmed = await _showConfirmationDialog(
      context,
      'Activate Event',
      'Are you sure you want to activate this event? This will make it available for submissions.',
    );

    if (confirmed && context.mounted) {
      try {
        await ref.read(eventServiceProvider).activateEvent(event.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event activated successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to activate event: $e')),
          );
        }
      }
    }
  }

  Future<void> _completeEvent(
      BuildContext context, WidgetRef ref, Event event) async {
    final confirmed = await _showConfirmationDialog(
      context,
      'Complete Event',
      'Are you sure you want to complete this event? This will close submissions and finalize results.',
    );

    if (confirmed && context.mounted) {
      try {
        await ref.read(eventServiceProvider).completeEvent(event.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event completed successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to complete event: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteEvent(
      BuildContext context, WidgetRef ref, Event event) async {
    final confirmed = await _showConfirmationDialog(
      context,
      'Delete Event',
      'Are you sure you want to delete this event? This action cannot be undone.',
      destructive: true,
    );

    if (confirmed && context.mounted) {
      try {
        await ref.read(eventServiceProvider).deleteEvent(event.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event deleted successfully')),
          );
          // Navigate back to events list since the event is deleted
          setState(() {
            _selectedEventId = null;
          });
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete event: $e')),
          );
        }
      }
    }
  }

  Future<bool> _showConfirmationDialog(
    BuildContext context,
    String title,
    String content, {
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: destructive
                ? TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

/// Dialog for scheduling an event
class _ScheduleEventDialog extends ConsumerStatefulWidget {
  final Event event;
  final VoidCallback? onScheduled;

  const _ScheduleEventDialog({
    required this.event,
    this.onScheduled,
  });

  @override
  ConsumerState<_ScheduleEventDialog> createState() =>
      _ScheduleEventDialogState();
}

class _ScheduleEventDialogState extends ConsumerState<_ScheduleEventDialog> {
  late DateTime startTime;
  late DateTime endTime;
  DateTime? submissionDeadline;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();

    // Initialize with existing times or smart defaults
    startTime = widget.event.startTime ?? now.add(const Duration(hours: 1));
    endTime = widget.event.endTime ?? startTime.add(const Duration(hours: 2));
    submissionDeadline = widget.event.submissionDeadline;

    // Ensure end time is after start time
    if (endTime.isBefore(startTime)) {
      endTime = startTime.add(const Duration(hours: 2));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Schedule Event'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Event: ${widget.event.title}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Start time
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('Start Time'),
                subtitle: Text(_formatDateTime(startTime)),
                onTap: () => _selectDateTime(context, true),
              ),

              // End time
              ListTile(
                leading: const Icon(Icons.stop),
                title: const Text('End Time'),
                subtitle: Text(_formatDateTime(endTime)),
                onTap: () => _selectDateTime(context, false),
              ),

              // Submission deadline (optional)
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Submission Deadline (Optional)'),
                subtitle: Text(submissionDeadline != null
                    ? _formatDateTime(submissionDeadline!)
                    : 'Not set'),
                onTap: () => _selectSubmissionDeadline(context),
                trailing: submissionDeadline != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            submissionDeadline = null;
                          });
                        },
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isLoading ? null : _scheduleEvent,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Schedule'),
        ),
      ],
    );
  }

  Future<void> _selectDateTime(BuildContext context, bool isStartTime) async {
    final currentTime = isStartTime ? startTime : endTime;

    final date = await showDatePicker(
      context: context,
      initialDate: currentTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentTime),
      );

      if (time != null) {
        final newDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (isStartTime) {
            startTime = newDateTime;
            // Ensure end time is after start time
            if (endTime.isBefore(startTime)) {
              endTime = startTime.add(const Duration(hours: 2));
            }
          } else {
            if (newDateTime.isAfter(startTime)) {
              endTime = newDateTime;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('End time must be after start time')),
              );
            }
          }
        });
      }
    }
  }

  Future<void> _selectSubmissionDeadline(BuildContext context) async {
    final currentDeadline = submissionDeadline ?? endTime;

    final date = await showDatePicker(
      context: context,
      initialDate: currentDeadline,
      firstDate: startTime,
      lastDate: endTime.add(const Duration(days: 30)),
    );

    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentDeadline),
      );

      if (time != null) {
        final newDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        setState(() {
          submissionDeadline = newDateTime;
        });
      }
    }
  }

  Future<void> _scheduleEvent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(eventServiceProvider).scheduleEvent(
            widget.event.id,
            startTime: startTime,
            endTime: endTime,
            submissionDeadline: submissionDeadline,
          );

      if (mounted) {
        widget.onScheduled?.call();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event scheduled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to schedule event: $e')),
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

/// Tab showing group-specific leaderboard
class _GroupLeaderboardTab extends ConsumerWidget {
  final String groupId;
  final String memberId;

  const _GroupLeaderboardTab({
    required this.groupId,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupEventsAsync = ref.watch(groupEventsStreamProvider(groupId));

    return groupEventsAsync.when(
      data: (events) {
        // Filter for completed events that have leaderboards
        final completedEvents = events
            .where((event) => event.status == EventStatus.completed)
            .toList();

        if (completedEvents.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.leaderboard,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No leaderboards yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Complete some events to see leaderboards',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Group Leaderboards',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ...completedEvents.map((event) => _buildEventLeaderboardCard(
                    context,
                    event,
                  )),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              SelectableText(
                'Error loading leaderboards',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SelectableErrorMessage(
                message: error.toString(),
                title: 'Error Details',
                backgroundColor:
                    FirebaseErrorHandler.isFirebaseIndexError(error.toString())
                        ? Colors.orange
                        : Colors.red,
                onRetry: () {
                  ref.invalidate(groupEventsStreamProvider(groupId));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventLeaderboardCard(BuildContext context, Event event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            LeaderboardScreen(eventId: event.id),
                      ),
                    );
                  },
                  child: const Text('View Full'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.leaderboard,
                      size: 48,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Leaderboard for ${event.title}',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap "View Full" to see complete results',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab showing group-specific events
class _GroupEventsTab extends ConsumerWidget {
  final String groupId;
  final String memberId;
  final Function(String)? onEventSelected;
  final VoidCallback? onCreateEvent;

  const _GroupEventsTab({
    required this.groupId,
    required this.memberId,
    this.onEventSelected,
    this.onCreateEvent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EventsListScreen(
      groupId: groupId,
      onEventSelected: onEventSelected,
      onCreateEvent: onCreateEvent,
    );
  }
}

/// Tab showing group teams
class _GroupTeamsTab extends ConsumerWidget {
  final String groupId;
  final String memberId;

  const _GroupTeamsTab({
    required this.groupId,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TeamsListScreen(groupId: groupId);
  }
}
