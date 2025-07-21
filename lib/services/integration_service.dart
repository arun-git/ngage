import '../models/integration_models.dart';
import '../utils/logger.dart';

/// Service for managing multi-platform integrations
class IntegrationService {
  final Logger _logger = Logger();
  final Map<IntegrationType, PlatformIntegration> _integrations = {};
  
  /// Initialize the integration service
  Future<void> initialize() async {
    try {
      _logger.info('Initializing integration service');
      
      // Initialize available integrations
      _integrations[IntegrationType.slack] = SlackIntegration();
      _integrations[IntegrationType.microsoftTeams] = MicrosoftTeamsIntegration();
      _integrations[IntegrationType.googleCalendar] = GoogleCalendarIntegration();
      _integrations[IntegrationType.microsoftCalendar] = MicrosoftCalendarIntegration();
      _integrations[IntegrationType.email] = EmailIntegration();
      
      // Initialize each integration
      for (final integration in _integrations.values) {
        await integration.initialize();
      }
      
      _logger.info('Integration service initialized successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize integration service', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Get available integrations
  List<IntegrationType> getAvailableIntegrations() {
    return _integrations.keys.toList();
  }
  
  /// Check if an integration is enabled
  bool isIntegrationEnabled(IntegrationType type) {
    return _integrations[type]?.isEnabled ?? false;
  }
  
  /// Enable an integration
  Future<void> enableIntegration(
    IntegrationType type,
    Map<String, dynamic> config,
  ) async {
    try {
      final integration = _integrations[type];
      if (integration == null) {
        throw IntegrationException('Integration type $type not supported');
      }
      
      await integration.configure(config);
      await integration.enable();
      
      _logger.info('Integration $type enabled successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to enable integration $type', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Disable an integration
  Future<void> disableIntegration(IntegrationType type) async {
    try {
      final integration = _integrations[type];
      if (integration == null) {
        throw IntegrationException('Integration type $type not supported');
      }
      
      await integration.disable();
      
      _logger.info('Integration $type disabled successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to disable integration $type', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Send notification through enabled integrations
  Future<void> sendNotification(NotificationMessage message) async {
    final enabledIntegrations = _integrations.entries
        .where((entry) => entry.value.isEnabled)
        .toList();
    
    if (enabledIntegrations.isEmpty) {
      _logger.warning('No enabled integrations for sending notification');
      return;
    }
    
    final futures = enabledIntegrations.map((entry) async {
      try {
        await entry.value.sendNotification(message);
        _logger.info('Notification sent via ${entry.key}');
      } catch (e, stackTrace) {
        _logger.error('Failed to send notification via ${entry.key}', error: e, stackTrace: stackTrace);
        // Don't rethrow - continue with other integrations
      }
    });
    
    await Future.wait(futures);
  }
  
  /// Send calendar event through calendar integrations
  Future<void> sendCalendarEvent(CalendarEvent event) async {
    final calendarIntegrations = _integrations.entries
        .where((entry) => 
          (entry.key == IntegrationType.googleCalendar || 
           entry.key == IntegrationType.microsoftCalendar) &&
          entry.value.isEnabled)
        .toList();
    
    if (calendarIntegrations.isEmpty) {
      _logger.warning('No enabled calendar integrations');
      return;
    }
    
    final futures = calendarIntegrations.map((entry) async {
      try {
        final calendarIntegration = entry.value as CalendarIntegration;
        await calendarIntegration.createEvent(event);
        _logger.info('Calendar event created via ${entry.key}');
      } catch (e, stackTrace) {
        _logger.error('Failed to create calendar event via ${entry.key}', error: e, stackTrace: stackTrace);
        // Don't rethrow - continue with other integrations
      }
    });
    
    await Future.wait(futures);
  }
  
  /// Get integration configuration
  IntegrationConfig? getIntegrationConfig(IntegrationType type) {
    return _integrations[type]?.getConfig();
  }
  
  /// Update integration configuration
  Future<void> updateIntegrationConfig(
    IntegrationType type,
    Map<String, dynamic> config,
  ) async {
    try {
      final integration = _integrations[type];
      if (integration == null) {
        throw IntegrationException('Integration type $type not supported');
      }
      
      await integration.configure(config);
      
      _logger.info('Integration $type configuration updated');
    } catch (e, stackTrace) {
      _logger.error('Failed to update integration $type configuration', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Test integration connection
  Future<bool> testIntegration(IntegrationType type) async {
    try {
      final integration = _integrations[type];
      if (integration == null) {
        throw IntegrationException('Integration type $type not supported');
      }
      
      final result = await integration.testConnection();
      
      _logger.info('Integration $type test result: $result');
      return result;
    } catch (e, stackTrace) {
      _logger.error('Failed to test integration $type', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Get integration status
  IntegrationStatus getIntegrationStatus(IntegrationType type) {
    final integration = _integrations[type];
    if (integration == null) {
      return IntegrationStatus.notSupported;
    }
    
    if (!integration.isEnabled) {
      return IntegrationStatus.disabled;
    }
    
    return integration.isConnected 
        ? IntegrationStatus.connected 
        : IntegrationStatus.disconnected;
  }
  
  /// Get all integration statuses
  Map<IntegrationType, IntegrationStatus> getAllIntegrationStatuses() {
    return Map.fromEntries(
      _integrations.keys.map((type) => 
        MapEntry(type, getIntegrationStatus(type))
      )
    );
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    try {
      for (final integration in _integrations.values) {
        await integration.dispose();
      }
      _integrations.clear();
      
      _logger.info('Integration service disposed');
    } catch (e, stackTrace) {
      _logger.error('Error disposing integration service', error: e, stackTrace: stackTrace);
    }
  }
}

/// Exception thrown by integration operations
class IntegrationException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  const IntegrationException(
    this.message, {
    this.code,
    this.originalError,
  });
  
  @override
  String toString() => 'IntegrationException: $message';
}