import "dart:math";

import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";

class RadioInput extends StatefulWidget {
  const RadioInput({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.disabled = false,
    this.hasBorder = false,
    this.whiteBG = true,
    this.height = 38,
    this.bg,
    this.margin,
    this.validate,
  });

  final List<SelectEntity> items;
  final dynamic value;
  final bool disabled, hasBorder, whiteBG;
  final double height;
  final Color? bg;
  final EdgeInsets? margin;
  final String? Function(String?)? validate;
  final Function(dynamic) onChanged;

  @override
  State<RadioInput> createState() => _RadioInputState();
}

class _RadioInputState extends State<RadioInput> {
  int _selectedValue = -1;
  final _fieldKey = GlobalKey<FormFieldState<String>>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _updateSelectedIndex();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToSelected(isInitial: true),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(RadioInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _updateSelectedIndex();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fieldKey.currentState?.didChange(widget.value?.toString());
        _scrollToSelected();
      });
    }
  }

  void _updateSelectedIndex() {
    _selectedValue = widget.items.indexWhere(
      (item) => item.value == widget.value,
    );
  }

  int _itemWeight(SelectEntity item) =>
      max(item.name.length, 1) + (item.icon != null ? 3 : 0);

  Map<String, double> _calculateLayout(double maxWidth) {
    const double paddingVal = 2;
    final int totalFlex = widget.items.fold(
      0,
      (sum, item) => sum + _itemWeight(item),
    );
    final double innerContainerWidth = maxWidth - (paddingVal * 4);
    final double requiredWidth = totalFlex * 10;
    final double scrollableWidth = max(innerContainerWidth, requiredWidth);

    double selectorWidth = 0;
    double selectorStart = 0;

    if (_selectedValue != -1 && totalFlex > 0) {
      int flexBefore = 0;
      for (int i = 0; i < _selectedValue; i++) {
        flexBefore += _itemWeight(widget.items[i]);
      }
      selectorStart = (flexBefore / totalFlex) * scrollableWidth;
      selectorWidth =
          (_itemWeight(widget.items[_selectedValue]) / totalFlex) *
          scrollableWidth;
    }

    return {
      "start": selectorStart,
      "width": selectorWidth,
      "scrollableWidth": scrollableWidth,
    };
  }

  void _scrollToSelected({bool isInitial = false}) {
    if (!mounted || !_scrollController.hasClients || _selectedValue == -1) {
      return;
    }

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final layout = _calculateLayout(renderBox.size.width);
    final double targetOffset =
        (layout["start"]! - (renderBox.size.width / 2) + 40).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );

    if (isInitial) {
      _scrollController.jumpTo(targetOffset);
    } else {
      _scrollController.animateTo(
        targetOffset,
        duration: kAnimationDuration,
        curve: kCurveEaseInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: _fieldKey,
      validator: widget.validate,
      initialValue: widget.value?.toString(),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (fieldState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final layout = _calculateLayout(constraints.maxWidth);

                return MyMaterial(
                  height: widget.height,
                  width: constraints.maxWidth,
                  margin: widget.margin,
                  padding: const EdgeInsets.all(4),
                  whiteBG: widget.whiteBG,
                  hasBorder: widget.hasBorder,
                  hasShadow: false,
                  bg:
                      widget.bg ??
                      (fieldState.hasError
                          ? context.error.withValues(alpha: 0.1)
                          : null),
                  borderRadius: BorderRadius.circular(50),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: layout["scrollableWidth"],
                      child: Stack(
                        children: [
                          if (_selectedValue != -1)
                            AnimatedPositionedDirectional(
                              start: layout["start"]!,
                              width: layout["width"]!,
                              top: 0,
                              bottom: 0,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: context.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                            ),
                          Row(
                            children: List.generate(widget.items.length, (
                              index,
                            ) {
                              final item = widget.items[index];
                              final isSelected = _selectedValue == index;

                              return Expanded(
                                flex: _itemWeight(item),
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () {
                                    if (widget.disabled) return;
                                    setState(() => _selectedValue = index);
                                    fieldState.didChange(
                                      item.value?.toString(),
                                    );
                                    widget.onChanged(item.value);
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      spacing: 5,
                                      children: [
                                        if (item.icon != null)
                                          Icon(
                                            item.icon,
                                            size: kSmallFont + 3,
                                            color: isSelected
                                                ? context.primary
                                                : context.text,
                                          ),
                                        Flexible(
                                          child: Text(
                                            item.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: kSmallFont,
                                              color: isSelected
                                                  ? context.primary
                                                  : context.text,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (fieldState.hasError)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  kSmallPadding,
                  4,
                  kSmallPadding,
                  0,
                ),
                child: Text(
                  fieldState.errorText ?? "",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: kSoSmallFont,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
