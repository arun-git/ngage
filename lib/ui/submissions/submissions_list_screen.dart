import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/submission.dart';
import '../../models/enums.dart';
import '../../providers/submission_providers.dart';
import 'submission_screen.dart';
import 'widgets/submission_status_indicator.dart';
import 'widgets/submission_card.dart';

/// Screen that displays a list of submissions for an event
class SubmissionsListScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String? teamId; // Optional filter by team
  final bool isJudgeView; // Whether this is for judges to review

  const SubmissionsListScreen({
    super.key,
    required this.eventId,
    this.teamId,
    this.isJudgeView = false,
  });

  @override
  ConsumerState<SubmissionsListScreen> createState() => _SubmissionsListScreenState();
}

class _SubmissionsListScreenState extends ConsumerState<SubmissionsListScreen> {
  List<Submission> _submissions = [];
  bool _isLoading = true;
  String? _error;
  SubmissionStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final submissionService = ref.read(submissionServiceProvider);
      List<Submission> submissions;
      
      if (widget.teamId != null) {
        submissions = await submissionService.getTeamSubmissions(widget.teamId!);
        // Filter by event ID
        submissions = submissions.where((s) => s.eventId == widget.eventId).toList();
      } else {
        submissions = await submissionService.getEventSubmissions(widget.eventId);
      }

      setState(() {
        _submissions = submissions;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load submissions: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Submission> get _filteredSubmissions {
    if (_statusFilter == null) return _submissions;
    return _submissions.where((s) => s.status == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isJudgeView ? 'Review Submissions' : 'Submissions'),
        actions: [
          // Status filter
          PopupMenuButton<SubmissionStatus?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by status',
            onSelected: (status) {
              setState(() {
                _statusFilter = status;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Submissions'),
              ),
              ...SubmissionStatus.values.map((status) => PopupMenuItem(
                value: status,
                child: Row(
                  children: [
                    SubmissionStatusIndicator(status: status, showLabel: false),
                    const SizedBox(width: 8),
                    Text(status.value.replaceAll('_', ' ').toUpperCase()),
                  ],
                ),
              )),
            ],
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubmissions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSubmissions,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredSubmissions = _filteredSubmissions;

    if (filteredSubmissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              _statusFilter == null 
                  ? 'No submissions yet'
                  : 'No submissions with selected status',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (_statusFilter != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _statusFilter = null;
                  });
                },
                child: const Text('Clear filter'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSubmissions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredSubmissions.length,
        itemBuilder: (context, index) {
          final submission = filteredSubmissions[index];
          return SubmissionCard(
            submission: submission,
            onTap: () => _openSubmission(submission),
          );
        },
      ),
    );
  }



  void _openSubmission(Submission submission) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubmissionScreen(
          eventId: submission.eventId,
          teamId: submission.teamId,
          memberId: submission.submittedBy,
          submissionId: submission.id,
        ),
      ),
    );
  }
}