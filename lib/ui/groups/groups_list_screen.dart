import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/group.dart';
import '../../models/enums.dart';
import '../../providers/group_providers.dart';
import '../../ui/widgets/selectable_error_message.dart';
import '../../utils/firebase_error_handler.dart';
import 'group_detail_screen.dart';

/// Screen displaying list of groups for a member
class GroupsListScreen extends ConsumerWidget {
  final String memberId;
  final VoidCallback? onCreateGroup;

  const GroupsListScreen({
    super.key,
    required this.memberId,
    this.onCreateGroup,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberGroupsAsync = ref.watch(memberGroupsStreamProvider(memberId));

    return Column(
      children: [
        // Header with create button
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Groups',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (onCreateGroup != null)
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: onCreateGroup,
                  tooltip: 'Create Group',
                ),
            ],
          ),
        ),
        Expanded(
          child: memberGroupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No groups yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Join a group or create your own to get started',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(memberGroupsStreamProvider(memberId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return _GroupCard(
                  group: group,
                  memberId: memberId,
                  isCreator: group.createdBy == memberId,
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
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
                  'Error loading groups',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SelectableErrorMessage(
                  message: error.toString(),
                  title: 'Error Details',
                  backgroundColor: FirebaseErrorHandler.isFirebaseIndexError(error.toString()) 
                      ? Colors.orange 
                      : Colors.red,
                  onRetry: () {
                    ref.invalidate(memberGroupsStreamProvider(memberId));
                  },
                ),
              ],
            ),
          ),
        ),
          ),
        ),
      ],
    );
  }
}



/// Card widget for displaying group information
class _GroupCard extends ConsumerWidget {
  final Group group;
  final String memberId;
  final bool isCreator;

  const _GroupCard({
    required this.group,
    required this.memberId,
    this.isCreator = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => GroupDetailScreen(
                groupId: group.id,
                memberId: memberId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getGroupTypeDisplayName(group.groupType),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getGroupTypeColor(group.groupType),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCreator)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Creator',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                group.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Created ${_formatDate(group.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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

  Color _getGroupTypeColor(GroupType type) {
    switch (type) {
      case GroupType.corporate:
        return Colors.blue;
      case GroupType.educational:
        return Colors.green;
      case GroupType.community:
        return Colors.orange;
      case GroupType.social:
        return Colors.purple;
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
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    }
  }
}