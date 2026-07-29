import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/components/breadcrumb_bar.dart';
import 'package:univ_tiaret/components/modern_list_tile.dart';
import 'package:univ_tiaret/components/skeleton_tile.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/logic/semesters_provider.dart';
import 'package:univ_tiaret/providers/navigation_provider.dart';
import 'package:univ_tiaret/route/route_constants.dart';
import 'package:univ_tiaret/widgets/app_bottom_nav.dart';

class SemestersScreen extends ConsumerStatefulWidget {
  final int levelId;
  final int seasonId;
  final String seasonName;
  final bool seasonIsCurrent;
  final String? levelName;
  final int? specialityId;

  const SemestersScreen({
    super.key,
    required this.levelId,
    required this.seasonId,
    required this.seasonName,
    required this.seasonIsCurrent,
    this.levelName,
    this.specialityId,
  });

  @override
  ConsumerState<SemestersScreen> createState() => _SemestersScreenState();
}

class _SemestersScreenState extends ConsumerState<SemestersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref
        .read(semestersProvider.notifier)
        .fetchSemesters(levelId: widget.levelId));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(semestersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.seasonName),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: ref.watch(navigationProvider),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BreadcrumbBar(
            items: [
              BreadcrumbItem(
                label: t.translate('seasons'),
                onTap: () => Navigator.pop(context),
              ),
              BreadcrumbItem(label: widget.seasonName),
            ],
          ),
          Expanded(
            child: state.loading
          ? const SkeletonList()
          : state.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: errorColor.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.cloud_off_rounded,
                            size: 36,
                            color: errorColor.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          t.translate('err_network'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: 160,
                          child: ElevatedButton.icon(
                            onPressed: () => ref
                                .read(semestersProvider.notifier)
                                .fetchSemesters(levelId: widget.levelId),
                            icon: Icon(Icons.refresh_rounded, size: 18),
                            label: Text(t.translate('try_again')),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : state.semesters.isEmpty
                  ? Center(
                      child: Text(
                        t.translate('no_semesters'),
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
                          .read(semestersProvider.notifier)
                          .fetchSemesters(levelId: widget.levelId),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.semesters.length,
                        separatorBuilder: (ctx, i) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final semester = state.semesters[index];
                          final startDate = semester.startDate != null
                              ? '${semester.startDate!.day}/${semester.startDate!.month}/${semester.startDate!.year}'
                              : '';
                          return ModernListTile(
                            icon: Icons.date_range_rounded,
                            title: semester.name,
                            subtitle: startDate,
                            badge: semester.isCurrent && widget.seasonIsCurrent
                                ? t.translate('current_semester')
                                : null,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                modulesScreenRoute,
                                arguments: {
                                  'semesterId': semester.id,
                                  'semesterName': semester.name,
                                  'seasonId': widget.seasonId,
                                  'seasonName': widget.seasonName,
                                  'levelName': widget.levelName,
                                  'specialityId': widget.specialityId,
                                },
                              );
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
