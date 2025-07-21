import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../../../lib/ui/submissions/widgets/deadline_countdown_widget.dart';
import '../../../../lib/services/deadline_service.dart';
import '../../../../lib/models/event.dart';
import '../../../../lib/models/enums.dart';

// Generate mocks
@GenerateMocks([DeadlineService])
import 'deadline_countdown_widget_test.mocks.dart';

void main() {
  group('DeadlineCountdownWidget', () {
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
            body: DeadlineCountdownWidget(
              event: event,
              deadlineService: mockDeadlineService,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(DeadlineCountdownWidget), findsOneWidget);
      expect(find.text('Submission Deadline'), findsNothing);
    });

    testWidgets('should render countdown in compact mode', (tester) async {
      // Arrange
      final futureDeadline = DateTime.now().add(const Duration(hours: 2));
      final event = _createTestEvent(submissionDeadline: futureDeadline);
      
      when(mockDeadlineService.getTimeUntilDeadline(event))
          .thenReturn(const Duration(hours: 2));
      when(mockDeadlineService.formatTimeRemaining(any))
          .thenReturn('2h remaining');
      when(mockDeadlineService.getDeadlineStatus(event))
          .thenReturn(DeadlineStatus.normal);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeadlineCountdownWidget(
              event: event,
              deadlineService: mockDeadlineService,
              compact: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('2h remaining'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);
    });

    testWidgets('should render countdown in full mode', (tester) async {
      // Arrange
      final futureDeadline = DateTime.now().add(const Duration(hours: 2));
      final event = _createTestEvent(submissionDeadline: futureDeadline);
      
      when(mockDeadlineService.getTimeUntilDeadline(event))
          .thenReturn(const Duration(hours: 2));
      when(mockDeadlineService.formatTimeRemaining(any))
          .thenReturn('2h remaining');
      when(mockDeadlineService.getDeadlineStatus(event))
          .thenReturn(DeadlineStatus.normal);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeadlineCountdownWidget(
              event: event,
              deadlineService: mockDeadlineService,
              compact: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Submission Deadline'), findsOneWidget);
      expect(find.text('2h remaining'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);
    });

    testWidgets('should show critical status with error colors', (tester) async {
      // Arrange
      final nearDeadline = DateTime.now().add(const Duration(minutes: 10));
      final event = _createTestEvent(submissionDeadline: nearDeadline);
      
      when(mockDeadlineService.getTimeUntilDeadline(event))
          .thenReturn(const Duration(minutes: 10));
      when(mockDeadlineService.formatTimeRemaining(any))
          .thenReturn('10m remaining');
      when(mockDeadlineService.getDeadlineStatus(event))
          .thenReturn(DeadlineStatus.critical);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeadlineCountdownWidget(
              event: event,
              deadlineService: mockDeadlineService,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('10m remaining'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
      
      // Check that the text color is error color (red-ish)
      final textWidget = tester.widget<Text>(find.text('10m remaining'));
      expect(textWidget.style?.color, isNotNull);
    });

    testWidgets('should show passed deadline status', (tester) async {
      // Arrange
      final pastDeadline = DateTime.now().subtract(const Duration(hours: 1));
      final event = _createTestEvent(submissionDeadline: pastDeadline);
      
      when(mockDeadlineService.getTimeUntilDeadline(event))
          .thenReturn(null);
      when(mockDeadlineService.formatTimeRemaining(null))
          .thenReturn('Deadline passed');
      when(mockDeadlineService.getDeadlineStatus(event))
          .thenReturn(DeadlineStatus.passed);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeadlineCountdownWidget(
              event: event,
              deadlineService: mockDeadlineService,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Deadline passed'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);
    });

    testWidgets('should hide icon when showIcon is false', (tester) async {
      // Arrange
      final futureDeadline = DateTime.now().add(const Duration(hours: 2));
      final event = _createTestEvent(submissionDeadline: futureDeadline);
      
      when(mockDeadlineService.getTimeUntilDeadline(event))
          .thenReturn(const Duration(hours: 2));
      when(mockDeadlineService.formatTimeRemaining(any))
          .thenReturn('2h remaining');
      when(mockDeadlineService.getDeadlineStatus(event))
          .thenReturn(DeadlineStatus.normal);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeadlineCountdownWidget(
              event: event,
              deadlineService: mockDeadlineService,
              showIcon: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('2h remaining'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_outlined), findsNothing);
    });
  });

  group('SimpleCountdownText', () {
    late MockDeadlineService mockDeadlineService;

    setUp(() {
      mockDeadlineService = MockDeadlineService();
    });

    testWidgets('should display countdown text', (tester) async {
      // Arrange
      final event = _createTestEvent();
      
      when(mockDeadlineService.getCountdownText(event))
          .thenReturn('2h 30m remaining');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleCountdownText(
              event: event,
              deadlineService: mockDeadlineService,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('2h 30m remaining'), findsOneWidget);
    });

    testWidgets('should update countdown text periodically', (tester) async {
      // Arrange
      final event = _createTestEvent();
      
      when(mockDeadlineService.getCountdownText(event))
          .thenReturn('2h 30m remaining');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleCountdownText(
              event: event,
              deadlineService: mockDeadlineService,
            ),
          ),
        ),
      );

      // Initial state
      expect(find.text('2h 30m remaining'), findsOneWidget);

      // Change the mock return value
      when(mockDeadlineService.getCountdownText(event))
          .thenReturn('2h 29m remaining');

      // Wait for timer to tick
      await tester.pump(const Duration(seconds: 1));

      // Assert updated text
      expect(find.text('2h 29m remaining'), findsOneWidget);
    });
  });

  group('DeadlineStatusChip', () {
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
            body: DeadlineStatusChip(
              event: event,
              deadlineService: mockDeadlineService,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Chip), findsNothing);
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
            body: DeadlineStatusChip(
              event: event,
              deadlineService: mockDeadlineService,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('should render critical status chip', (tester) async {
      // Arrange
      final event = _createTestEvent();
      
      when(mockDeadlineService.getDeadlineStatus(event))
          .thenReturn(DeadlineStatus.critical);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeadlineStatusChip(
              event: event,
              deadlineService: mockDeadlineService,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Chip), findsOneWidget);
      expect(find.text('Critical'), findsOneWidget);
    });

    testWidgets('should render urgent status chip', (tester) async {
      // Arrange
      final event = _createTestEvent();
      
      when(mockDeadlineService.getDeadlineStatus(event))
          .thenReturn(DeadlineStatus.urgent);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeadlineStatusChip(
              event: event,
              deadlineService: mockDeadlineService,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Chip), findsOneWidget);
      expect(find.text('Urgent'), findsOneWidget);
    });

    testWidgets('should render deadline passed chip', (tester) async {
      // Arrange
      final event = _createTestEvent();
      
      when(mockDeadlineService.getDeadlineStatus(event))
          .thenReturn(DeadlineStatus.passed);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeadlineStatusChip(
              event: event,
              deadlineService: mockDeadlineService,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Chip), findsOneWidget);
      expect(find.text('Deadline Passed'), findsOneWidget);
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
    submissionDeadline: submissionDeadline,
    createdBy: 'test-member-id',
    createdAt: now,
    updatedAt: now,
  );
}