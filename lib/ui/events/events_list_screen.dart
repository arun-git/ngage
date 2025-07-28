import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/event_providers.dart';
import '../../providers/group_providers.dart';

import '../../providers/member_providers.dart';
import '../../utils/firebase_error_handler.dart';
import '../widgets/selectable_error_message.dart';
import 'event_card.dart';
//import 'create_event_screen.dart';
import 'event_detail_inner_page.dart';

/// Screen displaying list of events for a group
class EventsListScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String? initialFilter;
  final Function(String)? onEventSelected;
  final VoidCallback? onCreateEvent;

  const EventsListScreen({
    super.key,
    required this.groupId,
    this.initialFilter,
    this.onEventSelected,
    this.onCreateEvent,
  });

  @override
  ConsumerState<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends ConsumerState<EventsListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  TabController? _nonAdminTabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Set initial tab based on filter
    if (widget.initialFilter != null) {
      switch (widget.initialFilter) {
        case 'active':
          _tabController.index = 1;
          break;
        case 'scheduled':
          _tabController.index = 2;
          break;
        case 'completed':
          _tabController.index = 3;
          break;
        case 'draft':
          _tabController.index = 4;
          break;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nonAdminTabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search bar and create button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search events...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                _buildCreateEventButton(),
              ],
            ),
          ),
          // Tabs with admin check for Draft tab
          _buildTabsWithAdminCheck(),
        ],
      ),
    );
  }

  Widget _buildAllEventsTab() {
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResults();
    }

    final eventsAsync = ref.watch(groupEventsStreamProvider(widget.groupId));

    return eventsAsync.when(
      data: (events) => _buildAllEventsWithAdminCheck(events),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(error),
    );
  }

  Widget _buildStatusEventsTab(EventStatus status) {
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResults();
    }

    final eventsAsync = ref.watch(groupEventsStreamProvider(widget.groupId));

    return eventsAsync.when(
      data: (allEvents) {
        // Filter events by status
        var filteredEvents =
            allEvents.where((event) => event.status == status).toList();

        // If showing draft events, filter to admin-only
        if (status == EventStatus.draft) {
          return _buildDraftEventsWithAdminCheck(filteredEvents);
        }

        return _buildEventsList(filteredEvents);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(error),
    );
  }

  Widget _buildSearchResults() {
    final params =
        SearchEventsParams(groupId: widget.groupId, searchTerm: _searchQuery);
    final eventsAsync = ref.watch(searchEventsProvider(params));

    return eventsAsync.when(
      data: (events) => _buildSearchResultsWithAdminCheck(events),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(error),
    );
  }

  /// Build search results with admin check for draft events
  Widget _buildSearchResultsWithAdminCheck(List<Event> events) {
    // Get current member from auth state
    final activeMemberAsync = ref.watch(activeMemberProvider);

    return activeMemberAsync.when(
      data: (member) {
        if (member == null) {
          // If no member, filter out draft events
          final filteredEvents =
              events.where((event) => !event.isDraft).toList();
          return _buildEventsList(filteredEvents);
        }

        // Check if current member is an admin in this group
        final isAdminAsync = ref.watch(isGroupAdminProvider((
          groupId: widget.groupId,
          memberId: member.id,
        )));

        return isAdminAsync.when(
          data: (isAdmin) {
            List<Event> filteredEvents;
            if (isAdmin) {
              // Admin can see all events including drafts in search
              filteredEvents = events;
            } else {
              // Non-admin cannot see draft events in search
              filteredEvents = events.where((event) => !event.isDraft).toList();
            }
            return _buildEventsList(filteredEvents);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) {
            // On error, filter out draft events for safety
            final filteredEvents =
                events.where((event) => !event.isDraft).toList();
            return _buildEventsList(filteredEvents);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) {
        // On error, filter out draft events for safety
        final filteredEvents = events.where((event) => !event.isDraft).toList();
        return _buildEventsList(filteredEvents);
      },
    );
  }

  Widget _buildEventsList(List<Event> events) {
    if (events.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        _refreshAllProviders();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate responsive cross axis count
          int crossAxisCount;
          if (constraints.maxWidth > 1200) {
            crossAxisCount = 4;
          } else if (constraints.maxWidth > 800) {
            crossAxisCount = 3;
          } else if (constraints.maxWidth > 600) {
            crossAxisCount = 2;
          } else {
            crossAxisCount = 1;
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return EventCard(
                event: event,
                onTap: () => _navigateToEventDetail(event),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No events found' : 'No events yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Create your first event to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            _buildCreateEventButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SelectableErrorMessage(
            message: error.toString(),
            title: 'Error loading events',
            backgroundColor:
                FirebaseErrorHandler.isFirebaseIndexError(error.toString())
                    ? Colors.orange
                    : Colors.red,
            onRetry: () {
              ref.invalidate(groupEventsStreamProvider(widget.groupId));
            },
          ),
          /* Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading events',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              ref.invalidate(groupEventsStreamProvider(widget.groupId));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),*/
        ],
      ),
    );
  }

  Widget _buildCreateEventButton() {
    // Get current member from auth state
    final activeMemberAsync = ref.watch(activeMemberProvider);

    return activeMemberAsync.when(
      data: (member) {
        if (member == null) return const SizedBox.shrink();

        // Check if current member is an admin in this group
        final isAdminAsync = ref.watch(isGroupAdminProvider((
          groupId: widget.groupId,
          memberId: member.id,
        )));

        return isAdminAsync.when(
          data: (isAdmin) {
            // Only show create event button to admin users
            if (!isAdmin) return const SizedBox.shrink();

            return FilledButton.icon(
              onPressed: _navigateToCreateEvent,
              icon: const Icon(Icons.add),
              label: const Text('Create Event'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
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

  void _navigateToCreateEvent() async {
    // if (widget.onCreateEvent != null) {
    // Use callback if provided (for inner page navigation)
    widget.onCreateEvent!();
    /* } else {
      // Fall back to navigation (for standalone screen)
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CreateEventScreen(groupId: widget.groupId),
        ),
      );

      // If an event was created, refresh all providers
      if (result == true) {
        _refreshAllProviders();
      }
    } */
  }

  void _navigateToEventDetail(Event event) {
    if (widget.onEventSelected != null) {
      widget.onEventSelected!(event.id);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _EventDetailWrapper(
            eventId: event.id,
            groupId: widget.groupId,
          ),
        ),
      );
    }
  }

  void _refreshAllProviders() {
    // Invalidate the main group events stream (this will refresh all tabs)
    ref.invalidate(groupEventsStreamProvider(widget.groupId));

    // If there's a search query, also refresh search results
    if (_searchQuery.isNotEmpty) {
      ref.invalidate(searchEventsProvider(SearchEventsParams(
        groupId: widget.groupId,
        searchTerm: _searchQuery,
      )));
    }
  }

  /// Build events list with admin check for draft events
  Widget _buildAllEventsWithAdminCheck(List<Event> events) {
    // Get current member from auth state
    final activeMemberAsync = ref.watch(activeMemberProvider);

    return activeMemberAsync.when(
      data: (member) {
        if (member == null) {
          // If no member, filter out draft events
          final filteredEvents =
              events.where((event) => !event.isDraft).toList();
          return _buildEventsList(filteredEvents);
        }

        // Check if current member is an admin in this group
        final isAdminAsync = ref.watch(isGroupAdminProvider((
          groupId: widget.groupId,
          memberId: member.id,
        )));

        return isAdminAsync.when(
          data: (isAdmin) {
            List<Event> filteredEvents;
            if (isAdmin) {
              // Admin can see all events including drafts
              filteredEvents = events;
            } else {
              // Non-admin cannot see draft events
              filteredEvents = events.where((event) => !event.isDraft).toList();
            }
            return _buildEventsList(filteredEvents);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) {
            // On error, filter out draft events for safety
            final filteredEvents =
                events.where((event) => !event.isDraft).toList();
            return _buildEventsList(filteredEvents);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) {
        // On error, filter out draft events for safety
        final filteredEvents = events.where((event) => !event.isDraft).toList();
        return _buildEventsList(filteredEvents);
      },
    );
  }

  /// Build draft events with admin check
  Widget _buildDraftEventsWithAdminCheck(List<Event> draftEvents) {
    // Get current member from auth state
    final activeMemberAsync = ref.watch(activeMemberProvider);

    return activeMemberAsync.when(
      data: (member) {
        if (member == null) {
          // If no member, show empty state
          return _buildEmptyState();
        }

        // Check if current member is an admin in this group
        final isAdminAsync = ref.watch(isGroupAdminProvider((
          groupId: widget.groupId,
          memberId: member.id,
        )));

        return isAdminAsync.when(
          data: (isAdmin) {
            if (isAdmin) {
              // Admin can see draft events
              return _buildEventsList(draftEvents);
            } else {
              // Non-admin cannot see draft events - show empty state
              return _buildNonAdminDraftMessage();
            }
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildNonAdminDraftMessage(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildNonAdminDraftMessage(),
    );
  }

  /// Build message for non-admin users trying to view draft events
  Widget _buildNonAdminDraftMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.admin_panel_settings,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Admin Access Required',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Draft events are only visible to group administrators',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build tabs with admin check for Draft tab visibility
  Widget _buildTabsWithAdminCheck() {
    // Get current member from auth state
    final activeMemberAsync = ref.watch(activeMemberProvider);

    return activeMemberAsync.when(
      data: (member) {
        if (member == null) {
          // If no member, show tabs without Draft tab
          return _buildTabsWithoutDraft();
        }

        // Check if current member is an admin in this group
        final isAdminAsync = ref.watch(isGroupAdminProvider((
          groupId: widget.groupId,
          memberId: member.id,
        )));

        return isAdminAsync.when(
          data: (isAdmin) {
            if (isAdmin) {
              // Admin can see all tabs including Draft
              return _buildAllTabs();
            } else {
              // Non-admin cannot see Draft tab
              return _buildTabsWithoutDraft();
            }
          },
          loading: () => _buildTabsWithoutDraft(),
          error: (_, __) => _buildTabsWithoutDraft(),
        );
      },
      loading: () => _buildTabsWithoutDraft(),
      error: (_, __) => _buildTabsWithoutDraft(),
    );
  }

  /// Build all tabs including Draft (for admins)
  Widget _buildAllTabs() {
    return Expanded(
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Active'),
              Tab(text: 'Scheduled'),
              Tab(text: 'Completed'),
              Tab(text: 'Draft'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllEventsTab(),
                _buildStatusEventsTab(EventStatus.active),
                _buildStatusEventsTab(EventStatus.scheduled),
                _buildStatusEventsTab(EventStatus.completed),
                _buildStatusEventsTab(EventStatus.draft),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build tabs without Draft tab (for non-admins)
  Widget _buildTabsWithoutDraft() {
    // Create TabController for non-admin if not exists
    _nonAdminTabController ??= TabController(length: 4, vsync: this);

    // Adjust initial tab index if it was pointing to Draft tab
    if (_tabController.index == 4) {
      _nonAdminTabController!.index = 0; // Default to All tab
    } else if (_tabController.index < 4) {
      _nonAdminTabController!.index = _tabController.index;
    }

    return Expanded(
      child: Column(
        children: [
          TabBar(
            controller: _nonAdminTabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Active'),
              Tab(text: 'Scheduled'),
              Tab(text: 'Completed'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _nonAdminTabController,
              children: [
                _buildAllEventsTab(),
                _buildStatusEventsTab(EventStatus.active),
                _buildStatusEventsTab(EventStatus.scheduled),
                _buildStatusEventsTab(EventStatus.completed),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Wrapper widget to handle group name fetching for EventDetailInnerPage
class _EventDetailWrapper extends ConsumerWidget {
  final String eventId;
  final String groupId;

  const _EventDetailWrapper({
    required this.eventId,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupProvider(groupId));
    final eventAsync = ref.watch(eventStreamProvider(eventId));

    return Scaffold(
      appBar: AppBar(
        title: eventAsync.when(
          data: (event) => Text(event?.title ?? 'Event Details'),
          loading: () => const Text('Event Details'),
          error: (_, __) => const Text('Event Details'),
        ),
      ),
      body: groupAsync.when(
        data: (group) => EventDetailInnerPage(
          eventId: eventId,
          groupName: group?.name ?? 'Unknown Group',
          onBack: () => Navigator.of(context).pop(),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading group',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
