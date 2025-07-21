import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ngage/utils/accessibility_utils.dart';

void main() {
  group('AccessibilityUtils Tests', () {
    testWidgets('should create semantic label correctly', (tester) async {
      const label = AccessibilityUtils.createSemanticLabel(
        label: 'Button',
        hint: 'Tap to continue',
        value: 'enabled',
        enabled: true,
        selected: false,
      );

      expect(label, equals('Button, enabled, Tap to continue'));
    });

    testWidgets('should create semantic label for selected item', (tester) async {
      const label = AccessibilityUtils.createSemanticLabel(
        label: 'Option',
        selected: true,
        enabled: true,
      );

      expect(label, equals('Option, selected'));
    });

    testWidgets('should create semantic label for disabled item', (tester) async {
      const label = AccessibilityUtils.createSemanticLabel(
        label: 'Button',
        enabled: false,
      );

      expect(label, equals('Button, disabled'));
    });

    testWidgets('should create accessible button with proper semantics', (tester) async {
      bool pressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibilityUtils.createAccessibleButton(
              child: const Text('Test Button'),
              onPressed: () => pressed = true,
              semanticLabel: 'Test button for accessibility',
              tooltip: 'This is a test button',
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(Tooltip), findsOneWidget);

      await tester.tap(find.text('Test Button'));
      expect(pressed, isTrue);
    });

    testWidgets('should create accessible text field with proper semantics', (tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibilityUtils.createAccessibleTextField(
              controller: controller,
              labelText: 'Email',
              hintText: 'Enter your email',
              semanticLabel: 'Email input field',
            ),
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'test@example.com');
      expect(controller.text, equals('test@example.com'));
    });

    testWidgets('should create accessible list tile with proper semantics', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibilityUtils.createAccessibleListTile(
              title: const Text('List Item'),
              subtitle: const Text('Subtitle'),
              leading: const Icon(Icons.person),
              onTap: () => tapped = true,
              semanticLabel: 'Person list item',
              selected: false,
            ),
          ),
        ),
      );

      expect(find.text('List Item'), findsOneWidget);
      expect(find.text('Subtitle'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);

      await tester.tap(find.text('List Item'));
      expect(tapped, isTrue);
    });

    testWidgets('should create accessible card with proper semantics', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibilityUtils.createAccessibleCard(
              child: const Text('Card Content'),
              onTap: () => tapped = true,
              semanticLabel: 'Interactive card',
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);

      await tester.tap(find.text('Card Content'));
      expect(tapped, isTrue);
    });

    testWidgets('should create accessible navigation rail', (tester) async {
      int selectedIndex = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibilityUtils.createAccessibleNavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => selectedIndex = index,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.search),
                  label: Text('Search'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets('should create accessible bottom navigation bar', (tester) async {
      int currentIndex = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AccessibilityUtils.createAccessibleBottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) => currentIndex = index,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Search',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
    });
  });

  group('KeyboardNavigationMixin Tests', () {
    testWidgets('should handle focus properly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestWidgetWithKeyboardNavigation(),
          ),
        ),
      );

      final testWidget = tester.state<_TestWidgetWithKeyboardNavigationState>(
        find.byType(_TestWidgetWithKeyboardNavigation),
      );

      expect(testWidget.hasFocus, isFalse);
      
      testWidget.requestFocus();
      await tester.pumpAndSettle();
      
      expect(testWidget.hasFocus, isTrue);
    });
  });

  group('DismissAction Tests', () {
    testWidgets('should execute dismiss callback', (tester) async {
      bool dismissed = false;
      final action = DismissAction(() => dismissed = true);
      
      action.invoke(const DismissIntent());
      
      expect(dismissed, isTrue);
    });
  });

  group('Common Shortcuts Tests', () {
    testWidgets('should include common keyboard shortcuts', (tester) async {
      final shortcuts = AccessibilityUtils.getCommonShortcuts();
      
      expect(shortcuts.containsKey(const SingleActivator(LogicalKeyboardKey.escape)), isTrue);
      expect(shortcuts.containsKey(const SingleActivator(LogicalKeyboardKey.enter)), isTrue);
      expect(shortcuts.containsKey(const SingleActivator(LogicalKeyboardKey.space)), isTrue);
      expect(shortcuts.containsKey(const SingleActivator(LogicalKeyboardKey.tab)), isTrue);
      expect(shortcuts.containsKey(const SingleActivator(LogicalKeyboardKey.tab, shift: true)), isTrue);
      expect(shortcuts.containsKey(const SingleActivator(LogicalKeyboardKey.arrowDown)), isTrue);
      expect(shortcuts.containsKey(const SingleActivator(LogicalKeyboardKey.arrowUp)), isTrue);
      expect(shortcuts.containsKey(const SingleActivator(LogicalKeyboardKey.arrowLeft)), isTrue);
      expect(shortcuts.containsKey(const SingleActivator(LogicalKeyboardKey.arrowRight)), isTrue);
    });
  });
}

class _TestWidgetWithKeyboardNavigation extends StatefulWidget {
  @override
  State<_TestWidgetWithKeyboardNavigation> createState() => _TestWidgetWithKeyboardNavigationState();
}

class _TestWidgetWithKeyboardNavigationState extends State<_TestWidgetWithKeyboardNavigation> 
    with KeyboardNavigationMixin {
  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      child: Container(
        width: 100,
        height: 100,
        color: hasFocus ? Colors.blue : Colors.grey,
        child: const Text('Test Widget'),
      ),
    );
  }
}