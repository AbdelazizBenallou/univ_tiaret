import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/logic/download_provider.dart';
import 'package:univ_tiaret/services/download_service.dart';
import 'package:univ_tiaret/utils/file_utils.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  bool _showSearch = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

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
    final completedItems = dlState.items
        .where((i) => i.status == DownloadStatus.completed)
        .where((i) =>
            _searchQuery.isEmpty ||
            i.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    final hasItems = activeItems.isNotEmpty || completedItems.isNotEmpty;

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
                    t.translate('downloads'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                if (hasItems)
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
            child: hasItems
                ? RefreshIndicator(
                    onRefresh: () async {
                      ref.read(downloadProvider.notifier).init();
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                      children: [
                        if (activeItems.isNotEmpty) ...[
                          Text(
                            t.translate('in_progress'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface.withValues(alpha: 0.5),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...activeItems.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _ActiveDownloadTile(item: item),
                              )),
                        ],
                        if (completedItems.isNotEmpty) ...[
                          if (activeItems.isNotEmpty) const SizedBox(height: 12),
                          Text(
                            t.translate('completed'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface.withValues(alpha: 0.5),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...completedItems.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _DownloadedFileTile(
                                  item: item,
                                  isDark: isDark,
                                  colors: colors,
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
    );
  }

  Widget _buildEmpty(AppLocalizations t, ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.download_done_rounded,
            size: 48,
            color: colors.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Text(
            t.translate('no_downloads'),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
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
    );
  }
}

class _ActiveDownloadTile extends ConsumerWidget {
  final DownloadItem item;
  const _ActiveDownloadTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final progress = ref.watch(downloadProvider.select((p) {
      final it = p.items.firstWhere(
        (i) => i.id == item.id,
        orElse: () => item,
      );
      return it.progress;
    }));

    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : const Color(0xFFF5F5F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
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
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(progress * 100).toInt()}%',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: colors.onSurface.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(
                  fileColor(item.fileType),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadedFileTile extends StatelessWidget {
  final DownloadItem item;
  final bool isDark;
  final ColorScheme colors;

  const _DownloadedFileTile({
    required this.item,
    required this.isDark,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : const Color(0xFFF5F5F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.folderPath.isNotEmpty
                        ? '${item.fileType.toUpperCase()}  ·  ${item.folderPath}'
                        : item.fileType.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
