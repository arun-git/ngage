import 'package:flutter/material.dart';
import '../../models/group.dart';
import 'robust_network_image.dart';

/// Widget for displaying group avatar with fallback to group type icon
class GroupAvatar extends StatelessWidget {
  final Group group;
  final double radius;
  final VoidCallback? onTap;
  final bool showBorder;

  const GroupAvatar({
    super.key,
    required this.group,
    this.radius = 24,
    this.onTap,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = _buildAvatar(context);

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildAvatar(BuildContext context) {
    final theme = Theme.of(context);

    // If group has image, use it
    if (group.imageUrl != null && group.imageUrl!.isNotEmpty) {
      return Container(
        decoration: showBorder
            ? BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                  width: 2,
                ),
              )
            : null,
        child: _buildImageAvatar(context),
      );
    }

    // Fallback to group type icon
    return _buildIconAvatar(context);
  }

  Widget _buildImageAvatar(BuildContext context) {
    // Add cache-busting parameter to ensure fresh images after updates
    final imageUrl = _getCacheBustedImageUrl(group.imageUrl!);

    return CircleAvatar(
      radius: radius,
      backgroundColor: _getBackgroundColor(context),
      child: ClipOval(
        child: RobustNetworkImage(
          imageUrl: imageUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: radius * 2,
              height: radius * 2,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _getIconColor(context),
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context) {
            // Fallback to icon avatar if image fails to load
            return _buildIconContent(context);
          },
        ),
      ),
    );
  }

  Widget _buildIconAvatar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: showBorder
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
                width: 2,
              ),
            )
          : null,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: _getBackgroundColor(context),
        child: _buildIconContent(context),
      ),
    );
  }

  Widget _buildIconContent(BuildContext context) {
    return Icon(
      _getGroupTypeIcon(),
      size: radius * 0.8,
      color: _getIconColor(context),
    );
  }

  IconData _getGroupTypeIcon() {
    switch (group.groupType.value) {
      case 'corporate':
        return Icons.business;
      case 'educational':
        return Icons.school;
      case 'community':
        return Icons.people;
      case 'social':
        return Icons.groups;
      default:
        return Icons.group;
    }
  }

  Color _getBackgroundColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (group.groupType.value) {
      case 'corporate':
        return Colors.blue.withOpacity(0.1);
      case 'educational':
        return Colors.green.withOpacity(0.1);
      case 'community':
        return Colors.orange.withOpacity(0.1);
      case 'social':
        return Colors.purple.withOpacity(0.1);
      default:
        return theme.colorScheme.primaryContainer;
    }
  }

  Color _getIconColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (group.groupType.value) {
      case 'corporate':
        return Colors.blue;
      case 'educational':
        return Colors.green;
      case 'community':
        return Colors.orange;
      case 'social':
        return Colors.purple;
      default:
        return theme.colorScheme.onPrimaryContainer;
    }
  }

  /// Add cache-busting parameter to image URL to ensure fresh images
  String _getCacheBustedImageUrl(String imageUrl) {
    // Use the group's updatedAt timestamp as cache buster
    final cacheBuster = group.updatedAt.millisecondsSinceEpoch.toString();

    // Check if URL already has query parameters
    if (imageUrl.contains('?')) {
      return '$imageUrl&cb=$cacheBuster';
    } else {
      return '$imageUrl?cb=$cacheBuster';
    }
  }
}

/// Widget for displaying a group avatar with name
class GroupAvatarWithName extends StatelessWidget {
  final Group group;
  final double avatarRadius;
  final VoidCallback? onTap;
  final bool showFullName;
  final bool showBorder;

  const GroupAvatarWithName({
    super.key,
    required this.group,
    this.avatarRadius = 16,
    this.onTap,
    this.showFullName = true,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GroupAvatar(
          group: group,
          radius: avatarRadius,
          onTap: onTap,
          showBorder: showBorder,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            showFullName ? group.name : _getShortName(),
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getShortName() {
    if (group.name.length <= 20) return group.name;
    return '${group.name.substring(0, 17)}...';
  }
}
