import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../repositories/leaderboard_repository.dart';
import '../../providers/leaderboard_providers.dart';
import 'widgets/leaderboard_filters_widget.dart';
import 'widgets/leaderboard_display_widget.dart';
import 'widgets/score_trend_widget.dart';
import 'widgets/individual_leaderboard_widget.dart';

/// Main leaderboard screen with filtering and real-time updates
class LeaderboardScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String? initialTeamId; // For highlighting specific team

  const LeaderboardScreen({
    super.key,
    required this.eventId,
    this.initialTeamId,
  });

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Filter and sort state
  LeaderboardFilter? _currentFilter;
  LeaderboardSort _currentSort = const LeaderboardSort(
    field: LeaderboardSortField.averageScore,
    ascending: false,
  );
  
  // Display options
  bool _showCriteriaBreakdown = false;
  bool _autoRefresh = true;
  LeaderboardViewMode _viewMode = LeaderboardViewMode.table;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          IconButton(
            icon: Icon(_autoRefresh ? Icons.sync : Icons.sync_disabled),
            onPressed: () => setState(() => _autoRefresh = !_autoRefresh),
            tooltip: _autoRefresh ? 'Disable Auto Refresh' : 'Enable Auto Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshLeaderboard(),
            tooltip: 'Refresh Now',
          ),
          PopupMenuButton<LeaderboardViewMode>(
            icon: const Icon(Icons.view_list),
            onSelected: (mode) => setState(() => _viewMode = mode),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: LeaderboardViewMode.table,
                child: ListTile(
                  leading: Icon(Icons.table_rows),
                  title: Text('Table View'),
                ),
              ),
              const PopupMenuItem(
                value: LeaderboardViewMode.cards,
                child: ListTile(
                  leading: Icon(Icons.view_agenda),
                  title: Text('Card View'),
                ),
              ),
              const PopupMenuItem(
                value: LeaderboardViewMode.podium,
                child: ListTile(
                  leading: Icon(Icons.emoji_events),
                  title: Text('Podium View'),
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.groups), text: 'Teams'),
            Tab(icon: Icon(Icons.person), text: 'Individuals'),
            Tab(icon: Icon(Icons.trending_up), text: 'Trends'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filters section
          LeaderboardFiltersWidget(
            currentFilter: _currentFilter,
            currentSort: _currentSort,
            showCriteriaBreakdown: _showCriteriaBreakdown,
            onFilterChanged: (filter) => setState(() => _currentFilter = filter),
            onSortChanged: (sort) => setState(() => _currentSort = sort),
            onShowCriteriaChanged: (show) => setState(() => _showCriteriaBreakdown = show),
          ),
          
          // Main content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Team leaderboard
                _buildTeamLeaderboard(),
                
                // Individual leaderboard
                _buildIndividualLeaderboard(),
                
                // Trends and analytics
                _buildTrendsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLeaderboard() {
    final leaderboardRequest = LeaderboardRequest(
      eventId: widget.eventId,
      filter: _currentFilter,
      sort: _currentSort,
    );

    if (_autoRefresh) {
      // Use stream provider for real-time updates
      final leaderboardAsync = ref.watch(eventLeaderboardStreamProvider(widget.eventId));
      
      return leaderboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorWidget(error),
        data: (leaderboard) => LeaderboardDisplayWidget(
          leaderboard: leaderboard,
          viewMode: _viewMode,
          showCriteriaBreakdown: _showCriteriaBreakdown,
          highlightTeamId: widget.initialTeamId,
          filter: _currentFilter,
          sort: _currentSort,
        ),
      );
    } else {
      // Use future provider for manual refresh
      final leaderboardAsync = ref.watch(filteredLeaderboardProvider(leaderboardRequest));
      
      return leaderboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorWidget(error),
        data: (leaderboard) => LeaderboardDisplayWidget(
          leaderboard: leaderboard,
          viewMode: _viewMode,
          showCriteriaBreakdown: _showCriteriaBreakdown,
          highlightTeamId: widget.initialTeamId,
          filter: _currentFilter,
          sort: _currentSort,
        ),
      );
    }
  }

  Widget _buildIndividualLeaderboard() {
    if (_autoRefresh) {
      final leaderboardAsync = ref.watch(individualLeaderboardStreamProvider(widget.eventId));
      
      return leaderboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorWidget(error),
        data: (leaderboard) => IndividualLeaderboardWidget(
          leaderboard: leaderboard,
          viewMode: _viewMode,
          showCriteriaBreakdown: _showCriteriaBreakdown,
        ),
      );
    } else {
      final leaderboardAsync = ref.watch(individualLeaderboardProvider(widget.eventId));
      
      return leaderboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorWidget(error),
        data: (leaderboard) => IndividualLeaderboardWidget(
          leaderboard: leaderboard,
          viewMode: _viewMode,
          showCriteriaBreakdown: _showCriteriaBreakdown,
        ),
      );
    }
  }

  Widget _buildTrendsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event statistics
          _buildEventStatistics(),
          
          const SizedBox(height: 24),
          
          // Score trends for highlighted team
          if (widget.initialTeamId != null) ...[
            Text(
              'Team Performance Trend',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ScoreTrendWidget(
              teamId: widget.initialTeamId!,
              period: const Duration(days: 30),
            ),
            const SizedBox(height: 24),
          ],
          
          // Leaderboard history
          _buildLeaderboardHistory(),
        ],
      ),
    );
  }

  Widget _buildEventStatistics() {
    final statisticsAsync = ref.watch(leaderboardStatisticsProvider(widget.eventId));
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event Statistics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            statisticsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error loading statistics: $error'),
              data: (stats) => _buildStatisticsContent(stats),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsContent(LeaderboardStatistics stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Snapshots',
                stats.totalSnapshots.toString(),
                Icons.camera_alt,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Avg Teams',
                stats.averageTeamCount.toStringAsFixed(1),
                Icons.groups,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Avg Score',
                stats.averageScore.toStringAsFixed(1),
                Icons.score,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Score Range',
                '${stats.lowestScore.toStringAsFixed(1)} - ${stats.highestScore.toStringAsFixed(1)}',
                Icons.trending_up,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardHistory() {
    final snapshotsRequest = LeaderboardSnapshotRequest(
      eventId: widget.eventId,
      limit: 10,
    );
    
    final snapshotsAsync = ref.watch(leaderboardSnapshotsProvider(snapshotsRequest));
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leaderboard History',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            snapshotsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error loading history: $error'),
              data: (snapshots) => _buildHistoryList(snapshots),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<Leaderboard> snapshots) {
    if (snapshots.isEmpty) {
      return const Center(
        child: Text('No leaderboard history available'),
      );
    }

    return Column(
      children: snapshots.take(5).map((snapshot) => ListTile(
        leading: CircleAvatar(
          child: Text(snapshot.teamCount.toString()),
        ),
        title: Text('${snapshot.teamCount} teams'),
        subtitle: Text(_formatDateTime(snapshot.calculatedAt)),
        trailing: snapshot.firstPlace != null
            ? Text(
                '${snapshot.firstPlace!.teamName}: ${snapshot.firstPlace!.averageScore.toStringAsFixed(1)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            : null,
      )).toList(),
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading leaderboard',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _refreshLeaderboard(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _refreshLeaderboard() {
    ref.invalidate(eventLeaderboardProvider(widget.eventId));
    ref.invalidate(individualLeaderboardProvider(widget.eventId));
    ref.invalidate(leaderboardStatisticsProvider(widget.eventId));
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

/// Leaderboard view mode enumeration
enum LeaderboardViewMode {
  table,
  cards,
  podium,
}