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

  @override
  Widget build(BuildContext context) {
    return Section<T>(
      title: widget.title,
      isLoading: widget.isLoading,
      listData: widget.listData,
      searchButton: widget.searchButton,
      searchMatcher: widget.searchMatcher,
      emptyMessage: widget.emptyMessage,
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
