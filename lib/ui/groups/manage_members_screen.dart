import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/group_member.dart';
import '../../models/enums.dart';
import '../../providers/group_providers.dart';
import '../widgets/breadcrumb_navigation.dart';

/// Screen for managing group members and their roles
class ManageMembersScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String currentMemberId;
  final String? groupName;

  const ManageMembersScreen({
    super.key,
    required this.groupId,
    required this.currentMemberId,
    this.groupName,
  });

  @override
  ConsumerState<ManageMembersScreen> createState() => _ManageMembersScreenState();
}

class _ManageMembersScreenState extends ConsumerState<ManageMembersScreen> {
  final _inviteController = TextEditingController();
  GroupRole _selectedRole = GroupRole.member;
  bool _isInviting = false;

  @override
  void dispose() {
    _inviteController.dispose();
    super.dispose();
  }

  Future<void> _inviteMember() async {
    final memberId = _inviteController.text.trim();
    if (memberId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a member ID'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isInviting = true;
    });

    try {
      final membershipNotifier = ref.read(groupMembershipNotifierProvider.notifier);
      
      await membershipNotifier.addMemberToGroup(
        groupId: widget.groupId,
        memberId: memberId,
        role: _selectedRole,
      );

      if (mounted) {
        _inviteController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add member: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInviting = false;
        });
      }
    }
  }

  Future<void> _updateMemberRole(GroupMember member, GroupRole newRole) async {
    if (member.role == newRole) return;

    try {
      final membershipNotifier = ref.read(groupMembershipNotifierProvider.notifier);
      
      await membershipNotifier.updateMemberRole(
        groupId: widget.groupId,
        memberId: member.memberId,
        newRole: newRole,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member role updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update member role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeMember(GroupMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove this member from the group?\n\nMember ID: ${member.memberId}',
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final membershipNotifier = ref.read(groupMembershipNotifierProvider.notifier);
        
        await membershipNotifier.removeMemberFromGroup(
          groupId: widget.groupId,
          memberId: member.memberId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Member removed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove member: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(groupMembersStreamProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Members'),
        elevation: 0,
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
                  title: 'Groups',
                  icon: Icons.group,
                  onTap: () => Navigator.of(context).popUntil(
                    (route) => route.settings.name == '/groups' || route.isFirst,
                  ),
                ),
                if (widget.groupName != null)
                  BreadcrumbItem(
                    title: widget.groupName!,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                const BreadcrumbItem(
                  title: 'Manage Members',
                  icon: Icons.people,
                ),
              ],
            ),
          ),
          
          // Invite member section
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invite Member',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _inviteController,
                          decoration: const InputDecoration(
                            labelText: 'Member ID',
                            hintText: 'Enter member ID to invite',
                            border: OutlineInputBorder(),
                          ),
                          enabled: !_isInviting,
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<GroupRole>(
                        value: _selectedRole,
                        items: GroupRole.values.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(_getRoleDisplayName(role)),
                          );
                        }).toList(),
                        onChanged: _isInviting ? null : (value) {
                          if (value != null) {
                            setState(() {
                              _selectedRole = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isInviting ? null : _inviteMember,
                      child: _isInviting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Invite Member'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Members list
          Expanded(
            child: membersAsync.when(
              data: (members) {
                if (members.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No members yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final isCurrentUser = member.memberId == widget.currentMemberId;
                    
                    return _MemberManagementCard(
                      member: member,
                      isCurrentUser: isCurrentUser,
                      onRoleChanged: (newRole) => _updateMemberRole(member, newRole),
                      onRemove: () => _removeMember(member),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
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
                      'Error loading members',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(groupMembersStreamProvider(widget.groupId));
                      },
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

  String _getRoleDisplayName(GroupRole role) {
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

/// Card widget for managing individual members
class _MemberManagementCard extends StatelessWidget {
  final GroupMember member;
  final bool isCurrentUser;
  final Function(GroupRole) onRoleChanged;
  final VoidCallback onRemove;

  const _MemberManagementCard({
    required this.member,
    required this.isCurrentUser,
    required this.onRoleChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getRoleColor(member.role).withOpacity(0.1),
                  child: Icon(
                    _getRoleIcon(member.role),
                    color: _getRoleColor(member.role),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Member ${member.memberId}', // TODO: Replace with actual member name
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'You',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        'Joined ${_formatDate(member.joinedAt)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isCurrentUser)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'remove') {
                        onRemove();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'remove',
                        child: ListTile(
                          leading: Icon(Icons.person_remove, color: Colors.red),
                          title: Text('Remove Member'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Role:',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<GroupRole>(
                    value: member.role,
                    isExpanded: true,
                    items: GroupRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(
                          _getRoleDisplayName(role),
                          style: TextStyle(
                            color: _getRoleColor(role),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: isCurrentUser ? null : (value) {
                      if (value != null && value != member.role) {
                        onRoleChanged(value);
                      }
                    },
                    underline: Container(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleDisplayName(GroupRole role) {
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

  IconData _getRoleIcon(GroupRole role) {
    switch (role) {
      case GroupRole.admin:
        return Icons.admin_panel_settings;
      case GroupRole.judge:
        return Icons.gavel;
      case GroupRole.teamLead:
        return Icons.supervisor_account;
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
        return Colors.orange;
      case GroupRole.member:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}