import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animations/animations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/providers/navigation_provider.dart';
import 'package:univ_tiaret/route/route_constants.dart';
import 'package:univ_tiaret/logic/download_provider.dart';
import 'package:univ_tiaret/screens/home/views/home_screen.dart';
import 'package:univ_tiaret/screens/home/views/favorites_screen.dart';
import 'package:univ_tiaret/screens/home/views/calendar_screen.dart';
import 'package:univ_tiaret/screens/settings/views/settings_screen.dart';
import 'package:univ_tiaret/widgets/app_bottom_nav.dart';

class EntryPoint extends ConsumerStatefulWidget {
  const EntryPoint({super.key});

  @override
  ConsumerState<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends ConsumerState<EntryPoint> {
  late final List<Widget> _pages;
  int _currentIndex;
  int _transitionDirection = 1;

  _EntryPointState() : _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = ref.read(navigationProvider);
    ref.read(downloadProvider.notifier).init();
    _pages = [
      const HomeScreen(),
      const FavoritesScreen(),
      const PlaceholderScreen(title: 'To Do'),
      const CalendarScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final nextIndex = ref.watch(navigationProvider);
    if (nextIndex != _currentIndex) {
      _transitionDirection = nextIndex > _currentIndex ? 1 : -1;
    }
    _currentIndex = nextIndex;
    final downloadCount = ref.watch(
      downloadProvider.select((p) => p.activeCount),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: const SizedBox(),
        leadingWidth: 0,
        centerTitle: false,
        title: Text(
          "Univ Tiaret",
          style: TextStyle(
            fontFamily: grandisExtendedFont,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).iconTheme.color,
          ),
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAppBarIcon(
                context,
                icon: LucideIcons.download,
                badge: downloadCount,
                onPressed: () {
                  Navigator.pushNamed(context, downloadsScreenRoute);
                },
              ),
              const SizedBox(width: 4),
              _buildAppBarIcon(
                context,
                icon: LucideIcons.bell,
                onPressed: () {
                  Navigator.pushNamed(context, notificationsScreenRoute);
                },
              ),
            ],
          ),
        ],
      ),
      body: PageTransitionSwitcher(
        duration: defaultDuration,
        transitionBuilder: (child, animation, secondaryAnimation) {
          final direction = _transitionDirection.toDouble();
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: Offset(0.12 * direction, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: _currentIndex),
    );
  }

  Widget _buildAppBarIcon(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    int badge = 0,
  }) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              size: 24,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
          if (badge > 0)
            Positioned(
              right: 4,
              top: 4,
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
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.build_rounded,
              size: 64,
              color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.3),
            ),
            const SizedBox(height: defaultPadding),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.headlineSmall?.color?.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: defaultPadding / 2),
            Text(
              t.translate('coming_soon'),
              style: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
