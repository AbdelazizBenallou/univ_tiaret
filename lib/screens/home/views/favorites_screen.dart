import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/logic/download_provider.dart';
import 'package:univ_tiaret/logic/favorite_provider.dart';
import 'package:univ_tiaret/models/favorite_file.dart';
import 'package:univ_tiaret/route/route_constants.dart';
import 'package:univ_tiaret/services/download_service.dart';
import 'package:univ_tiaret/utils/file_utils.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  String _selectedModule = '';
  String _searchQuery = '';
  bool _showSearch = false;
  bool _showFilter = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(favoriteProvider.notifier).init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FavoriteFile> _getFiltered(List<FavoriteFile> items) {
    var result = items.toList();
    if (_selectedModule.isNotEmpty) {
      result = result.where((f) => f.moduleName == _selectedModule).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((f) => f.fileName.toLowerCase().contains(q)).toList();
    }
    return result;
  }

  List<String> _getModules(List<FavoriteFile> items) {
    return items.map((f) => f.moduleName).toSet().toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(favoriteProvider);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allFavorites = state.favorites;
    final modules = _getModules(allFavorites);
    final filtered = _getFiltered(allFavorites);

    final grouped = <String, List<FavoriteFile>>{};
    for (final f in filtered) {
      grouped.putIfAbsent(f.moduleName.isEmpty ? t.translate('other') : f.moduleName, () => []).add(f);
    }

    return Container(
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
                  onPressed: () => setState(() => _showFilter = !_showFilter),
                  icon: Icon(
                    Icons.filter_list_rounded,
                    size: 22,
                    color: _showFilter ? AppColors.greenAccent : null,
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          if (_showFilter)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip('', t.translate('all'), colors, isDark),
                  const SizedBox(width: 8),
                  ...modules.map((m) => Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: _buildFilterChip(m, m, colors, isDark),
                  )),
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
    );
  }

  Widget _buildFilterChip(String value, String label, ColorScheme colors, bool isDark) {
    final selected = _selectedModule == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _selectedModule = value),
      selectedColor: AppColors.greenAccent.withValues(alpha: 0.15),
      checkmarkColor: AppColors.greenAccent,
      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F5),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        color: selected ? AppColors.greenAccent : colors.onSurface.withValues(alpha: 0.6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
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
              child: Icon(Icons.bookmark_rounded, size: 40, color: AppColors.greenAccent),
            ),
            const SizedBox(height: 20),
            Text(
              t.translate('no_favorites_title'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              t.translate('no_favorites_message'),
              style: TextStyle(fontSize: 14, color: colors.onSurface.withValues(alpha: 0.5)),
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
          Icon(Icons.zoom_out_rounded, size: 48, color: colors.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(t.translate('no_results'), style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5))),
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
              padding: const EdgeInsetsDirectional.only(start: 4, top: 12, bottom: 8),
              child: Text(
                module,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            ...files.map((f) => _FavoriteTile(
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
                  onRemove: () => ref.read(favoriteProvider.notifier).remove(f.fileId),
                )),
          ],
        );
      },
    );
  }
}

class _FavoriteTile extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<_FavoriteTile> createState() => _FavoriteTileState();
}

class _FavoriteTileState extends ConsumerState<_FavoriteTile> {
  bool _showActions = false;

  void _navigateToLessonPage() {
    Navigator.pushNamed(
      context,
      lessonFilesScreenRoute,
      arguments: {
        'moduleId': widget.fav.moduleId,
        'moduleName': widget.fav.moduleName,
        'activityTypeId': widget.fav.activityTypeId,
        'activityTypeName': widget.fav.activityName,
        'seasonId': widget.fav.seasonId,
        'seasonName': widget.fav.seasonName,
        'semesterName': widget.fav.semesterName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final downloaded = ref.watch(downloadProvider.select((p) => p.isDownloaded(widget.fav.fileId)));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: downloaded ? widget.onTap : null,
          onLongPress: () => setState(() => _showActions = !_showActions),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        fileColor(widget.fav.fileType).withValues(alpha: 0.8),
                        fileColor(widget.fav.fileType),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(fileIcon(widget.fav.fileType), size: 20, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.fav.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: widget.colors.onSurface),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: fileColor(widget.fav.fileType).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.fav.fileType.toUpperCase(),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fileColor(widget.fav.fileType)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.fav.activityName,
                            style: TextStyle(fontSize: 11, color: widget.colors.onSurface.withValues(alpha: 0.4)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_showActions && downloaded)
                  GestureDetector(
                    onTap: _navigateToLessonPage,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.greenAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.visibility_rounded, size: 18, color: AppColors.greenAccent),
                    ),
                  ),
                if (_showActions && downloaded) const SizedBox(width: 6),
                GestureDetector(
                  onTap: widget.onRemove,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.delete_rounded, size: 18, color: errorColor),
                  ),
                ),
                if (downloaded) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
