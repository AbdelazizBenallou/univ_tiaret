import 'package:flutter/material.dart';

class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;

  const BreadcrumbItem({required this.label, this.onTap});
}

class BreadcrumbBar extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const BreadcrumbBar({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Row(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
                  ),
                ),
              ],
              GestureDetector(
                onTap: items[i].onTap,
                child: Text(
                  items[i].label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: i == items.length - 1
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: i == items.length - 1
                        ? theme.textTheme.bodyMedium?.color
                        : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
