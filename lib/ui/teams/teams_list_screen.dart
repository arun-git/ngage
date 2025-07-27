import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/team_providers.dart';
import '../../models/team.dart';
import '../widgets/team_avatar.dart';
import 'create_team_screen.dart';
import 'team_detail_screen.dart';

class TeamsListScreen extends ConsumerWidget {
  final String groupId;

  const TeamsListScreen({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(groupTeamsProvider(groupId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teams'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCreateTeam(context),
            tooltip: 'Create Team',
          ),
        ],
      ),
      body: teamsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _buildErrorState(context, ref, error),
        data: (teams) => _buildTeamsList(context, teams),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateTeam(context),
        tooltip: 'Create Team',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error loading teams',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(groupTeamsProvider(groupId)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsList(BuildContext context, List<Team> teams) {
    if (teams.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh is handled automatically by Riverpod
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: teams.length,
        itemBuilder: (context, index) {
          final team = teams[index];
          return _buildTeamCard(context, team);
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
                color: Colors.grey[400],
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

  Widget _buildTeamCard(BuildContext context, Team team) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToTeamDetail(context, team.id),
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
                    radius: 28,
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
                              Theme.of(context).textTheme.titleLarge?.copyWith(
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildMemberCountChip(context, team),
                      if (team.maxMembers != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Max: ${team.maxMembers}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                team.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Lead: ${team.teamLeadId}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const Spacer(),
                  if (!team.isActive) ...[
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
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCountChip(BuildContext context, Team team) {
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
        ],
      ),
    );
  }

  void _navigateToCreateTeam(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateTeamScreen(
          groupId: groupId,
          groupName: 'Group', // TODO: Pass actual group name
        ),
      ),
    );
  }

  void _navigateToTeamDetail(BuildContext context, String teamId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TeamDetailScreen(
          teamId: teamId,
          groupName: 'Group', // TODO: Pass actual group name
        ),
      ),
    );
  }
}
