import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/team_providers.dart';
import '../../models/team.dart';
import '../widgets/breadcrumb_navigation.dart';
import '../widgets/team_logo_picker.dart';
import 'manage_team_members_screen.dart';
import 'team_settings_screen.dart';
import 'team_analytics_widget.dart';

class TeamDetailScreen extends ConsumerWidget {
  final String teamId;
  final String? groupName;

  const TeamDetailScreen({
    super.key,
    required this.teamId,
    this.groupName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamProvider(teamId));
    final teamStatsAsync = ref.watch(teamStatsProvider(teamId));

    return Scaffold(
      body: teamAsync.when(
        loading: () => const Scaffold(
          appBar: null,
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: _buildErrorState(context, ref, error),
        ),
        data: (team) {
          if (team == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Team Not Found')),
              body: _buildNotFoundState(context),
            );
          }
          return _buildTeamDetail(context, ref, team, teamStatsAsync);
        },
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
            'Error loading team',
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
            onPressed: () => ref.refresh(teamProvider(teamId)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Team Not Found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'The team you are looking for does not exist or has been deleted.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamDetail(BuildContext context, WidgetRef ref, Team team,
      AsyncValue<Map<String, dynamic>> teamStatsAsync) {
    return Scaffold(
      appBar: AppBar(
        title: Text(team.name),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value, team),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Team Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'manage_members',
                child: ListTile(
                  leading: Icon(Icons.people),
                  title: Text('Manage Members'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Breadcrumb navigation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: BreadcrumbNavigation(
              items: [
                BreadcrumbItem(
                  title: '',
                  icon: Icons.home_filled,
                  onTap: () => Navigator.of(context).popUntil(
                    (route) =>
                        route.settings.name == '/groups' || route.isFirst,
                  ),
                ),
                if (groupName != null)
                  BreadcrumbItem(
                    title: groupName!,
                    onTap: () => Navigator.of(context).popUntil(
                      (route) =>
                          route.settings.name?.contains('group_detail') ==
                              true ||
                          route.isFirst,
                    ),
                  ),
                BreadcrumbItem(
                  title: 'Manage Teams',
                  onTap: () => Navigator.of(context).pop(),
                ),
                BreadcrumbItem(
                  title: team.name,
                  icon: Icons.groups,
                ),
              ],
            ),
          ),

          // Team content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTeamHeader(context, team),
                  const SizedBox(height: 16),
                  TeamAnalyticsWidget(teamId: team.id),
                  const SizedBox(height: 16),
                  _buildTeamMembers(context, ref, team),
                  const SizedBox(height: 16),
                  _buildTeamActions(context, ref, team),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamHeader(BuildContext context, Team team) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Team Logo
                TeamLogoPicker(
                  team: team,
                  avatarRadius: 40,
                  showBorder: true,
                  isSquare: true,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      if (team.teamType != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            team.teamType!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!team.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Inactive',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              team.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Team Lead: ${team.teamLeadId}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const Spacer(),
                Text(
                  'Created ${_formatDate(team.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMembers(BuildContext context, WidgetRef ref, Team team) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Team Members (${team.memberCount})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () =>
                      _navigateToManageMembers(context, ref, team.id),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (team.memberIds.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.people_outline,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No members yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              )
            else
              ...team.memberIds.map((memberId) => _buildMemberItem(
                  context, memberId, team.isTeamLead(memberId))),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberItem(
      BuildContext context, String memberId, bool isTeamLead) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTeamLead
            ? Colors.amber.withOpacity(0.1)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTeamLead
              ? Colors.amber.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isTeamLead ? Colors.amber : Colors.grey[300],
            child: Icon(
              isTeamLead ? Icons.star : Icons.person,
              color: isTeamLead ? Colors.white : Colors.grey[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memberId,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (isTeamLead)
                  Text(
                    'Team Lead',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.amber[700],
                          fontWeight: FontWeight.w500,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamActions(BuildContext context, WidgetRef ref, Team team) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _navigateToManageMembers(context, ref, team.id),
                    icon: const Icon(Icons.people),
                    label: const Text('Manage Members'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _navigateToTeamSettings(context, ref, team.id),
                    icon: const Icon(Icons.settings),
                    label: const Text('Settings'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  void _handleMenuAction(
      BuildContext context, WidgetRef ref, String action, Team team) {
    switch (action) {
      case 'settings':
        _navigateToTeamSettings(context, ref, team.id);
        break;
      case 'manage_members':
        _navigateToManageMembers(context, ref, team.id);
        break;
    }
  }

  void _navigateToManageMembers(
      BuildContext context, WidgetRef ref, String teamId) {
    final team = ref.read(teamProvider(teamId)).value;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManageTeamMembersScreen(
          teamId: teamId,
          teamName: team?.name,
          groupName: groupName,
        ),
      ),
    );
  }

  void _navigateToTeamSettings(
      BuildContext context, WidgetRef ref, String teamId) {
    final team = ref.read(teamProvider(teamId)).value;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TeamSettingsScreen(
          teamId: teamId,
          teamName: team?.name,
          groupName: groupName,
        ),
      ),
    );
  }
}
