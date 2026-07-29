import 'package:flutter/material.dart';

import 'package:univ_tiaret/constants.dart';

class SortOption<T> {
  final T value;
  final String label;
  final IconData icon;

  const SortOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}

Future<T?> showSortBottomSheet<T>({
  required BuildContext context,
  required String title,
  required List<SortOption<T>> options,
  required T currentValue,
  bool ascending = true,
  VoidCallback? onToggleOrder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  if (onToggleOrder != null)
                    TextButton.icon(
                      onPressed: () {
                        onToggleOrder();
                        Navigator.pop(ctx);
                      },
                      icon: Icon(
                        ascending
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 18,
                      ),
                      label: Text(
                        ascending ? 'A-Z' : 'Z-A',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...options.map((option) => ListTile(
                  leading: Icon(
                    option.icon,
                    color: option.value == currentValue
                        ? primaryColor
                        : Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.5),
                  ),
                  title: Text(option.label),
                  trailing: option.value == currentValue
                      ? Icon(Icons.check_rounded, color: primaryColor, size: 20)
                      : null,
                  onTap: () => Navigator.pop(ctx, option.value),
                )),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}
