import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/judging_providers.dart';
import '../../providers/member_providers.dart';

/// Screen for managing judge assignments for an event
class JudgeAssignmentScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventTitle;

  const JudgeAssignmentScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  ConsumerState<JudgeAssignmentScreen> createState() => _JudgeAssignmentScreenState();
}

class _JudgeAssignmentScreenState extends ConsumerState<JudgeAssignmentScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(eventJudgeAssignmentsProvider(widget.eventId));
    final availableMembersAsync = ref.watch(availableJudgesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Judges - ${widget.eventTitle}'),
        actions: [
          IconButton(
            onPressed: _showAddJudgeDialog,
            icon: const Icon(Icons.person_add),
            tooltip: 'Add Judge',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search judges...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),

          // Judge assignments list
          Expanded(
            child: assignmentsAsync.when(
              data: (assignments) => _buildAssignmentsList(assignments),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading judge assignments: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(eventJudgeAssignmentsProvider(widget.eventId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsList(List<JudgeAssignment> assignments) {
    if (assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.gavel, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No judges assigned',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add judges to start the evaluation process',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddJudgeDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Add Judge'),
            ),
          ],
        ),
      );
    }

    // Filter assignments based on search query
    final filteredAssignments = assignments.where((assignment) {
      if (_searchQuery.isEmpty) return true;
      return assignment.judgeId.toLowerCase().contains(_searchQuery);
    }).toList();

    // Group by role
    final leadJudges = filteredAssignments.where((a) => a.role == JudgeRole.leadJudge).toList();
    final regularJudges = filteredAssignments.where((a) => a.role == JudgeRole.judge).toList();
    final panelMembers = filteredAssignments.where((a) => a.role == JudgeRole.panelMember).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (leadJudges.isNotEmpty) ...[
          _buildRoleSection('Lead Judges', leadJudges, Colors.purple),
          const SizedBox(height: 16),
        ],
        if (regularJudges.isNotEmpty) ...[
          _buildRoleSection('Judges', regularJudges, Colors.blue),
          const SizedBox(height: 16),
        ],
        if (panelMembers.isNotEmpty) ...[
          _buildRoleSection('Panel Members', panelMembers, Colors.green),
        ],
      ],
    );
  }

  Widget _buildRoleSection(String title, List<JudgeAssignment> assignments, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.group, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text('${assignments.length}'),
              backgroundColor: color.withOpacity(0.1),
              side: BorderSide(color: color.withOpacity(0.3)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...assignments.map((assignment) => _buildAssignmentCard(assignment)),
      ],
    );
  }

  Widget _buildAssignmentCard(JudgeAssignment assignment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(assignment.role).withOpacity(0.1),
          child: Icon(
            _getRoleIcon(assignment.role),
            color: _getRoleColor(assignment.role),
          ),
        ),
        title: Text('Judge ${assignment.judgeId.substring(0, 8)}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Role: ${assignment.role.value.replaceAll('_', ' ').toUpperCase()}'),
            if (assignment.permissions.isNotEmpty)
              Text('Permissions: ${assignment.permissions.join(', ')}'),
            Text('Assigned: ${_formatDateTime(assignment.assignedAt)}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleAssignmentAction(action, assignment),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit Role & Permissions')),
            const PopupMenuItem(value: 'remove', child: Text('Remove Judge')),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Color _getRoleColor(JudgeRole role) {
    switch (role) {
      case JudgeRole.leadJudge:
        return Colors.purple;
      case JudgeRole.judge:
        return Colors.blue;
      case JudgeRole.panelMember:
        return Colors.green;
    }
  }

  IconData _getRoleIcon(JudgeRole role) {
    switch (role) {
      case JudgeRole.leadJudge:
        return Icons.star;
      case JudgeRole.judge:
        return Icons.gavel;
      case JudgeRole.panelMember:
        return Icons.group;
    }
  }

  void _showAddJudgeDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddJudgeDialog(
        eventId: widget.eventId,
        onJudgeAdded: () {
          ref.refresh(eventJudgeAssignmentsProvider(widget.eventId));
        },
      ),
    );
  }

  void _handleAssignmentAction(String action, JudgeAssignment assignment) {
    switch (action) {
      case 'edit':
        _showEditAssignmentDialog(assignment);
        break;
      case 'remove':
        _showRemoveJudgeDialog(assignment);
        break;
    }
  }

  void _showEditAssignmentDialog(JudgeAssignment assignment) {
    showDialog(
      context: context,
      builder: (context) => _EditAssignmentDialog(
        assignment: assignment,
        onAssignmentUpdated: () {
          ref.refresh(eventJudgeAssignmentsProvider(widget.eventId));
        },
      ),
    );
  }

  void _showRemoveJudgeDialog(JudgeAssignment assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Judge'),
        content: Text(
          'Are you sure you want to remove Judge ${assignment.judgeId.substring(0, 8)} from this event?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(judgingServiceProvider).removeJudge(
                  eventId: widget.eventId,
                  judgeId: assignment.judgeId,
                );
                ref.refresh(eventJudgeAssignmentsProvider(widget.eventId));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Judge removed successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error removing judge: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class _AddJudgeDialog extends ConsumerStatefulWidget {
  final String eventId;
  final VoidCallback onJudgeAdded;

  const _AddJudgeDialog({
    required this.eventId,
    required this.onJudgeAdded,
  });

  @override
  ConsumerState<_AddJudgeDialog> createState() => _AddJudgeDialogState();
}

class _AddJudgeDialogState extends ConsumerState<_AddJudgeDialog> {
  String? _selectedJudgeId;
  JudgeRole _selectedRole = JudgeRole.judge;
  final List<String> _selectedPermissions = [];
  bool _isAdding = false;

  static const List<String> _availablePermissions = [
    'score_submissions',
    'comment_on_submissions',
    'view_all_scores',
    'moderate_discussions',
    'export_results',
  ];

  @override
  Widget build(BuildContext context) {
    final availableMembersAsync = ref.watch(availableJudgesProvider);

    return AlertDialog(
      title: const Text('Add Judge'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Judge selection
            availableMembersAsync.when(
              data: (members) => DropdownButtonFormField<String>(
                value: _selectedJudgeId,
                decoration: const InputDecoration(
                  labelText: 'Select Judge',
                  border: OutlineInputBorder(),
                ),
                items: members.map((member) {
                  return DropdownMenuItem(
                    value: member.id,
                    child: Text('${member.firstName} ${member.lastName}'),
                  );
                }).toList(),
                onChanged: (judgeId) => setState(() => _selectedJudgeId = judgeId),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error loading members: $error'),
            ),
            const SizedBox(height: 16),

            // Role selection
            DropdownButtonFormField<JudgeRole>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Judge Role',
                border: OutlineInputBorder(),
              ),
              items: JudgeRole.values.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role.value.replaceAll('_', ' ').toUpperCase()),
                );
              }).toList(),
              onChanged: (role) => setState(() => _selectedRole = role!),
            ),
            const SizedBox(height: 16),

            // Permissions selection
            const Text('Permissions:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _availablePermissions.map((permission) {
                final isSelected = _selectedPermissions.contains(permission);
                return FilterChip(
                  label: Text(permission.replaceAll('_', ' ').toUpperCase()),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedPermissions.add(permission);
                      } else {
                        _selectedPermissions.remove(permission);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isAdding ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isAdding || _selectedJudgeId == null ? null : _addJudge,
          child: _isAdding
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Judge'),
        ),
      ],
    );
  }

  Future<void> _addJudge() async {
    if (_selectedJudgeId == null) return;

    setState(() => _isAdding = true);

    try {
      await ref.read(judgingServiceProvider).assignJudge(
        eventId: widget.eventId,
        judgeId: _selectedJudgeId!,
        assignedBy: 'current_user', // TODO: Get current user ID
        role: _selectedRole,
        permissions: _selectedPermissions,
      );

      widget.onJudgeAdded();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Judge added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding judge: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }
}

class _EditAssignmentDialog extends ConsumerStatefulWidget {
  final JudgeAssignment assignment;
  final VoidCallback onAssignmentUpdated;

  const _EditAssignmentDialog({
    required this.assignment,
    required this.onAssignmentUpdated,
  });

  @override
  ConsumerState<_EditAssignmentDialog> createState() => _EditAssignmentDialogState();
}

class _EditAssignmentDialogState extends ConsumerState<_EditAssignmentDialog> {
  late JudgeRole _selectedRole;
  late List<String> _selectedPermissions;
  bool _isUpdating = false;

  static const List<String> _availablePermissions = [
    'score_submissions',
    'comment_on_submissions',
    'view_all_scores',
    'moderate_discussions',
    'export_results',
  ];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.assignment.role;
    _selectedPermissions = List.from(widget.assignment.permissions);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Judge Assignment'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Role selection
            DropdownButtonFormField<JudgeRole>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Judge Role',
                border: OutlineInputBorder(),
              ),
              items: JudgeRole.values.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role.value.replaceAll('_', ' ').toUpperCase()),
                );
              }).toList(),
              onChanged: (role) => setState(() => _selectedRole = role!),
            ),
            const SizedBox(height: 16),

            // Permissions selection
            const Text('Permissions:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _availablePermissions.map((permission) {
                final isSelected = _selectedPermissions.contains(permission);
                return FilterChip(
                  label: Text(permission.replaceAll('_', ' ').toUpperCase()),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedPermissions.add(permission);
                      } else {
                        _selectedPermissions.remove(permission);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUpdating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUpdating ? null : _updateAssignment,
          child: _isUpdating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _updateAssignment() async {
    setState(() => _isUpdating = true);

    try {
      await ref.read(judgingServiceProvider).updateJudgeAssignment(
        eventId: widget.assignment.eventId,
        judgeId: widget.assignment.judgeId,
        role: _selectedRole,
        permissions: _selectedPermissions,
      );

      widget.onAssignmentUpdated();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Judge assignment updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating assignment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }
}