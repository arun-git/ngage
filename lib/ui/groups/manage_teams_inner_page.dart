import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/team.dart';
import '../../providers/team_providers.dart';
import '../../ui/widgets/selectable_error_message.dart';
import '../../utils/firebase_error_handler.dart';
import '../teams/create_team_screen.dart';
import '../teams/team_detail_screen.dart';
import '../widgets/team_avatar.dart';

/// Inner page for managing teams within a group that replaces the group detail content
class ManageTeamsInnerPage extends ConsumerWidget {
  final String groupId;
  final String groupName;
  final VoidCallback onBack;
  final Function(String)? onTeamSelected;

  const ManageTeamsInnerPage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.onBack,
    this.onTeamSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(groupTeamsProvider(groupId));

    return Column(
      children: [
        // Create team action bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Manage Teams',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _navigateToCreateTeam(context),
                tooltip: 'Create Team',
              ),
            ],
          ),
        ),

        // Teams content
        Expanded(
          child: teamsAsync.when(
            data: (teams) => _buildTeamsContent(context, ref, teams),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorState(context, ref, error),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamsContent(
      BuildContext context, WidgetRef ref, List<Team> teams) {
    if (teams.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(groupTeamsProvider(groupId));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: teams.length,
        itemBuilder: (context, index) {
          final team = teams[index];
          return _TeamManagementCard(
            team: team,
            onTap: () => _navigateToTeamDetail(context, team),
            onEdit: () => _editTeam(context, team),
            onDelete: () => _deleteTeam(context, ref, team),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Icon(
                Icons.groups_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    size: 16,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'No Teams Yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first team with a custom logo to get started',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreateTeam(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Team'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading teams',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SelectableErrorMessage(
              message: error.toString(),
              title: 'Error Details',
              backgroundColor:
                  FirebaseErrorHandler.isFirebaseIndexError(error.toString())
                      ? Colors.orange
                      : Colors.red,
              onRetry: () {
                ref.invalidate(groupTeamsProvider(groupId));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateTeam(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateTeamScreen(
          groupId: groupId,
          groupName: groupName,
        ),
      ),
    );
  }

  void _navigateToTeamDetail(BuildContext context, Team team) {
    if (onTeamSelected != null) {
      onTeamSelected!(team.id);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TeamDetailScreen(
            teamId: team.id,
            groupName: groupName,
          ),
        ),
      );
    }
  }

  void _editTeam(BuildContext context, Team team) {
    // TODO: Navigate to edit team screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit team functionality coming soon')),
    );
  }

  Future<void> _deleteTeam(
      BuildContext context, WidgetRef ref, Team team) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this team?'),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone. All team data will be permanently deleted.',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            Text(
              'Team: ${team.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final teamNotifier = ref.read(teamManagementProvider.notifier);
        await teamNotifier.deleteTeam(team.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Team deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete team: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

/// Card widget for team management
class _TeamManagementCard extends StatelessWidget {
  final Team team;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TeamManagementCard({
    required this.team,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Team Avatar
                  TeamAvatar(
                    team: team,
                    radius: 24,
                    showBorder: true,
                    isSquare: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        if (team.teamType != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              team.teamType!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit Team'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete Team'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                team.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMemberCountChip(context),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Lead: ${team.teamLeadId}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const Spacer(),
                  if (!team.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Inactive',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCountChip(BuildContext context) {
    final isAtCapacity = team.isAtCapacity;
    final color = isAtCapacity ? Colors.orange : Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAtCapacity ? Icons.group : Icons.group_outlined,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${team.memberCount}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (team.maxMembers != null) ...[
            Text(
              '/${team.maxMembers}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
