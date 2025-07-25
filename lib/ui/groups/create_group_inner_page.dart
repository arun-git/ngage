import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';
import '../../providers/group_providers.dart';
import '../../providers/auth_providers.dart';
import '../../utils/firebase_error_handler.dart';
import '../widgets/breadcrumb_navigation.dart';

/// Inner page for creating a new group that replaces the groups list
class CreateGroupInnerPage extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onGroupCreated;

  const CreateGroupInnerPage({
    super.key,
    required this.onBack,
    required this.onGroupCreated,
  });

  @override
  ConsumerState<CreateGroupInnerPage> createState() =>
      _CreateGroupInnerPageState();
}

class _CreateGroupInnerPageState extends ConsumerState<CreateGroupInnerPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  GroupType _selectedGroupType = GroupType.corporate;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current member ID from auth state
      final currentMember = ref.read(currentMemberProvider);

      if (currentMember == null) {
        throw Exception('No active member profile found');
      }

      final groupNotifier = ref.read(groupNotifierProvider.notifier);

      await groupNotifier.createGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        groupType: _selectedGroupType,
        createdBy: currentMember.id,
      );

      if (mounted) {
        widget.onGroupCreated();
      }
    } catch (e) {
      if (mounted) {
        if (FirebaseErrorHandler.isFirebaseIndexError(e.toString())) {
          // Show Firebase index error in a dialog with selectable text
          FirebaseErrorHandler.showFirebaseErrorDialog(context, e);
        } else {
          // Show regular error in a snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create group: ${e.toString()}'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Details',
                textColor: Colors.white,
                onPressed: () {
                  FirebaseErrorHandler.showFirebaseErrorDialog(context, e);
                },
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                onTap: widget.onBack,
              ),
              const BreadcrumbItem(
                title: 'Create Group',
                icon: Icons.add,
              ),
            ],
          ),
        ),

        // Form content
        Expanded(
          child: SingleChildScrollView(
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
                            'Group Information',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Group Name',
                              hintText: 'Enter group name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Group name is required';
                              }
                              if (value.trim().length > 100) {
                                return 'Group name must not exceed 100 characters';
                              }
                              return null;
                            },
                            maxLength: 100,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              hintText: 'Enter group description',
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
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<GroupType>(
                            value: _selectedGroupType,
                            decoration: const InputDecoration(
                              labelText: 'Group Type',
                              border: OutlineInputBorder(),
                            ),
                            items: GroupType.values.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(_getGroupTypeDisplayName(type)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedGroupType = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : widget.onBack,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createGroup,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Create Group'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getGroupTypeDisplayName(GroupType type) {
    switch (type) {
      case GroupType.corporate:
        return 'Corporate';
      case GroupType.educational:
        return 'Educational';
      case GroupType.community:
        return 'Community';
      case GroupType.social:
        return 'Social';
    }
  }
}
