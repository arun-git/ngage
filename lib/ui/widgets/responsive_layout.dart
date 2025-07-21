import 'package:flutter/material.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/accessibility_utils.dart';

/// Responsive layout widget that adapts to different screen sizes
class ResponsiveLayout extends StatelessWidget {
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;
  final Widget child;
  
  const ResponsiveLayout({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    
    return responsive.responsive<Widget>(
      mobile: mobile ?? child,
      tablet: tablet ?? mobile ?? child,
      desktop: desktop ?? tablet ?? mobile ?? child,
      largeDesktop: largeDesktop ?? desktop ?? tablet ?? mobile ?? child,
    );
  }
}

/// Responsive scaffold that adapts navigation based on screen size
class ResponsiveScaffold extends StatefulWidget {
  final String title;
  final List<ResponsiveNavigationDestination> destinations;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final Widget? drawer;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final bool showNavigationRail;
  final bool extendedNavigationRail;
  
  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.destinations,
    required this.body,
    this.floatingActionButton,
    this.actions,
    this.drawer,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.showNavigationRail = true,
    this.extendedNavigationRail = false,
  });
  
  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> with KeyboardNavigationMixin {
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    
    // Desktop layout with navigation rail
    if (responsive.isDesktop && widget.showNavigationRail) {
      return _buildDesktopLayout(context);
    }
    
    // Mobile/tablet layout with bottom navigation or drawer
    return _buildMobileLayout(context);
  }
  
  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: widget.actions,
        automaticallyImplyLeading: false,
      ),
      body: Row(
        children: [
          AccessibilityUtils.createAccessibleNavigationRail(
            selectedIndex: widget.selectedIndex,
            onDestinationSelected: widget.onDestinationSelected ?? (_) {},
            extended: widget.extendedNavigationRail || context.responsive.isLargeDesktop,
            destinations: widget.destinations.map((dest) => NavigationRailDestination(
              icon: dest.icon,
              selectedIcon: dest.selectedIcon,
              label: Text(dest.label),
            )).toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Padding(
              padding: context.responsive.responsivePadding,
              child: widget.body,
            ),
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }
  
  Widget _buildMobileLayout(BuildContext context) {
    final responsive = context.responsive;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: widget.actions,
      ),
      drawer: widget.drawer,
      body: Padding(
        padding: responsive.responsivePadding,
        child: widget.body,
      ),
      bottomNavigationBar: widget.destinations.length <= 5 
        ? AccessibilityUtils.createAccessibleBottomNavigationBar(
            currentIndex: widget.selectedIndex,
            onTap: widget.onDestinationSelected ?? (_) {},
            type: widget.destinations.length > 3 
              ? BottomNavigationBarType.fixed 
              : BottomNavigationBarType.shifting,
            items: widget.destinations.map((dest) => BottomNavigationBarItem(
              icon: dest.icon,
              activeIcon: dest.selectedIcon,
              label: dest.label,
            )).toList(),
          )
        : null,
      floatingActionButton: widget.floatingActionButton,
    );
  }
}

/// Navigation destination for responsive scaffold
class ResponsiveNavigationDestination {
  final Widget icon;
  final Widget? selectedIcon;
  final String label;
  final String? tooltip;
  
  const NavigationDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.tooltip,
  });
}

/// Responsive grid that adapts column count based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double? childAspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final EdgeInsetsGeometry? padding;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final int? largeDesktopColumns;
  
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.childAspectRatio,
    this.mainAxisSpacing = 8.0,
    this.crossAxisSpacing = 8.0,
    this.padding,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.largeDesktopColumns,
  });
  
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    
    final columnCount = responsive.responsive<int>(
      mobile: mobileColumns ?? 1,
      tablet: tabletColumns ?? 2,
      desktop: desktopColumns ?? 3,
      largeDesktop: largeDesktopColumns ?? 4,
    );
    
    return Padding(
      padding: padding ?? responsive.responsivePadding,
      child: GridView.count(
        crossAxisCount: columnCount,
        childAspectRatio: childAspectRatio ?? 1.0,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        children: children,
      ),
    );
  }
}

/// Responsive card that adapts size and elevation based on screen size
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  
  const ResponsiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.margin,
    this.padding,
    this.elevation,
  });
  
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    
    return AccessibilityUtils.createAccessibleCard(
      semanticLabel: semanticLabel,
      onTap: onTap,
      elevation: elevation ?? responsive.responsiveCardElevation,
      margin: margin ?? responsive.responsiveMargin,
      child: Padding(
        padding: padding ?? responsive.responsivePadding,
        child: child,
      ),
    );
  }
}

/// Responsive dialog that adapts size based on screen size
class ResponsiveDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final bool scrollable;
  
  const ResponsiveDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.scrollable = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: responsive.responsive<double>(
            mobile: MediaQuery.of(context).size.width * 0.9,
            tablet: 500,
            desktop: 600,
            largeDesktop: 700,
          ),
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: responsive.responsivePadding,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close dialog',
                  ),
                ],
              ),
            ),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                padding: responsive.responsivePadding,
                child: content,
              ),
            ),
            if (actions != null) ...[
              const Divider(),
              Padding(
                padding: responsive.responsivePadding,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Responsive list view that adapts item height based on screen size
class ResponsiveListView extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  
  const ResponsiveListView({
    super.key,
    required this.children,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });
  
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    
    return ListView(
      padding: padding ?? responsive.responsivePadding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      children: children,
    );
  }
}

/// Responsive form that adapts field layout based on screen size
class ResponsiveForm extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final double spacing;
  
  const ResponsiveForm({
    super.key,
    required this.children,
    this.padding,
    this.spacing = 16.0,
  });
  
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    
    return Padding(
      padding: padding ?? responsive.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children
          .expand((child) => [child, SizedBox(height: spacing)])
          .take(children.length * 2 - 1)
          .toList(),
      ),
    );
  }
}