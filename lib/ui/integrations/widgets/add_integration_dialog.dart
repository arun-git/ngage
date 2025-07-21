import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/models.dart';
import '../../../providers/integration_providers.dart';

/// Dialog for adding or editing integration configurations
class AddIntegrationDialog extends ConsumerStatefulWidget {
  final String groupId;
  final IntegrationConfig? existingIntegration;
  final VoidCallback onIntegrationAdded;

  const AddIntegrationDialog({
    super.key,
    required this.groupId,
    this.existingIntegration,
    required this.onIntegrationAdded,
  });

  @override
  ConsumerState<AddIntegrationDialog> createState() => _AddIntegrationDialogState();
}

class _AddIntegrationDialogState extends ConsumerState<AddIntegrationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  IntegrationType? _selectedType;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _channelMappings = {};
  bool _isLoading = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    if (widget.existingIntegration != null) {
      _selectedType = widget.existingIntegration!.type;
      _initializeControllersFromExisting();
      _channelMappings.addAll(widget.existingIntegration!.channelMappings);
    }
  }

  void _initializeControllersFromExisting() {
    final settings = widget.existingIntegration!.settings;
    settings.forEach((key, value) {
      _controllers[key] = TextEditingController(text: value.toString());
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supportedPlatforms = ref.watch(supportedIntegrationPlatformsProvider);
    final notificationMappings = ref.watch(notificationTypeMappingsProvider);

    return Dialog(
      child: SizedBox(
        width: 600,
        height: 700,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    widget.existingIntegration != null 
                        ? 'Edit Integration' 
                        : 'Add Integration',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Progress Indicator
            LinearProgressIndicator(
              value: (_currentPage + 1) / 3,
              backgroundColor: Colors.grey[300],
            ),
            
            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildPlatformSelectionPage(supportedPlatforms),
                  _buildConfigurationPage(),
                  _buildChannelMappingPage(notificationMappings),
                ],
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  if (_currentPage < 2)
                    FilledButton(
                      onPressed: _nextPage,
                      child: const Text('Next'),
                    )
                  else
                    FilledButton(
                      onPressed: _isLoading ? null : _saveIntegration,
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.existingIntegration != null ? 'Update' : 'Create'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformSelectionPage(Map<IntegrationType, Map<String, dynamic>> supportedPlatforms) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Integration Platform',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the platform you want to integrate with.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: ListView(
              children: supportedPlatforms.entries.map((entry) {
                final type = entry.key;
                final info = entry.value;
                final isSelected = _selectedType == type;
                
                return Card(
                  elevation: isSelected ? 4 : 1,
                  color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(int.parse(info['color'].substring(1), radix: 16) + 0xFF000000).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getIconForPlatform(type),
                        color: Color(int.parse(info['color'].substring(1), radix: 16) + 0xFF000000),
                      ),
                    ),
                    title: Text(info['name']),
                    subtitle: Text(info['description']),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                    onTap: () => setState(() => _selectedType = type),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationPage() {
    if (_selectedType == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration Settings',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the required configuration details for ${_selectedType!.value}.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: ListView(
                children: _buildConfigurationFields(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildConfigurationFields() {
    switch (_selectedType!) {
      case IntegrationType.slack:
        return [
          _buildTextField('botToken', 'Bot Token', isRequired: true, isPassword: true),
          _buildTextField('channelId', 'Default Channel ID', isRequired: true),
        ];
      
      case IntegrationType.microsoftTeams:
        return [
          _buildTextField('tenantId', 'Tenant ID', isRequired: true),
          _buildTextField('clientId', 'Client ID', isRequired: true),
          _buildTextField('clientSecret', 'Client Secret', isRequired: true, isPassword: true),
          _buildTextField('teamId', 'Team ID', isRequired: true),
          _buildTextField('channelId', 'Default Channel ID', isRequired: true),
          _buildTextField('webhookUrl', 'Webhook URL (Optional)'),
        ];
      
      case IntegrationType.email:
        return [
          _buildTextField('smtpHost', 'SMTP Host', isRequired: true),
          _buildTextField('smtpPort', 'SMTP Port', isRequired: true, inputType: TextInputType.number),
          _buildTextField('username', 'Username', isRequired: true),
          _buildTextField('password', 'Password', isRequired: true, isPassword: true),
          _buildTextField('fromEmail', 'From Email', isRequired: true, inputType: TextInputType.emailAddress),
          _buildTextField('fromName', 'From Name', isRequired: true),
          SwitchListTile(
            title: const Text('Use TLS'),
            value: _controllers['useTLS']?.text == 'true',
            onChanged: (value) {
              _controllers['useTLS'] ??= TextEditingController();
              _controllers['useTLS']!.text = value.toString();
              setState(() {});
            },
          ),
        ];
      
      case IntegrationType.googleCalendar:
      case IntegrationType.microsoftCalendar:
        return [
          _buildTextField('calendarId', 'Calendar ID', isRequired: true),
          _buildTextField('accessToken', 'Access Token', isRequired: true, isPassword: true),
          _buildTextField('refreshToken', 'Refresh Token', isRequired: true, isPassword: true),
        ];
    }
  }

  Widget _buildTextField(
    String key,
    String label, {
    bool isRequired = false,
    bool isPassword = false,
    TextInputType inputType = TextInputType.text,
  }) {
    _controllers[key] ??= TextEditingController();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        obscureText: isPassword,
        keyboardType: inputType,
        validator: isRequired ? (value) {
          if (value == null || value.isEmpty) {
            return '$label is required';
          }
          return null;
        } : null,
      ),
    );
  }

  Widget _buildChannelMappingPage(Map<NotificationType, String> notificationMappings) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Channel Mapping',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Configure where different types of notifications should be sent.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: ListView(
              children: notificationMappings.entries.map((entry) {
                final type = entry.key;
                final label = entry.value;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: label,
                      border: const OutlineInputBorder(),
                      helperText: _getChannelHelperText(type),
                    ),
                    initialValue: _channelMappings[type.value],
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        _channelMappings[type.value] = value;
                      } else {
                        _channelMappings.remove(type.value);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getChannelHelperText(NotificationType type) {
    switch (_selectedType!) {
      case IntegrationType.slack:
      case IntegrationType.microsoftTeams:
        return 'Enter channel ID or name';
      case IntegrationType.email:
        return 'Enter email addresses (comma-separated)';
      case IntegrationType.googleCalendar:
      case IntegrationType.microsoftCalendar:
        return 'Enter calendar ID';
    }
  }

  IconData _getIconForPlatform(IntegrationType type) {
    switch (type) {
      case IntegrationType.slack:
        return Icons.chat;
      case IntegrationType.microsoftTeams:
        return Icons.groups;
      case IntegrationType.email:
        return Icons.email;
      case IntegrationType.googleCalendar:
      case IntegrationType.microsoftCalendar:
        return Icons.calendar_today;
    }
  }

  void _nextPage() {
    if (_currentPage == 0 && _selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a platform')),
      );
      return;
    }
    
    if (_currentPage == 1 && !_formKey.currentState!.validate()) {
      return;
    }
    
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _saveIntegration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(integrationServiceProvider);
      final settings = <String, dynamic>{};
      
      _controllers.forEach((key, controller) {
        final value = controller.text;
        if (value.isNotEmpty) {
          // Try to parse as number for numeric fields
          if (key == 'smtpPort') {
            settings[key] = int.tryParse(value) ?? value;
          } else if (key == 'useTLS') {
            settings[key] = value == 'true';
          } else {
            settings[key] = value;
          }
        }
      });

      if (widget.existingIntegration != null) {
        final updatedIntegration = widget.existingIntegration!.copyWith(
          settings: settings,
          channelMappings: _channelMappings,
          updatedAt: DateTime.now(),
        );
        await service.updateIntegration(updatedIntegration);
      } else {
        await service.createIntegration(
          groupId: widget.groupId,
          type: _selectedType!,
          settings: settings,
          channelMappings: _channelMappings,
        );
      }

      widget.onIntegrationAdded();
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingIntegration != null 
                  ? 'Integration updated successfully' 
                  : 'Integration created successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving integration: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}