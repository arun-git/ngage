import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/member.dart';
import '../../providers/member_providers.dart';
import '../../services/member_service.dart';
import 'widgets/member_profile_form.dart';
import 'widgets/member_avatar.dart';

/// Screen for viewing and editing member profile
class MemberProfileScreen extends ConsumerStatefulWidget {
  final String? memberId;

  const MemberProfileScreen({
    super.key,
    this.memberId,
  });

  @override
  ConsumerState<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends ConsumerState<MemberProfileScreen> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final memberId = widget.memberId;

    // If no memberId provided, show current member
    if (memberId == null) {
      return _buildCurrentMemberProfile();
    }

    // Show specific member profile
    return _buildSpecificMemberProfile(memberId);
  }

  Widget _buildCurrentMemberProfile() {
    final currentMemberAsync = ref.watch(activeMemberProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: currentMemberAsync.when(
        data: (member) {
          if (member == null) {
            return const Center(
              child: Text('No profile found'),
            );
          }
          return _buildProfileContent(member);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading profile: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(activeMemberProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecificMemberProfile(String memberId) {
    final memberAsync = ref.watch(memberProvider(memberId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: memberAsync.when(
        data: (member) {
          if (member == null) {
            return const Center(
              child: Text('Member not found'),
            );
          }
          return _buildProfileContent(member);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading member: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(memberProvider(memberId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(Member member) {
    if (_isEditing) {
      return MemberProfileForm(
        member: member,
        onSave: (updateData) => _handleSave(member.id, updateData),
        onCancel: () => setState(() => _isEditing = false),
      );
    }

    return _buildProfileView(member);
  }

  Widget _buildProfileView(Member member) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          Center(
            child: Column(
              children: [
                MemberAvatar(
                  member: member,
                  radius: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  member.fullName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (member.title != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    member.title!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
                if (member.category != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    member.category!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Profile details
          _buildDetailSection('Contact Information', [
            _buildDetailItem('Email', member.email, Icons.email),
            if (member.phone != null)
              _buildDetailItem('Phone', member.phone!, Icons.phone),
          ]),
          
          if (member.bio != null) ...[
            const SizedBox(height: 24),
            _buildDetailSection('About', [
              Text(
                member.bio!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ]),
          ],
          
          const SizedBox(height: 24),
          _buildDetailSection('Profile Information', [
            _buildDetailItem('Member ID', member.id, Icons.badge),
            if (member.externalId != null)
              _buildDetailItem('External ID', member.externalId!, Icons.link),
            _buildDetailItem(
              'Status', 
              member.isActive ? 'Active' : 'Inactive', 
              member.isActive ? Icons.check_circle : Icons.cancel,
            ),
            if (member.claimedAt != null)
              _buildDetailItem(
                'Claimed', 
                _formatDate(member.claimedAt!), 
                Icons.person_add,
              ),
            if (member.importedAt != null)
              _buildDetailItem(
                'Imported', 
                _formatDate(member.importedAt!), 
                Icons.upload,
              ),
          ]),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _handleSave(String memberId, MemberUpdateData updateData) async {
    try {
      await ref.read(memberProfileProvider.notifier).updateProfile(memberId, updateData);
      setState(() => _isEditing = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}