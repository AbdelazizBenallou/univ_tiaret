import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/components/breadcrumb_bar.dart';
import 'package:univ_tiaret/components/skeleton_tile.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/logic/activities_provider.dart';
import 'package:univ_tiaret/logic/lesson_files_provider.dart';
import 'package:univ_tiaret/providers/navigation_provider.dart';
import 'package:univ_tiaret/route/route_constants.dart';
import 'package:univ_tiaret/widgets/app_bottom_nav.dart';

class ActivitiesScreen extends ConsumerStatefulWidget {
  final int moduleId;
  final String moduleName;
  final int seasonId;
  final String semesterName;
  final String seasonName;

  const ActivitiesScreen({
    super.key,
    required this.moduleId,
    required this.moduleName,
    required this.seasonId,
    required this.semesterName,
    required this.seasonName,
  });

  @override
  ConsumerState<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends ConsumerState<ActivitiesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref
        .read(activitiesProvider.notifier)
        .fetchActivities(moduleId: widget.moduleId));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(activitiesProvider);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.moduleName),
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
              BreadcrumbItem(
                label: widget.seasonName,
                onTap: () => Navigator.pop(context),
              ),
              BreadcrumbItem(
                label: widget.semesterName,
                onTap: () => Navigator.pop(context),
              ),
              BreadcrumbItem(label: widget.moduleName),
            ],
          ),
          Expanded(
            child: state.loading
                ? const SkeletonList()
                : state.error != null
                    ? _buildError(state.error!, t)
                    : state.activities.isEmpty
                        ? Center(
                            child: Text(
                              t.translate('no_activities'),
                              style: TextStyle(
                                color: colors.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref
                                .read(activitiesProvider.notifier)
                                .fetchActivities(moduleId: widget.moduleId),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: state.activities.length,
                              separatorBuilder: (ctx, i) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final activity = state.activities[index];
                                return GestureDetector(
                                  onTap: () {
                                    ref.read(lessonFilesProvider.notifier).reset();
                                    Navigator.pushNamed(
                                      context,
                                      lessonFilesScreenRoute,
                                      arguments: {
                                        'moduleId': widget.moduleId,
                                        'moduleName': widget.moduleName,
                                        'activityTypeId': activity.id,
                                        'activityTypeName': _activityFullName(activity.name, t),
                                        'seasonId': widget.seasonId,
                                        'seasonName': widget.seasonName,
                                        'semesterName': widget.semesterName,
                                      },
                                    );
                                  },
                                  child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              AppColors.greenLight,
                                              AppColors.greenAccent,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          _activityIcon(activity.name),
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _activityFullName(
                                                  activity.name, t),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: colors.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              activity.name.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: colors.onSurface
                                                    .withValues(alpha: 0.5),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Directionality.of(context) == TextDirection.rtl
                                            ? Icons.chevron_left_rounded
                                            : Icons.chevron_right_rounded,
                                        size: 20,
                                        color: colors.onSurface
                                            .withValues(alpha: 0.3),
                                      ),
                                    ],
                                  ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message, AppLocalizations t) {
    return Center(
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
              t.translate(message),
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
                    .read(activitiesProvider.notifier)
                    .fetchActivities(moduleId: widget.moduleId),
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
    );
  }

  IconData _activityIcon(String name) {
    switch (name.toLowerCase()) {
      case 'lesson':
        return Icons.menu_book_rounded;
      case 'td':
        return Icons.edit_rounded;
      case 'tp':
        return Icons.science_rounded;
      case 'exam':
        return Icons.assignment_rounded;
      case 'controle':
        return Icons.assignment_rounded;
      default:
        return Icons.radio_button_unchecked_rounded;
    }
  }

  String _activityFullName(String name, AppLocalizations t) {
    switch (name.toLowerCase()) {
      case 'lesson':
        return t.translate('activity_lesson');
      case 'td':
        return t.translate('activity_td');
      case 'tp':
        return t.translate('activity_tp');
      case 'exam':
        return t.translate('activity_exam');
      case 'controle':
        return t.translate('activity_controle');
      default:
        return name;
    }
  }
}
