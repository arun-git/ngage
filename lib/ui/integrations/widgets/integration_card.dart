import 'package:flutter/material.dart';
import '../../../models/integration_models.dart';
import '../../../utils/responsive_theme.dart';
import '../../widgets/responsive_layout.dart';

class IntegrationCard extends StatelessWidget {
  final IntegrationType type;
  final IntegrationStatus status;
  final VoidCallback? onConfigure;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onTest;

  const IntegrationCard({
    super.key,
    required this.type,
    required this.status,
    this.onConfigure,
    this.onToggle,
    this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIcon(context),
              SizedBox(width: context.mediumSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDisplayName(type),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      _getDescription(type),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _buildStatusChip(context),
            ],
          ),
          SizedBox(height: context.mediumSpacing),
          _buildFeatures(context),
          SizedBox(height: context.mediumSpacing),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getColor(type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getIcon(type),
        color: _getColor(type),
        size: 24,
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final (color, text) = _getStatusInfo(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFeatures(BuildContext context) {
    final features = _getFeatures(type);
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: features.map((feature) => Chip(
        label: Text(
          feature,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      )).toList(),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        if (status != IntegrationStatus.notSupported) ...[
          Switch(
            value: status == IntegrationStatus.connected || status == IntegrationStatus.disconnected,
            onChanged: onToggle,
          ),
          SizedBox(width: context.smallSpacing),
        ],
        if (onConfigure != null)
          TextButton.icon(
            onPressed: onConfigure,
            icon: const Icon(Icons.settings, size: 16),
            label: const Text('Configure'),
          ),
        if (onTest != null && (status == IntegrationStatus.connected || status == IntegrationStatus.disconnected))
          TextButton.icon(
            onPressed: onTest,
            icon: const Icon(Icons.wifi_protected_setup, size: 16),
            label: const Text('Test'),
          ),
        const Spacer(),
        if (status == IntegrationStatus.error)
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 20,
          ),
      ],
    );
  }

  String _getDisplayName(IntegrationType type) {
    switch (type) {
      case IntegrationType.slack:
        return 'Slack';
      case IntegrationType.microsoftTeams:
        return 'Microsoft Teams';
      case IntegrationType.googleCalendar:
        return 'Google Calendar';
      case IntegrationType.microsoftCalendar:
        return 'Microsoft Calendar';
      case IntegrationType.email:
        return 'Email';
    }
  }

  String _getDescription(IntegrationType type) {
    switch (type) {
      case IntegrationType.slack:
        return 'Send notifications to Slack channels';
      case IntegrationType.microsoftTeams:
        return 'Send notifications to Teams channels';
      case IntegrationType.googleCalendar:
        return 'Create and manage calendar events';
      case IntegrationType.microsoftCalendar:
        return 'Create and manage Outlook calendar events';
      case IntegrationType.email:
        return 'Send email notifications';
    }
  }

  IconData _getIcon(IntegrationType type) {
    switch (type) {
      case IntegrationType.slack:
        return Icons.chat;
      case IntegrationType.microsoftTeams:
        return Icons.groups;
      case IntegrationType.googleCalendar:
      case IntegrationType.microsoftCalendar:
        return Icons.calendar_today;
      case IntegrationType.email:
        return Icons.email;
    }
  }

  Color _getColor(IntegrationType type) {
    switch (type) {
      case IntegrationType.slack:
        return const Color(0xFF4A154B);
      case IntegrationType.microsoftTeams:
        return const Color(0xFF6264A7);
      case IntegrationType.googleCalendar:
        return const Color(0xFF4285F4);
      case IntegrationType.microsoftCalendar:
        return const Color(0xFF0078D4);
      case IntegrationType.email:
        return const Color(0xFFEA4335);
    }
  }

  List<String> _getFeatures(IntegrationType type) {
    switch (type) {
      case IntegrationType.slack:
      case IntegrationType.microsoftTeams:
        return ['Notifications', 'Channel messaging', 'Bot integration'];
      case IntegrationType.googleCalendar:
      case IntegrationType.microsoftCalendar:
        return ['Event creation', 'Event updates', 'Calendar sync'];
      case IntegrationType.email:
        return ['Email notifications', 'HTML templates', 'Attachments'];
    }
  }

  (Color, String) _getStatusInfo(IntegrationStatus status) {
    switch (status) {
      case IntegrationStatus.connected:
        return (Colors.green, 'Connected');
      case IntegrationStatus.disconnected:
        return (Colors.orange, 'Disconnected');
      case IntegrationStatus.disabled:
        return (Colors.grey, 'Disabled');
      case IntegrationStatus.notSupported:
        return (Colors.red, 'Not Supported');
      case IntegrationStatus.error:
        return (Colors.red, 'Error');
    }
  }
}