import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Accessibility utilities for screen readers and keyboard navigation
class AccessibilityUtils {
  /// Announce text to screen readers
  static void announce(BuildContext context, String message) {
    // Use Flutter's built-in semantics announcement
    // SemanticsService.announce(message, TextDirection.ltr);
    // For now, we'll use a simple debug print as a placeholder
    debugPrint('Accessibility announcement: $message');
  }
  
  /// Create semantic label for complex widgets
  static String createSemanticLabel({
    required String label,
    String? hint,
    String? value,
    bool? enabled,
    bool? selected,
  }) {
    final buffer = StringBuffer(label);
    
    if (value != null && value.isNotEmpty) {
      buffer.write(', $value');
    }
    
    if (selected == true) {
      buffer.write(', selected');
    }
    
    if (enabled == false) {
      buffer.write(', disabled');
    }
    
    if (hint != null && hint.isNotEmpty) {
      buffer.write(', $hint');
    }
    
    return buffer.toString();
  }
  
  /// Get appropriate focus node for keyboard navigation
  static FocusNode createFocusNode({
    String? debugLabel,
    bool skipTraversal = false,
    bool canRequestFocus = true,
  }) {
    return FocusNode(
      debugLabel: debugLabel,
      skipTraversal: skipTraversal,
      canRequestFocus: canRequestFocus,
    );
  }
  
  /// Create keyboard shortcuts for common actions
  static Map<ShortcutActivator, Intent> getCommonShortcuts() {
    return {
      const SingleActivator(LogicalKeyboardKey.escape): const CustomDismissIntent(),
      const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
      const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
      const SingleActivator(LogicalKeyboardKey.tab): const NextFocusIntent(),
      const SingleActivator(LogicalKeyboardKey.tab, shift: true): const PreviousFocusIntent(),
      const SingleActivator(LogicalKeyboardKey.arrowDown): const DirectionalFocusIntent(TraversalDirection.down),
      const SingleActivator(LogicalKeyboardKey.arrowUp): const DirectionalFocusIntent(TraversalDirection.up),
      const SingleActivator(LogicalKeyboardKey.arrowLeft): const DirectionalFocusIntent(TraversalDirection.left),
      const SingleActivator(LogicalKeyboardKey.arrowRight): const DirectionalFocusIntent(TraversalDirection.right),
    };
  }
  
  /// Create accessible button with proper semantics
  static Widget createAccessibleButton({
    required Widget child,
    required VoidCallback? onPressed,
    String? semanticLabel,
    String? tooltip,
    FocusNode? focusNode,
    bool autofocus = false,
  }) {
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onPressed != null,
      child: Tooltip(
        message: tooltip ?? '',
        child: ElevatedButton(
          onPressed: onPressed,
          focusNode: focusNode,
          autofocus: autofocus,
          child: child,
        ),
      ),
    );
  }
  
  /// Create accessible text field with proper semantics
  static Widget createAccessibleTextField({
    required TextEditingController controller,
    String? labelText,
    String? hintText,
    String? semanticLabel,
    String? errorText,
    bool obscureText = false,
    TextInputType? keyboardType,
    FocusNode? focusNode,
    ValueChanged<String>? onChanged,
    VoidCallback? onEditingComplete,
  }) {
    return Semantics(
      label: semanticLabel ?? labelText,
      textField: true,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          errorText: errorText,
          border: const OutlineInputBorder(),
        ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        focusNode: focusNode,
        onChanged: onChanged,
        onEditingComplete: onEditingComplete,
      ),
    );
  }
  
  /// Create accessible list item with proper semantics
  static Widget createAccessibleListTile({
    required Widget title,
    Widget? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    String? semanticLabel,
    bool selected = false,
    FocusNode? focusNode,
  }) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      selected: selected,
      child: Focus(
        focusNode: focusNode,
        child: ListTile(
          title: title,
          subtitle: subtitle,
          leading: leading,
          trailing: trailing,
          onTap: onTap,
          selected: selected,
        ),
      ),
    );
  }
  
  /// Create accessible card with proper semantics
  static Widget createAccessibleCard({
    required Widget child,
    VoidCallback? onTap,
    String? semanticLabel,
    double? elevation,
    EdgeInsetsGeometry? margin,
    FocusNode? focusNode,
  }) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: Focus(
        focusNode: focusNode,
        child: Card(
          elevation: elevation,
          margin: margin,
          child: InkWell(
            onTap: onTap,
            child: child,
          ),
        ),
      ),
    );
  }
  
  /// Check if high contrast mode is enabled
  static bool isHighContrastEnabled(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }
  
  /// Check if animations should be reduced
  static bool shouldReduceAnimations(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }
  
  /// Get text scale factor for accessibility
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor;
  }
  
  /// Create accessible navigation rail for desktop
  static Widget createAccessibleNavigationRail({
    required int selectedIndex,
    required ValueChanged<int> onDestinationSelected,
    required List<NavigationRailDestination> destinations,
    Widget? leading,
    Widget? trailing,
    bool extended = false,
  }) {
    return Semantics(
      label: 'Navigation menu',
      child: NavigationRail(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
        leading: leading,
        trailing: trailing,
        extended: extended,
      ),
    );
  }
  
  /// Create accessible bottom navigation bar for mobile
  static Widget createAccessibleBottomNavigationBar({
    required int currentIndex,
    required ValueChanged<int> onTap,
    required List<BottomNavigationBarItem> items,
    BottomNavigationBarType? type,
  }) {
    return Semantics(
      label: 'Bottom navigation',
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: items,
        type: type,
      ),
    );
  }
}

/// Mixin for widgets that need keyboard navigation support
mixin KeyboardNavigationMixin<T extends StatefulWidget> on State<T> {
  late FocusNode _focusNode;
  
  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }
  
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
  
  FocusNode get focusNode => _focusNode;
  
  void requestFocus() {
    _focusNode.requestFocus();
  }
  
  bool get hasFocus => _focusNode.hasFocus;
}

/// Custom intent for dismissing dialogs/screens
class CustomDismissIntent extends Intent {
  const CustomDismissIntent();
}

/// Action for handling dismiss intent
class CustomDismissAction extends Action<CustomDismissIntent> {
  final VoidCallback onDismiss;
  
  CustomDismissAction(this.onDismiss);
  
  @override
  Object? invoke(CustomDismissIntent intent) {
    onDismiss();
    return null;
  }
}