import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/integration_models.dart';
import '../../providers/integration_providers.dart';
import '../../utils/responsive_theme.dart';
import '../widgets/responsive_layout.dart';
import 'widgets/integration_card.dart';
import 'widgets/integration_config_dialog.dart';

/// Screen for managing integration configurations
class IntegrationConfigScreen extends ConsumerStatefulWidget {
  const IntegrationConfigScreen({super.key});

  @override
  ConsumerState<IntegrationConfigScreen> createState() => _IntegrationConfigScreenState();
}

class _IntegrationConfigScreenState extends ConsumerState<IntegrationConfigScreen> {
  @override
  Widget build(BuildContext context) {
    final integrationStatuses = ref.watch(integrationStatusesProvider);
    final availableIntegrations = ref.watch(availableIntegrationsProvider);

    return ResponsiveScaffold(
      title: 'Integration Configuration',
      destinations: const [],
      body: integrationStatuses.when(
        data: (statuses) => _buildIntegrationList(context, statuses, availableIntegrations),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error),
      ),
    );
  }

  Widget _buildIntegrationList(
    BuildContext context,
    Map<IntegrationType, IntegrationStatus> statuses,
    List<IntegrationType> availableIntegrations,
  ) {
    return ResponsiveListView(
      children: [
        Text(
          'Available Integrations',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: context.mediumSpacing),
        Text(
          'Configure your preferred communication and calendar platforms',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: context.largeSpacing),
        ...availableIntegrations.map((type) => Padding(
          padding: EdgeInsets.only(bottom: context.mediumSpacing),
          child: IntegrationCard(
            type: type,
            status: statuses[type] ?? IntegrationStatus.notSupported,
            onConfigure: () => _showConfigurationDialog(context, type),
            onToggle: (enabled) => _toggleIntegration(type, enabled),
            onTest: () => _testIntegration(type),
          ),
        )),
        SizedBox(height: context.largeSpacing),
        _buildIntegrationTips(context),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          SizedBox(height: context.mediumSpacing),
          Text(
            'Failed to load integrations',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: context.smallSpacing),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: context.largeSpacing),
          ElevatedButton(
            onPressed: () => ref.refresh(integrationStatusesProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationTips(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: context.smallSpacing),
              Text(
                'Integration Tips',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          SizedBox(height: context.mediumSpacing),
          _buildTipItem(
            context,
            'Chat Platforms',
            'Enable Slack or Microsoft Teams to receive notifications in your team channels.',
          ),
          _buildTipItem(
            context,
            'Calendar Integration',
            'Connect Google Calendar or Microsoft Calendar to automatically create event reminders.',
          ),
          _buildTipItem(
            context,
            'Email Notifications',
            'Configure email as a fallback option when chat platforms are unavailable.',
          ),
          _buildTipItem(
            context,
            'Multiple Platforms',
            'You can enable multiple integrations simultaneously for redundancy.',
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.smallSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: EdgeInsets.only(top: 6, right: context.smallSpacing),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showConfigurationDialog(BuildContext context, IntegrationType type) {
    showDialog(
      context: context,
      builder: (context) => IntegrationConfigDialog(type: type),
    );
  }

  Future<void> _toggleIntegration(IntegrationType type, bool enabled) async {
    try {
      if (enabled) {
        // Show configuration dialog first
        final config = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => IntegrationConfigDialog(type: type),
        );
        
        if (config != null) {
          await ref.read(integrationServiceProvider).enableIntegration(type, config);
          ref.invalidate(integrationStatusesProvider);
        }
      } else {
        await ref.read(integrationServiceProvider).disableIntegration(type);
        ref.invalidate(integrationStatusesProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${enabled ? 'enable' : 'disable'} integration: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _testIntegration(IntegrationType type) async {
    try {
      final result = await ref.read(integrationServiceProvider).testIntegration(type);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result 
                ? 'Integration test successful' 
                : 'Integration test failed',
            ),
            backgroundColor: result 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to test integration: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}