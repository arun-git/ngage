import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/enums.dart';
import '../../models/group.dart';
import '../../providers/group_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/image_providers.dart';
import '../../utils/firebase_error_handler.dart';
import '../widgets/breadcrumb_navigation.dart';
import '../widgets/group_avatar.dart';

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
  XFile? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  bool _isLoading = false;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isUploadingImage = true;
      });

      final imageService = ref.read(imageServiceProvider);
      final imageFile = await imageService.pickImage(
        source: source,
        maxWidth: 800, // ImageService.groupImageMaxWidth
        maxHeight: 800, // ImageService.groupImageMaxHeight
        imageQuality: 85, // ImageService.groupImageQuality
      );

      if (imageFile != null) {
        // Read image bytes for web compatibility
        final imageBytes = await imageFile.readAsBytes();

        setState(() {
          _selectedImageFile = imageFile;
          _selectedImageBytes = imageBytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  void _showImageOptions() {
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
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_selectedImageFile != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Image'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImageFile = null;
                    _selectedImageBytes = null;
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

      // First create the group without image
      final group = await groupNotifier.createGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        groupType: _selectedGroupType,
        createdBy: currentMember.id,
      );

      // If image was selected, upload it and update the group
      if (_selectedImageFile != null) {
        try {
          final imageService = ref.read(imageServiceProvider);
          final imageUrl = await imageService.uploadGroupImage(
            imageFile: _selectedImageFile!,
            groupId: group.id,
          );

          // Update group with image URL
          await groupNotifier.updateGroupImage(
            groupId: group.id,
            imageUrl: imageUrl,
          );
        } catch (imageError) {
          // Group was created successfully, but image upload failed
          // Show warning but don't fail the entire operation
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Group created but image upload failed: $imageError'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      // Force refresh of the member groups stream to ensure the UI updates
      ref.invalidate(memberGroupsStreamProvider(currentMember.id));

      // Add a small delay to ensure Firestore has propagated the changes
      await Future.delayed(const Duration(milliseconds: 500));

      // Invalidate again to ensure the stream picks up the latest data
      ref.invalidate(memberGroupsStreamProvider(currentMember.id));

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
                            'Group Image',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    _selectedImageBytes != null
                                        ? CircleAvatar(
                                            radius: 60,
                                            backgroundImage: MemoryImage(
                                                _selectedImageBytes!),
                                          )
                                        : GroupAvatar(
                                            group: Group(
                                              id: 'temp',
                                              name: _nameController
                                                      .text.isNotEmpty
                                                  ? _nameController.text
                                                  : 'New Group',
                                              description: '',
                                              groupType: _selectedGroupType,
                                              createdBy: '',
                                              createdAt: DateTime.now(),
                                              updatedAt: DateTime.now(),
                                            ),
                                            radius: 60,
                                            showBorder: true,
                                          ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surface,
                                            width: 2,
                                          ),
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            _isUploadingImage
                                                ? Icons.hourglass_empty
                                                : Icons.camera_alt,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                            size: 20,
                                          ),
                                          onPressed:
                                              (_isLoading || _isUploadingImage)
                                                  ? null
                                                  : _showImageOptions,
                                          constraints: const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_isUploadingImage) ...[
                                  const SizedBox(height: 8),
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Processing image...',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
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
