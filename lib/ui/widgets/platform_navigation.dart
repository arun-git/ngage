import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/accessibility_utils.dart';

/// Platform-adaptive navigation widget
class PlatformNavigation extends StatefulWidget {
  final List<NavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final Widget body;
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  
  const PlatformNavigation({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.body,
    required this.title,
    this.actions,
    this.floatingActionButton,
  });
  
  @override
  State<PlatformNavigation> createState() => _PlatformNavigationState();
}

class _PlatformNavigationState extends State<PlatformNavigation> with KeyboardNavigationMixin {
  late Map<ShortcutActivator, Intent> _shortcuts;
  late Map<Type, Action<Intent>> _actions;
  
  @override
  void initState() {
    super.initState();
    _setupKeyboardShortcuts();
  }
  
  void _setupKeyboardShortcuts() {
    _shortcuts = {
      ...AccessibilityUtils.getCommonShortcuts(),
      // Add number key shortcuts for navigation (1-9)
      for (int i = 0; i < widget.items.length && i < 9; i++)
        SingleActivator(LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + i)): 
          NavigateToIndexIntent(i),
    };
    
    _actions = {
      NavigateToIndexIntent: CallbackAction<NavigateToIndexIntent>(
        onInvoke: (intent) {
          if (intent.index < widget.items.length) {
            widget.onItemSelected(intent.index);
          }
          return null;
        },
      ),
      CustomDismissIntent: CustomDismissAction(() {
        // Handle escape key - could close drawer or navigate back
        if (Scaffold.of(context).isDrawerOpen) {
          Navigator.of(context).pop();
        }
      }),
    };
  }
  
  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _shortcuts,
      child: Actions(
        actions: _actions,
        child: Focus(
          focusNode: focusNode,
          autofocus: true,
          child: _buildPlatformSpecificNavigation(context),
        ),
      ),
    );
  }
  
  Widget _buildPlatformSpecificNavigation(BuildContext context) {
    final responsive = context.responsive;
    
    if (PlatformUtils.isDesktop || responsive.isDesktop) {
      return _buildDesktopNavigation(context);
    } else if (responsive.isTablet) {
      return _buildTabletNavigation(context);
    } else {
      return _buildMobileNavigation(context);
    }
  }
  
  Widget _buildDesktopNavigation(BuildContext context) {
    final responsive = context.responsive;
    final extended = responsive.isLargeDesktop;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: widget.actions,
        automaticallyImplyLeading: false,
        elevation: 1,
      ),
      body: Row(
        children: [
          Container(
            width: extended ? 200 : 72,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                if (!extended) const SizedBox(height: 8),
                Expanded(
                  child: NavigationRail(
                    selectedIndex: widget.selectedIndex,
                    onDestinationSelected: widget.onItemSelected,
                    extended: extended,
                    minWidth: extended ? 200 : 72,
                    backgroundColor: Colors.transparent,
                    destinations: widget.items.map((item) => NavigationRailDestination(
                      icon: Tooltip(
                        message: item.tooltip ?? item.label,
                        child: item.icon,
                      ),
                      selectedIcon: item.selectedIcon ?? item.icon,
                      label: Text(item.label),
                    )).toList(),
                  ),
                ),
                if (extended) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildUserProfile(),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: widget.body,
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }
  
  Widget _buildTabletNavigation(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: widget.actions,
      ),
      drawer: _buildNavigationDrawer(context),
      body: widget.body,
      bottomNavigationBar: widget.items.length <= 5 
        ? _buildBottomNavigationBar(context)
        : null,
      floatingActionButton: widget.floatingActionButton,
    );
  }
  
  Widget _buildMobileNavigation(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: widget.actions,
      ),
      drawer: widget.items.length > 5 ? _buildNavigationDrawer(context) : null,
      body: widget.body,
      bottomNavigationBar: widget.items.length <= 5 
        ? _buildBottomNavigationBar(context)
        : null,
      floatingActionButton: widget.floatingActionButton,
    );
  }
  
  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.selectedIndex,
      onTap: widget.onItemSelected,
      type: widget.items.length > 3 
        ? BottomNavigationBarType.fixed 
        : BottomNavigationBarType.shifting,
      items: widget.items.take(5).map((item) => BottomNavigationBarItem(
        icon: item.icon,
        activeIcon: item.selectedIcon ?? item.icon,
        label: item.label,
        tooltip: item.tooltip,
      )).toList(),
    );
  }
  
  Widget _buildNavigationDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const Spacer(),
                _buildUserProfile(),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSelected = index == widget.selectedIndex;
                
                return AccessibilityUtils.createAccessibleListTile(
                  leading: item.icon,
                  title: Text(item.label),
                  selected: isSelected,
                  semanticLabel: '${item.label}${isSelected ? ', selected' : ''}',
                  onTap: () {
                    widget.onItemSelected(index);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUserProfile() {
    final responsive = context.responsive;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircleAvatar(
          radius: 16,
          child: Icon(Icons.person, size: 20),
        ),
        if (responsive.isLargeDesktop) ...[
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'User Name',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'user@example.com',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Navigation item for platform navigation
class NavigationItem {
  final Widget icon;
  final Widget? selectedIcon;
  final String label;
  final String? tooltip;
  final VoidCallback? onTap;
  
  const NavigationItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.tooltip,
    this.onTap,
  });
}

/// Intent for navigating to a specific index
class NavigateToIndexIntent extends Intent {
  final int index;
  
  const NavigateToIndexIntent(this.index);
}

/// Adaptive app bar that changes based on platform
class PlatformAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final double? elevation;
  
  const PlatformAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.elevation,
  });
  
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    
    return AppBar(
      title: Text(title),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      elevation: elevation ?? (responsive.isDesktop ? 1 : null),
      centerTitle: PlatformUtils.isMobile,
      toolbarHeight: responsive.responsive<double>(
        mobile: kToolbarHeight,
        tablet: kToolbarHeight + 8,
        desktop: kToolbarHeight + 16,
        largeDesktop: kToolbarHeight + 24,
      ),
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Adaptive floating action button that changes based on platform
class PlatformFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final String? tooltip;
  final String? heroTag;
  
  const PlatformFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.tooltip,
    this.heroTag,
  });
  
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    
    if (responsive.isDesktop) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: child,
        label: Text(tooltip ?? 'Action'),
        heroTag: heroTag,
      );
    } else {
      return FloatingActionButton(
        onPressed: onPressed,
        tooltip: tooltip,
        heroTag: heroTag,
        child: child,
      );
    }
  }
}