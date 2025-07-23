import 'package:flutter/material.dart';

/// Represents a single breadcrumb item
class BreadcrumbItem {
  final String title;
  final VoidCallback? onTap;
  final IconData? icon;

  const BreadcrumbItem({
    required this.title,
    this.onTap,
    this.icon,
  });
}

/// Widget for displaying breadcrumb navigation
class BreadcrumbNavigation extends StatelessWidget {
  final List<BreadcrumbItem> items;
  final Color? textColor;
  final Color? separatorColor;
  final double fontSize;

  const BreadcrumbNavigation({
    super.key,
    required this.items,
    this.textColor,
    this.separatorColor,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final defaultTextColor = textColor ?? theme.textTheme.bodyMedium?.color;
    final defaultSeparatorColor = separatorColor ?? Colors.grey.shade400;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildBreadcrumbItem(
              context,
              items[i],
              isLast: i == items.length - 1,
              textColor: defaultTextColor,
            ),
            if (i < items.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: defaultSeparatorColor,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildBreadcrumbItem(
    BuildContext context,
    BreadcrumbItem item,
    {required bool isLast,
    required Color? textColor}
  ) {
    final textStyle = TextStyle(
      fontSize: fontSize,
      color: isLast ? textColor : Colors.blue,
      fontWeight: isLast ? FontWeight.w500 : FontWeight.normal,
    );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.icon != null) ...[
          Icon(
            item.icon,
            size: fontSize + 2,
            color: textStyle.color,
          ),
          const SizedBox(width: 4),
        ],
        Text(item.title, style: textStyle),
      ],
    );

    if (isLast || item.onTap == null) {
      return content;
    }

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: content,
      ),
    );
  }
}