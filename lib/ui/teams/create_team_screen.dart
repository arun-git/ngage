import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/team.dart';
import '../../providers/team_providers.dart';
import '../../providers/group_providers.dart';
import '../../providers/image_providers.dart';
import '../../models/group_member.dart';
import '../widgets/breadcrumb_navigation.dart';
import '../widgets/team_avatar.dart';

class CreateTeamScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String? groupName;

  const CreateTeamScreen({
    super.key,
    required this.groupId,
    this.groupName,
  });

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxMembersController = TextEditingController();
  final _teamTypeController = TextEditingController();

  String? _selectedTeamLeadId;
  final Set<String> _selectedMemberIds = {};

  XFile? _selectedLogoFile;
  Uint8List? _selectedLogoBytes;
  bool _isUploadingLogo = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _maxMembersController.dispose();
    _teamTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupMembersAsync = ref.watch(groupMembersProvider(widget.groupId));
    final teamCreationAsync = ref.watch(teamCreationProvider);

    // Listen to team creation state changes
    ref.listen<AsyncValue<Team?>>(teamCreationProvider, (previous, next) {
      next.whenOrNull(
        data: (team) {
          if (team != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Team "${team.name}" created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(team);
          }
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create team: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Team'),
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
                    onTap: () => Navigator.of(context).pop(),
                  ),
                BreadcrumbItem(
                  title: 'Manage Teams',
                  onTap: () => Navigator.of(context).pop(),
                ),
                const BreadcrumbItem(
                  title: 'Create Team',
                  icon: Icons.add,
                ),
              ],
            ),
          ),

          // Form content
          Expanded(
            child: groupMembersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text('Error loading group members: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.refresh(groupMembersProvider(widget.groupId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (groupMembers) =>
                  _buildForm(context, groupMembers, teamCreationAsync),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, List<GroupMember> groupMembers,
      AsyncValue<Team?> teamCreationAsync) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Team Logo Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Logo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload a logo to give your team a unique visual identity',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              _selectedLogoBytes != null
                                  ? Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline
                                              .withOpacity(0.3),
                                          width: 2,
                                        ),
                                        image: DecorationImage(
                                          image:
                                              MemoryImage(_selectedLogoBytes!),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  : TeamAvatar(
                                      team: Team(
                                        id: 'temp',
                                        groupId: widget.groupId,
                                        name: _nameController.text.isNotEmpty
                                            ? _nameController.text
                                            : 'New Team',
                                        description: '',
                                        teamLeadId:
                                            _selectedTeamLeadId ?? 'temp',
                                        teamType:
                                            _teamTypeController.text.isNotEmpty
                                                ? _teamTypeController.text
                                                : null,
                                        createdAt: DateTime.now(),
                                        updatedAt: DateTime.now(),
                                      ),
                                      radius: 60,
                                      showBorder: true,
                                      isSquare: true,
                                    ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      width: 2,
                                    ),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      _isUploadingLogo
                                          ? Icons.hourglass_empty
                                          : Icons.camera_alt,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      size: 20,
                                    ),
                                    onPressed: (teamCreationAsync.isLoading ||
                                            _isUploadingLogo)
                                        ? null
                                        : _showLogoOptions,
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_isUploadingLogo) ...[
                            const SizedBox(height: 8),
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Processing logo...',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Team Name *',
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
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        hintText: 'Enter team description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Description is required';
                        }
                        if (value.trim().length > 1000) {
                          return 'Description must not exceed 1000 characters';
                        }
                        return null;
                      },
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
                              }
                              return null;
                            },
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
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Lead *',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    if (groupMembers.isEmpty)
                      const Text('No group members available')
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedTeamLeadId,
                        decoration: const InputDecoration(
                          labelText: 'Select Team Lead',
                          border: OutlineInputBorder(),
                        ),
                        items: groupMembers.map((member) {
                          return DropdownMenuItem(
                            value: member.memberId,
                            child: Text(
                                '${member.memberId} (${member.role.name})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTeamLeadId = value;
                            if (value != null) {
                              _selectedMemberIds.add(value);
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a team lead';
                          }
                          return null;
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Members',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select additional team members (team lead is automatically included)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    if (groupMembers.isEmpty)
                      const Text('No group members available')
                    else
                      ...groupMembers.map((member) {
                        final isTeamLead =
                            member.memberId == _selectedTeamLeadId;
                        final isSelected =
                            _selectedMemberIds.contains(member.memberId);

                        return CheckboxListTile(
                          title: Text(member.memberId),
                          subtitle: Text(member.role.name),
                          value: isSelected,
                          onChanged: isTeamLead
                              ? null
                              : (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedMemberIds.add(member.memberId);
                                    } else {
                                      _selectedMemberIds
                                          .remove(member.memberId);
                                    }
                                  });
                                },
                          secondary: isTeamLead
                              ? const Icon(Icons.star, color: Colors.amber)
                              : null,
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (teamCreationAsync.isLoading || _isUploadingLogo)
                  ? null
                  : _createTeam,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: (teamCreationAsync.isLoading || _isUploadingLogo)
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Team'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLogo(ImageSource source) async {
    try {
      setState(() {
        _isUploadingLogo = true;
      });

      final imageService = ref.read(imageServiceProvider);
      final logoFile = await imageService.pickImage(
        source: source,
        maxWidth: 400, // ImageService.teamLogoMaxWidth
        maxHeight: 400, // ImageService.teamLogoMaxHeight
        imageQuality: 90, // ImageService.teamLogoQuality
      );

      if (logoFile != null) {
        // Read image bytes for web compatibility
        final logoBytes = await logoFile.readAsBytes();

        setState(() {
          _selectedLogoFile = logoFile;
          _selectedLogoBytes = logoBytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick logo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingLogo = false;
        });
      }
    }
  }

  void _showLogoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickLogo(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickLogo(ImageSource.camera);
              },
            ),
            if (_selectedLogoFile != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Logo'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedLogoFile = null;
                    _selectedLogoBytes = null;
                  });
                },
              ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createTeam() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final maxMembers = _maxMembersController.text.isNotEmpty
        ? int.tryParse(_maxMembersController.text)
        : null;

    final teamType = _teamTypeController.text.isNotEmpty
        ? _teamTypeController.text.trim()
        : null;

    try {
      // Create team with logo in single atomic operation
      await ref.read(teamCreationProvider.notifier).createTeamWithLogo(
            groupId: widget.groupId,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            teamLeadId: _selectedTeamLeadId!,
            logoFile: _selectedLogoFile, // Pass file directly
            initialMemberIds: _selectedMemberIds.toList(),
            maxMembers: maxMembers,
            teamType: teamType,
          );
    } catch (e) {
      // Error handling is already done in the provider listener
      // This catch block is just for safety
    }
  }
}
