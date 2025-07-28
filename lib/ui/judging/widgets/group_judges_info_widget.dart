import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/models.dart';
import '../../../providers/group_providers.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/member_providers.dart';

/// Widget that shows group-level judges who can judge events (Admin only)
class GroupJudgesInfoWidget extends ConsumerWidget {
  final String groupId;
  final String groupName;

  const GroupJudgesInfoWidget({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current member from auth state
    final activeMemberAsync = ref.watch(activeMemberProvider);

    return activeMemberAsync.when(
      data: (member) {
        if (member == null) return const SizedBox.shrink();

        // Check if current member is an admin in this group
        final membershipAsync = ref.watch(groupMembershipProvider((
          groupId: groupId,
          memberId: member.id,
        )));

        return membershipAsync.when(
          data: (membership) {
            if (membership == null || !membership.isAdmin) {
              return const SizedBox.shrink();
            }

            return _buildGroupJudgesCard(context, ref);
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildGroupJudgesCard(BuildContext context, WidgetRef ref) {
    final groupMembersAsync = ref.watch(groupMembersProvider(groupId));

    return Card(
      color: Colors.red.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Group Judges Management',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _openMemberManagement(context),
                  icon: const Icon(Icons.settings, size: 16),
                  label: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'As an admin, you can manage judge permissions. Members with judge permissions can score submissions for all events in this group.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 16),
            groupMembersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text(
                'Error loading members: $error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              data: (members) => _buildJudgesList(context, members),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJudgesList(BuildContext context, List<GroupMember> members) {
    final judges = members.where((member) => member.canJudge).toList();

    if (judges.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.outline,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No judges assigned yet. Assign judge roles to group members to enable scoring.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '${judges.length} judge${judges.length == 1 ? '' : 's'} available',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Show first few judges
        ...judges.take(5).map((judge) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    _getRoleIcon(judge.role),
                    size: 16,
                    color: _getRoleColor(judge.role),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Member ${judge.memberId.length > 8 ? judge.memberId.substring(0, 8) : judge.memberId}... (${_getRoleLabel(judge.role)})',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            )),

        if (judges.length > 5)
          Text(
            '... and ${judges.length - 5} more judges',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),

        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openMemberManagement(context),
            icon: const Icon(Icons.person_add, size: 16),
            label: const Text('Manage Judge Roles'),
          ),
        ),
      ],
    );
  }

  void _openMemberManagement(context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Navigate to group member management to assign judge roles'),
      ),
    );
  }

  IconData _getRoleIcon(GroupRole role) {
    switch (role) {
      case GroupRole.admin:
        return Icons.admin_panel_settings;
      case GroupRole.judge:
        return Icons.gavel;
      case GroupRole.teamLead:
        return Icons.group;
      case GroupRole.member:
        return Icons.person;
    }
  }

  Color _getRoleColor(GroupRole role) {
    switch (role) {
      case GroupRole.admin:
        return Colors.red;
      case GroupRole.judge:
        return Colors.purple;
      case GroupRole.teamLead:
        return Colors.blue;
      case GroupRole.member:
        return Colors.grey;
    }
  }

  String _getRoleLabel(GroupRole role) {
    switch (role) {
      case GroupRole.admin:
        return 'Administrator';
      case GroupRole.judge:
        return 'Judge';
      case GroupRole.teamLead:
        return 'Team Lead';
      case GroupRole.member:
        return 'Member';
    }
  }
}
