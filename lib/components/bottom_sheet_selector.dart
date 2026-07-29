import 'package:flutter/material.dart';

import 'package:univ_tiaret/constants.dart';

Future<T?> showBottomSheetSelector<T>({
  required BuildContext context,
  required List<T> items,
  required String title,
  String? hintText,
  bool searchEnabled = false,
  String? selectedName,
  IconData? leadingIcon,
  required String Function(T) itemLabelBuilder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BottomSheetSelector<T>(
      items: items,
      title: title,
      hintText: hintText,
      searchEnabled: searchEnabled,
      selectedName: selectedName,
      leadingIcon: leadingIcon,
      itemLabelBuilder: itemLabelBuilder,
    ),
  );
}

class _BottomSheetSelector<T> extends StatefulWidget {
  final List<T> items;
  final String title;
  final String? hintText;
  final bool searchEnabled;
  final String? selectedName;
  final IconData? leadingIcon;
  final String Function(T) itemLabelBuilder;

  const _BottomSheetSelector({
    required this.items,
    required this.title,
    this.hintText,
    this.searchEnabled = false,
    this.selectedName,
    this.leadingIcon,
    required this.itemLabelBuilder,
  });

  @override
  State<_BottomSheetSelector<T>> createState() =>
      _BottomSheetSelectorState<T>();
}

class _BottomSheetSelectorState<T> extends State<_BottomSheetSelector<T>> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<T> get _filteredItems {
    if (_searchQuery.isEmpty) return widget.items;
    return widget.items
        .where((item) => widget
            .itemLabelBuilder(item)
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(defaultBorderRadious + 4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.dividerDark : blackColor10,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                defaultPadding, defaultPadding, defaultPadding, 0),
            child: Row(
              children: [
                if (widget.leadingIcon != null) ...[
                  Icon(widget.leadingIcon, size: 22, color: primaryColor),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: colors.onSurface.withValues(alpha: 0.5), size: 22),
                ),
              ],
            ),
          ),
          if (widget.searchEnabled) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  defaultPadding, defaultPadding, defaultPadding, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: widget.hintText ?? 'Search...',
                  prefixIcon: Icon(Icons.search_rounded, size: 22, color: colors.onSurface.withValues(alpha: 0.5)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: Icon(Icons.close_rounded, size: 20),
                        )
                      : null,
                ),
              ),
            ),
          ],
          Flexible(
            child: _filteredItems.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(defaultPadding * 2),
                    child: Text(
                      widget.hintText ?? 'No items found',
                      style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5), fontSize: 14),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: defaultPadding,
                        vertical: defaultPadding / 2),
                    shrinkWrap: true,
                    itemCount: _filteredItems.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: isDark ? Colors.white10 : blackColor5,
                    ),
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final label = widget.itemLabelBuilder(item);
                      final isSelected = label == widget.selectedName;

                      return ListTile(
                        onTap: () => Navigator.pop(context, item),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(defaultBorderRadious / 2),
                        ),
                        tileColor:
                            isSelected ? primaryColor.withValues(alpha: 0.08) : null,
                        leading: widget.leadingIcon != null
                            ? Icon(
                                widget.leadingIcon,
                                size: 20,
                                color: isSelected ? primaryColor : colors.onSurface.withValues(alpha: 0.5),
                              )
                            : null,
                        title: Text(
                          label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? primaryColor : colors.onSurface,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded,
                                color: primaryColor, size: 20)
                            : null,
                      );
                    },
                  ),
          ),
          const SizedBox(height: defaultPadding / 2),
        ],
      ),
    );
  }
}
