import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/models.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/member_providers.dart';
import '../../../providers/group_providers.dart';
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
    // Get current member from auth state
    final activeMemberAsync = ref.watch(activeMemberProvider);

    return activeMemberAsync.when(
      data: (member) {
        if (member == null) return const SizedBox.shrink();

        // Check if current member has judge or admin permissions in this group
        final membershipAsync = ref.watch(groupMembershipProvider((
          groupId: event.groupId,
          memberId: member.id,
        )));

        return membershipAsync.when(
          data: (membership) {
            if (membership == null || !membership.canJudge) {
              return const SizedBox.shrink();
            }

            return _buildJudgeAccessCard(context, membership.role);
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildJudgeAccessCard(BuildContext context, GroupRole role) {
    final isAdmin = role == GroupRole.admin;
    final roleLabel = isAdmin ? 'Admin' : 'Judge';
    final roleColor = isAdmin ? Colors.red : Colors.purple;

    return Card(
      color: roleColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAdmin ? Icons.admin_panel_settings : Icons.gavel,
                  color: roleColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Judging Access',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: roleColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isAdmin
                  ? 'You have admin permissions in this group. Access the judging dashboard to manage scoring, review submissions, and oversee the judging process.'
                  : 'You have judge permissions in this group. Access the judging dashboard to score submissions and collaborate with other judges.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: roleColor.withOpacity(0.3)),
              ),
              child: Text(
                'Role: $roleLabel',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: roleColor,
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
                  backgroundColor: roleColor,
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
}
