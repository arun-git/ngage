import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ngage/ui/widgets/responsive_layout.dart';

void main() {
  group('ResponsiveLayout Tests', () {
    testWidgets('should display mobile layout on small screens', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(400, 800)),
            child: ResponsiveLayout(
              mobile: Text('Mobile'),
              tablet: Text('Tablet'),
              desktop: Text('Desktop'),
              child: Text('Default'),
            ),
          ),
        ),
      );

      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Tablet'), findsNothing);
      expect(find.text('Desktop'), findsNothing);
    });

    testWidgets('should display tablet layout on medium screens', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(700, 1000)),
            child: ResponsiveLayout(
              mobile: Text('Mobile'),
              tablet: Text('Tablet'),
              desktop: Text('Desktop'),
              child: Text('Default'),
            ),
          ),
        ),
      );

      expect(find.text('Tablet'), findsOneWidget);
      expect(find.text('Mobile'), findsNothing);
      expect(find.text('Desktop'), findsNothing);
    });

    testWidgets('should display desktop layout on large screens', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(1200, 800)),
            child: ResponsiveLayout(
              mobile: Text('Mobile'),
              tablet: Text('Tablet'),
              desktop: Text('Desktop'),
              child: Text('Default'),
            ),
          ),
        ),
      );

      expect(find.text('Desktop'), findsOneWidget);
      expect(find.text('Mobile'), findsNothing);
      expect(find.text('Tablet'), findsNothing);
    });

    testWidgets('should fallback to mobile when tablet not provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(700, 1000)),
            child: ResponsiveLayout(
              mobile: Text('Mobile'),
              desktop: Text('Desktop'),
              child: Text('Default'),
            ),
          ),
        ),
      );

      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Desktop'), findsNothing);
    });
  });

  group('ResponsiveScaffold Tests', () {
    final destinations = [
      const ResponsiveNavigationDestination(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      const ResponsiveNavigationDestination(
        icon: Icon(Icons.search),
        label: 'Search',
      ),
      const ResponsiveNavigationDestination(
        icon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];

    testWidgets('should show bottom navigation on mobile', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: ResponsiveScaffold(
              title: 'Test App',
              destinations: destinations,
              body: const Text('Body'),
            ),
          ),
        ),
      );

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('should show navigation rail on desktop', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1200, 800)),
            child: ResponsiveScaffold(
              title: 'Test App',
              destinations: destinations,
              body: const Text('Body'),
            ),
          ),
        ),
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
    });

    testWidgets('should handle navigation selection', (tester) async {
      int selectedIndex = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: StatefulBuilder(
              builder: (context, setState) => ResponsiveScaffold(
                title: 'Test App',
                destinations: destinations,
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                body: Text('Selected: $selectedIndex'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Selected: 0'), findsOneWidget);

      // Tap on second navigation item
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      expect(find.text('Selected: 1'), findsOneWidget);
    });
  });

  group('ResponsiveGrid Tests', () {
    testWidgets('should adapt column count based on screen size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: ResponsiveGrid(
              mobileColumns: 1,
              tabletColumns: 2,
              desktopColumns: 3,
              children: List.generate(6, (index) => Text('Item $index')),
            ),
          ),
        ),
      );

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, equals(1)); // Mobile should show 1 column
    });

    testWidgets('should show correct number of items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: ResponsiveGrid(
              children: List.generate(3, (index) => Text('Item $index')),
            ),
          ),
        ),
      );

      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });
  });

  group('ResponsiveCard Tests', () {
    testWidgets('should render card with content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(400, 800)),
            child: ResponsiveCard(
              child: Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('should handle tap events', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: ResponsiveCard(
              onTap: () => tapped = true,
              child: const Text('Tappable Card'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tappable Card'));
      expect(tapped, isTrue);
    });
  });

  group('ResponsiveDialog Tests', () {
    testWidgets('should display dialog with title and content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const ResponsiveDialog(
                      title: 'Test Dialog',
                      content: Text('Dialog Content'),
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Test Dialog'), findsOneWidget);
      expect(find.text('Dialog Content'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should close dialog when close button is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const ResponsiveDialog(
                      title: 'Test Dialog',
                      content: Text('Dialog Content'),
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Test Dialog'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Test Dialog'), findsNothing);
    });
  });

  group('ResponsiveForm Tests', () {
    testWidgets('should layout form fields with proper spacing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(400, 800)),
            child: Scaffold(
              body: ResponsiveForm(
                children: [
                  TextField(decoration: InputDecoration(labelText: 'Field 1')),
                  TextField(decoration: InputDecoration(labelText: 'Field 2')),
                  TextField(decoration: InputDecoration(labelText: 'Field 3')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Field 1'), findsOneWidget);
      expect(find.text('Field 2'), findsOneWidget);
      expect(find.text('Field 3'), findsOneWidget);
    });
  });
}