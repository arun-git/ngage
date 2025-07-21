import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/integration.dart';
import '../models/enums.dart';

/// Service for handling email notifications
/// Supports multiple email providers (SendGrid, Mailgun, SES, SMTP)
class EmailService {
  final http.Client _httpClient;
  
  EmailService({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  /// Sends email notification using the configured provider
  Future<bool> sendNotification({
    required EmailIntegration integration,
    required NotificationMessage message,
  }) async {
    switch (integration.provider) {
      case EmailProvider.sendgrid:
        return await _sendViaSendGrid(integration, message);
      case EmailProvider.mailgun:
        return await _sendViaMailgun(integration, message);
      case EmailProvider.ses:
        return await _sendViaSES(integration, message);
      case EmailProvider.smtp:
        return await _sendViaSMTP(integration, message);
    }
  }

  /// Sends event reminder email
  Future<bool> sendEventReminder({
    required EmailIntegration integration,
    required Event event,
    List<String>? specificRecipients,
  }) async {
    final recipients = specificRecipients ?? 
        integration.notificationMappings['event_reminder'] ?? 
        integration.recipientEmails;

    final message = NotificationMessage(
      title: 'Event Reminder: ${event.title}',
      content: _buildEventReminderContent(event),
      type: NotificationType.eventReminder,
      recipients: recipients,
    );

    return await sendNotification(integration: integration, message: message);
  }

  /// Sends result announcement email
  Future<bool> sendResultAnnouncement({
    required EmailIntegration integration,
    required Event event,
    required List<Leaderboard> leaderboard,
    List<String>? specificRecipients,
  }) async {
    final recipients = specificRecipients ?? 
        integration.notificationMappings['result_announcement'] ?? 
        integration.recipientEmails;

    final message = NotificationMessage(
      title: 'Results Announced: ${event.title}',
      content: _buildResultAnnouncementContent(event, leaderboard),
      type: NotificationType.resultAnnouncement,
      recipients: recipients,
    );

    return await sendNotification(integration: integration, message: message);
  }

  /// Sends leaderboard update email
  Future<bool> sendLeaderboardUpdate({
    required EmailIntegration integration,
    required Event event,
    required List<Leaderboard> leaderboard,
    List<String>? specificRecipients,
  }) async {
    final recipients = specificRecipients ?? 
        integration.notificationMappings['leaderboard_update'] ?? 
        integration.recipientEmails;

    final message = NotificationMessage(
      title: 'Leaderboard Update: ${event.title}',
      content: _buildLeaderboardUpdateContent(event, leaderboard),
      type: NotificationType.leaderboardUpdate,
      recipients: recipients,
    );

    return await sendNotification(integration: integration, message: message);
  }

  /// Sends deadline alert email
  Future<bool> sendDeadlineAlert({
    required EmailIntegration integration,
    required Event event,
    required Duration timeRemaining,
    List<String>? specificRecipients,
  }) async {
    final recipients = specificRecipients ?? 
        integration.notificationMappings['deadline_alert'] ?? 
        integration.recipientEmails;

    final message = NotificationMessage(
      title: 'Deadline Alert: ${event.title}',
      content: _buildDeadlineAlertContent(event, timeRemaining),
      type: NotificationType.deadlineAlert,
      recipients: recipients,
    );

    return await sendNotification(integration: integration, message: message);
  }

  /// Tests email integration by sending a test message
  Future<bool> testIntegration({
    required EmailIntegration integration,
    String? testRecipient,
  }) async {
    final recipient = testRecipient ?? integration.recipientEmails.first;
    
    final message = NotificationMessage(
      title: '🎉 Ngage Email Integration Test',
      content: _buildTestEmailContent(),
      type: NotificationType.general,
      recipients: [recipient],
    );

    return await sendNotification(integration: integration, message: message);
  }

  /// Sends email via SendGrid
  Future<bool> _sendViaSendGrid(EmailIntegration integration, NotificationMessage message) async {
    try {
      final apiKey = integration.configuration['apiKey'] as String;
      final fromEmail = integration.configuration['fromEmail'] as String;
      final fromName = integration.configuration['fromName'] as String? ?? 'Ngage Platform';

      final emailData = {
        'personalizations': [
          {
            'to': message.recipients!.map((email) => {'email': email}).toList(),
            'subject': message.title,
          }
        ],
        'from': {
          'email': fromEmail,
          'name': fromName,
        },
        'content': [
          {
            'type': 'text/html',
            'value': message.content,
          }
        ],
      };

      final response = await _httpClient.post(
        Uri.parse('https://api.sendgrid.com/v3/mail/send'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode(emailData),
      );

      return response.statusCode == 202;
    } catch (e) {
      print('Failed to send email via SendGrid: $e');
      return false;
    }
  }

  /// Sends email via Mailgun
  Future<bool> _sendViaMailgun(EmailIntegration integration, NotificationMessage message) async {
    try {
      final apiKey = integration.configuration['apiKey'] as String;
      final domain = integration.configuration['domain'] as String;
      final fromEmail = integration.configuration['fromEmail'] as String;

      final response = await _httpClient.post(
        Uri.parse('https://api.mailgun.net/v3/$domain/messages'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('api:$apiKey'))}',
        },
        body: {
          'from': fromEmail,
          'to': message.recipients!.join(','),
          'subject': message.title,
          'html': message.content,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Failed to send email via Mailgun: $e');
      return false;
    }
  }

  /// Sends email via AWS SES
  Future<bool> _sendViaSES(EmailIntegration integration, NotificationMessage message) async {
    try {
      // AWS SES implementation would require AWS SDK
      // For now, return a placeholder implementation
      print('AWS SES integration not yet implemented');
      return false;
    } catch (e) {
      print('Failed to send email via SES: $e');
      return false;
    }
  }

  /// Sends email via SMTP
  Future<bool> _sendViaSMTP(EmailIntegration integration, NotificationMessage message) async {
    try {
      // SMTP implementation would require a proper SMTP client
      // For now, return a placeholder implementation
      print('SMTP integration not yet implemented');
      return false;
    } catch (e) {
      print('Failed to send email via SMTP: $e');
      return false;
    }
  }

  /// Builds event reminder email content
  String _buildEventReminderContent(Event event) {
    final startTime = event.startTime?.toLocal();
    final endTime = event.endTime?.toLocal();
    final submissionDeadline = event.submissionDeadline?.toLocal();

    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>Event Reminder</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background-color: #f9f9f9; }
            .footer { padding: 20px; text-align: center; color: #666; }
            .highlight { background-color: #fff3cd; padding: 10px; border-left: 4px solid #ffc107; margin: 10px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>📢 Event Reminder</h1>
            </div>
            <div class="content">
                <h2>${event.title}</h2>
                <p>${event.description}</p>
                
                <div class="highlight">
                    ${startTime != null ? '<p><strong>📅 Start:</strong> ${_formatDateTime(startTime)}</p>' : ''}
                    ${endTime != null ? '<p><strong>🏁 End:</strong> ${_formatDateTime(endTime)}</p>' : ''}
                    ${submissionDeadline != null ? '<p><strong>⏰ Submission Deadline:</strong> ${_formatDateTime(submissionDeadline)}</p>' : ''}
                    <p><strong>Event Type:</strong> ${event.eventType.value.toUpperCase()}</p>
                </div>
                
                <p><strong>🚀 Ready to participate?</strong> Make sure you're prepared!</p>
            </div>
            <div class="footer">
                <p>This email was sent by the Ngage Platform</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  /// Builds result announcement email content
  String _buildResultAnnouncementContent(Event event, List<Leaderboard> leaderboard) {
    final topEntries = leaderboard.take(3).toList();
    final resultsHtml = StringBuffer();
    
    for (int i = 0; i < topEntries.length; i++) {
      final entry = topEntries[i];
      final medal = i == 0 ? '🥇' : i == 1 ? '🥈' : '🥉';
      resultsHtml.write('<p>$medal <strong>${i + 1}.</strong> ${entry.teamName} - ${entry.totalScore.toStringAsFixed(1)} points</p>');
    }

    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>Results Announced</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #FF6B35; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background-color: #f9f9f9; }
            .footer { padding: 20px; text-align: center; color: #666; }
            .results { background-color: #fff; padding: 15px; border-radius: 5px; margin: 15px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🎉 Results Announced!</h1>
            </div>
            <div class="content">
                <h2>${event.title} results are now available!</h2>
                
                <div class="results">
                    <h3>🏆 Top Performers:</h3>
                    ${resultsHtml.toString()}
                </div>
                
                <p><strong>🎊 Congratulations to all participants!</strong></p>
            </div>
            <div class="footer">
                <p>This email was sent by the Ngage Platform</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  /// Builds leaderboard update email content
  String _buildLeaderboardUpdateContent(Event event, List<Leaderboard> leaderboard) {
    final topEntries = leaderboard.take(5).toList();
    final leaderboardHtml = StringBuffer();
    
    for (int i = 0; i < topEntries.length; i++) {
      final entry = topEntries[i];
      final position = i + 1;
      final emoji = position <= 3 ? ['🥇', '🥈', '🥉'][i] : '🏅';
      leaderboardHtml.write('<p>$emoji <strong>$position.</strong> ${entry.teamName} - ${entry.totalScore.toStringAsFixed(1)} pts</p>');
    }

    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>Leaderboard Update</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #2196F3; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background-color: #f9f9f9; }
            .footer { padding: 20px; text-align: center; color: #666; }
            .leaderboard { background-color: #fff; padding: 15px; border-radius: 5px; margin: 15px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>📊 Leaderboard Update</h1>
            </div>
            <div class="content">
                <h2>${event.title}</h2>
                <p>Current standings:</p>
                
                <div class="leaderboard">
                    ${leaderboardHtml.toString()}
                </div>
                
                <p><em>Keep up the great work! 💪</em></p>
            </div>
            <div class="footer">
                <p>This email was sent by the Ngage Platform</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  /// Builds deadline alert email content
  String _buildDeadlineAlertContent(Event event, Duration timeRemaining) {
    final hours = timeRemaining.inHours;
    final minutes = timeRemaining.inMinutes % 60;
    
    String timeRemainingText;
    if (hours > 0) {
      timeRemainingText = '$hours hours and $minutes minutes';
    } else {
      timeRemainingText = '$minutes minutes';
    }

    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>Deadline Alert</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #FF5722; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background-color: #f9f9f9; }
            .footer { padding: 20px; text-align: center; color: #666; }
            .alert { background-color: #fff3cd; padding: 15px; border-left: 4px solid #ffc107; margin: 15px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>⏰ Deadline Alert</h1>
            </div>
            <div class="content">
                <h2>${event.title}</h2>
                
                <div class="alert">
                    <p><strong>⚠️ Time is running out!</strong></p>
                    <p>Only <strong>$timeRemainingText</strong> remaining until the submission deadline.</p>
                    ${event.submissionDeadline != null ? '<p><strong>Deadline:</strong> ${_formatDateTime(event.submissionDeadline!)}</p>' : ''}
                </div>
                
                <p><strong>🏃‍♂️ Don't miss out!</strong> Make sure to submit your entry before the deadline.</p>
            </div>
            <div class="footer">
                <p>This email was sent by the Ngage Platform</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  /// Builds test email content
  String _buildTestEmailContent() {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>Integration Test</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background-color: #f9f9f9; }
            .footer { padding: 20px; text-align: center; color: #666; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🎉 Ngage Email Integration Test</h1>
            </div>
            <div class="content">
                <p>Your Ngage platform is successfully connected to your email service!</p>
                <p><em>This is a test message to verify the email integration.</em></p>
                <p>You should now receive email notifications for:</p>
                <ul>
                    <li>Event reminders</li>
                    <li>Deadline alerts</li>
                    <li>Result announcements</li>
                    <li>Leaderboard updates</li>
                </ul>
            </div>
            <div class="footer">
                <p>This email was sent by the Ngage Platform</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  /// Formats DateTime for display
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Validates email integration configuration
  bool validateConfiguration(EmailIntegration integration) {
    switch (integration.provider) {
      case EmailProvider.sendgrid:
        return integration.configuration.containsKey('apiKey') &&
               integration.configuration.containsKey('fromEmail');
      case EmailProvider.mailgun:
        return integration.configuration.containsKey('apiKey') &&
               integration.configuration.containsKey('domain') &&
               integration.configuration.containsKey('fromEmail');
      case EmailProvider.ses:
        return integration.configuration.containsKey('accessKeyId') &&
               integration.configuration.containsKey('secretAccessKey') &&
               integration.configuration.containsKey('region');
      case EmailProvider.smtp:
        return integration.configuration.containsKey('host') &&
               integration.configuration.containsKey('port') &&
               integration.configuration.containsKey('username') &&
               integration.configuration.containsKey('password');
    }
  }

  /// Disposes resources
  void dispose() {
    _httpClient.close();
  }
}