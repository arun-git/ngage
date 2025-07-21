import 'package:flutter/material.dart';

/// Responsive theme extensions for consistent styling across platforms
class ResponsiveTheme {
  static ThemeData createResponsiveTheme({
    required ColorScheme colorScheme,
    required BuildContext context,
  }) {
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
    );
  }
}

/// Extension for responsive spacing
extension ResponsiveSpacing on BuildContext {
  double get smallSpacing => 8.0;
  double get mediumSpacing => 16.0;
  double get largeSpacing => 24.0;
  double get extraLargeSpacing => 32.0;
}

/// Extension for responsive icon sizes
extension ResponsiveIcons on BuildContext {
  double get smallIconSize => 16.0;
  double get mediumIconSize => 24.0;
  double get largeIconSize => 32.0;
  double get extraLargeIconSize => 48.0;
}