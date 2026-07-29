import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/providers/navigation_provider.dart';
import 'package:univ_tiaret/route/route_constants.dart';
import 'package:univ_tiaret/logic/download_provider.dart';

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
    final downloadCount = ref.watch(downloadProvider.select((p) => p.activeCount));

    return Container(
      padding: const EdgeInsetsDirectional.only(
        start: defaultPadding,
        end: defaultPadding,
        bottom: defaultPadding,
      ),
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: defaultPadding,
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
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildItem(context, ref, 0, Icons.home_rounded, t.translate('home')),
            _buildItem(context, ref, 1, Icons.bookmark_rounded, t.translate('favorites')),
            _buildItem(context, ref, 2, Icons.download_rounded, t.translate('downloads'), badge: downloadCount),
            _buildItem(context, ref, 3, Icons.calendar_month_rounded, t.translate('calendar')),
            _buildItem(context, ref, 4, Icons.settings_rounded, t.translate('settings_nav')),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, WidgetRef ref, int index, IconData iconData, String label, {int badge = 0}) {
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
          navigator.pushNamedAndRemoveUntil(
            entryPointScreenRoute,
            (route) => false,
          );
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(iconData, size: 24, color: iconColor),
              if (badge > 0)
                Positioned(
                  right: -8,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      badge.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          if (showLabels) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? selectedColor : unselectedColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
