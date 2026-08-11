import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/providers/navigation_provider.dart';

class AppBottomNav extends ConsumerWidget {
  final int currentIndex;
  final bool showLabels;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsetsDirectional.only(
          start: defaultPadding,
          end: defaultPadding,
          bottom: defaultPadding,
        ),
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: defaultPadding / 2,
            vertical: defaultPadding / 2,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.all(
              Radius.circular(defaultBorderRadious * 2),
            ),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 4),
                blurRadius: 16,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(child: _buildItem(context, ref, 0, LucideIcons.home, t.translate('home'))),
              Expanded(child: _buildItem(context, ref, 1, LucideIcons.bookmark, t.translate('favorites'))),
              Expanded(child: _buildItem(context, ref, 2, LucideIcons.listTodo, t.translate('todo'))),
              Expanded(child: _buildItem(context, ref, 3, LucideIcons.calendarDays, t.translate('calendar'))),
              Expanded(child: _buildItem(context, ref, 4, LucideIcons.settings, t.translate('settings_nav'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, WidgetRef ref, int index, IconData iconData, String label) {
    final isSelected = currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark ? Colors.white : AppColors.primaryColor;
    final unselectedColor = isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.4);
    final iconColor = isSelected ? selectedColor : unselectedColor;

    return GestureDetector(
      onTap: () {
        ref.read(navigationProvider.notifier).state = index;
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.popUntil((route) => route.isFirst);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: defaultDuration,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.primaryColor.withValues(alpha: 0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, size: 24, color: iconColor),
            if (showLabels) ...[
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? selectedColor : unselectedColor,
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
