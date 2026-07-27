import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/components/breadcrumb_bar.dart';
import 'package:univ_tiaret/components/modern_list_tile.dart';
import 'package:univ_tiaret/components/skeleton_tile.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/logic/semesters_provider.dart';
import 'package:univ_tiaret/route/route_constants.dart';

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
                            .read(semestersProvider.notifier)
                            .fetchSemesters(levelId: widget.levelId),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(t.translate('try_again')),
                      ),
                    ],
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
