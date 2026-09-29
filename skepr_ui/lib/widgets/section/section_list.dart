import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";

const int kDefaultSectionListInitialItems = 30;
const int kDefaultSectionListIncrement = 30;

class SectionList<T> extends StatefulWidget {
  final List<T> listItems;
  final String? errorMessage;
  final String? emptyMessage;
  final EdgeInsets? padding;
  final int? lengthLimit;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int initialItemCount;
  final int loadMoreIncrement;
  final String? showMoreText;

  const SectionList({
    super.key,
    required this.listItems,
    this.errorMessage,
    this.emptyMessage,
    this.padding,
    this.lengthLimit,
    required this.itemBuilder,
    this.initialItemCount = kDefaultSectionListInitialItems,
    this.loadMoreIncrement = kDefaultSectionListIncrement,
    this.showMoreText,
  });

  @override
  State<SectionList<T>> createState() => _SectionListState<T>();
}

class _SectionListState<T> extends State<SectionList<T>> {
  late int _visibleCount;

  @override
  void initState() {
    super.initState();
    _visibleCount = widget.initialItemCount;
  }

  @override
  void didUpdateWidget(covariant SectionList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.listItems.length < _visibleCount) {
      final baseLimit = widget.initialItemCount;
      _visibleCount = widget.listItems.length > baseLimit
          ? widget.listItems.length
          : baseLimit;
    }
  }

  void _showMore() {
    setState(() {
      _visibleCount += widget.loadMoreIncrement;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.listItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(kSmallPadding),
        child: Center(
          child: Text(
            widget.errorMessage ?? widget.emptyMessage ?? "لا يوجد بيانات",
          ),
        ),
      );
    }

    final int visibleCount = _visibleCount < widget.listItems.length
        ? _visibleCount
        : widget.listItems.length;
    final bool hasMore = visibleCount < widget.listItems.length;
    final EdgeInsets listPadding =
        widget.padding ?? const EdgeInsets.all(kSmallPadding);

    // حالة وجود lengthLimit (سكرول داخلي بارتفاع محسوب بدقة مع زرار عرض المزيد)
    if (widget.lengthLimit != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // قياس عينة أول عنصر في نفس الفريم للحصول على الارتفاع الفعلي بدون فريمات متأخرة
          final sampleWidget = widget.itemBuilder(
            context,
            widget.listItems.first,
            0,
          );

          return Stack(
            children: [
              // عنصر مخفي تماماً لاستنتاج الارتفاع المتزامن
              Opacity(
                opacity: 0,
                child: IgnorePointer(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: sampleWidget,
                  ),
                ),
              ),
              _LimitedListView(
                lengthLimit: widget.lengthLimit!,
                itemCount: visibleCount + (hasMore ? 1 : 0),
                padding: listPadding,
                itemBuilder: (context, index) {
                  if (hasMore && index == visibleCount) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: kSmallPadding,
                      ),
                      child: Center(
                        child: TextButton(
                          onPressed: _showMore,
                          child: Text(widget.showMoreText ?? "عرض المزيد"),
                        ),
                      ),
                    );
                  }
                  return widget.itemBuilder(
                    context,
                    widget.listItems[index],
                    index,
                  );
                },
              ),
            ],
          );
        },
      );
    }

    // الوضع العادي بدون lengthLimit
    return ListView.builder(
      padding: listPadding,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleCount + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (hasMore && index == visibleCount) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: kSmallPadding),
            child: Center(
              child: TextButton(
                onPressed: _showMore,
                child: Text(widget.showMoreText ?? "عرض المزيد"),
              ),
            ),
          );
        }
        return widget.itemBuilder(context, widget.listItems[index], index);
      },
    );
  }
}

class _LimitedListView extends StatelessWidget {
  final int lengthLimit;
  final int itemCount;
  final EdgeInsets padding;
  final NullableIndexedWidgetBuilder itemBuilder;

  const _LimitedListView({
    required this.lengthLimit,
    required this.itemCount,
    required this.padding,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    const double kEstimatedTileHeight = 50;
    final double calculatedMaxHeight =
        (kEstimatedTileHeight * lengthLimit) + padding.vertical;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: calculatedMaxHeight),
      child: ListView.builder(
        padding: padding,
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      ),
    );
  }
}
