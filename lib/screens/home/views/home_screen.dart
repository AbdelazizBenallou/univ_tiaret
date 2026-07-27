import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/components/breadcrumb_bar.dart';
import 'package:univ_tiaret/components/modern_list_tile.dart';
import 'package:univ_tiaret/components/skeleton_tile.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/logic/auth_provider.dart';
import 'package:univ_tiaret/logic/seasons_provider.dart';
import 'package:univ_tiaret/route/route_constants.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(seasonsProvider.notifier).fetchSeasons());
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final seasonsState = ref.watch(seasonsProvider);

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BreadcrumbBar(
            items: [
              BreadcrumbItem(label: t.translate('seasons')),
            ],
          ),
          Expanded(
            child: seasonsState.loading
                ? const SkeletonList()
                : seasonsState.error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: errorColor.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              t.translate('err_network'),
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () => ref
                                  .read(seasonsProvider.notifier)
                                  .fetchSeasons(),
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(t.translate('resend_code')),
                            ),
                          ],
                        ),
                      )
                    : seasonsState.seasons.isEmpty
                        ? Center(
                            child: Text(
                              t.translate('no_seasons'),
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(alpha: 0.5),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref
                                .read(seasonsProvider.notifier)
                                .fetchSeasons(),
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                              itemCount: seasonsState.seasons.length,
                              separatorBuilder: (ctx, i) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final season = seasonsState.seasons[index];
                                return ModernListTile(
                                  icon: Icons.calendar_today_rounded,
                                  title: season.name,
                                  subtitle: t.translate('season'),
                                  badge: season.isCurrent
                                      ? t.translate('current_season')
                                      : null,
                                  onTap: () {
                                    final user =
                                        ref.read(authProvider).user;
                                    final levelId = user?.levelId;
                                    if (levelId != null) {
                                      Navigator.pushNamed(
                                        context,
                                        semestersScreenRoute,
                                        arguments: {
                                          'levelId': levelId,
                                          'seasonId': season.id,
                                          'seasonName': season.name,
                                          'seasonIsCurrent': season.isCurrent,
                                          'levelName': user?.levelName,
                                          'specialityId': user?.specialityId,
                                        },
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
