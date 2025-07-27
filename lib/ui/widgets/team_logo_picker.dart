import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/team.dart';
import '../../providers/team_providers.dart';
import '../../providers/image_providers.dart';
import 'team_avatar.dart';

/// Widget for picking and updating team logo
class TeamLogoPicker extends ConsumerStatefulWidget {
  final Team team;
  final double avatarRadius;
  final bool showBorder;
  final bool isSquare;

  const TeamLogoPicker({
    super.key,
    required this.team,
    this.avatarRadius = 60,
    this.showBorder = true,
    this.isSquare = true,
  });

  @override
  ConsumerState<TeamLogoPicker> createState() => _TeamLogoPickerState();
}

class _TeamLogoPickerState extends ConsumerState<TeamLogoPicker> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TeamAvatar(
          team: widget.team,
          radius: widget.avatarRadius,
          showBorder: widget.showBorder,
          isSquare: widget.isSquare,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 2,
              ),
            ),
            child: IconButton(
              icon: Icon(
                _isUploading ? Icons.hourglass_empty : Icons.camera_alt,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 20,
              ),
              onPressed: _isUploading ? null : _showLogoOptions,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
            ),
          ),
        ),
        if (_isUploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: widget.isSquare
                    ? BorderRadius.circular(8)
                    : BorderRadius.circular(widget.avatarRadius),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
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
            if (widget.team.logoUrl != null && widget.team.logoUrl!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Logo'),
                onTap: () {
                  Navigator.pop(context);
                  _removeLogo();
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

  Future<void> _pickLogo(ImageSource source) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final imageService = ref.read(imageServiceProvider);
      final logoUrl = await imageService.pickAndUploadTeamLogo(
        teamId: widget.team.id,
        groupId: widget.team.groupId,
        source: source,
      );

      if (logoUrl != null) {
        await _updateTeamLogo(logoUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload logo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _removeLogo() async {
    setState(() {
      _isUploading = true;
    });

    try {
      // Delete the current logo from storage if it exists
      if (widget.team.logoUrl != null && widget.team.logoUrl!.isNotEmpty) {
        final imageService = ref.read(imageServiceProvider);
        await imageService.deleteImage(widget.team.logoUrl!);
      }

      // Update team with null logo URL
      await _updateTeamLogo(null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove logo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _updateTeamLogo(String? logoUrl) async {
    try {
      final teamManagement = ref.read(teamManagementProvider.notifier);
      await teamManagement.updateTeamLogo(
        teamId: widget.team.id,
        logoUrl: logoUrl,
      );

      // Force refresh of the team provider to ensure the UI updates
      ref.invalidate(teamProvider(widget.team.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(logoUrl != null
                ? 'Team logo updated successfully'
                : 'Team logo removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update team logo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
