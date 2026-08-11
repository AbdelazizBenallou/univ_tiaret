import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:univ_tiaret/components/subscription_guard.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/logic/download_provider.dart';
import 'package:univ_tiaret/route/route_constants.dart';
import 'package:univ_tiaret/services/download_service.dart';
import 'package:univ_tiaret/utils/file_utils.dart';

enum _DateFilter { all, today, thisWeek, thisMonth, older }

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  bool _showSearch = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  _DateFilter _dateFilter = _DateFilter.all;
  String? _selectedModule;
  String? _selectedType;
  String? _selectedFileType;

  bool get _hasActiveFilter =>
      _selectedModule != null ||
      _selectedType != null ||
      _selectedFileType != null ||
      _dateFilter != _DateFilter.all;

  @override
  void initState() {
    super.initState();
    ref.read(downloadProvider.notifier).init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DownloadItem> _filtered(List<DownloadItem> items) {
    var result = items
        .where((i) => i.status == DownloadStatus.completed)
        .toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where(
            (i) =>
                i.name.toLowerCase().contains(q) ||
                i.moduleName.toLowerCase().contains(q) ||
                i.activityName.toLowerCase().contains(q),
          )
          .toList();
    }

    if (_selectedModule != null) {
      result = result.where((i) => i.moduleName == _selectedModule).toList();
    }
    if (_selectedType != null) {
      result = result.where((i) => i.activityName == _selectedType).toList();
    }
    if (_selectedFileType != null) {
      result = result
          .where(
            (i) => i.fileType.toLowerCase() == _selectedFileType!.toLowerCase(),
          )
          .toList();
    }
    if (_dateFilter != _DateFilter.all) {
      result = _filterByDate(result);
    }

    return result;
  }

  List<DownloadItem> _filterByDate(List<DownloadItem> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_dateFilter) {
      case _DateFilter.today:
        return items.where((i) {
          final d = i.completedAt;
          if (d == null) return false;
          return d.isAfter(today);
        }).toList();
      case _DateFilter.thisWeek:
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return items.where((i) {
          final d = i.completedAt;
          if (d == null) return false;
          return d.isAfter(weekStart);
        }).toList();
      case _DateFilter.thisMonth:
        final monthStart = DateTime(now.year, now.month, 1);
        return items.where((i) {
          final d = i.completedAt;
          if (d == null) return false;
          return d.isAfter(monthStart);
        }).toList();
      case _DateFilter.older:
        final monthStart = DateTime(now.year, now.month, 1);
        return items.where((i) {
          final d = i.completedAt;
          if (d == null) return false;
          return d.isBefore(monthStart);
        }).toList();
      case _DateFilter.all:
        return items;
    }
  }

  List<String> _uniqueValues(Iterable<String> values) {
    return values.where((v) => v.isNotEmpty).toSet().toList()..sort();
  }

  void _showFilterSheet() {
    final items = ref
        .read(downloadProvider)
        .items
        .where((i) => i.status == DownloadStatus.completed)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _FilterSheet(
        moduleOptions: _uniqueValues(items.map((i) => i.moduleName)),
        activityOptions: _uniqueValues(items.map((i) => i.activityName)),
        fileTypeOptions: const ['pdf', 'docx', 'pptx', 'xlsx', 'jpg', 'png'],
        initialModule: _selectedModule ?? '',
        initialActivity: _selectedType ?? '',
        initialFileType: _selectedFileType ?? '',
        initialDate: _dateFilter,
        onApply: (module, activity, fileType, date) {
          setState(() {
            _selectedModule = module.isEmpty ? null : module;
            _selectedType = activity.isEmpty ? null : activity;
            _selectedFileType = fileType.isEmpty ? null : fileType;
            _dateFilter = date;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final dlState = ref.watch(downloadProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeItems = dlState.items
        .where(
          (i) =>
              i.status == DownloadStatus.downloading ||
              i.status == DownloadStatus.queued,
        )
        .toList();

    final allCompleted = dlState.items
        .where((i) => i.status == DownloadStatus.completed)
        .toList();

    final filteredCompleted = _filtered(allCompleted);
    final totalCount = allCompleted.length;
    final activeCount = activeItems.length;

    final hasItems = activeItems.isNotEmpty || filteredCompleted.isNotEmpty;

    Map<String, List<DownloadItem>> grouped = {};
    if (_selectedModule == null) {
      for (final item in filteredCompleted) {
        final key = item.moduleName.isNotEmpty
            ? item.moduleName
            : t.translate('other');
        grouped.putIfAbsent(key, () => []).add(item);
      }
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.translate('downloads'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        if (totalCount > 0)
                          Text(
                            '$totalCount ${t.translate('files')}${activeCount > 0 ? '  ·  $activeCount ${t.translate('in_progress')}' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (hasItems) ...[
                    IconButton(
                      onPressed: _showFilterSheet,
                      icon: Icon(
                        Icons.filter_list_rounded,
                        size: 22,
                        color: _hasActiveFilter ? primaryColor : null,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showSearch = !_showSearch;
                          if (!_showSearch) {
                            _searchController.clear();
                            _searchQuery = '';
                          }
                        });
                      },
                      icon: Icon(
                        _showSearch
                            ? Icons.close_rounded
                            : Icons.search_rounded,
                        size: 22,
                      ),
                    ),
                  ],
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
                    hintText: t.translate('search_downloads'),
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
            if (_hasActiveFilter)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _showFilterSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_list_rounded,
                              size: 14,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _activeFilterLabel(t),
                              style: TextStyle(
                                fontSize: 12,
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          _selectedModule = null;
                          _selectedType = null;
                          _selectedFileType = null;
                          _dateFilter = _DateFilter.all;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
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
            Expanded(
              child: hasItems
                  ? RefreshIndicator(
                      onRefresh: () async {
                        ref.read(downloadProvider.notifier).init();
                      },
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                        children: [
                          if (activeItems.isNotEmpty) ...[
                            _sectionHeader(
                              t.translate('in_progress'),
                              '$activeCount ${t.translate('files')}',
                              colors,
                            ),
                            const SizedBox(height: 8),
                            ...activeItems.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _ActiveDownloadTile(
                                  item: item,
                                  colors: colors,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (filteredCompleted.isNotEmpty) ...[
                            _sectionHeader(
                              t.translate('completed'),
                              '${filteredCompleted.length} ${t.translate('files')}',
                              colors,
                            ),
                            const SizedBox(height: 8),
                            if (_selectedModule == null)
                              ...grouped.entries.map(
                                (entry) => _ModuleGroup(
                                  moduleName: entry.key,
                                  files: entry.value,
                                  isDark: isDark,
                                  colors: colors,
                                ),
                              )
                            else
                              ...filteredCompleted.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _DownloadedFileTile(
                                    item: item,
                                    isDark: isDark,
                                    colors: colors,
                                    onTap: item.localPath != null
                                        ? () => Navigator.pushNamed(
                                            context,
                                            fileViewerScreenRoute,
                                            arguments: {
                                              'filePath': item.localPath,
                                              'fileName': item.name,
                                              'fileType': item.fileType,
                                            },
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    )
                  : _buildEmpty(t, colors),
            ),
          ],
        ),
      ),
    );
  }

  String _activeFilterLabel(AppLocalizations t) {
    final parts = <String>[];
    if (_selectedModule != null) {
      parts.add('${t.translate('module')}: $_selectedModule');
    }
    if (_selectedType != null) {
      parts.add('${t.translate('activity_type')}: $_selectedType');
    }
    if (_selectedFileType != null) {
      parts.add(
        '${t.translate('file_type')}: ${_selectedFileType!.toUpperCase()}',
      );
    }
    switch (_dateFilter) {
      case _DateFilter.all:
        break;
      case _DateFilter.today:
        parts.add(t.translate('today'));
        break;
      case _DateFilter.thisWeek:
        parts.add(t.translate('this_week'));
        break;
      case _DateFilter.thisMonth:
        parts.add(t.translate('this_month'));
        break;
      case _DateFilter.older:
        parts.add(t.translate('older'));
        break;
    }
    return parts.join(' · ');
  }

  Widget _sectionHeader(String title, String subtitle, ColorScheme colors) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colors.onSurface.withValues(alpha: 0.5),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: colors.onSurface.withValues(alpha: 0.3),
          ),
        ),
      ],
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
                Icons.download_rounded,
                size: 36,
                color: colors.onSurface.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t.translate('no_downloads'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t.translate('no_downloads_hint'),
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveDownloadTile extends ConsumerWidget {
  final DownloadItem item;
  final ColorScheme colors;
  final bool isDark;

  const _ActiveDownloadTile({
    required this.item,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(
      downloadProvider.select((p) {
        final it = p.items.firstWhere(
          (i) => i.id == item.id,
          orElse: () => item,
        );
        return it.progress;
      }),
    );

    final speed = ref.watch(
      downloadProvider.select((p) {
        final it = p.items.firstWhere(
          (i) => i.id == item.id,
          orElse: () => item,
        );
        return it.speed;
      }),
    );

    final speedText = speed < 1024
        ? '${speed.toStringAsFixed(0)} B/s'
        : speed < 1048576
        ? '${(speed / 1024).toStringAsFixed(1)} KB/s'
        : '${(speed / 1048576).toStringAsFixed(1)} MB/s';

    final progressPercent = (progress * 100).toInt();

    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : const Color(0xFFF5F5F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        fileColor(item.fileType).withValues(alpha: 0.8),
                        fileColor(item.fileType),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    fileIcon(item.fileType),
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
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$progressPercent%  ·  $speedText',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 3,
                            backgroundColor: colors.onSurface.withValues(
                              alpha: 0.08,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              fileColor(item.fileType),
                            ),
                          ),
                          Icon(
                            Icons.hourglass_bottom_rounded,
                            size: 16,
                            color: fileColor(item.fileType),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => ref
                          .read(downloadProvider.notifier)
                          .cancelDownload(item.id),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: errorColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: errorColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: colors.onSurface.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      fileColor(item.fileType).withValues(alpha: 0.7),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleGroup extends StatelessWidget {
  final String moduleName;
  final List<DownloadItem> files;
  final bool isDark;
  final ColorScheme colors;

  const _ModuleGroup({
    required this.moduleName,
    required this.files,
    required this.isDark,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.book_rounded, size: 16, color: primaryColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  moduleName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${files.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...files.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _DownloadedFileTile(
                item: item,
                isDark: isDark,
                colors: colors,
                compact: true,
                onTap: item.localPath != null
                    ? () => Navigator.pushNamed(
                        context,
                        fileViewerScreenRoute,
                        arguments: {
                          'filePath': item.localPath,
                          'fileName': item.name,
                          'fileType': item.fileType,
                        },
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadedFileTile extends ConsumerWidget {
  final DownloadItem item;
  final bool isDark;
  final ColorScheme colors;
  final VoidCallback? onTap;
  final bool compact;

  const _DownloadedFileTile({
    required this.item,
    required this.isDark,
    required this.colors,
    this.onTap,
    this.compact = false,
  });

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(t.translate('delete_file')),
        content: Text(
          t.translate('delete_file_confirm').replaceAll('{name}', item.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(downloadProvider.notifier).deleteDownload(item.id);
            },
            child: Text(
              t.translate('delete'),
              style: TextStyle(color: errorColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : const Color(0xFFF5F5F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: compact ? 6 : 12,
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 36 : 42,
                height: compact ? 36 : 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      fileColor(item.fileType).withValues(alpha: 0.8),
                      fileColor(item.fileType),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  fileIcon(item.fileType),
                  size: compact ? 18 : 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 13 : 14,
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
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: fileColor(
                              item.fileType,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.fileType.toUpperCase(),
                            style: TextStyle(
                              fontSize: compact ? 9 : 10,
                              fontWeight: FontWeight.w700,
                              color: fileColor(item.fileType),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (item.moduleName.isNotEmpty) ...[
                          Flexible(
                            child: Text(
                              item.moduleName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: compact ? 10 : 11,
                                color: colors.onSurface.withValues(alpha: 0.45),
                              ),
                            ),
                          ),
                        ],
                        if (item.completedAt != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            _formatDateShort(item.completedAt!),
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.onSurface.withValues(alpha: 0.35),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _iconButton(
                    bgColor: AppColors.greenAccent.withValues(alpha: 0.1),
                    icon: Icons.open_in_new_rounded,
                    iconColor: AppColors.greenAccent,
                    onTap: () {
                      if (item.localPath != null) {
                        OpenFilex.open(item.localPath!);
                      }
                    },
                  ),
                  const SizedBox(width: 6),
                  _iconButton(
                    bgColor: errorColor.withValues(alpha: 0.1),
                    icon: Icons.delete_outline_rounded,
                    iconColor: errorColor,
                    onTap: () => _confirmDelete(context, ref),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconButton({
    required Color bgColor,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }

  String _formatDateShort(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _FilterSheet extends StatefulWidget {
  final List<String> moduleOptions;
  final List<String> activityOptions;
  final List<String> fileTypeOptions;
  final String initialModule;
  final String initialActivity;
  final String initialFileType;
  final _DateFilter initialDate;
  final void Function(
    String module,
    String activity,
    String fileType,
    _DateFilter date,
  )
  onApply;

  const _FilterSheet({
    required this.moduleOptions,
    required this.activityOptions,
    required this.fileTypeOptions,
    required this.initialModule,
    required this.initialActivity,
    required this.initialFileType,
    required this.initialDate,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _module;
  late String _activity;
  late String _fileType;
  late String _date;

  @override
  void initState() {
    super.initState();
    _module = widget.initialModule;
    _activity = widget.initialActivity;
    _fileType = widget.initialFileType;
    _date = _dateKey(widget.initialDate);
  }

  String _dateKey(_DateFilter filter) {
    switch (filter) {
      case _DateFilter.all:
        return '';
      case _DateFilter.today:
        return 'today';
      case _DateFilter.thisWeek:
        return 'week';
      case _DateFilter.thisMonth:
        return 'month';
      case _DateFilter.older:
        return 'older';
    }
  }

  _DateFilter _dateValue(String key) {
    switch (key) {
      case 'today':
        return _DateFilter.today;
      case 'week':
        return _DateFilter.thisWeek;
      case 'month':
        return _DateFilter.thisMonth;
      case 'older':
        return _DateFilter.older;
      default:
        return _DateFilter.all;
    }
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
              label: t.translate('file_type'),
              value: _fileType,
              options: widget.fileTypeOptions,
              allLabel: t.translate('all'),
              onChanged: (v) => setState(() => _fileType = v),
            ),
            _buildDropdown(
              label: t.translate('date'),
              value: _date,
              options: const ['today', 'week', 'month', 'older'],
              allLabel: t.translate('all'),
              optionLabel: (v) {
                switch (v) {
                  case 'today':
                    return t.translate('today');
                  case 'week':
                    return t.translate('this_week');
                  case 'month':
                    return t.translate('this_month');
                  default:
                    return t.translate('older');
                }
              },
              onChanged: (v) => setState(() => _date = v),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onApply('', '', '', _DateFilter.all);
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
                      widget.onApply(
                        _module,
                        _activity,
                        _fileType,
                        _dateValue(_date),
                      );
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
    String Function(String)? optionLabel,
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
              child: Text(
                optionLabel?.call(o) ?? o,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        onChanged: (v) => onChanged(v ?? ''),
      ),
    );
  }
}
