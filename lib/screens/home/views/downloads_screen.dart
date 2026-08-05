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

enum _FilterMode { all, module, activityType, date, fileType }

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
  _FilterMode _filterMode = _FilterMode.all;
  _DateFilter _dateFilter = _DateFilter.all;
  String? _selectedModule;
  String? _selectedType;
  String? _selectedFileType;
  bool _showFilters = false;

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
    var result = items.where((i) => i.status == DownloadStatus.completed).toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((i) =>
        i.name.toLowerCase().contains(q) ||
        i.moduleName.toLowerCase().contains(q) ||
        i.activityName.toLowerCase().contains(q)
      ).toList();
    }

    switch (_filterMode) {
      case _FilterMode.module:
        if (_selectedModule != null) {
          result = result.where((i) => i.moduleName == _selectedModule).toList();
        }
      case _FilterMode.activityType:
        if (_selectedType != null) {
          result = result.where((i) => i.activityName == _selectedType).toList();
        }
      case _FilterMode.date:
        result = _filterByDate(result);
      case _FilterMode.fileType:
        if (_selectedFileType != null) {
          result = result.where((i) => i.fileType.toLowerCase() == _selectedFileType!.toLowerCase()).toList();
        }
      case _FilterMode.all:
        break;
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

  List<String> _availableModules(List<DownloadItem> items) {
    return items
        .where((i) => i.status == DownloadStatus.completed && i.moduleName.isNotEmpty)
        .map((i) => i.moduleName)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> _availableTypes(List<DownloadItem> items) {
    return items
        .where((i) => i.status == DownloadStatus.completed && i.activityName.isNotEmpty)
        .map((i) => i.activityName)
        .toSet()
        .toList()
      ..sort();
  }

  void _showFilterSheet() {
    final t = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  t.translate('filter'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                _filterChipRow(ctx, t, _FilterMode.all, Icons.all_inclusive_rounded, t.translate('all')),
                const SizedBox(height: 8),
                _filterChipRow(ctx, t, _FilterMode.module, Icons.book_rounded, t.translate('modules')),
                const SizedBox(height: 8),
                _filterChipRow(ctx, t, _FilterMode.activityType, Icons.grid_view_rounded, t.translate('activity_type')),
                const SizedBox(height: 8),
                _filterChipRow(ctx, t, _FilterMode.date, Icons.date_range_rounded, t.translate('date')),
                const SizedBox(height: 8),
                _filterChipRow(ctx, t, _FilterMode.fileType, Icons.insert_drive_file_rounded, t.translate('file_type')),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _filterChipRow(BuildContext ctx, AppLocalizations t, _FilterMode mode, IconData icon, String label) {
    final isSelected = _filterMode == mode;
    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        setState(() {
          _filterMode = mode;
          _showFilters = mode != _FilterMode.all;
          if (mode == _FilterMode.all) {
            _selectedModule = null;
            _selectedType = null;
            _selectedFileType = null;
            _dateFilter = _DateFilter.all;
          }
        });
        if (mode != _FilterMode.all) {
          _showSubFilterSheet();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.1)
              : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.3)
                : Theme.of(context).dividerTheme.color?.withValues(alpha: 0.3) ?? Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? primaryColor : null),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? primaryColor : null,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_rounded, size: 20, color: primaryColor),
          ],
        ),
      ),
    );
  }

  void _showSubFilterSheet() {
    final t = AppLocalizations.of(context);
    final items = ref.read(downloadProvider).items;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _filterTitle(t),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                ..._subFilterOptions(ctx, t, items),
              ],
            ),
          ),
        );
      },
    );
  }

  String _filterTitle(AppLocalizations t) {
    switch (_filterMode) {
      case _FilterMode.module: return t.translate('modules');
      case _FilterMode.activityType: return t.translate('activity_type');
      case _FilterMode.date: return t.translate('date');
      case _FilterMode.fileType: return t.translate('file_type');
      case _FilterMode.all: return '';
    }
  }

  List<Widget> _subFilterOptions(BuildContext ctx, AppLocalizations t, List<DownloadItem> items) {
    switch (_filterMode) {
      case _FilterMode.module:
        final modules = _availableModules(items);
        return modules.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _subFilterTile(ctx, m, m == _selectedModule, () {
            setState(() { _selectedModule = m; });
            Navigator.pop(ctx);
          }),
        )).toList();

      case _FilterMode.activityType:
        final types = _availableTypes(items);
        return types.map((type) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _subFilterTile(ctx, type, type == _selectedType, () {
            setState(() { _selectedType = type; });
            Navigator.pop(ctx);
          }),
        )).toList();

      case _FilterMode.date:
        return [
          _subFilterTile(ctx, t.translate('all'), _dateFilter == _DateFilter.all, () { setState(() { _dateFilter = _DateFilter.all; }); Navigator.pop(ctx); }),
          const SizedBox(height: 8),
          _subFilterTile(ctx, t.translate('today'), _dateFilter == _DateFilter.today, () { setState(() { _dateFilter = _DateFilter.today; }); Navigator.pop(ctx); }),
          const SizedBox(height: 8),
          _subFilterTile(ctx, t.translate('this_week'), _dateFilter == _DateFilter.thisWeek, () { setState(() { _dateFilter = _DateFilter.thisWeek; }); Navigator.pop(ctx); }),
          const SizedBox(height: 8),
          _subFilterTile(ctx, t.translate('this_month'), _dateFilter == _DateFilter.thisMonth, () { setState(() { _dateFilter = _DateFilter.thisMonth; }); Navigator.pop(ctx); }),
          const SizedBox(height: 8),
          _subFilterTile(ctx, t.translate('older'), _dateFilter == _DateFilter.older, () { setState(() { _dateFilter = _DateFilter.older; }); Navigator.pop(ctx); }),
        ];

      case _FilterMode.fileType:
        const types = ['pdf', 'docx', 'pptx', 'xlsx', 'jpg', 'png'];
        return types.map((type) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: fileColor(type).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(fileIcon(type), size: 16, color: fileColor(type)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _subFilterTile(ctx, type.toUpperCase(), type == _selectedFileType, () {
                  setState(() { _selectedFileType = type; });
                  Navigator.pop(ctx);
                }),
              ),
            ],
          ),
        )).toList();

      case _FilterMode.all:
        return [];
    }
  }

  Widget _subFilterTile(BuildContext ctx, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? primaryColor.withValues(alpha: 0.1)
              : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? primaryColor.withValues(alpha: 0.3)
                : Theme.of(context).dividerTheme.color?.withValues(alpha: 0.3) ?? Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? primaryColor : null,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, size: 20, color: primaryColor),
          ],
        ),
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
        .where((i) =>
            i.status == DownloadStatus.downloading ||
            i.status == DownloadStatus.queued)
        .toList();

    final allCompleted = dlState.items
        .where((i) => i.status == DownloadStatus.completed)
        .toList();

    final filteredCompleted = _filtered(allCompleted);
    final totalCount = allCompleted.length;
    final activeCount = activeItems.length;

    final hasItems = activeItems.isNotEmpty || filteredCompleted.isNotEmpty;

    Map<String, List<DownloadItem>> grouped = {};
    if (_filterMode == _FilterMode.module && _selectedModule == null) {
      for (final item in filteredCompleted) {
        final key = item.moduleName.isNotEmpty ? item.moduleName : t.translate('other');
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
                    onPressed: () {
                      setState(() {
                        _showFilters = !_showFilters;
                        _showSearch = false;
                      });
                      if (_showFilters) _showFilterSheet();
                    },
                    icon: Icon(
                      Icons.filter_list_rounded,
                      size: 22,
                      color: _filterMode != _FilterMode.all ? primaryColor : null,
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
                      _showSearch ? Icons.close_rounded : Icons.search_rounded,
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          if (_filterMode != _FilterMode.all && _showFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.filter_list_rounded, size: 14, color: primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      _activeFilterLabel(t),
                      style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _filterMode = _FilterMode.all;
                          _showFilters = false;
                          _selectedModule = null;
                          _selectedType = null;
                          _selectedFileType = null;
                          _dateFilter = _DateFilter.all;
                        });
                      },
                      child: Icon(Icons.close_rounded, size: 14, color: primaryColor),
                    ),
                  ],
                ),
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
                          _sectionHeader(t.translate('in_progress'), '$activeCount ${t.translate('files')}', colors),
                          const SizedBox(height: 8),
                          ...activeItems.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ActiveDownloadTile(item: item, colors: colors, isDark: isDark),
                          )),
                          const SizedBox(height: 12),
                        ],
                        if (filteredCompleted.isNotEmpty) ...[
                          _sectionHeader(t.translate('completed'), '${filteredCompleted.length} ${t.translate('files')}', colors),
                          const SizedBox(height: 8),
                          if (_filterMode == _FilterMode.module && _selectedModule == null)
                            ...grouped.entries.map((entry) => _ModuleGroup(
                              moduleName: entry.key,
                              files: entry.value,
                              isDark: isDark,
                              colors: colors,
                            ))
                          else
                            ...filteredCompleted.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _DownloadedFileTile(
                                item: item,
                                isDark: isDark,
                                colors: colors,
                                onTap: item.localPath != null
                                    ? () => Navigator.pushNamed(context, fileViewerScreenRoute, arguments: {
                                          'filePath': item.localPath,
                                          'fileName': item.name,
                                          'fileType': item.fileType,
                                        })
                                    : null,
                              ),
                            )),
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
    switch (_filterMode) {
      case _FilterMode.module:
        return '${t.translate('module')}: ${_selectedModule ?? t.translate('all')}';
      case _FilterMode.activityType:
        return '${t.translate('activity_type')}: ${_selectedType ?? t.translate('all')}';
      case _FilterMode.date:
        switch (_dateFilter) {
          case _DateFilter.all: return t.translate('all');
          case _DateFilter.today: return t.translate('today');
          case _DateFilter.thisWeek: return t.translate('this_week');
          case _DateFilter.thisMonth: return t.translate('this_month');
          case _DateFilter.older: return t.translate('older');
        }
      case _FilterMode.fileType:
        return '${t.translate('file_type')}: ${_selectedFileType?.toUpperCase() ?? t.translate('all')}';
      case _FilterMode.all:
        return '';
    }
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
    final progress = ref.watch(downloadProvider.select((p) {
      final it = p.items.firstWhere(
        (i) => i.id == item.id,
        orElse: () => item,
      );
      return it.progress;
    }));

    final speed = ref.watch(downloadProvider.select((p) {
      final it = p.items.firstWhere(
        (i) => i.id == item.id,
        orElse: () => item,
      );
      return it.speed;
    }));

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
                    borderRadius: BorderRadius.circular(12),
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
                            backgroundColor: colors.onSurface.withValues(alpha: 0.08),
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
                      onTap: () => ref.read(downloadProvider.notifier).cancelDownload(item.id),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: errorColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.close_rounded, size: 18, color: errorColor),
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
            ...files.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _DownloadedFileTile(
              item: item,
              isDark: isDark,
              colors: colors,
              compact: true,
              onTap: item.localPath != null
                  ? () => Navigator.pushNamed(context, fileViewerScreenRoute, arguments: {
                        'filePath': item.localPath,
                        'fileName': item.name,
                        'fileType': item.fileType,
                      })
                  : null,
            ),
          )),
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
        content: Text(t.translate('delete_file_confirm').replaceAll('{name}', item.name)),
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
            child: Text(t.translate('delete'), style: TextStyle(color: errorColor)),
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
            vertical: compact ? 6 : 10,
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 36 : 40,
                height: compact ? 36 : 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      fileColor(item.fileType).withValues(alpha: 0.8),
                      fileColor(item.fileType),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(compact ? 10 : 12),
                ),
                child: Icon(
                  fileIcon(item.fileType),
                  size: compact ? 18 : 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: fileColor(item.fileType).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.fileType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: fileColor(item.fileType),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (item.completedAt != null)
                          Text(
                            _formatDateShort(item.completedAt!),
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.onSurface.withValues(alpha: 0.35),
                            ),
                          ),
                        if (item.moduleName.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              item.moduleName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.onSurface.withValues(alpha: 0.35),
                              ),
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
                      if (item.localPath != null) OpenFilex.open(item.localPath!);
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

  String _formatDateShort(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
