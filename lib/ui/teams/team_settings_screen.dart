import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/team.dart';
import '../../providers/team_providers.dart';
import '../widgets/breadcrumb_navigation.dart';
import '../widgets/selectable_error_message.dart';
import '../../utils/firebase_error_handler.dart';

class TeamSettingsScreen extends ConsumerStatefulWidget {
  final String teamId;
  final String? teamName;
  final String? groupName;

  const TeamSettingsScreen({
    super.key,
    required this.teamId,
    this.teamName,
    this.groupName,
  });

  @override
  ConsumerState<TeamSettingsScreen> createState() => _TeamSettingsScreenState();
}

class _TeamSettingsScreenState extends ConsumerState<TeamSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _maxMembersController;
  late TextEditingController _teamTypeController;
  bool _isActive = true;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _maxMembersController = TextEditingController();
    _teamTypeController = TextEditingController();

    // Listen for changes
    _nameController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
    _maxMembersController.addListener(_onFieldChanged);
    _teamTypeController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _maxMembersController.dispose();
    _teamTypeController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _initializeFields(Team team) {
    _nameController.text = team.name;
    _descriptionController.text = team.description;
    _maxMembersController.text = team.maxMembers?.toString() ?? '';
    _teamTypeController.text = team.teamType ?? '';
    _isActive = team.isActive;
    _hasChanges = false;
  }

  Future<void> _saveChanges(Team team) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final teamNotifier = ref.read(teamManagementProvider.notifier);

      await teamNotifier.updateTeam(
        teamId: widget.teamId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        maxMembers: _maxMembersController.text.isNotEmpty
            ? int.tryParse(_maxMembersController.text)
            : null,
        teamType: _teamTypeController.text.isNotEmpty
            ? _teamTypeController.text.trim()
            : null,
        isActive: _isActive,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team settings updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _hasChanges = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update team settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteTeam() async {
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
              'Team: ${_nameController.text}',
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
      setState(() {
        _isLoading = true;
      });

      try {
        final teamNotifier = ref.read(teamManagementProvider.notifier);
        await teamNotifier.deleteTeam(widget.teamId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Team deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete team: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamAsync = ref.watch(teamProvider(widget.teamId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Settings'),
        elevation: 0,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      final team = teamAsync.value;
                      if (team != null) {
                        _saveChanges(team);
                      }
                    },
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
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
                if (widget.groupName != null)
                  BreadcrumbItem(
                    title: widget.groupName!,
                    onTap: () => Navigator.of(context).popUntil(
                      (route) =>
                          route.settings.name?.contains('group_detail') ==
                              true ||
                          route.isFirst,
                    ),
                  ),
                BreadcrumbItem(
                  title: 'Manage Teams',
                  onTap: () => Navigator.of(context).popUntil(
                    (route) =>
                        route.settings.name?.contains('manage_teams') == true,
                  ),
                ),
                if (widget.teamName != null)
                  BreadcrumbItem(
                    title: widget.teamName!,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                const BreadcrumbItem(
                  title: 'Settings',
                  icon: Icons.settings,
                ),
              ],
            ),
          ),

          // Settings content
          Expanded(
            child: teamAsync.when(
              data: (team) {
                if (team == null) {
                  return const Center(
                    child: Text('Team not found'),
                  );
                }

                // Initialize fields when team data is loaded
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_nameController.text.isEmpty) {
                    _initializeFields(team);
                  }
                });

                return _buildSettingsForm(context, team);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(context, error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsForm(BuildContext context, Team team) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Team Name',
                        hintText: 'Enter team name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Team name is required';
                        }
                        if (value.trim().length > 100) {
                          return 'Team name must not exceed 100 characters';
                        }
                        return null;
                      },
                      maxLength: 100,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter team description',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Description is required';
                        }
                        if (value.trim().length > 1000) {
                          return 'Description must not exceed 1000 characters';
                        }
                        return null;
                      },
                      maxLines: 3,
                      maxLength: 1000,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _maxMembersController,
                            decoration: const InputDecoration(
                              labelText: 'Max Members',
                              hintText: 'Optional',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final maxMembers = int.tryParse(value);
                                if (maxMembers == null || maxMembers < 1) {
                                  return 'Must be a positive number';
                                }
                                if (maxMembers > 100) {
                                  return 'Maximum 100 members allowed';
                                }
                                if (maxMembers < team.memberCount) {
                                  return 'Cannot be less than current member count (${team.memberCount})';
                                }
                              }
                              return null;
                            },
                            enabled: !_isLoading,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _teamTypeController,
                            decoration: const InputDecoration(
                              labelText: 'Team Type',
                              hintText: 'Optional',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value != null && value.length > 50) {
                                return 'Team type must not exceed 50 characters';
                              }
                              return null;
                            },
                            enabled: !_isLoading,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Active Team'),
                      subtitle: const Text(
                          'Inactive teams cannot participate in events'),
                      value: _isActive,
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _isActive = value;
                              });
                              _onFieldChanged();
                            },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(
                      icon: Icons.fingerprint,
                      label: 'Team ID',
                      value: team.id,
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.people,
                      label: 'Current Members',
                      value: '${team.memberCount}',
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.person,
                      label: 'Team Lead',
                      value: team.teamLeadId,
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.calendar_today,
                      label: 'Created',
                      value: _formatDate(team.createdAt),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.update,
                      label: 'Last Updated',
                      value: _formatDate(team.updatedAt),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Danger Zone',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Once you delete a team, there is no going back. Please be certain.',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _deleteTeam,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade700),
                        ),
                        child: const Text('Delete Team'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
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
              'Error loading team',
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
                ref.invalidate(teamProvider(widget.teamId));
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Widget for displaying information rows
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}
