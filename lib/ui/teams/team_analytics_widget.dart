import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/team_providers.dart';
import '../../models/team.dart';
import '../widgets/team_avatar.dart';

class TeamAnalyticsWidget extends ConsumerWidget {
  final String teamId;

  const TeamAnalyticsWidget({
    super.key,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamProvider(teamId));
    final teamStatsAsync = ref.watch(teamStatsProvider(teamId));
    final teamMemberDetailsAsync = ref.watch(teamMemberDetailsProvider(teamId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            teamAsync.when(
              loading: () => Row(
                children: [
                  Icon(
                    Icons.analytics,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Team Analytics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              error: (error, _) => Row(
                children: [
                  Icon(
                    Icons.analytics,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Team Analytics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              data: (team) => Row(
                children: [
                  if (team != null) ...[
                    TeamAvatar(
                      team: team,
                      radius: 16,
                      showBorder: true,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Icon(
                    Icons.analytics,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Team Analytics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            teamAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Error: $error'),
              data: (team) {
                if (team == null) return const Text('Team not found');
                return _buildAnalyticsContent(
                  context,
                  team,
                  teamStatsAsync,
                  teamMemberDetailsAsync,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent(
    BuildContext context,
    Team team,
    AsyncValue<Map<String, dynamic>> teamStatsAsync,
    AsyncValue<List<Map<String, dynamic>>> teamMemberDetailsAsync,
  ) {
    return Column(
      children: [
        _buildBasicStats(context, team),
        const SizedBox(height: 16),
        teamStatsAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => Text('Error loading stats: $error'),
          data: (stats) => _buildDetailedStats(context, stats),
        ),
        const SizedBox(height: 16),
        teamMemberDetailsAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => Text('Error loading member details: $error'),
          data: (memberDetails) =>
              _buildMemberAnalytics(context, memberDetails),
        ),
      ],
    );
  }

  Widget _buildBasicStats(BuildContext context, Team team) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Members',
            team.memberCount.toString(),
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Capacity',
            team.maxMembers?.toString() ?? 'Unlimited',
            Icons.group,
            team.isAtCapacity ? Colors.orange : Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Status',
            team.isActive ? 'Active' : 'Inactive',
            team.isActive ? Icons.check_circle : Icons.pause_circle,
            team.isActive ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
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
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(BuildContext context, Map<String, dynamic> stats) {
    final createdAt = DateTime.parse(stats['createdAt'].toString());
    final updatedAt = DateTime.parse(stats['updatedAt'].toString());
    final daysSinceCreation = DateTime.now().difference(createdAt).inDays;
    final daysSinceUpdate = DateTime.now().difference(updatedAt).inDays;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Timeline',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Created $daysSinceCreation day${daysSinceCreation == 1 ? '' : 's'} ago',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.update, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Updated $daysSinceUpdate day${daysSinceUpdate == 1 ? '' : 's'} ago',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberAnalytics(
      BuildContext context, List<Map<String, dynamic>> memberDetails) {
    if (memberDetails.isEmpty) {
      return const SizedBox.shrink();
    }

    // Count members by group role
    final roleCount = <String, int>{};
    for (final member in memberDetails) {
      final role = member['groupRole'] as String;
      roleCount[role] = (roleCount[role] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Member Composition',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ...roleCount.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getRoleColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.key}: ${entry.value}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          _buildCapacityIndicator(context, memberDetails.length, roleCount),
        ],
      ),
    );
  }

  Widget _buildCapacityIndicator(
    BuildContext context,
    int currentMembers,
    Map<String, int> roleCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Team Health',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.health_and_safety,
              size: 16,
              color: _getHealthColor(roleCount),
            ),
            const SizedBox(width: 4),
            Text(
              _getHealthStatus(roleCount),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getHealthColor(roleCount),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'judge':
        return Colors.purple;
      case 'team_lead':
        return Colors.amber;
      case 'member':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getHealthColor(Map<String, int> roleCount) {
    final hasAdmin = roleCount.containsKey('admin') && roleCount['admin']! > 0;
    final hasTeamLead =
        roleCount.containsKey('team_lead') && roleCount['team_lead']! > 0;
    final totalMembers = roleCount.values.fold(0, (sum, count) => sum + count);

    if (hasAdmin || hasTeamLead) {
      return totalMembers >= 3 ? Colors.green : Colors.orange;
    }
    return Colors.red;
  }

  String _getHealthStatus(Map<String, int> roleCount) {
    final hasAdmin = roleCount.containsKey('admin') && roleCount['admin']! > 0;
    final hasTeamLead =
        roleCount.containsKey('team_lead') && roleCount['team_lead']! > 0;
    final totalMembers = roleCount.values.fold(0, (sum, count) => sum + count);

    if (hasAdmin || hasTeamLead) {
      if (totalMembers >= 5) return 'Excellent';
      if (totalMembers >= 3) return 'Good';
      return 'Fair';
    }
    return 'Needs Leadership';
  }
}
