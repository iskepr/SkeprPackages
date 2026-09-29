import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";

class MulteSelect<T> extends StatefulWidget {
  const MulteSelect({
    super.key,
    required this.title,
    required this.listData,
    required this.onSelected,
    required this.getItemId,
    required this.getItemTitle,
    this.getItemSubtitle,
    this.isLoading = false,
    this.emptyMessage = "",
    this.searchButton,
    this.searchMatcher,
    this.initialSelectedIds = const [],
    this.showSelectAll = true,
  });

  final String title;
  final List<T> listData;
  final bool isLoading;
  final String emptyMessage;
  final void Function(List<dynamic> ids) onSelected;
  final dynamic Function(T item) getItemId;
  final String Function(T item) getItemTitle;
  final String Function(T item)? getItemSubtitle;
  final Function(String)? searchButton;
  final String Function(T item)? searchMatcher;
  final List<dynamic> initialSelectedIds;
  final bool showSelectAll;

  @override
  State<MulteSelect<T>> createState() => _MulteSelectState<T>();
}

class _MulteSelectState<T> extends State<MulteSelect<T>> {
  List<dynamic> selectedIds = [];

  @override
  void initState() {
    super.initState();
    selectedIds = List.from(widget.initialSelectedIds);
  }

  void _toggleSelectAll() {
    if (widget.listData.isEmpty) return;

    final currentVisibleIds = widget.listData.map(widget.getItemId).toSet();
    final isAllVisibleSelected = currentVisibleIds.every(selectedIds.contains);

    setState(() {
      if (isAllVisibleSelected) {
        selectedIds.removeWhere(currentVisibleIds.contains);
      } else {
        selectedIds = {...selectedIds, ...currentVisibleIds}.toList();
      }
    });

    widget.onSelected(selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final hasItems = widget.listData.isNotEmpty;
    final isAllSelected =
        hasItems &&
        widget.listData.map(widget.getItemId).every(selectedIds.contains);

    final displayTitle = selectedIds.isEmpty
        ? widget.title
        : "${widget.title} (${selectedIds.length})";

    return Section<T>(
      title: displayTitle,
      isLoading: widget.isLoading,
      listData: widget.listData,
      searchButton: widget.searchButton,
      searchMatcher: widget.searchMatcher,
      emptyMessage: widget.emptyMessage,
      actionButtons: [
        if (widget.showSelectAll && hasItems)
          SectionHeaderButton(
            title: isAllSelected ? "إلغاء التحديد" : "تحديد الكل",
            icon: isAllSelected
                ? LucideIcons.listCheck
                : LucideIcons.listChecks,
            onTap: _toggleSelectAll,
          ),
      ],
      itemBuilder: (context, item, index) {
        final id = widget.getItemId(item);
        final isSelected = selectedIds.contains(id);

        return CustomListTile(
          onTap: () {
            setState(() {
              isSelected ? selectedIds.remove(id) : selectedIds.add(id);
            });
            widget.onSelected(selectedIds);
          },
          title: widget.getItemTitle(item),
          subtitle: widget.getItemSubtitle != null
              ? Text(widget.getItemSubtitle!(item))
              : null,
          trailing: Icon(
            isSelected ? LucideIcons.check : LucideIcons.plus,
            color: isSelected
                ? context.primary
                : context.text.withValues(alpha: 0.5),
          ),
        );
      },
    );
  }
}
