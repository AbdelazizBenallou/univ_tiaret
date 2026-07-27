import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/components/breadcrumb_bar.dart';
import 'package:univ_tiaret/components/skeleton_tile.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/logic/modules_provider.dart';
import 'package:univ_tiaret/models/module.dart';
import 'package:univ_tiaret/route/route_constants.dart';

enum SortOption { name, coefficient }
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
  SortOption _sortOption = SortOption.name;
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
      if (_sortOption == SortOption.name) {
        cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      } else {
        cmp = double.parse(a.coefficient)
            .compareTo(double.parse(b.coefficient));
      }
      return _sortAscending ? cmp : -cmp;
    });

    return filtered;
  }

  void _showSortMenu() {
    final t = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  t.translate('sort_by'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(
                  Icons.sort_by_alpha_rounded,
                  color: _sortOption == SortOption.name
                      ? primaryColor
                      : Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.5),
                ),
                title: Text(t.translate('sort_name')),
                trailing: _sortOption == SortOption.name
                    ? Icon(
                        _sortAscending
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        color: primaryColor,
                        size: 20,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    if (_sortOption == SortOption.name) {
                      _sortAscending = !_sortAscending;
                    } else {
                      _sortOption = SortOption.name;
                      _sortAscending = true;
                    }
                  });
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.numbers_rounded,
                  color: _sortOption == SortOption.coefficient
                      ? primaryColor
                      : Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.5),
                ),
                title: Text(t.translate('sort_coeff')),
                trailing: _sortOption == SortOption.coefficient
                    ? Icon(
                        _sortAscending
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        color: primaryColor,
                        size: 20,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    if (_sortOption == SortOption.coefficient) {
                      _sortAscending = !_sortAscending;
                    } else {
                      _sortOption = SortOption.coefficient;
                      _sortAscending = true;
                    }
                  });
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
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
                  : Icons.view_list_rounded,
              size: 24,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'sort') {
                _showSortMenu();
              }
            },
            icon: const Icon(Icons.more_vert_rounded, size: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'sort',
                child: Row(
                  children: [
                    const Icon(Icons.sort_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(t.translate('sort')),
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
            onPressed: () => ref.read(modulesProvider.notifier).fetchModules(
                  semesterId: widget.semesterId,
                  levelName: widget.levelName,
                  specialityId: widget.specialityId,
                ),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(t.translate('try_again')),
          ),
        ],
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
        padding: const EdgeInsets.all(14),
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
                child: const Icon(
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
                child: const Icon(
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
