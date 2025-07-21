import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/group_providers.dart';
import '../../providers/event_providers.dart';
import '../../ui/widgets/selectable_error_message.dart';
import '../../ui/widgets/realtime_post_feed.dart';
import '../../ui/leaderboard/leaderboard_screen.dart';
import '../../ui/events/events_list_screen.dart';
import '../../utils/firebase_error_handler.dart';
import 'group_settings_screen.dart';
import 'manage_members_screen.dart';

/// Screen showing group details and member management
class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String memberId;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.memberId,
  });

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          return Scaffold(
            appBar: AppBar(title: const Text('Group Not Found')),
            body: const Center(
              child: Text('Group not found or you don\'t have access to it.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(group.name),
            elevation: 0,
            actions: [
              isAdminAsync.when(
                data: (isAdmin) => isAdmin
                    ? PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'settings':
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => GroupSettingsScreen(
                                    group: group,
                                  ),
                                ),
                              );
                              break;
                            case 'manage_members':
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ManageMembersScreen(
                                    groupId: widget.groupId,
                                    currentMemberId: widget.memberId,
                                  ),
                                ),
                              );
                              break;
                          }
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
                        ],
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Leaderboard'),
                Tab(text: 'Events'),
              ],
            ),
          ),
          body: TabBarView(
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
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
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
              ],
            ),
          ),
        ),
      ),
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
            SizedBox(
              height: 200,
              child: RealtimeLeaderboard(
                eventId: event.id,
                showConnectionStatus: false,
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

