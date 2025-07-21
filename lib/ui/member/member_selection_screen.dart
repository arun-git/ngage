import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/member.dart';
import '../../providers/member_providers.dart';
import '../../providers/auth_providers.dart';
import 'widgets/member_avatar.dart';

/// Screen for selecting and switching between member profiles
class MemberSelectionScreen extends ConsumerWidget {
  const MemberSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).user;
    final userMembersAsync = ref.watch(userMembersProvider);
    final currentMemberAsync = ref.watch(activeMemberProvider);
    final memberSwitchState = ref.watch(memberSwitchProvider);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view member profiles'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Profile'),
        elevation: 0,
      ),
      body: userMembersAsync.when(
        data: (members) {
          if (members.isEmpty) {
            return _buildEmptyState(context);
          }

          return currentMemberAsync.when(
            data: (currentMember) => _buildMemberList(
              context,
              ref,
              members,
              currentMember,
              memberSwitchState,
              currentUser.id,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _buildErrorState(context, error.toString()),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(context, error.toString()),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Member Profiles',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any member profiles yet.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to profile creation or contact admin
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contact your administrator to create a profile'),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Get Started'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Profiles',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Retry loading
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberList(
    BuildContext context,
    WidgetRef ref,
    List<Member> members,
    Member? currentMember,
    AsyncValue<void> switchState,
    String userId,
  ) {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Profiles',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select a profile to use across the platform',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Member list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final isCurrentMember = currentMember?.id == member.id;
              final isSwitching = switchState.isLoading;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Stack(
                    children: [
                      MemberAvatar(
                        member: member,
                        radius: 24,
                      ),
                      if (isCurrentMember)
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
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    member.fullName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: isCurrentMember ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (member.title != null) ...[
                        const SizedBox(height: 4),
                        Text(member.title!),
                      ],
                      if (member.category != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          member.category!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (isCurrentMember) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Current Profile',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: isCurrentMember
                      ? Icon(
                          Icons.radio_button_checked,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : const Icon(Icons.radio_button_unchecked),
                  onTap: isCurrentMember || isSwitching
                      ? null
                      : () => _switchMember(context, ref, userId, member),
                ),
              );
            },
          ),
        ),

        // Loading indicator
        if (switchState.isLoading)
          Container(
            padding: const EdgeInsets.all(16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Switching profile...'),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _switchMember(
    BuildContext context,
    WidgetRef ref,
    String userId,
    Member member,
  ) async {
    try {
      await ref.read(memberSwitchProvider.notifier).switchMember(userId, member.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to ${member.fullName}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}