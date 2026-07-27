import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/components/breadcrumb_bar.dart';
import 'package:univ_tiaret/components/skeleton_tile.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/logic/activities_provider.dart';
import 'package:univ_tiaret/logic/lesson_files_provider.dart';
import 'package:univ_tiaret/route/route_constants.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.moduleName),
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
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: colors.onSurface
                                          .withValues(alpha: 0.1),
                                      width: 1,
                                    ),
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
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: colors.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              activity.name,
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
                                        Icons.chevron_right_rounded,
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
            message,
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
                .read(activitiesProvider.notifier)
                .fetchActivities(moduleId: widget.moduleId),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(t.translate('try_again')),
          ),
        ],
      ),
    );
  }

  IconData _activityIcon(String name) {
    switch (name.toLowerCase()) {
      case 'lesson':
        return Icons.menu_book_rounded;
      case 'td':
        return Icons.edit_note_rounded;
      case 'tp':
        return Icons.science_rounded;
      case 'exam':
        return Icons.assignment_rounded;
      case 'controle':
        return Icons.fact_check_rounded;
      default:
        return Icons.circle_rounded;
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
