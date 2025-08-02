import 'package:flutter/material.dart';
import '../../models/team.dart';
import 'robust_network_image.dart';

/// Widget for displaying team avatar with fallback to team type icon
class TeamAvatar extends StatelessWidget {
  final Team team;
  final double radius;
  final VoidCallback? onTap;
  final bool showBorder;
  final bool isSquare;

  const TeamAvatar({
    super.key,
    required this.team,
    this.radius = 24,
    this.onTap,
    this.showBorder = false,
    this.isSquare = false,
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

    // If team has logo, use it
    if (team.logoUrl != null && team.logoUrl!.isNotEmpty) {
      return Container(
        decoration: showBorder
            ? BoxDecoration(
                shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: isSquare ? BorderRadius.circular(8) : null,
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                  width: 2,
                ),
              )
            : null,
        child: _buildImageAvatar(context),
      );
    }

    // Fallback to team type icon or default team icon
    return _buildIconAvatar(context);
  }

  Widget _buildImageAvatar(BuildContext context) {
    // Add cache-busting parameter to ensure fresh images after updates
    final imageUrl = _getCacheBustedImageUrl(team.logoUrl!);

    if (isSquare) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: _getBackgroundColor(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
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

    if (isSquare) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: _getBackgroundColor(context),
          borderRadius: BorderRadius.circular(8),
          border: showBorder
              ? Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                  width: 2,
                )
              : null,
        ),
        child: Center(child: _buildIconContent(context)),
      );
    }

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
      _getTeamTypeIcon(),
      size: radius * 0.8,
      color: _getIconColor(context),
    );
  }

  IconData _getTeamTypeIcon() {
    if (team.teamType != null) {
      switch (team.teamType!.toLowerCase()) {
        case 'development':
        case 'dev':
          return Icons.code;
        case 'design':
        case 'ui':
        case 'ux':
          return Icons.design_services;
        case 'marketing':
          return Icons.campaign;
        case 'sales':
          return Icons.trending_up;
        case 'support':
          return Icons.support_agent;
        case 'qa':
        case 'testing':
          return Icons.bug_report;
        case 'management':
        case 'admin':
          return Icons.admin_panel_settings;
        case 'finance':
          return Icons.account_balance;
        case 'hr':
        case 'human resources':
          return Icons.people_alt;
        default:
          return Icons.groups;
      }
    }
    return Icons.groups; // Default team icon
  }

  Color _getBackgroundColor(BuildContext context) {
    final theme = Theme.of(context);
    if (team.teamType != null) {
      switch (team.teamType!.toLowerCase()) {
        case 'development':
        case 'dev':
          return Colors.blue.withOpacity(0.1);
        case 'design':
        case 'ui':
        case 'ux':
          return Colors.purple.withOpacity(0.1);
        case 'marketing':
          return Colors.orange.withOpacity(0.1);
        case 'sales':
          return Colors.green.withOpacity(0.1);
        case 'support':
          return Colors.teal.withOpacity(0.1);
        case 'qa':
        case 'testing':
          return Colors.red.withOpacity(0.1);
        case 'management':
        case 'admin':
          return Colors.indigo.withOpacity(0.1);
        case 'finance':
          return Colors.amber.withOpacity(0.1);
        case 'hr':
        case 'human resources':
          return Colors.pink.withOpacity(0.1);
        default:
          return theme.colorScheme.primaryContainer;
      }
    }
    return theme.colorScheme.primaryContainer;
  }

  Color _getIconColor(BuildContext context) {
    final theme = Theme.of(context);
    if (team.teamType != null) {
      switch (team.teamType!.toLowerCase()) {
        case 'development':
        case 'dev':
          return Colors.blue;
        case 'design':
        case 'ui':
        case 'ux':
          return Colors.purple;
        case 'marketing':
          return Colors.orange;
        case 'sales':
          return Colors.green;
        case 'support':
          return Colors.teal;
        case 'qa':
        case 'testing':
          return Colors.red;
        case 'management':
        case 'admin':
          return Colors.indigo;
        case 'finance':
          return Colors.amber;
        case 'hr':
        case 'human resources':
          return Colors.pink;
        default:
          return theme.colorScheme.onPrimaryContainer;
      }
    }
    return theme.colorScheme.onPrimaryContainer;
  }

  /// Add cache-busting parameter to image URL to ensure fresh images
  String _getCacheBustedImageUrl(String imageUrl) {
    // Use the team's updatedAt timestamp as cache buster
    final cacheBuster = team.updatedAt.millisecondsSinceEpoch.toString();

    // Check if URL already has query parameters
    if (imageUrl.contains('?')) {
      return '$imageUrl&cb=$cacheBuster';
    } else {
      return '$imageUrl?cb=$cacheBuster';
    }
  }
}

/// Widget for displaying a team avatar with name
class TeamAvatarWithName extends StatelessWidget {
  final Team team;
  final double avatarRadius;
  final VoidCallback? onTap;
  final bool showFullName;
  final bool showBorder;

  const TeamAvatarWithName({
    super.key,
    required this.team,
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
        TeamAvatar(
          team: team,
          radius: avatarRadius,
          onTap: onTap,
          showBorder: showBorder,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            showFullName ? team.name : _getShortName(),
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getShortName() {
    if (team.name.length <= 20) return team.name;
    return '${team.name.substring(0, 17)}...';
  }
}
