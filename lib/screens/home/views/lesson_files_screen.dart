import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/components/breadcrumb_bar.dart';
import 'package:univ_tiaret/components/floating_snackbar.dart';
import 'package:univ_tiaret/components/skeleton_tile.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/logic/download_provider.dart';
import 'package:univ_tiaret/logic/lesson_files_provider.dart';
import 'package:univ_tiaret/models/lesson_file.dart';
import 'package:univ_tiaret/services/api_service.dart';
import 'package:univ_tiaret/services/download_service.dart';
import 'package:univ_tiaret/route/route_constants.dart';
import 'package:univ_tiaret/utils/file_utils.dart';

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
  bool _isLoadingNextPage = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    ref.read(downloadProvider.notifier).init();
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

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingNextPage) {
        final notifier = ref.read(lessonFilesProvider.notifier);
        final state = notifier.state;
        if (state.status == LessonFilesStatus.loaded &&
            state.page < state.totalPages) {
          _isLoadingNextPage = true;
          notifier.loadNextPage(
            moduleId: widget.moduleId,
            activityTypeId: widget.activityTypeId,
            seasonId: widget.seasonId,
          ).then((_) {
            _isLoadingNextPage = false;
            _onScroll();
          });
        }
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activityTypeName),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, 'downloads');
            },
            icon: const Icon(
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
          PopupMenuButton<FileSortOption>(
            onSelected: (value) => setState(() => _sortOption = value),
            icon: const Icon(Icons.sort_rounded, size: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: FileSortOption.dateNewest,
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 20,
                      color: _sortOption == FileSortOption.dateNewest
                          ? primaryColor
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      t.translate('sort_newest'),
                      style: TextStyle(
                        color: _sortOption == FileSortOption.dateNewest
                            ? primaryColor
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: FileSortOption.dateOldest,
                child: Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 20,
                      color: _sortOption == FileSortOption.dateOldest
                          ? primaryColor
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      t.translate('sort_oldest'),
                      style: TextStyle(
                        color: _sortOption == FileSortOption.dateOldest
                            ? primaryColor
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: FileSortOption.nameAZ,
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha_rounded,
                      size: 20,
                      color: _sortOption == FileSortOption.nameAZ
                          ? primaryColor
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      t.translate('sort_name_az'),
                      style: TextStyle(
                        color: _sortOption == FileSortOption.nameAZ
                            ? primaryColor
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: FileSortOption.nameZA,
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha_rounded,
                      size: 20,
                      color: _sortOption == FileSortOption.nameZA
                          ? primaryColor
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      t.translate('sort_name_za'),
                      style: TextStyle(
                        color: _sortOption == FileSortOption.nameZA
                            ? primaryColor
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
                  prefixIcon: const Icon(Icons.search_rounded, size: 22),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.clear_rounded, size: 20),
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
        return const SkeletonList();

      case LessonFilesStatus.noSubscription:
        return _buildNoSubscription(t, colors, isDark);

      case LessonFilesStatus.error:
        return _buildError(state.error ?? 'err_network', t);

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
                Icons.lock_outline_rounded,
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
            onPressed: () =>
                ref.read(lessonFilesProvider.notifier).fetchFiles(
                      moduleId: widget.moduleId,
                      activityTypeId: widget.activityTypeId,
                      seasonId: widget.seasonId,
                    ),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(t.translate('try_again')),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations t, ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_off_rounded,
            size: 48,
            color: colors.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Text(
            t.translate('no_files'),
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
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
    final isLoadingMore = state.status == LessonFilesStatus.loading &&
        state.files.isNotEmpty;
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
                              Icons.search_off_rounded,
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
                          Icons.delete_outline_rounded,
                          size: 18,
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
    return ListView.separated(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 8),
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
        );
      },
    ),
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

    showFloatingSnackBar(
      context,
      message: 'Preparing: ${file.name}',
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
              message: '${file.name} queued',
              type: SnackBarType.success,
            );
          }
        }
      } else {
        if (mounted) {
          showFloatingSnackBar(
            context,
            message: response['message'] ?? 'Download failed',
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

  const _FileTile({
    required this.file,
    required this.isDark,
    required this.colors,
    required this.isDownloaded,
    required this.isActive,
    required this.onTap,
    required this.onDownload,
    this.isPreparing = false,
    this.isSelected = false,
    this.selectionMode = false,
    this.onLongPress,
  });

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
    final currentIsActive = dlSignature.startsWith('active:');

    return Material(
      color: isSelected
          ? AppColors.greenAccent.withValues(alpha: 0.1)
          : isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFF5F5F5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: AppColors.greenAccent.withValues(alpha: 0.4), width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isDownloaded ? onTap : null,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              if (selectionMode && isDownloaded)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 22,
                    color: isSelected
                        ? AppColors.greenAccent
                        : colors.onSurface.withValues(alpha: 0.3),
                  ),
                ),
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
                child: Icon(
                  fileIcon(file.fileType),
                  size: 20,
                  color: Colors.white,
                ),
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
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: fileColor(file.fileType)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            file.fileType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: fileColor(file.fileType),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          date,
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
              const SizedBox(width: 8),
              if (!selectionMode) ...[
                if (currentIsDownloaded)
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text('Delete file'),
                          content: Text('Delete "${file.name}" from your downloads?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                ref.read(downloadProvider.notifier).deleteDownload(file.id);
                              },
                              child: Text('Delete', style: TextStyle(color: errorColor)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: errorColor,
                      ),
                    ),
                  ),
                if (currentIsDownloaded) const SizedBox(width: 6),
                GestureDetector(
                  onTap: (currentIsActive || isPreparing) ? null : (currentIsDownloaded ? onTap : onDownload),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: currentIsDownloaded
                          ? AppColors.success.withValues(alpha: 0.1)
                          : currentIsActive || isPreparing
                              ? AppColors.warning.withValues(alpha: 0.1)
                              : AppColors.greenAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isPreparing
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.warning,
                            ),
                          )
                        : Icon(
                            currentIsDownloaded
                                ? Icons.check_circle_rounded
                                : currentIsActive
                                    ? Icons.hourglass_top_rounded
                                    : Icons.download_rounded,
                            size: 20,
                            color: currentIsDownloaded
                                ? AppColors.success
                                : currentIsActive
                                    ? AppColors.warning
                                    : AppColors.greenAccent,
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

}
