import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/moderation_action.dart';
import '../../../providers/moderation_providers.dart';

class ModerationActionsList extends ConsumerStatefulWidget {
  const ModerationActionsList({super.key});

  @override
  ConsumerState<ModerationActionsList> createState() => _ModerationActionsListState();
}

class _ModerationActionsListState extends ConsumerState<ModerationActionsList> {
  ModerationActionType? _selectedActionType;
  bool _showActiveOnly = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: _buildActionsList(),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ModerationActionType?>(
                    value: _selectedActionType,
                    decoration: const InputDecoration(
                      labelText: 'Action Type',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<ModerationActionType?>(
                        value: null,
                        child: Text('All Types'),
                      ),
                      ...ModerationActionType.values.map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(_getActionTypeText(type)),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedActionType = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                FilterChip(
                  label: const Text('Active Only'),
                  selected: _showActiveOnly,
                  onSelected: (selected) {
                    setState(() {
                      _showActiveOnly = selected;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsList() {
    // For now, we'll show a placeholder since we don't have a provider for all actions
    // In a real implementation, you'd create a provider that fetches actions based on filters
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.gavel,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Moderation Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Recent moderation actions will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildSampleActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleActions() {
    // Sample actions for demonstration
    final sampleActions = [
      _buildActionTile(
        'Hidden Post',
        'Post #12345 hidden for inappropriate content',
        ModerationActionType.hide,
        DateTime.now().subtract(const Duration(hours: 2)),
        true,
      ),
      _buildActionTile(
        'User Warned',
        'User @john_doe warned for harassment',
        ModerationActionType.warn,
        DateTime.now().subtract(const Duration(hours: 5)),
        true,
      ),
      _buildActionTile(
        'Comment Deleted',
        'Comment #67890 deleted for spam',
        ModerationActionType.delete,
        DateTime.now().subtract(const Duration(days: 1)),
        true,
      ),
    ];

    return Column(
      children: sampleActions,
    );
  }

  Widget _buildActionTile(
    String title,
    String description,
    ModerationActionType actionType,
    DateTime createdAt,
    bool isActive,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getActionTypeColor(actionType),
          child: Icon(
            _getActionTypeIcon(actionType),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            Text(
              _formatDate(createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Text(
                  'Active',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Text(
                  'Inactive',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (action) => _handleActionMenu(action),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'details',
                  child: Text('View Details'),
                ),
                if (isActive)
                  const PopupMenuItem(
                    value: 'reverse',
                    child: Text('Reverse Action'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getActionTypeColor(ModerationActionType actionType) {
    switch (actionType) {
      case ModerationActionType.hide:
        return Colors.orange;
      case ModerationActionType.delete:
        return Colors.red;
      case ModerationActionType.warn:
        return Colors.amber;
      case ModerationActionType.suspend:
        return Colors.purple;
      case ModerationActionType.ban:
        return Colors.red[800]!;
      case ModerationActionType.approve:
        return Colors.green;
      case ModerationActionType.dismiss:
        return Colors.grey;
    }
  }

  IconData _getActionTypeIcon(ModerationActionType actionType) {
    switch (actionType) {
      case ModerationActionType.hide:
        return Icons.visibility_off;
      case ModerationActionType.delete:
        return Icons.delete;
      case ModerationActionType.warn:
        return Icons.warning;
      case ModerationActionType.suspend:
        return Icons.pause_circle;
      case ModerationActionType.ban:
        return Icons.block;
      case ModerationActionType.approve:
        return Icons.check_circle;
      case ModerationActionType.dismiss:
        return Icons.cancel;
    }
  }

  String _getActionTypeText(ModerationActionType actionType) {
    switch (actionType) {
      case ModerationActionType.hide:
        return 'Hide';
      case ModerationActionType.delete:
        return 'Delete';
      case ModerationActionType.warn:
        return 'Warn';
      case ModerationActionType.suspend:
        return 'Suspend';
      case ModerationActionType.ban:
        return 'Ban';
      case ModerationActionType.approve:
        return 'Approve';
      case ModerationActionType.dismiss:
        return 'Dismiss';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleActionMenu(String action) {
    switch (action) {
      case 'details':
        _showActionDetails();
        break;
      case 'reverse':
        _reverseAction();
        break;
    }
  }

  void _showActionDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Action Details'),
        content: const Text('Detailed information about the moderation action would be shown here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _reverseAction() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reverse Action'),
        content: const Text('Are you sure you want to reverse this moderation action?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Action reversed')),
              );
            },
            child: const Text('Reverse'),
          ),
        ],
      ),
    );
  }
}