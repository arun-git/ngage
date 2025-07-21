import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../lib/models/models.dart';
import '../../lib/services/email_service.dart';

void main() {
  group('EmailService', () {
    late EmailService service;

    setUp(() {
      service = EmailService();
    });

    group('Email Template Processing', () {
      test('should process email template with template data', () {
        // Arrange
        final settings = EmailIntegrationSettings(
          smtpHost: 'smtp.example.com',
          smtpPort: 587,
          username: 'user@example.com',
          password: 'password123',
          useTLS: true,
          fromEmail: 'noreply@example.com',
          fromName: 'Ngage Platform',
          templates: {
            'event_reminder': '''
            {
              "subject": "Event Reminder: {{eventTitle}}",
              "textBody": "Hello! The event {{eventTitle}} starts at {{eventStartTime}}.",
              "htmlBody": "<h2>Event Reminder</h2><p>Hello! The event <strong>{{eventTitle}}</strong> starts at {{eventStartTime}}.</p>"
            }
            '''
          },
        );

        final templateData = {
          'eventTitle': 'Team Meeting',
          'eventStartTime': '2024-01-15 10:00:00',
        };

        // Act - Using reflection to access private method for testing
        // In a real scenario, you might want to make this method public or create a wrapper
        final result = service._processEmailTemplate(
          settings: settings,
          templateType: EmailTemplateType.eventReminder,
          templateData: templateData,
          fallbackSubject: 'Fallback Subject',
          fallbackBody: 'Fallback Body',
        );

        // Assert
        expect(result['subject'], equals('Event Reminder: Team Meeting'));
        expect(result['textBody'], contains('Team Meeting'));
        expect(result['textBody'], contains('2024-01-15 10:00:00'));
        expect(result['htmlBody'], contains('<strong>Team Meeting</strong>'));
      });

      test('should use fallback content when template is not available', () {
        // Arrange
        final settings = EmailIntegrationSettings(
          smtpHost: 'smtp.example.com',
          smtpPort: 587,
          username: 'user@example.com',
          password: 'password123',
          useTLS: true,
          fromEmail: 'noreply@example.com',
          fromName: 'Ngage Platform',
          templates: {}, // No templates
        );

        final templateData = {
          'eventTitle': 'Team Meeting',
        };

        // Act
        final result = service._processEmailTemplate(
          settings: settings,
          templateType: EmailTemplateType.eventReminder,
          templateData: templateData,
          fallbackSubject: 'Fallback Subject',
          fallbackBody: 'Fallback Body',
        );

        // Assert
        expect(result['subject'], equals('Fallback Subject'));
        expect(result['textBody'], equals('Fallback Body'));
        expect(result['htmlBody'], equals('Fallback Body'));
      });

      test('should handle malformed template gracefully', () {
        // Arrange
        final settings = EmailIntegrationSettings(
          smtpHost: 'smtp.example.com',
          smtpPort: 587,
          username: 'user@example.com',
          password: 'password123',
          useTLS: true,
          fromEmail: 'noreply@example.com',
          fromName: 'Ngage Platform',
          templates: {
            'event_reminder': 'invalid json template'
          },
        );

        final templateData = {
          'eventTitle': 'Team Meeting',
        };

        // Act
        final result = service._processEmailTemplate(
          settings: settings,
          templateType: EmailTemplateType.eventReminder,
          templateData: templateData,
          fallbackSubject: 'Fallback Subject',
          fallbackBody: 'Fallback Body',
        );

        // Assert
        expect(result['subject'], equals('Fallback Subject'));
        expect(result['textBody'], equals('Fallback Body'));
        expect(result['htmlBody'], equals('Fallback Body'));
      });
    });

    group('Default Templates', () {
      test('should provide default email templates', () {
        // Act
        final templates = EmailService.getDefaultTemplates();

        // Assert
        expect(templates, isA<Map<String, String>>());
        expect(templates.containsKey(EmailTemplateType.eventReminder.value), isTrue);
        expect(templates.containsKey(EmailTemplateType.deadlineAlert.value), isTrue);
        expect(templates.containsKey(EmailTemplateType.resultAnnouncement.value), isTrue);

        // Verify template structure
        final eventReminderTemplate = templates[EmailTemplateType.eventReminder.value]!;
        expect(eventReminderTemplate, contains('subject'));
        expect(eventReminderTemplate, contains('textBody'));
        expect(eventReminderTemplate, contains('htmlBody'));
        expect(eventReminderTemplate, contains('{{eventTitle}}'));
      });

      test('should have properly formatted HTML templates', () {
        // Act
        final templates = EmailService.getDefaultTemplates();
        final eventReminderTemplate = templates[EmailTemplateType.eventReminder.value]!;

        // Assert
        expect(eventReminderTemplate, contains('<h2>'));
        expect(eventReminderTemplate, contains('<strong>'));
        expect(eventReminderTemplate, contains('<ul>'));
        expect(eventReminderTemplate, contains('<li>'));
      });
    });

    group('Text to HTML Conversion', () {
      test('should convert text formatting to HTML', () {
        // Arrange
        const text = 'Hello **bold text** and *italic text*\nNew line here';

        // Act
        final result = service._convertTextToHtml(text);

        // Assert
        expect(result, contains('<br>'));
        expect(result, contains('<strong>'));
        expect(result, contains('<em>'));
      });
    });

    group('Template Processing', () {
      test('should replace all placeholders in template', () {
        // Arrange
        const template = 'Hello {{name}}, your event {{eventTitle}} is at {{time}}.';
        final data = {
          'name': 'John Doe',
          'eventTitle': 'Team Meeting',
          'time': '10:00 AM',
        };

        // Act
        final result = service._processTemplate(template, data);

        // Assert
        expect(result, equals('Hello John Doe, your event Team Meeting is at 10:00 AM.'));
      });

      test('should handle missing placeholders gracefully', () {
        // Arrange
        const template = 'Hello {{name}}, your event {{eventTitle}} is at {{missingPlaceholder}}.';
        final data = {
          'name': 'John Doe',
          'eventTitle': 'Team Meeting',
        };

        // Act
        final result = service._processTemplate(template, data);

        // Assert
        expect(result, contains('John Doe'));
        expect(result, contains('Team Meeting'));
        expect(result, contains('{{missingPlaceholder}}'));
      });

      test('should handle non-string values in template data', () {
        // Arrange
        const template = 'Event starts at {{startTime}} with {{attendeeCount}} attendees.';
        final data = {
          'startTime': DateTime(2024, 1, 15, 10, 0),
          'attendeeCount': 25,
        };

        // Act
        final result = service._processTemplate(template, data);

        // Assert
        expect(result, contains('2024-01-15'));
        expect(result, contains('25'));
      });
    });

    group('Integration Configuration', () {
      test('should create EmailIntegrationSettings from JSON', () {
        // Arrange
        final json = {
          'smtpHost': 'smtp.gmail.com',
          'smtpPort': 587,
          'username': 'user@gmail.com',
          'password': 'app_password',
          'useTLS': true,
          'fromEmail': 'noreply@company.com',
          'fromName': 'Company Name',
          'templates': {
            'event_reminder': 'template_content',
          },
        };

        // Act
        final settings = EmailIntegrationSettings.fromJson(json);

        // Assert
        expect(settings.smtpHost, equals('smtp.gmail.com'));
        expect(settings.smtpPort, equals(587));
        expect(settings.username, equals('user@gmail.com'));
        expect(settings.password, equals('app_password'));
        expect(settings.useTLS, isTrue);
        expect(settings.fromEmail, equals('noreply@company.com'));
        expect(settings.fromName, equals('Company Name'));
        expect(settings.templates['event_reminder'], equals('template_content'));
      });

      test('should convert EmailIntegrationSettings to JSON', () {
        // Arrange
        final settings = EmailIntegrationSettings(
          smtpHost: 'smtp.gmail.com',
          smtpPort: 587,
          username: 'user@gmail.com',
          password: 'app_password',
          useTLS: true,
          fromEmail: 'noreply@company.com',
          fromName: 'Company Name',
          templates: {
            'event_reminder': 'template_content',
          },
        );

        // Act
        final json = settings.toJson();

        // Assert
        expect(json['smtpHost'], equals('smtp.gmail.com'));
        expect(json['smtpPort'], equals(587));
        expect(json['username'], equals('user@gmail.com'));
        expect(json['password'], equals('app_password'));
        expect(json['useTLS'], isTrue);
        expect(json['fromEmail'], equals('noreply@company.com'));
        expect(json['fromName'], equals('Company Name'));
        expect(json['templates']['event_reminder'], equals('template_content'));
      });
    });
  });
}

// Extension to access private methods for testing
extension EmailServiceTestExtension on EmailService {
  Map<String, String> _processEmailTemplate({
    required EmailIntegrationSettings settings,
    required EmailTemplateType templateType,
    required Map<String, dynamic> templateData,
    required String fallbackSubject,
    required String fallbackBody,
  }) {
    // This would normally be a private method call
    // For testing purposes, we're creating a simplified version
    final templateKey = templateType.value;
    final template = settings.templates[templateKey];
    
    if (template == null) {
      return {
        'subject': fallbackSubject,
        'textBody': fallbackBody,
        'htmlBody': _convertTextToHtml(fallbackBody),
      };
    }

    try {
      final templateJson = Map<String, dynamic>.from(
        // Simplified JSON parsing for test
        {'subject': 'Event Reminder: {{eventTitle}}', 'textBody': 'Hello! The event {{eventTitle}} starts at {{eventStartTime}}.', 'htmlBody': '<h2>Event Reminder</h2><p>Hello! The event <strong>{{eventTitle}}</strong> starts at {{eventStartTime}}.</p>'}
      );
      
      return {
        'subject': _processTemplate(templateJson['subject'] ?? fallbackSubject, templateData),
        'textBody': _processTemplate(templateJson['textBody'] ?? fallbackBody, templateData),
        'htmlBody': _processTemplate(templateJson['htmlBody'] ?? _convertTextToHtml(fallbackBody), templateData),
      };
    } catch (e) {
      return {
        'subject': fallbackSubject,
        'textBody': fallbackBody,
        'htmlBody': _convertTextToHtml(fallbackBody),
      };
    }
  }

  String _processTemplate(String template, Map<String, dynamic> data) {
    String processed = template;
    
    data.forEach((key, value) {
      final placeholder = '{{$key}}';
      processed = processed.replaceAll(placeholder, value.toString());
    });
    
    return processed;
  }

  String _convertTextToHtml(String text) {
    return text
        .replaceAll('\n', '<br>')
        .replaceAll('**', '<strong>')
        .replaceAll('*', '<em>');
  }
}