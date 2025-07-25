// Mocks generated by Mockito 5.4.4 from annotations
// in ngage/test/services/event_prerequisites_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;

import 'package:mockito/mockito.dart' as _i1;
import 'package:ngage/models/models.dart' as _i2;
import 'package:ngage/repositories/event_repository.dart' as _i3;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeEvent_0 extends _i1.SmartFake implements _i2.Event {
  _FakeEvent_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [EventRepository].
///
/// See the documentation for Mockito's code generation for more information.
class MockEventRepository extends _i1.Mock implements _i3.EventRepository {
  MockEventRepository() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.Future<void> createEvent(_i2.Event? event) => (super.noSuchMethod(
        Invocation.method(
          #createEvent,
          [event],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<_i2.Event?> getEventById(String? eventId) => (super.noSuchMethod(
        Invocation.method(
          #getEventById,
          [eventId],
        ),
        returnValue: _i4.Future<_i2.Event?>.value(),
      ) as _i4.Future<_i2.Event?>);

  @override
  _i4.Future<void> updateEvent(_i2.Event? event) => (super.noSuchMethod(
        Invocation.method(
          #updateEvent,
          [event],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<void> deleteEvent(String? eventId) => (super.noSuchMethod(
        Invocation.method(
          #deleteEvent,
          [eventId],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<List<_i2.Event>> getGroupEvents(String? groupId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getGroupEvents,
          [groupId],
        ),
        returnValue: _i4.Future<List<_i2.Event>>.value(<_i2.Event>[]),
      ) as _i4.Future<List<_i2.Event>>);

  @override
  _i4.Future<List<_i2.Event>> getEventsByStatus(
    String? groupId,
    _i2.EventStatus? status,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #getEventsByStatus,
          [
            groupId,
            status,
          ],
        ),
        returnValue: _i4.Future<List<_i2.Event>>.value(<_i2.Event>[]),
      ) as _i4.Future<List<_i2.Event>>);

  @override
  _i4.Future<List<_i2.Event>> getActiveEvents(String? groupId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getActiveEvents,
          [groupId],
        ),
        returnValue: _i4.Future<List<_i2.Event>>.value(<_i2.Event>[]),
      ) as _i4.Future<List<_i2.Event>>);

  @override
  _i4.Future<List<_i2.Event>> getAllActiveEvents() => (super.noSuchMethod(
        Invocation.method(
          #getAllActiveEvents,
          [],
        ),
        returnValue: _i4.Future<List<_i2.Event>>.value(<_i2.Event>[]),
      ) as _i4.Future<List<_i2.Event>>);

  @override
  _i4.Future<List<_i2.Event>> getScheduledEvents(String? groupId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getScheduledEvents,
          [groupId],
        ),
        returnValue: _i4.Future<List<_i2.Event>>.value(<_i2.Event>[]),
      ) as _i4.Future<List<_i2.Event>>);

  @override
  _i4.Future<List<_i2.Event>> getTeamEligibleEvents(
    String? groupId,
    String? teamId,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #getTeamEligibleEvents,
          [
            groupId,
            teamId,
          ],
        ),
        returnValue: _i4.Future<List<_i2.Event>>.value(<_i2.Event>[]),
      ) as _i4.Future<List<_i2.Event>>);

  @override
  _i4.Future<List<_i2.Event>> getEventsWithUpcomingDeadlines(
    String? groupId, {
    int? daysAhead = 7,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #getEventsWithUpcomingDeadlines,
          [groupId],
          {#daysAhead: daysAhead},
        ),
        returnValue: _i4.Future<List<_i2.Event>>.value(<_i2.Event>[]),
      ) as _i4.Future<List<_i2.Event>>);

  @override
  _i4.Stream<List<_i2.Event>> streamGroupEvents(String? groupId) =>
      (super.noSuchMethod(
        Invocation.method(
          #streamGroupEvents,
          [groupId],
        ),
        returnValue: _i4.Stream<List<_i2.Event>>.empty(),
      ) as _i4.Stream<List<_i2.Event>>);

  @override
  _i4.Stream<_i2.Event?> streamEvent(String? eventId) => (super.noSuchMethod(
        Invocation.method(
          #streamEvent,
          [eventId],
        ),
        returnValue: _i4.Stream<_i2.Event?>.empty(),
      ) as _i4.Stream<_i2.Event?>);

  @override
  _i4.Future<void> updateEventStatus(
    String? eventId,
    _i2.EventStatus? status,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #updateEventStatus,
          [
            eventId,
            status,
          ],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<void> updateEventSchedule(
    String? eventId, {
    DateTime? startTime,
    DateTime? endTime,
    DateTime? submissionDeadline,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #updateEventSchedule,
          [eventId],
          {
            #startTime: startTime,
            #endTime: endTime,
            #submissionDeadline: submissionDeadline,
          },
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<bool> eventExists(String? eventId) => (super.noSuchMethod(
        Invocation.method(
          #eventExists,
          [eventId],
        ),
        returnValue: _i4.Future<bool>.value(false),
      ) as _i4.Future<bool>);

  @override
  _i4.Future<int> getGroupEventsCount(String? groupId) => (super.noSuchMethod(
        Invocation.method(
          #getGroupEventsCount,
          [groupId],
        ),
        returnValue: _i4.Future<int>.value(0),
      ) as _i4.Future<int>);

  @override
  _i4.Future<List<_i2.Event>> searchEventsByTitle(
    String? groupId,
    String? searchTerm,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #searchEventsByTitle,
          [
            groupId,
            searchTerm,
          ],
        ),
        returnValue: _i4.Future<List<_i2.Event>>.value(<_i2.Event>[]),
      ) as _i4.Future<List<_i2.Event>>);

  @override
  _i4.Future<void> updateEventAccess(
    String? eventId, {
    List<String>? eligibleTeamIds,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #updateEventAccess,
          [eventId],
          {#eligibleTeamIds: eligibleTeamIds},
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<List<String>> getAllGroupTeamIds(String? groupId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getAllGroupTeamIds,
          [groupId],
        ),
        returnValue: _i4.Future<List<String>>.value(<String>[]),
      ) as _i4.Future<List<String>>);

  @override
  _i4.Future<List<String>> validateTeamsInGroup(
    String? groupId,
    List<String>? teamIds,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #validateTeamsInGroup,
          [
            groupId,
            teamIds,
          ],
        ),
        returnValue: _i4.Future<List<String>>.value(<String>[]),
      ) as _i4.Future<List<String>>);

  @override
  _i4.Future<bool> hasTeamCompletedEvent(
    String? eventId,
    String? teamId,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #hasTeamCompletedEvent,
          [
            eventId,
            teamId,
          ],
        ),
        returnValue: _i4.Future<bool>.value(false),
      ) as _i4.Future<bool>);

  @override
  _i4.Future<_i2.Event> update(_i2.Event? event) => (super.noSuchMethod(
        Invocation.method(
          #update,
          [event],
        ),
        returnValue: _i4.Future<_i2.Event>.value(_FakeEvent_0(
          this,
          Invocation.method(
            #update,
            [event],
          ),
        )),
      ) as _i4.Future<_i2.Event>);
}
