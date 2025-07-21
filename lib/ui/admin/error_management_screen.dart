import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/error_providers.dart';
import '../../services/error_reporting_service.dart';
import '../../utils/logger.dart';
import '../widgets/error_widgets.dart';

/// Screen for administrators to manage errors and view logs
class ErrorManagementScreen extends ConsumerStatefulWidget {
  const ErrorManagementScreen({super.key});

  @override
  ConsumerState<ErrorManagementScreen> createState() => _ErrorManagementScreenState();
}

class _ErrorManagementScreenState extends ConsumerState<ErrorManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
        title: const Text('Error Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Error Reports', icon: Icon(Icons.bug_report)),
            Tab(text: 'System Logs', icon: Icon(Icons.list_alt)),
            Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ErrorReportsTab(),
          SystemLogsTab(),
          ErrorStatisticsTab(),
        ],
      ),
    );
  }
}

/// Tab for viewing and managing error reports
class ErrorReportsTab extends ConsumerWidget {
  const ErrorReportsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openReports = ref.watch(errorReportsByStatusProvider(ErrorReportStatus.open));

    return openReports.when(
      data: (reports) => _buildReportsList(context, ref, reports),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorDisplayWidget(
        error: error,
        stackTrace: stack,
        onRetry: () => ref.refresh(errorReportsByStatusProvider(ErrorReportStatus.open)),
      ),
    );
  }

  Widget _buildReportsList(BuildContext context, WidgetRef ref, List<ErrorReport> reports) {
    if (reports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('No open error reports', style: TextStyle(fontSize: 18)),
            Text('Great job! All issues have been resolved.'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return _buildReportCard(context, ref, report);
      },
    );
  }

  Widget _buildReportCard(BuildContext context, WidgetRef ref, ErrorReport report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          _getReportIcon(report.type),
          color: _getPriorityColor(report.priority),
        ),
        title: Text(
          report.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Priority: ${report.priority.name.toUpperCase()}'),
            Text('Type: ${report.type.name}'),
            Text('Created: ${_formatDate(report.createdAt)}'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(report.description),
                if (report.technicalDetails != null) ...[
                  const SizedBox(height: 16),
                  const Text('Technical Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      report.technicalDetails.toString(),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _updateReportStatus(ref, report, ErrorReportStatus.inProgress),
                      child: const Text('In Progress'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _updateReportStatus(ref, report, ErrorReportStatus.resolved),
                      child: const Text('Resolve'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _updateReportStatus(ref, report, ErrorReportStatus.closed),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getReportIcon(ErrorReportType type) {
    switch (type) {
      case ErrorReportType.bug:
        return Icons.bug_report;
      case ErrorReportType.crash:
        return Icons.error;
      case ErrorReportType.performance:
        return Icons.speed;
      case ErrorReportType.ui:
        return Icons.design_services;
      case ErrorReportType.feature:
        return Icons.lightbulb;
      case ErrorReportType.other:
        return Icons.help;
    }
  }

  Color _getPriorityColor(ErrorReportPriority priority) {
    switch (priority) {
      case ErrorReportPriority.low:
        return Colors.green;
      case ErrorReportPriority.medium:
        return Colors.orange;
      case ErrorReportPriority.high:
        return Colors.red;
      case ErrorReportPriority.critical:
        return Colors.purple;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _updateReportStatus(WidgetRef ref, ErrorReport report, ErrorReportStatus status) async {
    try {
      final errorReportingService = ref.read(errorReportingServiceProvider);
      await errorReportingService.updateErrorReportStatus(report.id, status);
      
      // Refresh the reports list
      ref.refresh(errorReportsByStatusProvider(ErrorReportStatus.open));
    } catch (e) {
      // Handle error updating status
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(
          content: Text('Failed to update report status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Tab for viewing system logs
class SystemLogsTab extends ConsumerStatefulWidget {
  const SystemLogsTab({super.key});

  @override
  ConsumerState<SystemLogsTab> createState() => _SystemLogsTabState();
}

class _SystemLogsTabState extends ConsumerState<SystemLogsTab> {
  LogLevel _selectedLevel = LogLevel.info;

  @override
  Widget build(BuildContext context) {
    final logger = ref.watch(loggerProvider);
    final logs = logger.getLogsByLevel(_selectedLevel);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Filter by level: '),
              const SizedBox(width: 8),
              DropdownButton<LogLevel>(
                value: _selectedLevel,
                items: LogLevel.values.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(level.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (level) {
                  if (level != null) {
                    setState(() {
                      _selectedLevel = level;
                    });
                  }
                },
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _exportLogs(logger),
                child: const Text('Export Logs'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildLogsList(logs),
        ),
      ],
    );
  }

  Widget _buildLogsList(List<LogEntry> logs) {
    if (logs.isEmpty) {
      return const Center(
        child: Text('No logs found for the selected level'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return _buildLogCard(log);
      },
    );
  }

  Widget _buildLogCard(LogEntry log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(
          _getLogIcon(log.level),
          color: _getLogColor(log.level),
        ),
        title: Text(
          log.message,
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          '${log.level.name.toUpperCase()} • ${_formatDate(log.timestamp)}${log.category != null ? ' • ${log.category}' : ''}',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (log.error != null) ...[
                  const Text('Error:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(log.error.toString()),
                  const SizedBox(height: 8),
                ],
                if (log.stackTrace != null) ...[
                  const Text('Stack Trace:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      log.stackTrace.toString(),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (log.context != null) ...[
                  const Text('Context:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(log.context.toString()),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getLogIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.info:
        return Icons.info;
      case LogLevel.warning:
        return Icons.warning;
      case LogLevel.error:
        return Icons.error;
      case LogLevel.critical:
        return Icons.dangerous;
    }
  }

  Color _getLogColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.critical:
        return Colors.purple;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  void _exportLogs(Logger logger) {
    final jsonString = logger.exportLogsAsJson();
    // In a real implementation, you would save this to a file or share it
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logs exported to JSON format'),
      ),
    );
  }
}

/// Tab for viewing error statistics
class ErrorStatisticsTab extends ConsumerWidget {
  const ErrorStatisticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(errorReportStatsProvider);

    return statsAsync.when(
      data: (stats) => _buildStatistics(context, stats),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorDisplayWidget(
        error: error,
        stackTrace: stack,
        onRetry: () => ref.refresh(errorReportStatsProvider),
      ),
    );
  }

  Widget _buildStatistics(BuildContext context, Map<String, dynamic> stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCard('Total Reports', stats['total']?.toString() ?? '0'),
          const SizedBox(height: 16),
          const Text('By Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._buildStatItems(stats['byStatus'] ?? {}),
          const SizedBox(height: 16),
          const Text('By Type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._buildStatItems(stats['byType'] ?? {}),
          const SizedBox(height: 16),
          const Text('By Priority', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._buildStatItems(stats['byPriority'] ?? {}),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStatItems(Map<String, dynamic> items) {
    return items.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(entry.key.toUpperCase()),
            Text(entry.value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }).toList();
  }
}