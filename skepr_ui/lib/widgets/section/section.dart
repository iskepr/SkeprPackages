import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";
import "package:skepr_ui/widgets/loading.dart";
import "package:skepr_ui/widgets/section/section_list.dart";
import "package:skepr_ui/widgets/section/section_search_input.dart";

export "package:skepr_ui/widgets/section/section_filters.dart";
export "package:skepr_ui/widgets/section/section_header.dart";
export "package:skepr_ui/widgets/section/section_sorts.dart";

enum SectionToggle { search, sort, filter }

const int kDefultSectionListLimit = 6;

class Section<T> extends StatefulWidget {
  const Section({
    super.key,
    this.title,
    this.bigTitle = false,
    this.centerTitle = false,
    this.refresh,
    this.actionButtons = const [],
    this.actionButtonsBuilder,
    this.sortOptions = const [],
    this.filterOptions = const [],
    this.child,
    this.padding,
    this.margin = const EdgeInsets.symmetric(vertical: 5),
    this.hasBG = true,
    this.whiteBG = true,
    this.hasBorder = false,
    this.isLoading = false,
    this.bg,
    this.listData,
    this.lengthLimit,
    this.emptyMessage,
    this.errorMessage,
    this.itemBuilder,
    this.searchMatcher,
    this.searchButton,
  }) : assert(title is String || title is Widget || title == null);

  final dynamic title;
  final bool bigTitle, centerTitle;
  final Function()? refresh;
  final List<SectionHeaderButton> actionButtons;
  final List<SectionHeaderButton> Function(List<T> filteredData)?
  actionButtonsBuilder;
  final List<SectionSortEntity<T>> sortOptions;
  final List<SectionFilterEntity<T>> filterOptions;
  final bool hasBG, whiteBG, hasBorder;
  final Color? bg;
  final Widget? child;
  final EdgeInsets? padding, margin;
  final bool isLoading;
  final List<T>? listData;
  final int? lengthLimit;
  final String? emptyMessage, errorMessage;
  final Widget Function(BuildContext c, T item, int index)? itemBuilder;
  final String Function(T item)? searchMatcher;
  final Function(String query)? searchButton;

  @override
  State<Section<T>> createState() => _SectionState<T>();
}

class _SectionState<T> extends State<Section<T>> {
  bool isBigData = true;
  String _searchQuery = "";
  bool enableSearch = false;
  bool withSearch = false;
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();

  bool enableSorting = false;
  int selectedSort = 0;
  bool isAscending = false;

  List<SectionFilterEntity<T>> filterOptions = [];
  bool enableFilter = false;
  List<int> selectedFilters = [0];
  Map<int, bool> toggledStates = {};

  @override
  void initState() {
    super.initState();
    withSearch =
        isBigData &&
        (widget.searchMatcher != null || widget.searchButton != null);

    filterOptions = widget.filterOptions.isNotEmpty
        ? [
            SectionFilterEntity(
              title: "الكل",
              icon: LucideIcons.layoutList,
              condition: null,
            ),
            ...widget.filterOptions,
          ]
        : [];
  }

  List<SectionHeaderButton> _buildActions(List<T> filteredList) {
    return [
      ...widget.actionButtons,
      if (widget.actionButtonsBuilder != null)
        ...widget.actionButtonsBuilder!(filteredList),

      if (filterOptions.isNotEmpty && isBigData)
        SectionHeaderButton(
          title: "فلتر",
          onTap: () => toggleAction(SectionToggle.filter),
          icon: LucideIcons.listFilter,
        ),
      if (widget.sortOptions.isNotEmpty && isBigData)
        SectionHeaderButton(
          title: l10n.sortBy,
          onTap: () => toggleAction(SectionToggle.sort),
          icon: LucideIcons.arrowUpDown,
        ),
      if (withSearch)
        SectionHeaderButton(
          title: l10n.search,
          onTap: () => toggleAction(SectionToggle.search),
          icon: LucideIcons.search,
        ),
      if (widget.refresh != null)
        SectionHeaderButton(
          title: l10n.refresh,
          onTap: widget.refresh!,
          icon: LucideIcons.refreshCw,
        ),
    ];
  }

  void toggleAction(SectionToggle type) {
    setState(() {
      enableSearch = type == SectionToggle.search && !enableSearch;
      enableSorting = type == SectionToggle.sort && !enableSorting;
      enableFilter = type == SectionToggle.filter && !enableFilter;
    });

    if (enableSearch) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focusNode.requestFocus(),
      );
    } else {
      _focusNode.unfocus();
      _controller.clear();
      if (_searchQuery.isNotEmpty) {
        setState(() => _searchQuery = "");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<T> resultList = List.from(widget.listData ?? []);

    // البحث
    if (_searchQuery.isNotEmpty && widget.searchMatcher != null) {
      final searchWords = _searchQuery.trim().toLowerCase().split(
        RegExp(r"\s+"),
      );
      resultList = resultList.where((item) {
        final searchableData = widget.searchMatcher!(item).toLowerCase();
        return searchWords.every((word) => searchableData.contains(word));
      }).toList();
    }

    // الترتيب
    if (widget.sortOptions.isNotEmpty) {
      final compareFunc = widget.sortOptions[selectedSort].compare;
      resultList.sort(
        (a, b) => isAscending ? compareFunc(a, b) : compareFunc(b, a),
      );
    }

    // الفلترة
    if (filterOptions.isNotEmpty && !selectedFilters.contains(0)) {
      resultList = resultList.where((item) {
        final Map<String, List<int>> groupedFilters = {};
        for (var index in selectedFilters) {
          final filter = filterOptions[index];
          final groupName = filter.group ?? "general";
          groupedFilters.putIfAbsent(groupName, () => []).add(index);
        }

        return groupedFilters.values.every((groupIndices) {
          return groupIndices.any((index) {
            final filter = filterOptions[index];
            final isToggled = toggledStates[index] ?? false;
            final currentCondition =
                (isToggled && filter.toggleCondition != null)
                ? filter.toggleCondition
                : filter.condition;
            return currentCondition != null ? currentCondition(item) : true;
          });
        });
      }).toList();
    }

    return Container(
      margin: widget.margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null || _buildActions(resultList).isNotEmpty)
            SectionHeader(
              title: widget.title,
              bigTitle: widget.bigTitle,
              actionButtons: _buildActions(resultList),
              isLoading: widget.isLoading,
              listItems: resultList,
              centerTitle: widget.centerTitle,
            ),

          if (withSearch)
            SectionSearchInput(
              enableSearch: enableSearch,
              focusNode: _focusNode,
              controller: _controller,
              disableButton: widget.searchButton == null,
              onChanged: (value) {
                widget.searchButton?.call(value ?? "");
                if (widget.searchButton == null) {
                  setState(() => _searchQuery = value ?? "");
                }
              },
            ),

          if (widget.sortOptions.isNotEmpty)
            SectionSorts<T>(
              enableSorting: enableSorting,
              selectedSort: selectedSort,
              sorts: widget.sortOptions,
              isAscending: isAscending,
              onChanged: (value) {
                setState(() {
                  if (selectedSort == value) {
                    isAscending = !isAscending;
                  } else {
                    selectedSort = value;
                    isAscending = false;
                  }
                });
              },
            ),

          if (widget.filterOptions.isNotEmpty)
            SectionFilters<T>(
              enableFilter: enableFilter,
              selectedFilters: selectedFilters,
              toggledStates: toggledStates,
              filters: filterOptions,
              onChanged: handleFilterChange,
            ),

          MyMaterial(
            width: double.infinity,
            borderRadius: BorderRadius.circular(kSmallBorderRadius),
            whiteBG: widget.whiteBG,
            hasBorder: widget.hasBorder,
            hasShadow: false,
            bg: widget.bg ?? (widget.hasBG ? null : Colors.transparent),
            padding: widget.padding,
            child: AnimatedSize(
              duration: kAnimationSlowerDuration,
              curve: kCurveEaseInOut,
              alignment: Alignment.topCenter,
              child: widget.isLoading
                  ? const Loading()
                  : (widget.listData != null && widget.itemBuilder != null)
                  ? SectionList<T>(
                      listItems: resultList,
                      errorMessage: widget.errorMessage,
                      emptyMessage: widget.emptyMessage,
                      padding: widget.padding,
                      lengthLimit: widget.lengthLimit,
                      itemBuilder: widget.itemBuilder!,
                    )
                  : (widget.child ?? const SizedBox.shrink()),
            ),
          ),
        ],
      ),
    );
  }

  void handleFilterChange(int index) {
    setState(() {
      if (index == 0) {
        selectedFilters = [0];
        toggledStates.clear();
      } else {
        selectedFilters.remove(0);
        final filter = filterOptions[index];

        if (!selectedFilters.contains(index)) {
          selectedFilters.add(index);
          toggledStates[index] = false;
        } else if (toggledStates[index] == false &&
            filter.toggleCondition != null) {
          toggledStates[index] = true;
        } else {
          selectedFilters.remove(index);
          toggledStates.remove(index);
        }

        if (selectedFilters.isEmpty) selectedFilters.add(0);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
