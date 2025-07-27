import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/models.dart';
import '../judging_dashboard_screen.dart';

/// Widget that provides navigation to judging features for group-level judges
class JudgeNavigationWidget extends ConsumerWidget {
  final String eventId;
  final String currentUserId;
  final Event event;

  const JudgeNavigationWidget({
    super.key,
    required this.eventId,
    required this.currentUserId,
    required this.event,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For now, show judge access to demonstrate the interface
    // In a real implementation, you would check if currentUserId
    // corresponds to a member with judge permissions in this group
    final isJudge = _checkIfUserIsJudge(currentUserId, event.groupId);

    if (!isJudge) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.purple.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.gavel,
                  color: Colors.purple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Judge Access',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'You have judge permissions in this group. Access the judging dashboard to score submissions and collaborate with other judges.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.withOpacity(0.3)),
              ),
              child: Text(
                'Role: Judge',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.purple,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openJudgingDashboard(context),
                icon: const Icon(Icons.dashboard, size: 16),
                label: const Text('Open Judging Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openJudgingDashboard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JudgingDashboardScreen(
          eventId: eventId,
          currentUserId: currentUserId,
        ),
      ),
    );
  }

  /// Check if the current user has judge permissions in the group
  /// This is a placeholder implementation - in a real app, you would:
  /// 1. Get the member record for the current user
  /// 2. Check if that member has a GroupMember record with judge role
  /// 3. Return true if they can judge
  bool _checkIfUserIsJudge(String userId, String groupId) {
    // Placeholder: For demo purposes, show judge interface
    // In production, implement proper permission checking
    return true; // TODO: Implement proper judge permission checking
  }
}
