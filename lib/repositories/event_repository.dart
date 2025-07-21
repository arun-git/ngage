import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

/// Repository for Event data operations
/// 
/// Handles all Firebase Firestore operations for events including
/// CRUD operations, queries, and real-time updates.
class EventRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'events';

  EventRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get events collection reference
  CollectionReference get _eventsCollection => _firestore.collection(_collection);

  /// Create a new event
  Future<void> createEvent(Event event) async {
    try {
      await _eventsCollection.doc(event.id).set(event.toJson());
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  /// Get event by ID
  Future<Event?> getEventById(String eventId) async {
    try {
      final doc = await _eventsCollection.doc(eventId).get();
      if (!doc.exists) return null;
      
      return Event.fromJson({
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      });
    } catch (e) {
      throw Exception('Failed to get event: $e');
    }
  }

  /// Update an existing event
  Future<void> updateEvent(Event event) async {
    try {
      final data = event.toJson();
      data.remove('id'); // Remove ID from update data
      data['updatedAt'] = DateTime.now().toIso8601String();
      
      await _eventsCollection.doc(event.id).update(data);
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _eventsCollection.doc(eventId).delete();
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  /// Get all events for a group
  Future<List<Event>> getGroupEvents(String groupId) async {
    try {
      final query = await _eventsCollection
          .where('groupId', isEqualTo: groupId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) {
        return Event.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get group events: $e');
    }
  }

  /// Get events by status
  Future<List<Event>> getEventsByStatus(String groupId, EventStatus status) async {
    try {
      final query = await _eventsCollection
          .where('groupId', isEqualTo: groupId)
          .where('status', isEqualTo: status.value)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) {
        return Event.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get events by status: $e');
    }
  }

  /// Get active events for a group
  Future<List<Event>> getActiveEvents(String groupId) async {
    return getEventsByStatus(groupId, EventStatus.active);
  }

  /// Get all active events across all groups (for deadline monitoring)
  Future<List<Event>> getAllActiveEvents() async {
    try {
      final query = await _eventsCollection
          .where('status', isEqualTo: EventStatus.active.value)
          .get();

      return query.docs.map((doc) {
        return Event.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get all active events: $e');
    }
  }

  /// Get scheduled events for a group
  Future<List<Event>> getScheduledEvents(String groupId) async {
    return getEventsByStatus(groupId, EventStatus.scheduled);
  }

  /// Get events that a team is eligible for
  Future<List<Event>> getTeamEligibleEvents(String groupId, String teamId) async {
    try {
      // Get all events for the group
      final allEvents = await getGroupEvents(groupId);
      
      // Filter for events the team is eligible for
      return allEvents.where((event) => event.isTeamEligible(teamId)).toList();
    } catch (e) {
      throw Exception('Failed to get team eligible events: $e');
    }
  }

  /// Get events with upcoming deadlines
  Future<List<Event>> getEventsWithUpcomingDeadlines(String groupId, {int daysAhead = 7}) async {
    try {
      final now = DateTime.now();
      final futureDate = now.add(Duration(days: daysAhead));
      
      final query = await _eventsCollection
          .where('groupId', isEqualTo: groupId)
          .where('status', isEqualTo: EventStatus.active.value)
          .where('submissionDeadline', isGreaterThan: now.toIso8601String())
          .where('submissionDeadline', isLessThan: futureDate.toIso8601String())
          .orderBy('submissionDeadline')
          .get();

      return query.docs.map((doc) {
        return Event.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get events with upcoming deadlines: $e');
    }
  }

  /// Stream events for real-time updates
  Stream<List<Event>> streamGroupEvents(String groupId) {
    try {
      return _eventsCollection
          .where('groupId', isEqualTo: groupId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Event.fromJson({
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          });
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to stream group events: $e');
    }
  }

  /// Stream a single event for real-time updates
  Stream<Event?> streamEvent(String eventId) {
    try {
      return _eventsCollection.doc(eventId).snapshots().map((doc) {
        if (!doc.exists) return null;
        
        return Event.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      });
    } catch (e) {
      throw Exception('Failed to stream event: $e');
    }
  }

  /// Update event status
  Future<void> updateEventStatus(String eventId, EventStatus status) async {
    try {
      await _eventsCollection.doc(eventId).update({
        'status': status.value,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update event status: $e');
    }
  }

  /// Update event scheduling
  Future<void> updateEventSchedule(
    String eventId, {
    DateTime? startTime,
    DateTime? endTime,
    DateTime? submissionDeadline,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (startTime != null) {
        updates['startTime'] = startTime.toIso8601String();
      }
      if (endTime != null) {
        updates['endTime'] = endTime.toIso8601String();
      }
      if (submissionDeadline != null) {
        updates['submissionDeadline'] = submissionDeadline.toIso8601String();
      }

      await _eventsCollection.doc(eventId).update(updates);
    } catch (e) {
      throw Exception('Failed to update event schedule: $e');
    }
  }

  /// Check if event exists
  Future<bool> eventExists(String eventId) async {
    try {
      final doc = await _eventsCollection.doc(eventId).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check if event exists: $e');
    }
  }

  /// Get events count for a group
  Future<int> getGroupEventsCount(String groupId) async {
    try {
      final query = await _eventsCollection
          .where('groupId', isEqualTo: groupId)
          .count()
          .get();
      
      return query.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get group events count: $e');
    }
  }

  /// Search events by title
  Future<List<Event>> searchEventsByTitle(String groupId, String searchTerm) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation that gets all events and filters client-side
      // For production, consider using Algolia or similar search service
      
      final allEvents = await getGroupEvents(groupId);
      final searchTermLower = searchTerm.toLowerCase();
      
      return allEvents.where((event) {
        return event.title.toLowerCase().contains(searchTermLower) ||
               event.description.toLowerCase().contains(searchTermLower);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search events: $e');
    }
  }

  /// Update event access control
  Future<void> updateEventAccess(String eventId, {
    List<String>? eligibleTeamIds,
  }) async {
    try {
      final updates = <String, dynamic>{
        'eligibleTeamIds': eligibleTeamIds,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _eventsCollection.doc(eventId).update(updates);
    } catch (e) {
      throw Exception('Failed to update event access: $e');
    }
  }

  /// Get all team IDs for a group
  Future<List<String>> getAllGroupTeamIds(String groupId) async {
    try {
      final query = await _firestore
          .collection('teams')
          .where('groupId', isEqualTo: groupId)
          .where('isActive', isEqualTo: true)
          .get();
      
      return query.docs.map((doc) => doc.id).toList();
    } catch (e) {
      throw Exception('Failed to get group team IDs: $e');
    }
  }

  /// Validate that teams exist in a group
  Future<List<String>> validateTeamsInGroup(String groupId, List<String> teamIds) async {
    try {
      if (teamIds.isEmpty) return [];
      
      final validTeams = <String>[];
      
      // Batch validate teams (Firestore 'in' query limit is 10)
      for (int i = 0; i < teamIds.length; i += 10) {
        final batch = teamIds.skip(i).take(10).toList();
        final query = await _firestore
            .collection('teams')
            .where('groupId', isEqualTo: groupId)
            .where(FieldPath.documentId, whereIn: batch)
            .where('isActive', isEqualTo: true)
            .get();
        
        validTeams.addAll(query.docs.map((doc) => doc.id));
      }
      
      return validTeams;
    } catch (e) {
      throw Exception('Failed to validate teams in group: $e');
    }
  }

  /// Check if a team has completed an event (check submissions)
  Future<bool> hasTeamCompletedEvent(String eventId, String teamId) async {
    try {
      final query = await _firestore
          .collection('submissions')
          .where('eventId', isEqualTo: eventId)
          .where('teamId', isEqualTo: teamId)
          .where('status', whereIn: ['submitted', 'approved'])
          .limit(1)
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check team completion: $e');
    }
  }

  /// Update an event (generic method)
  Future<Event> update(Event event) async {
    try {
      final updatedEvent = event.copyWith(updatedAt: DateTime.now());
      await updateEvent(updatedEvent);
      return updatedEvent;
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }
}