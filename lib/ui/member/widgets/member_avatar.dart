import 'package:flutter/material.dart';
import '../../../models/member.dart';

/// Widget for displaying member avatar with fallback to initials
class MemberAvatar extends StatelessWidget {
  final Member member;
  final double radius;
  final VoidCallback? onTap;

  const MemberAvatar({
    super.key,
    required this.member,
    this.radius = 20,
    this.onTap,
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
    // If member has profile photo, use it
    if (member.profilePhoto != null && member.profilePhoto!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(member.profilePhoto!),
        onBackgroundImageError: (_, __) {
          // Fallback to initials if image fails to load
        },
        child: null,
      );
    }

    // Fallback to initials
    return CircleAvatar(
      radius: radius,
      backgroundColor: _getBackgroundColor(context),
      child: Text(
        _getInitials(),
        style: TextStyle(
          fontSize: radius * 0.6,
          fontWeight: FontWeight.bold,
          color: _getTextColor(context),
        ),
      ),
    );
  }

  String _getInitials() {
    final firstName = member.firstName.trim();
    final lastName = member.lastName.trim();
    
    String initials = '';
    
    if (firstName.isNotEmpty) {
      initials += firstName[0].toUpperCase();
    }
    
    if (lastName.isNotEmpty) {
      initials += lastName[0].toUpperCase();
    }
    
    // Fallback if no valid initials
    if (initials.isEmpty) {
      initials = member.email[0].toUpperCase();
    }
    
    return initials;
  }

  Color _getBackgroundColor(BuildContext context) {
    // Generate a consistent color based on member ID
    final hash = member.id.hashCode;
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    
    return colors[hash.abs() % colors.length];
  }

  Color _getTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onPrimary;
  }
}

/// Widget for displaying a small member avatar with name
class MemberAvatarWithName extends StatelessWidget {
  final Member member;
  final double avatarRadius;
  final VoidCallback? onTap;
  final bool showFullName;

  const MemberAvatarWithName({
    super.key,
    required this.member,
    this.avatarRadius = 16,
    this.onTap,
    this.showFullName = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MemberAvatar(
          member: member,
          radius: avatarRadius,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                showFullName ? member.fullName : member.firstName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (member.title != null) ...[
                Text(
                  member.title!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// Widget for displaying member status indicator
class MemberStatusIndicator extends StatelessWidget {
  final Member member;
  final double size;

  const MemberStatusIndicator({
    super.key,
    required this.member,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: member.isActive ? Colors.green : Colors.grey,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 2,
        ),
      ),
    );
  }
}