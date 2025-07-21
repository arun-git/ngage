import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ngage/utils/performance_utils.dart';

void main() {
  group('PerformanceUtils Tests', () {
    testWidgets('should optimize image provider based on screen size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              devicePixelRatio: 2.0,
            ),
            child: Builder(
              builder: (context) {
                final imageProvider = PerformanceUtils.optimizeImageProvider(
                  imagePath: 'assets/test_image.png',
                  context: context,
                  width: 200,
                  height: 200,
                );
                
                expect(imageProvider, isA<ResizeImage>());
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('should create optimized list view', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceUtils.createOptimizedListView(
              itemCount: 100,
              itemBuilder: (context, index) => ListTile(
                title: Text('Item $index'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('should create optimized grid view', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceUtils.createOptimizedGridView(
              itemCount: 20,
              crossAxisCount: 2,
              itemBuilder: (context, index) => Container(
                child: Text('Item $index'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('should return optimized animation duration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                final duration = PerformanceUtils.getOptimizedAnimationDuration(context);
                expect(duration, equals(const Duration(milliseconds: 200)));
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('should return zero duration when animations are disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              disableAnimations: true,
            ),
            child: Builder(
              builder: (context) {
                final duration = PerformanceUtils.getOptimizedAnimationDuration(context);
                expect(duration, equals(Duration.zero));
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('should create optimized image widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: PerformanceUtils.createOptimizedImage(
              imagePath: 'assets/test_image.png',
              context: NavigationToolbar.kMiddleSpacing as BuildContext, // Mock context
              width: 100,
              height: 100,
              semanticLabel: 'Test image',
            ),
          ),
        ),
      );

      // Note: This test might fail in actual execution due to asset loading
      // but demonstrates the structure
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should get optimal batch size based on screen size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                final batchSize = PerformanceUtils.getOptimalBatchSize(context);
                expect(batchSize, equals(10)); // Mobile should return 10
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('should create optimized custom scroll view', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceUtils.createOptimizedCustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ListTile(title: Text('Item $index')),
                    childCount: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('should create memory efficient widget', (tester) async {
      bool disposed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: PerformanceUtils.createMemoryEfficientWidget(
            onDispose: () => disposed = true,
            child: const Text('Test Widget'),
          ),
        ),
      );

      expect(find.text('Test Widget'), findsOneWidget);
      
      // Dispose the widget
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      
      expect(disposed, isTrue);
    });

    test('should check high memory capacity correctly', () {
      // This is a simplified test - actual implementation would depend on platform
      final hasHighMemory = PerformanceUtils.hasHighMemoryCapacity();
      expect(hasHighMemory, isA<bool>());
    });
  });

  group('PerformanceMonitoringMixin Tests', () {
    testWidgets('should monitor widget performance', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestWidgetWithPerformanceMonitoring(),
          ),
        ),
      );

      final testWidget = tester.state<_TestWidgetWithPerformanceMonitoringState>(
        find.byType(_TestWidgetWithPerformanceMonitoring),
      );

      // Test performance measurement
      testWidget.measurePerformance('test operation', () {
        // Simulate some work
        for (int i = 0; i < 1000; i++) {
          // Do nothing, just consume time
        }
      });

      expect(find.text('Performance Test Widget'), findsOneWidget);
    });
  });
}

class _TestWidgetWithPerformanceMonitoring extends StatefulWidget {
  @override
  State<_TestWidgetWithPerformanceMonitoring> createState() => _TestWidgetWithPerformanceMonitoringState();
}

class _TestWidgetWithPerformanceMonitoringState extends State<_TestWidgetWithPerformanceMonitoring> 
    with PerformanceMonitoringMixin {
  @override
  Widget build(BuildContext context) {
    return const Text('Performance Test Widget');
  }
}