import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ngage/utils/responsive_utils.dart';

void main() {
  group('ResponsiveBreakpoints Tests', () {
    test('should have correct breakpoint values', () {
      expect(ResponsiveBreakpoints.mobile, equals(600));
      expect(ResponsiveBreakpoints.tablet, equals(900));
      expect(ResponsiveBreakpoints.desktop, equals(1200));
      expect(ResponsiveBreakpoints.largeDesktop, equals(1600));
    });
  });

  group('ResponsiveHelper Tests', () {
    testWidgets('should identify mobile screen size correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                final responsive = ResponsiveHelper(context);
                expect(responsive.screenSize, equals(ScreenSize.mobile));
                expect(responsive.isMobile, isTrue);
                expect(responsive.isTablet, isFalse);
                expect(responsive.isDesktop, isFalse);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('should identify tablet screen size correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(700, 1000)),
            child: Builder(
              builder: (context) {
                final responsive = ResponsiveHelper(context);
                expect(responsive.screenSize, equals(ScreenSize.tablet));
                expect(responsive.isMobile, isFalse);
                expect(responsive.isTablet, isTrue);
                expect(responsive.isDesktop, isFalse);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('should identify desktop screen size correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1000, 800)),
            child: Builder(
              builder: (context) {
                final responsive = ResponsiveHelper(context);
                expect(responsive.screenSize, equals(ScreenSize.desktop));
                expect(responsive.isMobile, isFalse);
                expect(responsive.isTablet, isFalse);
                expect(responsive.isDesktop, isTrue);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('should identify large desktop screen size correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1800, 1200)),
            child: Builder(
              builder: (context) {
                final responsive = ResponsiveHelper(context);
                expect(responsive.screenSize, equals(ScreenSize.largeDesktop));
                expect(responsive.isMobile, isFalse);
                expect(responsive.isTablet, isFalse);
                expect(responsive.isDesktop, isFalse);
                expect(responsive.isLargeDesktop, isTrue);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('should return correct responsive values', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                final responsive = ResponsiveHelper(context);
                final value = responsive.responsive<int>(
                  mobile: 1,
                  tablet: 2,
                  desktop: 3,
                  largeDesktop: 4,
                );
                expect(value, equals(1)); // Should return mobile value
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('should fallback to mobile when tablet not provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(700, 1000)),
            child: Builder(
              builder: (context) {
                final responsive = ResponsiveHelper(context);
                final value = responsive.responsive<int>(
                  mobile: 1,
                  desktop: 3,
                  largeDesktop: 4,
                );
                expect(value, equals(1)); // Should fallback to mobile
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('should return correct responsive padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                final responsive = ResponsiveHelper(context);
                final padding = responsive.responsivePadding;
                expect(padding, equals(const EdgeInsets.all(16.0)));
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('should return correct responsive font size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                final responsive = ResponsiveHelper(context);
                final fontSize = responsive.responsiveFontSize(
                  mobile: 14.0,
                  tablet: 16.0,
                  desktop: 18.0,
                );
                expect(fontSize, equals(14.0));
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('should return correct responsive grid columns', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1000, 800)),
            child: Builder(
              builder: (context) {
                final responsive = ResponsiveHelper(context);
                final columns = responsive.responsiveGridColumns;
                expect(columns, equals(3)); // Desktop should have 3 columns
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('should return correct responsive icon size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                final responsive = ResponsiveHelper(context);
                final iconSize = responsive.responsiveIconSize;
                expect(iconSize, equals(24.0));
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('should return correct responsive border radius', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                final responsive = ResponsiveHelper(context);
                final borderRadius = responsive.responsiveBorderRadius;
                expect(borderRadius, equals(BorderRadius.circular(8.0)));
                return Container();
              },
            ),
          ),
        ),
      );
    });
  });

  group('ResponsiveContext Extension Tests', () {
    testWidgets('should provide responsive helper through context extension', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                final responsive = context.responsive;
                expect(responsive, isA<ResponsiveHelper>());
                expect(responsive.isMobile, isTrue);
                return Container();
              },
            ),
          ),
        ),
      );
    });
  });

  group('ScreenSize Enum Tests', () {
    test('should have all screen size values', () {
      expect(ScreenSize.values.length, equals(4));
      expect(ScreenSize.values, contains(ScreenSize.mobile));
      expect(ScreenSize.values, contains(ScreenSize.tablet));
      expect(ScreenSize.values, contains(ScreenSize.desktop));
      expect(ScreenSize.values, contains(ScreenSize.largeDesktop));
    });
  });
}