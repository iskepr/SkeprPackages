import "dart:async";

import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";
import "package:skepr_ui/widgets/loading.dart";
import "package:skepr_ui/widgets/section/section_list.dart";
import "package:skepr_ui/widgets/section/section_search_input.dart";

export "package:skepr_ui/widgets/section/section_filters.dart";
export "package:skepr_ui/widgets/section/section_header.dart";
export "package:skepr_ui/widgets/section/section_sorts.dart";

enum SectionToggle { search, sort, filter }

const int kDefultSectionListLimit = 5;

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
    this.collapsible = false,
    this.initiallyExpanded = true,
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
  final bool collapsible;
  final bool initiallyExpanded;

  @override
  State<Section<T>> createState() => _SectionState<T>();
}

class _SectionState<T> extends State<Section<T>> {
  static const _searchDebounceDuration = Duration(milliseconds: 300);

  String _searchQuery = "";
  bool enableSearch = false;
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  Timer? _searchDebounceTimer;

  bool enableSorting = false;
  int selectedSort = 0;
  bool isAscending = false;

  List<SectionFilterEntity<T>> filterOptions = [];
  bool enableFilter = false;
  List<int> selectedFilters = [0];
  Map<int, bool> toggledStates = {};

  late bool isExpanded;

  bool _dirty = true;
  List<T> _processedData = <T>[];
  List<String>? _searchIndex;

  bool get _withSearch =>
      widget.searchMatcher != null || widget.searchButton != null;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.initiallyExpanded;
    _rebuildFilterOptions();
  }

  @override
  void didUpdateWidget(covariant Section<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.listData, widget.listData) ||
        oldWidget.listData?.length != widget.listData?.length ||
        oldWidget.searchMatcher != widget.searchMatcher) {
      _dirty = true;
      _searchIndex = null;
    }

    if (!identical(oldWidget.sortOptions, widget.sortOptions) ||
        oldWidget.sortOptions.length != widget.sortOptions.length) {
      _dirty = true;

      if (widget.sortOptions.isEmpty) {
        selectedSort = 0;
        isAscending = false;
      } else if (selectedSort >= widget.sortOptions.length) {
        selectedSort = widget.sortOptions.length - 1;
      }
    }

    if (!identical(oldWidget.filterOptions, widget.filterOptions) ||
        oldWidget.filterOptions.length != widget.filterOptions.length) {
      _dirty = true;
      _rebuildFilterOptions();
    }
  }

  void _rebuildFilterOptions() {
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

    if (filterOptions.isEmpty) {
      selectedFilters = [0];
      toggledStates.clear();
      return;
    }

    selectedFilters.removeWhere((i) => i < 0 || i >= filterOptions.length);

    if (selectedFilters.isEmpty ||
        (selectedFilters.length == 1 && selectedFilters.first == 0)) {
      selectedFilters = [0];
    } else {
      selectedFilters.remove(0);
      if (selectedFilters.isEmpty) selectedFilters.add(0);
    }

    toggledStates.removeWhere(
      (key, value) =>
          key < 0 ||
          key >= filterOptions.length ||
          !selectedFilters.contains(key),
    );
  }

  List<SectionHeaderButton> _buildActions(List<T> filteredList) {
    return [
      ...widget.actionButtons,
      if (widget.actionButtonsBuilder != null)
        ...widget.actionButtonsBuilder!(filteredList),
      if (filterOptions.isNotEmpty)
        SectionHeaderButton(
          title: "فلتر",
          onTap: () => toggleAction(SectionToggle.filter),
          icon: LucideIcons.listFilter,
        ),
      if (widget.sortOptions.isNotEmpty)
        SectionHeaderButton(
          title: l10n.sortBy,
          onTap: () => toggleAction(SectionToggle.sort),
          icon: LucideIcons.arrowUpDown,
        ),
      if (_withSearch)
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
      if (widget.collapsible)
        SectionHeaderButton(
          title: isExpanded ? "تصغير" : "توسيع",
          onTap: () => setState(() => isExpanded = !isExpanded),
          icon: isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    } else {
      _searchDebounceTimer?.cancel();
      _focusNode.unfocus();
      _controller.clear();

      if (_searchQuery.isNotEmpty) {
        setState(() {
          _searchQuery = "";
          _dirty = true;
        });
      }
    }
  }

  void _onSearchChanged(String? value) {
    final query = value ?? "";

    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounceDuration, () {
      if (!mounted) return;

      widget.searchButton?.call(query);

      if (widget.searchButton == null && _searchQuery != query) {
        setState(() {
          _searchQuery = query;
          _dirty = true;
        });
      }
    });
  }

  void _ensureSearchIndex(List<T> source) {
    if (_searchIndex != null && _searchIndex!.length == source.length) return;

    _searchIndex = source
        .map((item) => widget.searchMatcher!(item).toLowerCase())
        .toList(growable: false);
  }

  List<T> _applyFilters(List<T> items) {
    final grouped = <String, List<bool Function(T)>>{};

    for (final index in selectedFilters) {
      if (index <= 0 || index >= filterOptions.length) continue;

      final filter = filterOptions[index];
      final groupName = filter.group ?? "general";
      final isToggled = toggledStates[index] ?? false;

      final condition = (isToggled && filter.toggleCondition != null)
          ? filter.toggleCondition
          : filter.condition;

      grouped
          .putIfAbsent(groupName, () => <bool Function(T)>[])
          .add(condition ?? ((T _) => true));
    }

    if (grouped.isEmpty) return items;

    return items.where((item) {
      for (final predicates in grouped.values) {
        var any = false;
        for (final predicate in predicates) {
          if (predicate(item)) {
            any = true;
            break;
          }
        }
        if (!any) return false;
      }
      return true;
    }).toList();
  }

  List<T> _computeProcessedData() {
    final source = widget.listData;
    if (source == null || source.isEmpty) return <T>[];

    List<T> result;

    // 1. Search with Index
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty && widget.searchMatcher != null) {
      _ensureSearchIndex(source);
      final searchWords = query.split(RegExp(r"\s+"));
      final filtered = <T>[];

      for (var i = 0; i < source.length; i++) {
        final searchable = _searchIndex![i];
        if (searchWords.every(searchable.contains)) {
          filtered.add(source[i]);
        }
      }
      result = filtered;
    } else {
      result = List<T>.of(source);
    }

    // 2. Filter
    if (filterOptions.isNotEmpty && !selectedFilters.contains(0)) {
      result = _applyFilters(result);
    }

    // 3. Sort (safe on copied list)
    if (widget.sortOptions.isNotEmpty && result.length > 1) {
      final sortIndex =
          (selectedSort >= 0 && selectedSort < widget.sortOptions.length)
          ? selectedSort
          : 0;
      final compareFunc = widget.sortOptions[sortIndex].compare;
      result.sort(
        (a, b) => isAscending ? compareFunc(a, b) : compareFunc(b, a),
      );
    }

    return result;
  }

  void handleFilterChange(int index) {
    setState(() {
      if (index == 0) {
        selectedFilters = [0];
        toggledStates.clear();
      } else {
        if (index < 0 || index >= filterOptions.length) return;

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
      _dirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_dirty) {
      _processedData = _computeProcessedData();
      _dirty = false;
    }

    final resultList = _processedData;
    final actions = _buildActions(resultList);
    final hasList = widget.listData != null && widget.itemBuilder != null;

    return Container(
      margin: widget.margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null || actions.isNotEmpty)
            SectionHeader(
              title: widget.title,
              bigTitle: widget.bigTitle,
              actionButtons: actions,
              isLoading: widget.isLoading,
              listItems: resultList,
              centerTitle: widget.centerTitle,
            ),
          if (_withSearch && isExpanded)
            SectionSearchInput(
              enableSearch: enableSearch,
              focusNode: _focusNode,
              controller: _controller,
              disableButton: widget.searchButton == null,
              onChanged: _onSearchChanged,
            ),
          if (widget.sortOptions.isNotEmpty && isExpanded)
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
                  _dirty = true;
                });
              },
            ),
          if (widget.filterOptions.isNotEmpty && isExpanded)
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
            padding: isExpanded
                ? (hasList ? EdgeInsets.zero : widget.padding)
                : EdgeInsets.zero,
            child: AnimatedSize(
              duration: kAnimationSlowerDuration,
              curve: kCurveEaseInOut,
              alignment: Alignment.topCenter,
              child: !isExpanded
                  ? const SizedBox.shrink()
                  : widget.isLoading
                  ? const Loading()
                  : hasList
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

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
