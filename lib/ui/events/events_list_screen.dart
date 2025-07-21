import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/event_providers.dart';
import 'event_card.dart';
import 'create_event_screen.dart';
import 'event_detail_screen.dart';

/// Screen displaying list of events for a group
class EventsListScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String? initialFilter;

  const EventsListScreen({
    super.key,
    required this.groupId,
    this.initialFilter,
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
      appBar: AppBar(
        title: const Text('Events'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllEventsTab(),
          _buildStatusEventsTab(EventStatus.active),
          _buildStatusEventsTab(EventStatus.scheduled),
          _buildStatusEventsTab(EventStatus.completed),
          _buildStatusEventsTab(EventStatus.draft),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateEvent(),
        child: const Icon(Icons.add),
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

    final params = EventsByStatusParams(groupId: widget.groupId, status: status);
    final eventsAsync = ref.watch(eventsByStatusProvider(params));
    
    return eventsAsync.when(
      data: (events) => _buildEventsList(events),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(error),
    );
  }

  Widget _buildSearchResults() {
    final params = SearchEventsParams(groupId: widget.groupId, searchTerm: _searchQuery);
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
        ref.invalidate(groupEventsStreamProvider(widget.groupId));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: EventCard(
              event: event,
              onTap: () => _navigateToEventDetail(event),
            ),
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
          Icon(
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
          ),
        ],
      ),
    );
  }

  void _navigateToCreateEvent() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateEventScreen(groupId: widget.groupId),
      ),
    );
  }

  void _navigateToEventDetail(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(eventId: event.id),
      ),
    );
  }
}