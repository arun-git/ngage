import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/team_providers.dart';
import '../../providers/group_providers.dart';
import '../../models/team.dart';
import '../../models/group_member.dart';

class ManageTeamMembersScreen extends ConsumerStatefulWidget {
  final String teamId;

  const ManageTeamMembersScreen({
    super.key,
    required this.teamId,
  });

  @override
  ConsumerState<ManageTeamMembersScreen> createState() => _ManageTeamMembersScreenState();
}

class _ManageTeamMembersScreenState extends ConsumerState<ManageTeamMembersScreen> {
  final Set<String> _selectedMembers = {};
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    final teamAsync = ref.watch(teamProvider(widget.teamId));
    final availableMembersAsync = ref.watch(availableMembersProvider(widget.teamId));
    final teamManagementAsync = ref.watch(teamManagementProvider);

    // Listen to team management state changes
    ref.listen<AsyncValue<String?>>(teamManagementProvider, (previous, next) {
      next.whenOrNull(
        data: (message) {
          if (message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.green,
              ),
            );
            ref.read(teamManagementProvider.notifier).reset();
          }
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Team Members'),
        elevation: 0,
        actions: [
          if (_isSelectionMode) ...[
            TextButton(
              onPressed: _selectedMembers.isEmpty ? null : _removeSelectedMembers,
              child: const Text('Remove'),
            ),
            IconButton(
              onPressed: _exitSelectionMode,
              icon: const Icon(Icons.close),
            ),
          ] else ...[
            IconButton(
              onPressed: _enterSelectionMode,
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Members',
            ),
          ],
        ],
      ),
      body: teamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(context, error),
        data: (team) {
          if (team == null) {
            return _buildNotFoundState(context);
          }
          return _buildContent(context, team, availableMembersAsync, teamManagementAsync);
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
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
            onPressed: () => ref.refresh(teamProvider(widget.teamId)),
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Team team,
    AsyncValue<List<GroupMember>> availableMembersAsync,
    AsyncValue<String?> teamManagementAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTeamInfo(context, team),
          const SizedBox(height: 16),
          _buildCurrentMembers(context, team, teamManagementAsync),
          const SizedBox(height: 16),
          _buildAvailableMembers(context, team, availableMembersAsync, teamManagementAsync),
        ],
      ),
    );
  }

  Widget _buildTeamInfo(BuildContext context, Team team) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              team.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${team.memberCount} member${team.memberCount == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                if (team.maxMembers != null) ...[
                  Text(
                    ' / ${team.maxMembers} max',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const Spacer(),
                if (team.isAtCapacity)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'At Capacity',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentMembers(BuildContext context, Team team, AsyncValue<String?> teamManagementAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Current Members (${team.memberCount})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!_isSelectionMode && team.memberCount > 1)
                  TextButton.icon(
                    onPressed: _enterSelectionMode,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (team.memberIds.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
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
              ...team.memberIds.map((memberId) => _buildCurrentMemberItem(
                context,
                memberId,
                team.isTeamLead(memberId),
                teamManagementAsync,
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentMemberItem(
    BuildContext context,
    String memberId,
    bool isTeamLead,
    AsyncValue<String?> teamManagementAsync,
  ) {
    final isSelected = _selectedMembers.contains(memberId);
    final isLoading = teamManagementAsync.isLoading;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: _isSelectionMode && !isTeamLead ? () => _toggleMemberSelection(memberId) : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : isTeamLead
                        ? Colors.amber.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (_isSelectionMode && !isTeamLead)
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) => _toggleMemberSelection(memberId),
                  )
                else
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
                if (!_isSelectionMode && !isTeamLead)
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMemberAction(value, memberId),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'make_lead',
                        child: ListTile(
                          leading: Icon(Icons.star),
                          title: Text('Make Team Lead'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'remove',
                        child: ListTile(
                          leading: Icon(Icons.remove_circle, color: Colors.red),
                          title: Text('Remove from Team'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableMembers(
    BuildContext context,
    Team team,
    AsyncValue<List<GroupMember>> availableMembersAsync,
    AsyncValue<String?> teamManagementAsync,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Members',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Group members who can be added to this team',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            availableMembersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Error loading available members: $error'),
              data: (availableMembers) {
                if (availableMembers.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          team.isAtCapacity
                              ? 'Team is at maximum capacity'
                              : 'No available members to add',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: availableMembers
                      .map((member) => _buildAvailableMemberItem(
                            context,
                            member,
                            team,
                            teamManagementAsync,
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableMemberItem(
    BuildContext context,
    GroupMember member,
    Team team,
    AsyncValue<String?> teamManagementAsync,
  ) {
    final canAdd = !team.isAtCapacity;
    final isLoading = teamManagementAsync.isLoading;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[300],
            child: Icon(
              Icons.person,
              color: Colors.grey[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.memberId,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  member.role.value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: canAdd && !isLoading ? () => _addMemberToTeam(member.memberId) : null,
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add, size: 16),
            label: Text(canAdd ? 'Add' : 'Full'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedMembers.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedMembers.clear();
    });
  }

  void _toggleMemberSelection(String memberId) {
    setState(() {
      if (_selectedMembers.contains(memberId)) {
        _selectedMembers.remove(memberId);
      } else {
        _selectedMembers.add(memberId);
      }
    });
  }

  void _handleMemberAction(String action, String memberId) {
    switch (action) {
      case 'make_lead':
        _changeTeamLead(memberId);
        break;
      case 'remove':
        _removeMemberFromTeam(memberId);
        break;
    }
  }

  void _addMemberToTeam(String memberId) {
    ref.read(teamManagementProvider.notifier).addMemberToTeam(widget.teamId, memberId);
  }

  void _removeMemberFromTeam(String memberId) {
    ref.read(teamManagementProvider.notifier).removeMemberFromTeam(widget.teamId, memberId);
  }

  void _removeSelectedMembers() {
    for (final memberId in _selectedMembers) {
      ref.read(teamManagementProvider.notifier).removeMemberFromTeam(widget.teamId, memberId);
    }
    _exitSelectionMode();
  }

  void _changeTeamLead(String newTeamLeadId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Team Lead'),
        content: Text('Are you sure you want to make this member the new team lead?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(teamManagementProvider.notifier).changeTeamLead(widget.teamId, newTeamLeadId);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}