import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../../../lib/ui/submissions/widgets/deadline_notification_banner.dart';
import '../../../../lib/services/deadline_service.dart';
import '../../../../lib/models/event.dart';
import '../../../../lib/models/enums.dart';

// Generate mocks
@GenerateMocks([DeadlineService])
import 'deadline_notification_banner_test.mocks.dart';

void main() {
  group('DeadlineNotificationBanner', () {
    late MockDeadlineService mockDeadlineService;

    setUp(() {
      mockDeadlineService = MockDeadlineService();
    });

    testWidgets('should not render when event has no deadline', (tester) async {
      // Arrange
      final event = _createTestEvent(submissionDeadline: null);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeadlineNotificationBanner(
              event: event,
              deadlineService: mockDeadlineService,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('should not render for normal status', (tester) async {
      // Arrange
      final event = _createTestEvent();
      
      when(mockDeadlineService.getDeadlineStatus(event))
          .thenReturn(DeadlineStatus.normal);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeadlineNotificationBanner(
              event: event,
              deadlineService: mockDeadlineService,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Critical: Deadline Very Soon!'), findsNothing);
    });

    testWidgets('should render critical deadline banner', (tester) async {
      // Arrange
      final event = _createTestEvent();
      
      when(mockDeadlineService.getDeadlineStatus(event))
          .thenReturn(DeadlineStatus.critical);
      when(mockDeadlineService.getTimeUntilDeadline(event))
          .thenReturn(const Duration(minutes: 10));
      when(mockDeadlineService.formatTimeRemaining(any))
          .thenReturn('10m remaining');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeadlineNotificationBanner(
              event: event,
              deadlineService: mockDeadlineService,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Critical: Deadline Very Soon!'), findsOneWidget);
      expect(find.text('The submission deadline for "Test Event" is in less than 15 minutes. Submit your entry now!'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    });

    testWidgets('should render urgent deadline banner', (tester) async {
      // Arrange
      final event = _createTestEvent();
      
      when(mockDeadlineService.getDeadlineStatus(event))
          .thenReturn(DeadlineStatus.urgent);
      when(mockDeadlineService.getTimeUntilDeadline(event))
          .thenReturn(const Duration(minutes: 30));
      when(mockDeadlineService.formatTimeRemaining(any))
          .thenReturn('30m remaining');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeadlineNotificationBanner(
              event: event,
              deadlineService: mockDeadlineService,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Urgent: Deadline Approaching'), findsOneWidget);
      expect(find.text('The submission deadline for "Test Event" is in less than 1 hour. Don\'t forget to submit!'), findsOneWidget);
      expect(find.byIcon(Icons.access_time_outlined), findsOneWidget);
    });

    testWidgets('should render warning deadline banner', (tester) async {
      // Arrange
      final event = _createTestEvent();
      
      when(mockDeadlineService.getDeadlineStatus(event))
          .thenReturn(DeadlineStatus.warning);
      when(mockDeadlineService.getTimeUntilDeadline(event))
          .thenReturn(const Duration(hours: 2));
      when(mockDeadlineService.formatTimeRemaining(any))
          .thenReturn('2h remaining');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeadlineNotificationBanner(
              event: event,
              deadlineService: mockDeadlineService,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Warning: Deadline Today'), findsOneWidget);
      expect(find.text('The submission deadline for "Test Event" is in less than 4 hours. Make sure to submit your entry.'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);
    });

    testWidgets('should render deadline passed banner', (tester) async {
      // Arrange
      final event = _createTestEvent();
      
      when(mockDeadlineService.getDeadlineStatus(event))
          .thenReturn(DeadlineStatus.passed);
      when(mockDeadlineService.getTimeUntilDeadline(event))
          .thenReturn(null);
      when(mockDeadlineService.formatTimeRemaining(null))
          .thenReturn('Deadline passed');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeadlineNotificationBanner(
              event: event,
              deadlineService: mockDeadlineService,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Deadline Passed'), findsOneWidget);
      expect(find.text('The submission deadline for "Test Event" has passed. No more submissions will be accepted.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should show submit button when callback provided and deadline not passed', (tester) async {
      // Arrange
      final event = _createTestEvent();
      bool submitPressed = false;
      
      when(mockDeadlineService.getDeadlineStatus(event))
          .thenReturn(DeadlineStatus.critical);
      when(mockDeadlineService.getTimeUntilDeadline(event))
          .thenReturn(const Duration(minutes: 10));
      when(mockDeadlineService.formatTimeRemaining(any))
          .thenReturn('10m remaining');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeadlineNotificationBanner(
              event: event,
              deadlineService: mockDeadlineService,
              onSubmitPressed: () {
                submitPressed = true;
              },
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Submit Now'), findsOneWidget);
      
      // Tap the submit button
      await tester.tap(find.text('Submit Now'));
      await tester.pump();
      
      expect(submitPressed, isTrue);
    });

    testWidgets('should not show submit button when deadline has passed', (tester) async {
      // Arrange
      final event = _createTestEvent();
      
      when(mockDeadlineService.getDeadlineStatus(event))
          .thenReturn(DeadlineStatus.passed);
      when(mockDeadlineService.getTimeUntilDeadline(event))
          .thenReturn(null);
      when(mockDeadlineService.formatTimeRemaining(null))
          .thenReturn('Deadline passed');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeadlineNotificationBanner(
              event: event,
              deadlineService: mockDeadlineService,
              onSubmitPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Submit Now'), findsNothing);
    });

    testWidgets('should show dismiss button when dismissible and callback provided', (tester) async {
      // Arrange
      final event = _createTestEvent();
      bool dismissed = false;
      
      when(mockDeadlineService.getDeadlineStatus(event))
          .thenReturn(DeadlineStatus.warning);
      when(mockDeadlineService.getTimeUntilDeadline(event))
          .thenReturn(const Duration(hours: 2));
      when(mockDeadlineService.formatTimeRemaining(any))
          .thenReturn('2h remaining');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeadlineNotificationBanner(
              event: event,
              deadlineService: mockDeadlineService,
              dismissible: true,
              onDismiss: () {
                dismissed = true;
              },
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.close), findsOneWidget);
      
      // Tap the dismiss button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      
      expect(dismissed, isTrue);
    });

    testWidgets('should not show dismiss button when not dismissible', (tester) async {
      // Arrange
      final event = _createTestEvent();
      
      when(mockDeadlineService.getDeadlineStatus(event))
          .thenReturn(DeadlineStatus.warning);
      when(mockDeadlineService.getTimeUntilDeadline(event))
          .thenReturn(const Duration(hours: 2));
      when(mockDeadlineService.formatTimeRemaining(any))
          .thenReturn('2h remaining');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeadlineNotificationBanner(
              event: event,
              deadlineService: mockDeadlineService,
              dismissible: false,
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('should include countdown widget in banner', (tester) async {
      // Arrange
      final event = _createTestEvent();
      
      when(mockDeadlineService.getDeadlineStatus(event))
          .thenReturn(DeadlineStatus.urgent);
      when(mockDeadlineService.getTimeUntilDeadline(event))
          .thenReturn(const Duration(minutes: 45));
      when(mockDeadlineService.formatTimeRemaining(any))
          .thenReturn('45m remaining');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeadlineNotificationBanner(
              event: event,
              deadlineService: mockDeadlineService,
            ),
          ),
        ),
      );

      // Assert
      // The countdown widget should be embedded in the banner
      expect(find.text('45m remaining'), findsOneWidget);
    });
  });
}

// Helper function to create test events
Event _createTestEvent({
  String? id,
  DateTime? submissionDeadline,
}) {
  final now = DateTime.now();
  return Event(
    id: id ?? 'test-event-id',
    groupId: 'test-group-id',
    title: 'Test Event',
    description: 'Test event description',
    eventType: EventType.competition,
    status: EventStatus.active,
    submissionDeadline: submissionDeadline ?? now.add(const Duration(hours: 1)),
    createdBy: 'test-member-id',
    createdAt: now,
    updatedAt: now,
  );
}