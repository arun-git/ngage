import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import '../models/models.dart';

/// Service for calendar integration (Google Calendar and Microsoft Calendar)
/// 
/// Provides functionality to create calendar events, manage calendar access,
/// and handle calendar-specific operations.
class CalendarService {
  static const String _googleCalendarScope = 'https://www.googleapis.com/auth/calendar';
  static const String _microsoftGraphUrl = 'https://graph.microsoft.com/v1.0';

  /// Test calendar integration connectivity
  Future<bool> testConnection(IntegrationConfig integration) async {
    try {
      switch (integration.type) {
        case IntegrationType.googleCalendar:
          return await _testGoogleCalendarConnection(integration);
        case IntegrationType.microsoftCalendar:
          return await _testMicrosoftCalendarConnection(integration);
        default:
          return false;
      }
    } catch (e) {
      print('Calendar integration test failed: $e');
      return false;
    }
  }

  /// Create calendar event
  Future<void> createEvent(IntegrationConfig integration, CalendarEvent calendarEvent) async {
    try {
      switch (integration.type) {
        case IntegrationType.googleCalendar:
          await _createGoogleCalendarEvent(integration, calendarEvent);
          break;
        case IntegrationType.microsoftCalendar:
          await _createMicrosoftCalendarEvent(integration, calendarEvent);
          break;
        default:
          throw Exception('Unsupported calendar type: ${integration.type}');
      }
    } catch (e) {
      throw Exception('Failed to create calendar event: $e');
    }
  }

  /// Update calendar event
  Future<void> updateEvent(IntegrationConfig integration, CalendarEvent calendarEvent) async {
    try {
      switch (integration.type) {
        case IntegrationType.googleCalendar:
          await _updateGoogleCalendarEvent(integration, calendarEvent);
          break;
        case IntegrationType.microsoftCalendar:
          await _updateMicrosoftCalendarEvent(integration, calendarEvent);
          break;
        default:
          throw Exception('Unsupported calendar type: ${integration.type}');
      }
    } catch (e) {
      throw Exception('Failed to update calendar event: $e');
    }
  }

  /// Delete calendar event
  Future<void> deleteEvent(IntegrationConfig integration, String eventId) async {
    try {
      switch (integration.type) {
        case IntegrationType.googleCalendar:
          await _deleteGoogleCalendarEvent(integration, eventId);
          break;
        case IntegrationType.microsoftCalendar:
          await _deleteMicrosoftCalendarEvent(integration, eventId);
          break;
        default:
          throw Exception('Unsupported calendar type: ${integration.type}');
      }
    } catch (e) {
      throw Exception('Failed to delete calendar event: $e');
    }
  }

  /// Get calendar events
  Future<List<CalendarEvent>> getEvents(
    IntegrationConfig integration, {
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      switch (integration.type) {
        case IntegrationType.googleCalendar:
          return await _getGoogleCalendarEvents(integration, startTime: startTime, endTime: endTime);
        case IntegrationType.microsoftCalendar:
          return await _getMicrosoftCalendarEvents(integration, startTime: startTime, endTime: endTime);
        default:
          throw Exception('Unsupported calendar type: ${integration.type}');
      }
    } catch (e) {
      throw Exception('Failed to get calendar events: $e');
    }
  }

  // Google Calendar methods

  Future<bool> _testGoogleCalendarConnection(IntegrationConfig integration) async {
    try {
      final settings = CalendarIntegrationSettings.fromJson(integration.settings);
      final credentials = _createGoogleCredentials(settings);
      final client = await clientViaServiceAccount(credentials, [_googleCalendarScope]);
      
      final calendarApi = calendar.CalendarApi(client);
      await calendarApi.calendarList.list();
      
      client.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _createGoogleCalendarEvent(IntegrationConfig integration, CalendarEvent calendarEvent) async {
    final settings = CalendarIntegrationSettings.fromJson(integration.settings);
    final credentials = _createGoogleCredentials(settings);
    final client = await clientViaServiceAccount(credentials, [_googleCalendarScope]);
    
    try {
      final calendarApi = calendar.CalendarApi(client);
      
      final event = calendar.Event()
        ..summary = calendarEvent.title
        ..description = calendarEvent.description
        ..location = calendarEvent.location
        ..start = calendar.EventDateTime()
        ..start!.dateTime = calendarEvent.startTime
        ..end = calendar.EventDateTime()
        ..end!.dateTime = calendarEvent.endTime;

      if (calendarEvent.attendees.isNotEmpty) {
        event.attendees = calendarEvent.attendees
            .map((email) => calendar.EventAttendee()..email = email)
            .toList();
      }

      await calendarApi.events.insert(event, settings.calendarId);
    } finally {
      client.close();
    }
  }

  Future<void> _updateGoogleCalendarEvent(IntegrationConfig integration, CalendarEvent calendarEvent) async {
    final settings = CalendarIntegrationSettings.fromJson(integration.settings);
    final credentials = _createGoogleCredentials(settings);
    final client = await clientViaServiceAccount(credentials, [_googleCalendarScope]);
    
    try {
      final calendarApi = calendar.CalendarApi(client);
      
      final event = calendar.Event()
        ..summary = calendarEvent.title
        ..description = calendarEvent.description
        ..location = calendarEvent.location
        ..start = calendar.EventDateTime()
        ..start!.dateTime = calendarEvent.startTime
        ..end = calendar.EventDateTime()
        ..end!.dateTime = calendarEvent.endTime;

      if (calendarEvent.attendees.isNotEmpty) {
        event.attendees = calendarEvent.attendees
            .map((email) => calendar.EventAttendee()..email = email)
            .toList();
      }

      await calendarApi.events.update(event, settings.calendarId, calendarEvent.id);
    } finally {
      client.close();
    }
  }

  Future<void> _deleteGoogleCalendarEvent(IntegrationConfig integration, String eventId) async {
    final settings = CalendarIntegrationSettings.fromJson(integration.settings);
    final credentials = _createGoogleCredentials(settings);
    final client = await clientViaServiceAccount(credentials, [_googleCalendarScope]);
    
    try {
      final calendarApi = calendar.CalendarApi(client);
      await calendarApi.events.delete(settings.calendarId, eventId);
    } finally {
      client.close();
    }
  }

  Future<List<CalendarEvent>> _getGoogleCalendarEvents(
    IntegrationConfig integration, {
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final settings = CalendarIntegrationSettings.fromJson(integration.settings);
    final credentials = _createGoogleCredentials(settings);
    final client = await clientViaServiceAccount(credentials, [_googleCalendarScope]);
    
    try {
      final calendarApi = calendar.CalendarApi(client);
      final events = await calendarApi.events.list(
        settings.calendarId,
        timeMin: startTime,
        timeMax: endTime,
      );

      return events.items?.map((event) => _convertGoogleEventToCalendarEvent(event)).toList() ?? [];
    } finally {
      client.close();
    }
  }

  // Microsoft Calendar methods

  Future<bool> _testMicrosoftCalendarConnection(IntegrationConfig integration) async {
    try {
      final settings = CalendarIntegrationSettings.fromJson(integration.settings);
      
      final response = await http.get(
        Uri.parse('$_microsoftGraphUrl/me/calendars'),
        headers: {
          'Authorization': 'Bearer ${settings.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> _createMicrosoftCalendarEvent(IntegrationConfig integration, CalendarEvent calendarEvent) async {
    final settings = CalendarIntegrationSettings.fromJson(integration.settings);
    
    final eventData = {
      'subject': calendarEvent.title,
      'body': {
        'contentType': 'HTML',
        'content': calendarEvent.description,
      },
      'start': {
        'dateTime': calendarEvent.startTime.toIso8601String(),
        'timeZone': 'UTC',
      },
      'end': {
        'dateTime': calendarEvent.endTime.toIso8601String(),
        'timeZone': 'UTC',
      },
      'location': {
        'displayName': calendarEvent.location ?? '',
      },
      'attendees': calendarEvent.attendees.map((email) => {
        'emailAddress': {
          'address': email,
          'name': email,
        },
      }).toList(),
    };

    final response = await http.post(
      Uri.parse('$_microsoftGraphUrl/me/calendars/${settings.calendarId}/events'),
      headers: {
        'Authorization': 'Bearer ${settings.accessToken}',
        'Content-Type': 'application/json',
      },
      body: json.encode(eventData),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create Microsoft calendar event: ${response.statusCode}');
    }
  }

  Future<void> _updateMicrosoftCalendarEvent(IntegrationConfig integration, CalendarEvent calendarEvent) async {
    final settings = CalendarIntegrationSettings.fromJson(integration.settings);
    
    final eventData = {
      'subject': calendarEvent.title,
      'body': {
        'contentType': 'HTML',
        'content': calendarEvent.description,
      },
      'start': {
        'dateTime': calendarEvent.startTime.toIso8601String(),
        'timeZone': 'UTC',
      },
      'end': {
        'dateTime': calendarEvent.endTime.toIso8601String(),
        'timeZone': 'UTC',
      },
      'location': {
        'displayName': calendarEvent.location ?? '',
      },
      'attendees': calendarEvent.attendees.map((email) => {
        'emailAddress': {
          'address': email,
          'name': email,
        },
      }).toList(),
    };

    final response = await http.patch(
      Uri.parse('$_microsoftGraphUrl/me/calendars/${settings.calendarId}/events/${calendarEvent.id}'),
      headers: {
        'Authorization': 'Bearer ${settings.accessToken}',
        'Content-Type': 'application/json',
      },
      body: json.encode(eventData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update Microsoft calendar event: ${response.statusCode}');
    }
  }

  Future<void> _deleteMicrosoftCalendarEvent(IntegrationConfig integration, String eventId) async {
    final settings = CalendarIntegrationSettings.fromJson(integration.settings);
    
    final response = await http.delete(
      Uri.parse('$_microsoftGraphUrl/me/calendars/${settings.calendarId}/events/$eventId'),
      headers: {
        'Authorization': 'Bearer ${settings.accessToken}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete Microsoft calendar event: ${response.statusCode}');
    }
  }

  Future<List<CalendarEvent>> _getMicrosoftCalendarEvents(
    IntegrationConfig integration, {
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final settings = CalendarIntegrationSettings.fromJson(integration.settings);
    
    String url = '$_microsoftGraphUrl/me/calendars/${settings.calendarId}/events';
    final queryParams = <String>[];
    
    if (startTime != null) {
      queryParams.add('\$filter=start/dateTime ge \'${startTime.toIso8601String()}\'');
    }
    if (endTime != null) {
      final filterPrefix = queryParams.isNotEmpty ? ' and ' : '\$filter=';
      queryParams.add('${filterPrefix}end/dateTime le \'${endTime.toIso8601String()}\'');
    }
    
    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${settings.accessToken}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final events = data['value'] as List<dynamic>;
      return events.map((event) => _convertMicrosoftEventToCalendarEvent(event)).toList();
    } else {
      throw Exception('Failed to get Microsoft calendar events: ${response.statusCode}');
    }
  }

  // Helper methods

  ServiceAccountCredentials _createGoogleCredentials(CalendarIntegrationSettings settings) {
    // This would typically be loaded from a service account JSON file
    // For now, we'll create it from the settings
    return ServiceAccountCredentials.fromJson({
      'type': 'service_account',
      'private_key': settings.accessToken, // This should be the private key
      'client_email': 'service-account@project.iam.gserviceaccount.com',
      'client_id': 'client_id',
      'auth_uri': 'https://accounts.google.com/o/oauth2/auth',
      'token_uri': 'https://oauth2.googleapis.com/token',
    });
  }

  CalendarEvent _convertGoogleEventToCalendarEvent(calendar.Event event) {
    return CalendarEvent(
      id: event.id ?? '',
      title: event.summary ?? '',
      description: event.description ?? '',
      startTime: event.start?.dateTime ?? DateTime.now(),
      endTime: event.end?.dateTime ?? DateTime.now(),
      location: event.location,
      attendees: event.attendees?.map((attendee) => attendee.email ?? '').toList() ?? [],
      eventType: CalendarEventType.eventReminder,
      metadata: {},
      createdAt: event.created ?? DateTime.now(),
      updatedAt: event.updated ?? DateTime.now(),
    );
  }

  CalendarEvent _convertMicrosoftEventToCalendarEvent(Map<String, dynamic> event) {
    return CalendarEvent(
      id: event['id'] ?? '',
      title: event['subject'] ?? '',
      description: event['body']?['content'] ?? '',
      startTime: DateTime.parse(event['start']['dateTime']),
      endTime: DateTime.parse(event['end']['dateTime']),
      location: event['location']?['displayName'],
      attendees: (event['attendees'] as List<dynamic>?)
          ?.map((attendee) => attendee['emailAddress']['address'] as String)
          .toList() ?? [],
      eventType: CalendarEventType.eventReminder,
      metadata: {},
      createdAt: DateTime.parse(event['createdDateTime']),
      updatedAt: DateTime.parse(event['lastModifiedDateTime']),
    );
  }
}