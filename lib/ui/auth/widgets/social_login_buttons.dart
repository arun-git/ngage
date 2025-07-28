import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_providers.dart';
import '../../../services/auth_config_service.dart';
import '../../../services/slack_oauth_service.dart';

class SocialLoginButtons extends ConsumerWidget {
  final bool isEnabled;
  final bool hidePhoneButton;

  const SocialLoginButtons({
    super.key,
    required this.isEnabled,
    this.hidePhoneButton = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Phone Sign-In button (only show if not hidden)
        if (!hidePhoneButton) ...[
          _SocialLoginButton(
            onPressed: isEnabled ? () => _handlePhoneSignIn(context, ref) : null,
            icon: Icons.phone,
            label: 'Continue with phone',
            backgroundColor: Colors.white,
            textColor: Colors.black87,
            borderColor: Colors.grey[300],
          ),
          const SizedBox(height: 12),
        ],

        // Google Sign-In button
        _SocialLoginButton(
          onPressed: isEnabled ? () => _handleGoogleSignIn(ref) : null,
          icon: Icons.g_mobiledata,
          label: 'Continue with Google',
          backgroundColor: Colors.white,
          textColor: Colors.black87,
          borderColor: Colors.grey[300],
        ),
        const SizedBox(height: 12),

        // Slack Sign-In button
        _SocialLoginButton(
          onPressed: isEnabled ? () => _handleSlackSignIn(context, ref) : null,
          icon: Icons.chat_bubble_outline,
          label: 'Continue with Slack',
          backgroundColor: const Color(0xFF4A154B),
          textColor: Colors.white,
        ),
        const SizedBox(height: 12),

        // Microsoft Teams Sign-In button
        _SocialLoginButton(
          onPressed: isEnabled ? () => _handleTeamsSignIn(context, ref) : null,
          icon: Icons.groups,
          label: 'Continue with Teams',
          backgroundColor: const Color(0xFF6264A7),
          textColor: Colors.white,
        ),
      ],
    );
  }

  void _handlePhoneSignIn(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phone sign-in not implemented yet'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _handleGoogleSignIn(WidgetRef ref) {
    try {
      ref.read(authStateProvider.notifier).signInWithGoogle();
    } catch (e) {
      // Handle Google Sign-In configuration error gracefully
      // This will be caught by the auth provider and shown as an error
    }
  }

  void _handleSlackSignIn(BuildContext context, WidgetRef ref) {
    final slackConfig = AuthConfigService.getSlackConfig();
    
    if (slackConfig == null) {
      _showSlackConfigurationDialog(context);
      return;
    }

    final slackOAuthService = SlackOAuthService(slackConfig);
    _launchSlackOAuth(context, ref, slackOAuthService);
  }

  void _handleTeamsSignIn(BuildContext context, WidgetRef ref) {
    // For demo purposes, show configuration dialog
    // In production, you would get this from environment variables
    _showTeamsConfigurationDialog(context);
  }

  void _showTeamsConfigurationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microsoft Teams OAuth Configuration'),
        content: const Text(
          'Microsoft Teams OAuth is not properly configured. Please set up your Teams app '
          'credentials in the environment variables:\n\n'
          '• TEAMS_CLIENT_ID\n'
          '• TEAMS_TENANT_ID\n'
          '• TEAMS_REDIRECT_URI\n\n'
          'Contact your administrator for assistance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSlackConfigurationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slack OAuth Configuration'),
        content: const Text(
          'Slack OAuth is not properly configured. Please set up your Slack app '
          'credentials in the environment variables:\n\n'
          '• SLACK_CLIENT_ID\n'
          '• SLACK_CLIENT_SECRET\n'
          '• SLACK_REDIRECT_URI\n\n'
          'Contact your administrator for assistance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _launchSlackOAuth(BuildContext context, WidgetRef ref, SlackOAuthService slackService) async {
    try {
      final launched = await slackService.launchOAuthFlow();
      
      if (!launched) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to launch Slack OAuth. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // In a real implementation, you would:
      // 1. Handle the OAuth callback in your app
      // 2. Extract the authorization code from the callback
      // 3. Call ref.read(authStateProvider.notifier).signInWithSlack(code)
      
      // For now, show a message about the OAuth flow
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Slack OAuth launched. Complete the authorization in your browser, '
              'then return to the app to finish sign-in.',
            ),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.blue,
          ),
        );
      }
      
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Slack OAuth error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _SocialLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;

  const _SocialLoginButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          side: BorderSide(
            color: borderColor ?? Colors.grey[300]!,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(width: 8),
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}