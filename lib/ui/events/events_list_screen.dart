import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/event_providers.dart';
import '../../providers/group_providers.dart';
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
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
                FilledButton.icon(
                  onPressed: _navigateToCreateEvent,
                  icon: const Icon(Icons.add),
                  label: const Text('Create'),
                ),
              ],
            ),
          ),
          // Tabs
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
          // Tab content
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

  Widget _buildAllEventsTab() {
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResults();
    }

    final eventsAsync = ref.watch(groupEventsStreamProvider(widget.groupId));

    return eventsAsync.when(
      data: (events) => _buildEventsList(events),
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
        final filteredEvents =
            allEvents.where((event) => event.status == status).toList();
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
      data: (events) => _buildEventsList(events),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(error),
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
            FilledButton.icon(
              onPressed: _navigateToCreateEvent,
              icon: const Icon(Icons.add),
              label: const Text('Create Event'),
            ),
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
