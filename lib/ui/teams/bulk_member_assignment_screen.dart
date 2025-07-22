import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/team_providers.dart';
import '../../providers/group_providers.dart';
import '../../models/team.dart';
import '../../models/group_member.dart';

class BulkMemberAssignmentScreen extends ConsumerStatefulWidget {
  final String teamId;

  const BulkMemberAssignmentScreen({
    super.key,
    required this.teamId,
  });

  @override
  ConsumerState<BulkMemberAssignmentScreen> createState() => _BulkMemberAssignmentScreenState();
}

class _BulkMemberAssignmentScreenState extends ConsumerState<BulkMemberAssignmentScreen> {
  final Set<String> _selectedMembers = {};
  String _searchQuery = '';
  bool _showOnlyAvailable = true;

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
            Navigator.of(context).pop();
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
        title: const Text('Bulk Member Assignment'),
        elevation: 0,
        actions: [
          if (_selectedMembers.isNotEmpty)
            TextButton(
              onPressed: teamManagementAsync.isLoading ? null : _assignSelectedMembers,
              child: Text('Add ${_selectedMembers.length}'),
            ),
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
    return Column(
      children: [
        _buildHeader(context, team),
        _buildSearchAndFilters(context),
        Expanded(
          child: availableMembersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text('Error loading members: $error'),
            ),
            data: (availableMembers) => _buildMembersList(
              context,
              team,
              availableMembers,
              teamManagementAsync,
            ),
          ),
        ),
        if (_selectedMembers.isNotEmpty) _buildBottomBar(context, teamManagementAsync),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, Team team) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
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
                '${team.memberCount} current member${team.memberCount == 1 ? '' : 's'}',
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
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search members...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilterChip(
                label: const Text('Available Only'),
                selected: _showOnlyAvailable,
                onSelected: (selected) {
                  setState(() {
                    _showOnlyAvailable = selected;
                  });
                },
              ),
              const SizedBox(width: 8),
              if (_selectedMembers.isNotEmpty) ...[
                FilterChip(
                  label: Text('Selected (${_selectedMembers.length})'),
                  selected: true,
                  onSelected: null,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedMembers.clear();
                    });
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(
    BuildContext context,
    Team team,
    List<GroupMember> availableMembers,
    AsyncValue<String?> teamManagementAsync,
  ) {
    // Filter members based on search and availability
    var filteredMembers = availableMembers;
    
    if (_searchQuery.isNotEmpty) {
      filteredMembers = filteredMembers
          .where((member) => member.memberId.toLowerCase().contains(_searchQuery))
          .toList();
    }

    if (filteredMembers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No members found matching "$_searchQuery"'
                  : team.isAtCapacity
                      ? 'Team is at maximum capacity'
                      : 'No available members to add',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredMembers.length,
      itemBuilder: (context, index) {
        final member = filteredMembers[index];
        return _buildMemberItem(context, member, team, teamManagementAsync);
      },
    );
  }

  Widget _buildMemberItem(
    BuildContext context,
    GroupMember member,
    Team team,
    AsyncValue<String?> teamManagementAsync,
  ) {
    final isSelected = _selectedMembers.contains(member.memberId);
    final canAdd = !team.isAtCapacity || isSelected; // Allow deselection even at capacity

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: canAdd ? () => _toggleMemberSelection(member.memberId) : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.withOpacity(0.2),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: canAdd ? (value) => _toggleMemberSelection(member.memberId) : null,
                ),
                const SizedBox(width: 12),
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
                if (!canAdd)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Team Full',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, AsyncValue<String?> teamManagementAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_selectedMembers.length} member${_selectedMembers.length == 1 ? '' : 's'} selected',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_selectedMembers.length > 1)
                    Text(
                      'All selected members will be added to the team',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: teamManagementAsync.isLoading ? null : _assignSelectedMembers,
              icon: teamManagementAsync.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.group_add),
              label: Text('Add ${_selectedMembers.length}'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
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

  void _assignSelectedMembers() {
    if (_selectedMembers.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Members to Team'),
        content: Text(
          'Are you sure you want to add ${_selectedMembers.length} member${_selectedMembers.length == 1 ? '' : 's'} to this team?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(teamManagementProvider.notifier).addMembersToTeam(
                widget.teamId,
                _selectedMembers.toList(),
              );
            },
            child: const Text('Add Members'),
          ),
        ],
      ),
    );
  }
}