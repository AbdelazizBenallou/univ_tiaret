import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/logic/download_provider.dart';
import 'package:univ_tiaret/logic/favorite_provider.dart';
import 'package:univ_tiaret/models/favorite_file.dart';
import 'package:univ_tiaret/route/route_constants.dart';
import 'package:univ_tiaret/services/download_service.dart';
import 'package:univ_tiaret/components/subscription_guard.dart';
import 'package:univ_tiaret/utils/file_utils.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  String _searchQuery = '';
  bool _showSearch = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(favoriteProvider.notifier).init();
    ref.read(downloadProvider.notifier).init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FavoriteFile> _getFiltered(List<FavoriteFile> items) {
    var result = items.toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((f) => f.fileName.toLowerCase().contains(q))
          .toList();
    }
    return result;
  }

  String _activeFilterLabel(AppLocalizations t) {
    final f = ref.read(favoriteProvider);
    final parts = <String>[];
    if (f.filterModule.isNotEmpty) {
      parts.add('${t.translate('module')}: ${f.filterModule}');
    }
    if (f.filterActivity.isNotEmpty) {
      parts.add('${t.translate('activity_type')}: ${f.filterActivity}');
    }
    if (f.filterSeason.isNotEmpty) {
      parts.add('${t.translate('season')}: ${f.filterSeason}');
    }
    return parts.join('  ·  ');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(favoriteProvider);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allFavorites = state.favorites;
    final filtered = _getFiltered(state.filteredFavorites());

    final grouped = <String, List<FavoriteFile>>{};
    for (final f in filtered) {
      grouped
          .putIfAbsent(
            f.moduleName.isEmpty ? t.translate('other') : f.moduleName,
            () => [],
          )
          .add(f);
    }

    return SubscriptionGuard(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        width: double.infinity,
        height: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.translate('favorites'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _showFilterSheet,
                    icon: Icon(
                      Icons.filter_list_rounded,
                      size: 22,
                      color: state.hasActiveFilter
                          ? AppColors.greenAccent
                          : null,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showSearch = !_showSearch;
                        if (!_showSearch) {
                          _searchQuery = '';
                          _searchController.clear();
                        }
                      });
                    },
                    icon: Icon(
                      _showSearch ? Icons.close_rounded : Icons.search_rounded,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            if (_showSearch)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: t.translate('search_favorites'),
                    prefixIcon: Icon(Icons.search_rounded, size: 22),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            icon: Icon(Icons.close_rounded, size: 20),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            if (state.hasActiveFilter)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _activeFilterLabel(t),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.greenAccent,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () =>
                          ref.read(favoriteProvider.notifier).setFilter(),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Text(
                          t.translate('reset_filters'),
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Expanded(
              child: allFavorites.isEmpty
                  ? _buildEmpty(t, colors)
                  : filtered.isEmpty
                  ? _buildNoResults(t, colors)
                  : _buildGroupedList(grouped, colors, isDark, t),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    final provider = ref.read(favoriteProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _FilterSheet(
        moduleOptions: _uniqueValues(
          provider.favorites.map((f) => f.moduleName),
        ),
        activityOptions: _uniqueValues(
          provider.favorites.map((f) => f.activityName),
        ),
        seasonOptions: _uniqueValues(
          provider.favorites.map((f) => f.seasonName),
        ),
        initialModule: provider.filterModule,
        initialActivity: provider.filterActivity,
        initialSeason: provider.filterSeason,
        onApply: (module, activity, season) {
          ref
              .read(favoriteProvider.notifier)
              .setFilter(module: module, activity: activity, season: season);
        },
      ),
    );
  }

  List<String> _uniqueValues(Iterable<String> values) {
    return values.where((v) => v.isNotEmpty).toSet().toList()..sort();
  }

  Widget _buildEmpty(AppLocalizations t, ColorScheme colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.greenAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_rounded,
                size: 40,
                color: AppColors.greenAccent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t.translate('no_favorites_title'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              t.translate('no_favorites_message'),
              style: TextStyle(
                fontSize: 14,
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults(AppLocalizations t, ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.zoom_out_rounded,
            size: 48,
            color: colors.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Text(
            t.translate('no_results'),
            style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList(
    Map<String, List<FavoriteFile>> grouped,
    ColorScheme colors,
    bool isDark,
    AppLocalizations t,
  ) {
    final keys = grouped.keys.toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: keys.length,
      itemBuilder: (ctx, i) {
        final module = keys[i];
        final files = grouped[module]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 4,
                top: 12,
                bottom: 8,
              ),
              child: Text(
                module,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            ...files.map(
              (f) => _FavoriteTile(
                fav: f,
                isDark: isDark,
                colors: colors,
                onTap: () {
                  final localPath = DownloadService.getLocalPath(f.fileId);
                  if (localPath != null) {
                    Navigator.pushNamed(
                      context,
                      fileViewerScreenRoute,
                      arguments: {
                        'filePath': localPath,
                        'fileName': f.fileName,
                        'fileType': f.fileType,
                      },
                    );
                  }
                },
                onRemove: () =>
                    ref.read(favoriteProvider.notifier).remove(f.fileId),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FavoriteTile extends ConsumerWidget {
  final FavoriteFile fav;
  final bool isDark;
  final ColorScheme colors;
  final VoidCallback? onTap;
  final VoidCallback onRemove;

  const _FavoriteTile({
    required this.fav,
    required this.isDark,
    required this.colors,
    this.onTap,
    required this.onRemove,
  });

  Widget _iconButton({
    required Color bgColor,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: iconColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloaded = ref.watch(
      downloadProvider.select((p) => p.isDownloaded(fav.fileId)),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF5F5F5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: downloaded ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            fileColor(fav.fileType).withValues(alpha: 0.8),
                            fileColor(fav.fileType),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        fileIcon(fav.fileType),
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    if (downloaded)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2ED573),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fav.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: fileColor(
                                fav.fileType,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              fav.fileType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: fileColor(fav.fileType),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            fav.activityName,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (downloaded) ...[
                  _iconButton(
                    bgColor: AppColors.greenAccent.withValues(alpha: 0.1),
                    icon: Icons.open_in_new_rounded,
                    iconColor: AppColors.greenAccent,
                    onTap: () {
                      final localPath = DownloadService.getLocalPath(
                        fav.fileId,
                      );
                      if (localPath != null) OpenFilex.open(localPath);
                    },
                  ),
                  const SizedBox(width: 6),
                ],
                _iconButton(
                  bgColor: AppColors.greenAccent.withValues(alpha: 0.08),
                  icon: Icons.visibility_rounded,
                  iconColor: AppColors.greenAccent,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      lessonFilesScreenRoute,
                      arguments: {
                        'moduleId': fav.moduleId,
                        'moduleName': fav.moduleName,
                        'activityTypeId': fav.activityTypeId,
                        'activityTypeName': fav.activityName,
                        'seasonId': fav.seasonId,
                        'seasonName': fav.seasonName,
                        'semesterName': fav.semesterName,
                      },
                    );
                  },
                ),
                const SizedBox(width: 6),
                _iconButton(
                  bgColor: errorColor.withValues(alpha: 0.1),
                  icon: Icons.delete_outline_rounded,
                  iconColor: errorColor,
                  onTap: onRemove,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final List<String> moduleOptions;
  final List<String> activityOptions;
  final List<String> seasonOptions;
  final String initialModule;
  final String initialActivity;
  final String initialSeason;
  final void Function(String module, String activity, String season) onApply;

  const _FilterSheet({
    required this.moduleOptions,
    required this.activityOptions,
    required this.seasonOptions,
    required this.initialModule,
    required this.initialActivity,
    required this.initialSeason,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _module;
  late String _activity;
  late String _season;

  @override
  void initState() {
    super.initState();
    _module = widget.initialModule;
    _activity = widget.initialActivity;
    _season = widget.initialSeason;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.translate('filter'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildDropdown(
              label: t.translate('module'),
              value: _module,
              options: widget.moduleOptions,
              allLabel: t.translate('all'),
              onChanged: (v) => setState(() => _module = v),
            ),
            _buildDropdown(
              label: t.translate('activity_type'),
              value: _activity,
              options: widget.activityOptions,
              allLabel: t.translate('all'),
              onChanged: (v) => setState(() => _activity = v),
            ),
            _buildDropdown(
              label: t.translate('season'),
              value: _season,
              options: widget.seasonOptions,
              allLabel: t.translate('all'),
              onChanged: (v) => setState(() => _season = v),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onApply('', '', '');
                      Navigator.pop(context);
                    },
                    child: Text(t.translate('reset_filters')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.greenAccent,
                    ),
                    onPressed: () {
                      widget.onApply(_module, _activity, _season);
                      Navigator.pop(context);
                    },
                    child: Text(t.translate('apply')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> options,
    required String allLabel,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value.isEmpty ? '' : value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        items: [
          DropdownMenuItem(value: '', child: Text(allLabel)),
          ...options.map(
            (o) => DropdownMenuItem(
              value: o,
              child: Text(o, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: (v) => onChanged(v ?? ''),
      ),
    );
  }
}
