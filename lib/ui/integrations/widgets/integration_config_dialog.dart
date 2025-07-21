import 'package:flutter/material.dart';
import '../../../models/integration_models.dart';
import '../../../utils/responsive_theme.dart';
import '../../../utils/accessibility_utils.dart';
import '../../widgets/responsive_layout.dart';

class IntegrationConfigDialog extends StatefulWidget {
  final IntegrationType type;
  final IntegrationConfig? existingConfig;

  const IntegrationConfigDialog({
    super.key,
    required this.type,
    this.existingConfig,
  });

  @override
  State<IntegrationConfigDialog> createState() => _IntegrationConfigDialogState();
}

class _IntegrationConfigDialogState extends State<IntegrationConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _controllers;
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _controllers = {};
    final fields = _getConfigFields(widget.type);
    
    for (final field in fields) {
      _controllers[field.key] = TextEditingController(
        text: widget.existingConfig?.settings[field.key]?.toString() ?? field.defaultValue ?? '',
      );
    }
    
    _enabled = widget.existingConfig?.enabled ?? true;
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveDialog(
      title: '${widget.existingConfig != null ? 'Edit' : 'Configure'} ${_getDisplayName(widget.type)}',
      content: _buildConfigForm(context),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveConfiguration,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildConfigForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: ResponsiveForm(
        children: [
          SwitchListTile(
            title: const Text('Enable Integration'),
            subtitle: Text('Allow ${_getDisplayName(widget.type)} integration'),
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
          ),
          SizedBox(height: context.mediumSpacing),
          if (_enabled) ..._buildConfigFields(context),
          SizedBox(height: context.mediumSpacing),
          _buildIntegrationInfo(context),
        ],
      ),
    );
  }

  List<Widget> _buildConfigFields(BuildContext context) {
    final fields = _getConfigFields(widget.type);
    
    return fields.map((field) {
      return AccessibilityUtils.createAccessibleTextField(
        controller: _controllers[field.key]!,
        labelText: field.label,
        hintText: field.hint,
        obscureText: field.isSecret,
        keyboardType: field.keyboardType,
      );
    }).toList();
  }

  Widget _buildIntegrationInfo(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: context.smallSpacing),
              Text(
                'Setup Instructions',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          SizedBox(height: context.smallSpacing),
          ..._getSetupInstructions(widget.type).map((instruction) => 
            Padding(
              padding: EdgeInsets.only(bottom: context.smallSpacing / 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Expanded(
                    child: Text(
                      instruction,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveConfiguration() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final config = <String, dynamic>{
      'enabled': _enabled,
    };

    if (_enabled) {
      for (final entry in _controllers.entries) {
        config[entry.key] = entry.value.text;
      }
    }

    Navigator.of(context).pop(config);
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

  List<ConfigField> _getConfigFields(IntegrationType type) {
    switch (type) {
      case IntegrationType.slack:
        return [
          const ConfigField(
            key: 'botToken',
            label: 'Bot Token',
            hint: 'xoxb-your-bot-token',
            isSecret: true,
            isRequired: true,
          ),
          const ConfigField(
            key: 'defaultChannel',
            label: 'Default Channel',
            hint: '#general',
            defaultValue: '#general',
          ),
          const ConfigField(
            key: 'webhookUrl',
            label: 'Webhook URL (Optional)',
            hint: 'https://hooks.slack.com/services/...',
          ),
        ];
      
      case IntegrationType.microsoftTeams:
        return [
          const ConfigField(
            key: 'tenantId',
            label: 'Tenant ID',
            hint: 'your-tenant-id',
            isRequired: true,
          ),
          const ConfigField(
            key: 'clientId',
            label: 'Client ID',
            hint: 'your-client-id',
            isRequired: true,
          ),
          const ConfigField(
            key: 'clientSecret',
            label: 'Client Secret',
            hint: 'your-client-secret',
            isSecret: true,
            isRequired: true,
          ),
          const ConfigField(
            key: 'defaultTeam',
            label: 'Default Team',
            hint: 'Team Name',
          ),
        ];
      
      case IntegrationType.googleCalendar:
        return [
          const ConfigField(
            key: 'clientId',
            label: 'Client ID',
            hint: 'your-google-client-id',
            isRequired: true,
          ),
          const ConfigField(
            key: 'clientSecret',
            label: 'Client Secret',
            hint: 'your-google-client-secret',
            isSecret: true,
            isRequired: true,
          ),
          const ConfigField(
            key: 'calendarId',
            label: 'Calendar ID',
            hint: 'primary',
            defaultValue: 'primary',
          ),
        ];
      
      case IntegrationType.microsoftCalendar:
        return [
          const ConfigField(
            key: 'tenantId',
            label: 'Tenant ID',
            hint: 'your-tenant-id',
            isRequired: true,
          ),
          const ConfigField(
            key: 'clientId',
            label: 'Client ID',
            hint: 'your-client-id',
            isRequired: true,
          ),
          const ConfigField(
            key: 'clientSecret',
            label: 'Client Secret',
            hint: 'your-client-secret',
            isSecret: true,
            isRequired: true,
          ),
        ];
      
      case IntegrationType.email:
        return [
          const ConfigField(
            key: 'smtpHost',
            label: 'SMTP Host',
            hint: 'smtp.gmail.com',
            isRequired: true,
          ),
          const ConfigField(
            key: 'smtpPort',
            label: 'SMTP Port',
            hint: '587',
            defaultValue: '587',
            keyboardType: TextInputType.number,
          ),
          const ConfigField(
            key: 'username',
            label: 'Username',
            hint: 'your-email@example.com',
            isRequired: true,
            keyboardType: TextInputType.emailAddress,
          ),
          const ConfigField(
            key: 'password',
            label: 'Password',
            hint: 'your-password',
            isSecret: true,
            isRequired: true,
          ),
          const ConfigField(
            key: 'fromName',
            label: 'From Name',
            hint: 'Ngage Platform',
            defaultValue: 'Ngage Platform',
          ),
        ];
    }
  }

  List<String> _getSetupInstructions(IntegrationType type) {
    switch (type) {
      case IntegrationType.slack:
        return [
          'Create a Slack app at api.slack.com',
          'Add the bot token scope and install to your workspace',
          'Copy the Bot User OAuth Token',
          'Optionally configure incoming webhooks for additional functionality',
        ];
      
      case IntegrationType.microsoftTeams:
        return [
          'Register an app in Azure Active Directory',
          'Grant necessary permissions for Teams and Graph API',
          'Create a client secret',
          'Configure the app for your Teams organization',
        ];
      
      case IntegrationType.googleCalendar:
        return [
          'Create a project in Google Cloud Console',
          'Enable the Google Calendar API',
          'Create OAuth 2.0 credentials',
          'Configure authorized redirect URIs',
        ];
      
      case IntegrationType.microsoftCalendar:
        return [
          'Register an app in Azure Active Directory',
          'Grant Calendar.ReadWrite permissions',
          'Create a client secret',
          'Configure OAuth redirect URIs',
        ];
      
      case IntegrationType.email:
        return [
          'Use your email provider\'s SMTP settings',
          'For Gmail, enable 2-factor auth and use app passwords',
          'For Office 365, use smtp-mail.outlook.com:587',
          'Test the connection after configuration',
        ];
    }
  }
}

class ConfigField {
  final String key;
  final String label;
  final String? hint;
  final String? defaultValue;
  final bool isSecret;
  final bool isRequired;
  final TextInputType? keyboardType;

  const ConfigField({
    required this.key,
    required this.label,
    this.hint,
    this.defaultValue,
    this.isSecret = false,
    this.isRequired = false,
    this.keyboardType,
  });
}