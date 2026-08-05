import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:univ_tiaret/components/breadcrumb_bar.dart';
import 'package:univ_tiaret/components/skeleton_tile.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/logic/modules_provider.dart';
import 'package:univ_tiaret/models/module.dart';
import 'package:univ_tiaret/providers/navigation_provider.dart';
import 'package:univ_tiaret/route/route_constants.dart';
import 'package:univ_tiaret/widgets/app_bottom_nav.dart';
import 'package:univ_tiaret/widgets/sort_bottom_sheet.dart';

enum ModuleSortOption { name, coefficient }
enum ViewMode { list, grid }

class ModulesScreen extends ConsumerStatefulWidget {
  final int semesterId;
  final String semesterName;
  final int seasonId;
  final String seasonName;
  final String? levelName;
  final int? specialityId;

  const ModulesScreen({
    super.key,
    required this.semesterId,
    required this.semesterName,
    required this.seasonId,
    required this.seasonName,
    this.levelName,
    this.specialityId,
  });

  @override
  ConsumerState<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends ConsumerState<ModulesScreen> {
  bool _showSearch = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  ModuleSortOption _sortOption = ModuleSortOption.name;
  bool _sortAscending = true;
  ViewMode _viewMode = ViewMode.list;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(modulesProvider.notifier).fetchModules(
          semesterId: widget.semesterId,
          levelName: widget.levelName,
          specialityId: widget.specialityId,
        ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Module> _getFilteredAndSorted(List<Module> modules) {
    var filtered = modules;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = modules
          .where((m) =>
              m.name.toLowerCase().contains(q) ||
              m.code.toLowerCase().contains(q))
          .toList();
    }

    filtered.sort((a, b) {
      int cmp;
      if (_sortOption == ModuleSortOption.name) {
        cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      } else {
        cmp = double.parse(a.coefficient)
            .compareTo(double.parse(b.coefficient));
      }
      return _sortAscending ? cmp : -cmp;
    });

    return filtered;
  }

  Future<void> _showSortMenu() async {
    final t = AppLocalizations.of(context);
    final result = await showSortBottomSheet<ModuleSortOption>(
      context: context,
      title: t.translate('sort_by'),
      currentValue: _sortOption,
      ascending: _sortAscending,
      onToggleOrder: () {
        setState(() => _sortAscending = !_sortAscending);
      },
      options: [
        SortOption(value: ModuleSortOption.name, label: t.translate('sort_name'), icon: Icons.sort_by_alpha_rounded),
        SortOption(value: ModuleSortOption.coefficient, label: t.translate('sort_coeff'), icon: Icons.tag_rounded),
      ],
    );
    if (result != null && mounted) {
      setState(() {
        _sortOption = result;
        _sortAscending = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(modulesProvider);

    final modules = state.loading ? <Module>[] : _getFilteredAndSorted(state.modules);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.semesterName),
        actions: [
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
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == ViewMode.list
                    ? ViewMode.grid
                    : ViewMode.list;
              });
            },
            icon: Icon(
              _viewMode == ViewMode.list
                  ? Icons.grid_view_rounded
                  : Icons.menu_rounded,
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
              BreadcrumbItem(label: widget.semesterName),
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
                  hintText: t.translate('search_modules'),
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
            child: state.loading
                ? const SkeletonList()
                : state.error != null
                    ? _buildError(state.error!, t)
                    : modules.isEmpty
                        ? Center(
                            child: Text(
                              t.translate('no_modules'),
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
                                .read(modulesProvider.notifier)
                                .fetchModules(
                                  semesterId: widget.semesterId,
                                  levelName: widget.levelName,
                                  specialityId: widget.specialityId,
                                ),
                            child: _viewMode == ViewMode.list
                                ? _buildList(modules, t)
                                : _buildGrid(modules, t),
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
                onPressed: () => ref.read(modulesProvider.notifier).fetchModules(
                      semesterId: widget.semesterId,
                      levelName: widget.levelName,
                      specialityId: widget.specialityId,
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

  Widget _buildList(List<Module> modules, AppLocalizations t) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: modules.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final module = modules[index];
        return _ModuleListTile(
          module: module,
          t: t,
          onTap: () => _navigateToActivities(module),
        );
      },
    );
  }

  Widget _buildGrid(List<Module> modules, AppLocalizations t) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.4,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        return _ModuleGridCard(
          module: module,
          t: t,
          onTap: () => _navigateToActivities(module),
        );
      },
    );
  }

  void _navigateToActivities(Module module) {
    Navigator.pushNamed(
      context,
      activitiesScreenRoute,
      arguments: {
        'moduleId': module.id,
        'moduleName': module.name,
        'seasonId': widget.seasonId,
        'semesterName': widget.semesterName,
        'seasonName': widget.seasonName,
      },
    );
  }
}

class _ModuleListTile extends StatelessWidget {
  final Module module;
  final AppLocalizations t;
  final VoidCallback? onTap;

  const _ModuleListTile({required this.module, required this.t, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.greenLight, AppColors.greenAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
                child: Icon(
                  Icons.book_rounded,
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
                  module.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  module.code,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${t.translate('coefficient')} ${module.coefficient}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${module.credit} ${t.translate('credit')}',
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
    );
  }
}

class _ModuleGridCard extends StatelessWidget {
  final Module module;
  final AppLocalizations t;
  final VoidCallback? onTap;

  const _ModuleGridCard({required this.module, required this.t, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.greenLight, AppColors.greenAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.book_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  module.code,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurface.withValues(alpha: 0.5),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            module.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'C${module.coefficient}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
              Text(
                '${module.credit} ${t.translate('credit')}',
                style: TextStyle(
                  fontSize: 10,
                  color: colors.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}
