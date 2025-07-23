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
  ConsumerState<GroupDetailInnerPage> createState() => _GroupDetailInnerPageState();
}

class _GroupDetailInnerPageState extends ConsumerState<GroupDetailInnerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _currentSubPage; // 'settings', 'members', 'teams'

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
                  isAdminAsync.when(
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

            // Content based on current sub-page
            Expanded(
              child: _currentSubPage != null
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
                backgroundColor: FirebaseErrorHandler.isFirebaseIndexError(error.toString()) 
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
        title: 'Groups',
        icon: Icons.group,
        onTap: widget.onBack,
      ),
    ];

    if (_currentSubPage != null) {
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
          icon: Icons.group_work,
        ),
      );
    }

    return items;
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
              Text(
                'Error loading leaderboards',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SelectableErrorMessage(
                message: error.toString(),
                title: 'Error Details',
                backgroundColor: FirebaseErrorHandler.isFirebaseIndexError(error.toString()) 
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
                        builder: (context) => LeaderboardScreen(eventId: event.id),
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

  const _GroupEventsTab({
    required this.groupId,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EventsListScreen(groupId: groupId);
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