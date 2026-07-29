import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import 'package:univ_tiaret/components/breadcrumb_bar.dart';
import 'package:univ_tiaret/components/floating_snackbar.dart';
import 'package:univ_tiaret/components/skeleton_tile.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/logic/download_provider.dart';
import 'package:univ_tiaret/logic/favorite_provider.dart';
import 'package:univ_tiaret/logic/lesson_files_provider.dart';
import 'package:univ_tiaret/models/favorite_file.dart';
import 'package:univ_tiaret/models/lesson_file.dart';
import 'package:univ_tiaret/providers/navigation_provider.dart';
import 'package:univ_tiaret/services/api_service.dart';
import 'package:univ_tiaret/services/download_service.dart';
import 'package:univ_tiaret/route/route_constants.dart';
import 'package:univ_tiaret/utils/file_utils.dart';
import 'package:univ_tiaret/widgets/app_bottom_nav.dart';
import 'package:univ_tiaret/widgets/sort_bottom_sheet.dart';

enum FileSortOption { dateNewest, dateOldest, nameAZ, nameZA }

class LessonFilesScreen extends ConsumerStatefulWidget {
  final int moduleId;
  final String moduleName;
  final int activityTypeId;
  final String activityTypeName;
  final int seasonId;
  final String seasonName;
  final String semesterName;

  const LessonFilesScreen({
    super.key,
    required this.moduleId,
    required this.moduleName,
    required this.activityTypeId,
    required this.activityTypeName,
    required this.seasonId,
    required this.seasonName,
    required this.semesterName,
  });

  @override
  ConsumerState<LessonFilesScreen> createState() => _LessonFilesScreenState();
}

class _LessonFilesScreenState extends ConsumerState<LessonFilesScreen> {
  bool _showSearch = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  FileSortOption _sortOption = FileSortOption.dateNewest;
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};
  final ScrollController _scrollController = ScrollController();
  final Set<int> _preparingDownloads = {};
  bool _lastFromCache = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    ref.read(downloadProvider.notifier).init();
    ref.read(favoriteProvider.notifier).init();
    Future.microtask(() => ref.read(lessonFilesProvider.notifier).fetchFiles(
          moduleId: widget.moduleId,
          activityTypeId: widget.activityTypeId,
          seasonId: widget.seasonId,
        ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _checkScrollAfterCache() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _onScroll();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      final notifier = ref.read(lessonFilesProvider.notifier);
      final s = notifier.state;
      if (s.status == LessonFilesStatus.loaded && s.page < s.totalPages) {
        notifier.loadNextPage(
          moduleId: widget.moduleId,
          activityTypeId: widget.activityTypeId,
          seasonId: widget.seasonId,
        );
      }
    }
  }

  List<LessonFile> _getFilteredAndSorted(List<LessonFile> files) {
    var result = files;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((f) =>
              f.name.toLowerCase().contains(q) ||
              f.description.toLowerCase().contains(q) ||
              f.fileType.toLowerCase().contains(q))
          .toList();
    }

    result.sort((a, b) {
      switch (_sortOption) {
        case FileSortOption.dateNewest:
          return b.uploadedAt.compareTo(a.uploadedAt);
        case FileSortOption.dateOldest:
          return a.uploadedAt.compareTo(b.uploadedAt);
        case FileSortOption.nameAZ:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case FileSortOption.nameZA:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
      }
    });

    return result;
  }

  Future<void> _showSortMenu() async {
    final t = AppLocalizations.of(context);
    final result = await showSortBottomSheet<FileSortOption>(
      context: context,
      title: t.translate('sort_by'),
      currentValue: _sortOption,
      options: [
        SortOption(value: FileSortOption.dateNewest, label: t.translate('sort_newest'), icon: Icons.access_time_rounded),
        SortOption(value: FileSortOption.dateOldest, label: t.translate('sort_oldest'), icon: Icons.history_rounded),
        SortOption(value: FileSortOption.nameAZ, label: t.translate('sort_name_az'), icon: Icons.arrow_downward_rounded),
        SortOption(value: FileSortOption.nameZA, label: t.translate('sort_name_za'), icon: Icons.arrow_upward_rounded),
      ],
    );
    if (result != null && mounted) {
      setState(() => _sortOption = result);
    }
  }

  void _enterSelection(int fileId) {
    setState(() {
      _selectionMode = true;
      _selectedIds.clear();
      _selectedIds.add(fileId);
    });
  }

  void _toggleSelection(int fileId) {
    setState(() {
      if (_selectedIds.contains(fileId)) {
        _selectedIds.remove(fileId);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(fileId);
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete files'),
        content: Text('Delete ${_selectedIds.length} files from your downloads?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: errorColor)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final dp = ref.read(downloadProvider.notifier);
    for (final id in _selectedIds) {
      dp.deleteDownload(id);
    }
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(lessonFilesProvider).state;
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!state.fromCache && _lastFromCache && state.files.isNotEmpty) {
      _lastFromCache = false;
      _checkScrollAfterCache();
    } else {
      _lastFromCache = state.fromCache;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activityTypeName),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, 'downloads');
            },
            icon: Icon(
              Icons.download_rounded,
              size: 24,
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
              size: 24,
            ),
          ),
          IconButton(
            onPressed: _showSortMenu,
            icon: Icon(Icons.filter_list_rounded, size: 24),
          ),
        ],
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
              BreadcrumbItem(
                label: widget.moduleName,
                onTap: () => Navigator.pop(context),
              ),
              BreadcrumbItem(label: widget.activityTypeName),
            ],
          ),
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: t.translate('search_files'),
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          Expanded(
            child: _buildBody(state, t, colors, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    LessonFilesState state,
    AppLocalizations t,
    ColorScheme colors,
    bool isDark,
  ) {
    switch (state.status) {
      case LessonFilesStatus.initial:
      case LessonFilesStatus.loading:
        return state.files.isEmpty
            ? const SkeletonList()
            : _buildFileList(state, t, colors, isDark);

      case LessonFilesStatus.noSubscription:
        return _buildNoSubscription(t, colors, isDark);

      case LessonFilesStatus.error:
        return _buildError(state.error ?? 'err_network', t);

      case LessonFilesStatus.loadingMore:
      case LessonFilesStatus.loaded:
        if (state.files.isEmpty) {
          return _buildEmpty(t, colors);
        }
        return _buildFileList(state, t, colors, isDark);
    }
  }

  Widget _buildNoSubscription(
      AppLocalizations t, ColorScheme colors, bool isDark) {
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
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_rounded,
                size: 40,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t.translate('no_subscription_title'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              t.translate('no_subscription_message'),
              style: TextStyle(
                fontSize: 14,
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  t.translate('subscribe_now'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
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
                onPressed: () =>
                    ref.read(lessonFilesProvider.notifier).fetchFiles(
                          moduleId: widget.moduleId,
                          activityTypeId: widget.activityTypeId,
                          seasonId: widget.seasonId,
                        ),
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

  Widget _buildEmpty(AppLocalizations t, ColorScheme colors) {
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
                color: colors.onSurface.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 36,
                color: colors.onSurface.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t.translate('no_files'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileList(
    LessonFilesState state,
    AppLocalizations t,
    ColorScheme colors,
    bool isDark,
  ) {
    final filtered = _getFilteredAndSorted(state.files);
    final isLoadingMore = state.status == LessonFilesStatus.loadingMore;
    final dlNotifier = ref.read(downloadProvider.notifier);

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(lessonFilesProvider.notifier).fetchFiles(
                  moduleId: widget.moduleId,
                  activityTypeId: widget.activityTypeId,
                  seasonId: widget.seasonId,
                ),
            child: filtered.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.1,
                      ),
                      Center(
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
                              style: TextStyle(
                                color:
                                    colors.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : _buildFlatList(filtered, dlNotifier, isDark, colors),
          ),
        ),
        if (_selectionMode)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF5F5F5),
              border: Border(
                top: BorderSide(
                  color: colors.onSurface.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _cancelSelection,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: errorColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_selectedIds.length} selected',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _deleteSelected,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_rounded,
                          size: 24,
                          color: errorColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: errorColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFlatList(
    List<LessonFile> filtered,
    dynamic dlNotifier,
    bool isDark,
    ColorScheme colors,
  ) {
    return ListView.builder(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final file = filtered[index];
        final isDownloaded = dlNotifier.isDownloaded(file.id);
        final isActive = dlNotifier.isActive(file.id);
        final isPreparing = _preparingDownloads.contains(file.id);
        return _FileTile(
          file: file,
          isDark: isDark,
          colors: colors,
          isDownloaded: isDownloaded,
          isActive: isActive,
          isPreparing: isPreparing,
          isSelected: _selectedIds.contains(file.id),
          selectionMode: _selectionMode,
          onTap: _selectionMode
              ? (isDownloaded ? () => _toggleSelection(file.id) : null)
              : () => _onTapFile(file),
          onLongPress: isDownloaded ? () => _enterSelection(file.id) : null,
          onDownload: () => _onDownload(file),
          moduleName: widget.moduleName,
          activityName: widget.activityTypeName,
          moduleId: widget.moduleId,
          seasonId: widget.seasonId,
          seasonName: widget.seasonName,
          semesterName: widget.semesterName,
          activityTypeId: widget.activityTypeId,
        );
      },
    );
  }

  void _onTapFile(LessonFile file) {
    final dp = ref.read(downloadProvider.notifier);
    if (!dp.isDownloaded(file.id)) return;

    final localPath = DownloadService.getLocalPath(file.id);
    if (localPath == null) return;

    Navigator.pushNamed(
      context,
      fileViewerScreenRoute,
      arguments: {
        'filePath': localPath,
        'fileName': file.name,
        'fileType': file.fileType,
      },
    );
  }

  Future<void> _onDownload(LessonFile file) async {
    if (_preparingDownloads.contains(file.id)) return;
    final dp = ref.read(downloadProvider.notifier);
    if (dp.isDownloaded(file.id)) return;
    if (dp.isActive(file.id)) return;

    setState(() => _preparingDownloads.add(file.id));
    final t = AppLocalizations.of(context);

    showFloatingSnackBar(
      context,
      message: '${t.translate('preparing')}: ${file.name}',
      type: SnackBarType.info,
    );

    try {
      final response = await ApiService.get(
        '/v1/lesson-files/${file.id}/download',
      );

      if (!mounted) return;

      if (response['success'] == true) {
        final data = response['data'];
        final downloadUrl = data['download_url'] as String?;
        if (downloadUrl != null) {
          await dp.downloadFile(
            id: file.id,
            name: file.name,
            fileType: file.fileType,
            downloadUrl: downloadUrl,
            seasonName: widget.seasonName,
            semesterName: widget.semesterName,
            moduleName: widget.moduleName,
            activityName: widget.activityTypeName,
          );
          if (mounted) {
            showFloatingSnackBar(
              context,
              message: '${file.name} ${t.translate('queued')}',
              type: SnackBarType.success,
            );
          }
        }
      } else {
        if (mounted) {
          showFloatingSnackBar(
            context,
            message: t.translate('err_download_failed'),
            type: SnackBarType.error,
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _preparingDownloads.remove(file.id));
      }
    }
  }
}

class _FileTile extends ConsumerWidget {
  final LessonFile file;
  final bool isDark;
  final ColorScheme colors;
  final bool isDownloaded;
  final bool isActive;
  final bool isPreparing;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onDownload;
  final String moduleName;
  final String activityName;
  final int moduleId;
  final int seasonId;
  final String seasonName;
  final String semesterName;
  final int activityTypeId;

  const _FileTile({
    required this.file,
    required this.isDark,
    required this.colors,
    required this.isDownloaded,
    required this.isActive,
    required this.onTap,
    required this.onDownload,
    required this.moduleName,
    required this.activityName,
    required this.moduleId,
    required this.seasonId,
    required this.seasonName,
    required this.semesterName,
    required this.activityTypeId,
    this.isPreparing = false,
    this.isSelected = false,
    this.selectionMode = false,
    this.onLongPress,
  });

  void _showFileMenu(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isDownloaded)
                ListTile(
                  leading: Icon(Icons.download_rounded, color: AppColors.greenAccent),
                  title: Text(t.translate('download')),
                  onTap: () {
                    Navigator.pop(ctx);
                    onDownload();
                  },
                ),
              if (isDownloaded) ...[
                ListTile(
                  leading: Icon(Icons.open_in_new_rounded, color: AppColors.greenAccent),
                  title: Text(t.translate('open_external')),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openExternal();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_rounded, color: errorColor),
                  title: Text(t.translate('delete')),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDelete(context, ref);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openExternal() {
    final localPath = DownloadService.getLocalPath(file.id);
    if (localPath != null) {
      OpenFilex.open(localPath);
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context).translate('delete_file')),
        content: Text(AppLocalizations.of(context).translate('delete_file_confirm').replaceAll('{name}', file.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(downloadProvider.notifier).deleteDownload(file.id);
            },
            child: Text(AppLocalizations.of(context).translate('delete'), style: TextStyle(color: errorColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = _formatDate(file.uploadedAt);

    final dlSignature = ref.watch(downloadProvider.select((p) {
      final isDone = p.isDownloaded(file.id);
      final active = p.isActive(file.id);
      if (isDone) return 'done';
      if (!active) return 'idle';
      final item = p.items.firstWhere(
        (i) => i.id == file.id,
        orElse: () => DownloadItem(id: -1, name: '', fileType: '', downloadUrl: ''),
      );
      return 'active:${(item.progress * 100).toInt()}';
    }));

    final currentIsDownloaded = dlSignature == 'done';
    final isFav = ref.watch(favoriteProvider.select((p) => p.isFavorited(file.id)));

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.greenAccent.withValues(alpha: 0.1)
              : isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: currentIsDownloaded ? onTap : null,
          onLongPress: onLongPress,
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
                        fileColor(file.fileType).withValues(alpha: 0.8),
                        fileColor(file.fileType),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(fileIcon(file.fileType), size: 20, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: fileColor(file.fileType).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              file.fileType.toUpperCase(),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fileColor(file.fileType)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              moduleName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: colors.onSurface.withValues(alpha: 0.45)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            date,
                            style: TextStyle(fontSize: 10, color: colors.onSurface.withValues(alpha: 0.35)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!selectionMode) ...[
                  GestureDetector(
                    onTap: () {
                      final fp = ref.read(favoriteProvider.notifier);
                      if (isFav) {
                        fp.remove(file.id);
                      } else {
                        fp.add(FavoriteFile(
                          fileId: file.id,
                          fileName: file.name,
                          fileType: file.fileType,
                          fileUrl: file.url,
                          moduleId: moduleId,
                          moduleName: moduleName,
                          seasonId: seasonId,
                          seasonName: seasonName,
                          semesterName: semesterName,
                          activityTypeId: activityTypeId,
                          activityName: activityName,
                        ));
                      }
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isFav
                            ? const Color(0xFFFFBE21).withValues(alpha: 0.15)
                            : colors.onSurface.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        size: 18,
                        color: isFav
                            ? const Color(0xFFFFBE21)
                            : colors.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _showFileMenu(context, ref),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.onSurface.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.more_vert_rounded, size: 18, color: colors.onSurface.withValues(alpha: 0.4)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
