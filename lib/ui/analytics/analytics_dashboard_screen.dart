import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/analytics.dart';
import '../../providers/analytics_providers.dart';
import 'widgets/analytics_filter_widget.dart';
import 'widgets/participation_metrics_card.dart';
import 'widgets/judge_activity_card.dart';
import 'widgets/engagement_metrics_card.dart';
import 'widgets/trends_chart_widget.dart';
import 'widgets/analytics_summary_card.dart';

class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  final String groupId;

  const AnalyticsDashboardScreen({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends ConsumerState<AnalyticsDashboardScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  String? _selectedEventId;
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.monthly;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = _endDate.subtract(const Duration(days: 30));
  }

  @override
  Widget build(BuildContext context) {
    final analyticsParams = AnalyticsMetricsParams(
      groupId: widget.groupId,
      startDate: _startDate,
      endDate: _endDate,
      eventId: _selectedEventId,
    );

    final trendsParams = TrendsParams(
      groupId: widget.groupId,
      startDate: _startDate,
      endDate: _endDate,
      period: _selectedPeriod,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(analyticsMetricsProvider);
              ref.invalidate(trendsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportReport(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: AnalyticsFilterWidget(
              startDate: _startDate,
              endDate: _endDate,
              selectedEventId: _selectedEventId,
              selectedPeriod: _selectedPeriod,
              groupId: widget.groupId,
              onFilterChanged: (startDate, endDate, eventId, period) {
                setState(() {
                  _startDate = startDate;
                  _endDate = endDate;
                  _selectedEventId = eventId;
                  _selectedPeriod = period;
                });
              },
            ),
          ),
          
          // Dashboard Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Section
                  ref.watch(analyticsMetricsProvider(analyticsParams)).when(
                    data: (metrics) => AnalyticsSummaryCard(metrics: metrics),
                    loading: () => const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                    error: (error, stack) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Error loading summary: $error',
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Metrics Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWideScreen = constraints.maxWidth > 1200;
                      final crossAxisCount = isWideScreen ? 3 : (constraints.maxWidth > 800 ? 2 : 1);
                      
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.2,
                        children: [
                          // Participation Metrics
                          ref.watch(participationMetricsProvider(analyticsParams)).when(
                            data: (metrics) => ParticipationMetricsCard(metrics: metrics),
                            loading: () => const Card(
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (error, stack) => Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Theme.of(context).colorScheme.error,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Error loading participation data',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // Judge Activity Metrics
                          ref.watch(judgeActivityMetricsProvider(analyticsParams)).when(
                            data: (metrics) => JudgeActivityCard(metrics: metrics),
                            loading: () => const Card(
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (error, stack) => Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Theme.of(context).colorScheme.error,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Error loading judge activity data',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // Engagement Metrics
                          ref.watch(engagementMetricsProvider(EngagementMetricsParams(
                            groupId: widget.groupId,
                            startDate: _startDate,
                            endDate: _endDate,
                          ))).when(
                            data: (metrics) => EngagementMetricsCard(metrics: metrics),
                            loading: () => const Card(
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (error, stack) => Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Theme.of(context).colorScheme.error,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Error loading engagement data',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Trends Section
                  Text(
                    'Trends Analysis',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  
                  ref.watch(trendsProvider(trendsParams)).when(
                    data: (trendsData) => TrendsChartWidget(
                      trendsData: trendsData,
                      period: _selectedPeriod,
                    ),
                    loading: () => const Card(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                    error: (error, stack) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.trending_up,
                              color: Theme.of(context).colorScheme.error,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Error loading trends data: $error',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _exportReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Report'),
        content: const Text('Report export functionality will be implemented in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}