import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ngage/ui/widgets/platform_navigation.dart';

void main() {
  group('PlatformNavigation Tests', () {
    final navigationItems = [
      const NavigationItem(
        icon: Icon(Icons.home),
        label: 'Home',
        tooltip: 'Go to home',
      ),
      const NavigationItem(
        icon: Icon(Icons.search),
        label: 'Search',
        tooltip: 'Search items',
      ),
      const NavigationItem(
        icon: Icon(Icons.person),
        label: 'Profile',
        tooltip: 'View profile',
      ),
    ];

    testWidgets('should display mobile navigation on small screens', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: PlatformNavigation(
              items: navigationItems,
              selectedIndex: 0,
              onItemSelected: (_) {},
              body: const Text('Body Content'),
              title: 'Test App',
            ),
          ),
        ),
      );

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('Test App'), findsOneWidget);
      expect(find.text('Body Content'), findsOneWidget);
    });

    testWidgets('should display desktop navigation on large screens', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1200, 800)),
            child: PlatformNavigation(
              items: navigationItems,
              selectedIndex: 0,
              onItemSelected: (_) {},
              body: const Text('Body Content'),
              title: 'Test App',
            ),
          ),
        ),
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.text('Test App'), findsOneWidget);
      expect(find.text('Body Content'), findsOneWidget);
    });

    testWidgets('should handle navigation item selection', (tester) async {
      int selectedIndex = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: StatefulBuilder(
              builder: (context, setState) => PlatformNavigation(
                items: navigationItems,
                selectedIndex: selectedIndex,
                onItemSelected: (index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                body: Text('Selected: $selectedIndex'),
                title: 'Test App',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Selected: 0'), findsOneWidget);

      // Tap on search navigation item
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      expect(find.text('Selected: 1'), findsOneWidget);
    });

    testWidgets('should show drawer when more than 5 items on mobile', (tester) async {
      final manyItems = List.generate(7, (index) => NavigationItem(
        icon: const Icon(Icons.star),
        label: 'Item $index',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: PlatformNavigation(
              items: manyItems,
              selectedIndex: 0,
              onItemSelected: (_) {},
              body: const Text('Body Content'),
              title: 'Test App',
            ),
          ),
        ),
      );

      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(Drawer), findsOneWidget);
    });

    testWidgets('should handle keyboard shortcuts', (tester) async {
      int selectedIndex = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: StatefulBuilder(
              builder: (context, setState) => PlatformNavigation(
                items: navigationItems,
                selectedIndex: selectedIndex,
                onItemSelected: (index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                body: Text('Selected: $selectedIndex'),
                title: 'Test App',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Selected: 0'), findsOneWidget);

      // Simulate pressing '2' key to navigate to second item (index 1)
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.pumpAndSettle();

      expect(find.text('Selected: 1'), findsOneWidget);
    });

    testWidgets('should display floating action button when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: PlatformNavigation(
              items: navigationItems,
              selectedIndex: 0,
              onItemSelected: (_) {},
              body: const Text('Body Content'),
              title: 'Test App',
              floatingActionButton: FloatingActionButton(
                onPressed: () {},
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should display app bar actions when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: PlatformNavigation(
              items: navigationItems,
              selectedIndex: 0,
              onItemSelected: (_) {},
              body: const Text('Body Content'),
              title: 'Test App',
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });

  group('NavigationItem Tests', () {
    testWidgets('should create navigation item with required properties', (tester) async {
      const item = NavigationItem(
        icon: Icon(Icons.home),
        label: 'Home',
        tooltip: 'Go to home',
      );

      expect(item.icon, isA<Icon>());
      expect(item.label, equals('Home'));
      expect(item.tooltip, equals('Go to home'));
    });
  });

  group('PlatformAppBar Tests', () {
    testWidgets('should display app bar with title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: PlatformAppBar(
              title: 'Test Title',
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display actions when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: PlatformAppBar(
              title: 'Test Title',
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('should handle custom leading widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: PlatformAppBar(
              title: 'Test Title',
              leading: Icon(Icons.menu),
              automaticallyImplyLeading: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.menu), findsOneWidget);
    });
  });

  group('PlatformFloatingActionButton Tests', () {
    testWidgets('should display regular FAB on mobile', (tester) async {
      bool pressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Scaffold(
              floatingActionButton: PlatformFloatingActionButton(
                onPressed: () => pressed = true,
                tooltip: 'Add Item',
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      expect(pressed, isTrue);
    });

    testWidgets('should display extended FAB on desktop', (tester) async {
      bool pressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1200, 800)),
            child: Scaffold(
              floatingActionButton: PlatformFloatingActionButton(
                onPressed: () => pressed = true,
                tooltip: 'Add Item',
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Add Item'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      expect(pressed, isTrue);
    });
  });
}