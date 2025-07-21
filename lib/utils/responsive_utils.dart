import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Responsive breakpoints for different screen sizes
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double largeDesktop = 1600;
}

/// Platform detection utilities
class PlatformUtils {
  static bool get isMobile => defaultTargetPlatform == TargetPlatform.android || 
                             defaultTargetPlatform == TargetPlatform.iOS;
  
  static bool get isDesktop => defaultTargetPlatform == TargetPlatform.windows ||
                              defaultTargetPlatform == TargetPlatform.macOS ||
                              defaultTargetPlatform == TargetPlatform.linux;
  
  static bool get isWeb => kIsWeb;
  
  static bool get isTouchDevice => isMobile || (isWeb && _isTouchWeb());
  
  static bool _isTouchWeb() {
    // Simple heuristic for touch devices on web
    return MediaQueryData.fromView(WidgetsBinding.instance.platformDispatcher.views.first).size.width < ResponsiveBreakpoints.tablet;
  }
}

/// Screen size categories
enum ScreenSize { mobile, tablet, desktop, largeDesktop }

/// Responsive helper class for layout decisions
class ResponsiveHelper {
  final BuildContext context;
  
  ResponsiveHelper(this.context);
  
  /// Get current screen width
  double get screenWidth => MediaQuery.of(context).size.width;
  
  /// Get current screen height
  double get screenHeight => MediaQuery.of(context).size.height;
  
  /// Determine current screen size category
  ScreenSize get screenSize {
    if (screenWidth < ResponsiveBreakpoints.mobile) {
      return ScreenSize.mobile;
    } else if (screenWidth < ResponsiveBreakpoints.tablet) {
      return ScreenSize.tablet;
    } else if (screenWidth < ResponsiveBreakpoints.largeDesktop) {
      return ScreenSize.desktop;
    } else {
      return ScreenSize.largeDesktop;
    }
  }
  
  /// Check if current screen is mobile
  bool get isMobile => screenSize == ScreenSize.mobile;
  
  /// Check if current screen is tablet
  bool get isTablet => screenSize == ScreenSize.tablet;
  
  /// Check if current screen is desktop
  bool get isDesktop => screenSize == ScreenSize.desktop || screenSize == ScreenSize.largeDesktop;
  
  /// Check if current screen is large desktop
  bool get isLargeDesktop => screenSize == ScreenSize.largeDesktop;
  
  /// Get responsive value based on screen size
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    switch (screenSize) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenSize.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }
  
  /// Get responsive padding
  EdgeInsets get responsivePadding {
    return EdgeInsets.all(responsive(
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
      largeDesktop: 40.0,
    ));
  }
  
  /// Get responsive margin
  EdgeInsets get responsiveMargin {
    return EdgeInsets.all(responsive(
      mobile: 8.0,
      tablet: 12.0,
      desktop: 16.0,
      largeDesktop: 20.0,
    ));
  }
  
  /// Get responsive font size
  double responsiveFontSize({
    required double mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    return responsive(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }
  
  /// Get responsive icon size
  double get responsiveIconSize {
    return responsive(
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
      largeDesktop: 36.0,
    );
  }
  
  /// Get responsive card elevation
  double get responsiveCardElevation {
    return responsive(
      mobile: 2.0,
      tablet: 4.0,
      desktop: 6.0,
      largeDesktop: 8.0,
    );
  }
  
  /// Get responsive border radius
  BorderRadius get responsiveBorderRadius {
    return BorderRadius.circular(responsive(
      mobile: 8.0,
      tablet: 12.0,
      desktop: 16.0,
      largeDesktop: 20.0,
    ));
  }
  
  /// Get responsive grid column count
  int get responsiveGridColumns {
    return responsive(
      mobile: 1,
      tablet: 2,
      desktop: 3,
      largeDesktop: 4,
    );
  }
  
  /// Get responsive list tile height
  double get responsiveListTileHeight {
    return responsive(
      mobile: 72.0,
      tablet: 80.0,
      desktop: 88.0,
      largeDesktop: 96.0,
    );
  }
}

/// Extension on BuildContext for easy access to responsive helper
extension ResponsiveContext on BuildContext {
  ResponsiveHelper get responsive => ResponsiveHelper(this);
}