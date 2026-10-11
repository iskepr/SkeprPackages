import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";

class OptionsSelector extends StatefulWidget {
  final List<String> options;

  final int? initialValue;
  final ValueChanged<int?>? onChanged;

  final bool multiSelect;
  final List<int>? initialValues;
  final ValueChanged<List<int>>? onMultiChanged;

  final bool disabled;
  final bool isExpanded;
  final Map<int, Color>? activeColors;
  final Map<int, IconData>? activeIcons;

  const OptionsSelector({
    super.key,
    required this.options,
    this.initialValue,
    this.onChanged,
    this.initialValues,
    this.onMultiChanged,
    this.multiSelect = false,
    this.disabled = false,
    this.isExpanded = false,
    this.activeColors,
    this.activeIcons,
  }) : assert(
         !multiSelect || onMultiChanged != null,
         "onMultiChanged مطلوب لما multiSelect = true",
       ),
       assert(
         multiSelect || onChanged != null,
         "onChanged مطلوب لما multiSelect = false",
       );

  @override
  State<OptionsSelector> createState() => _OptionsSelectorState();
}

class _OptionsSelectorState extends State<OptionsSelector> {
  int? _selectedSingle;
  Set<int> _selectedMulti = {};

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(covariant OptionsSelector oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.multiSelect) {
      final oldSet = (oldWidget.initialValues ?? const []).toSet();
      final newSet = (widget.initialValues ?? const []).toSet();
      if (!_setEquals(oldSet, newSet)) {
        _selectedMulti = newSet;
      }
    } else {
      if (oldWidget.initialValue != widget.initialValue) {
        _selectedSingle = widget.initialValue;
      }
    }

    if (oldWidget.multiSelect != widget.multiSelect) {
      _syncFromWidget();
    }
  }

  void _syncFromWidget() {
    if (widget.multiSelect) {
      _selectedMulti = (widget.initialValues ?? const []).toSet();
    } else {
      _selectedSingle = widget.initialValue;
    }
  }

  static bool _setEquals(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);

  bool _isSelected(int index) => widget.multiSelect
      ? _selectedMulti.contains(index)
      : _selectedSingle == index;

  bool get _hasAnySelection =>
      widget.multiSelect ? _selectedMulti.isNotEmpty : _selectedSingle != null;

  void _handleTap(int index) {
    if (widget.multiSelect) {
      setState(() {
        if (!_selectedMulti.remove(index)) {
          _selectedMulti.add(index);
        }
      });
      final sorted = _selectedMulti.toList()..sort();
      widget.onMultiChanged?.call(sorted);
    } else {
      final newValue = _selectedSingle == index ? null : index;
      setState(() => _selectedSingle = newValue);
      widget.onChanged?.call(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.options.isEmpty) return const SizedBox.shrink();

    if (widget.isExpanded) {
      return Row(
        spacing: kSmallPadding,
        children: [
          for (int i = 0; i < widget.options.length; i++)
            _buildExpandedOption(i),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = _wrapIntoRows(constraints.maxWidth);
        return Column(
          spacing: kSmallPadding,
          children: [
            for (final row in rows)
              Row(
                spacing: kSmallPadding,
                children: [
                  for (final i in row)
                    Flexible(
                      flex: _measureWidth(widget.options[i]).round(),
                      fit: FlexFit.tight,
                      child: _buildOption(i),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildExpandedOption(int index) {
    final isSelected = _isSelected(index);
    final shouldCollapse = _hasAnySelection && !isSelected;
    return Flexible(
      flex: shouldCollapse ? 0 : 1,
      fit: FlexFit.tight,
      child: _buildOption(index),
    );
  }

  List<List<int>> _wrapIntoRows(double maxWidth) {
    final rows = <List<int>>[];
    var currentRow = <int>[];
    var currentWidth = 0.0;

    for (int i = 0; i < widget.options.length; i++) {
      final itemWidth = _measureWidth(widget.options[i]);
      final needed = currentRow.isEmpty
          ? itemWidth
          : currentWidth + kSmallPadding + itemWidth;

      if (currentRow.isNotEmpty && needed > maxWidth) {
        rows.add(currentRow);
        currentRow = [i];
        currentWidth = itemWidth;
      } else {
        currentRow.add(i);
        currentWidth = needed;
      }
    }
    if (currentRow.isNotEmpty) rows.add(currentRow);
    return rows;
  }

  double _measureWidth(String text) {
    final tp = TextPainter(
      text: TextSpan(
        text: text.replaceAll("\$", ""),
        style: const TextStyle(fontSize: kSoLargeFont),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    const iconAndSpacing = 24.0;
    return tp.width + (kLargePadding * 2) + iconAndSpacing;
  }

  Widget _buildOption(int index) {
    final isSelected = _isSelected(index);
    final option = widget.options[index];
    final accent = widget.activeColors?[index] ?? context.primary;
    final bgColor = isSelected ? accent : context.foreground;
    final icon = widget.activeIcons?[index] ?? LucideIcons.dot;

    return AnimatedContainer(
      key: ValueKey("option_$index"),
      duration: kAnimationFasterDuration,
      padding: const EdgeInsets.symmetric(
        vertical: kSmallPadding,
        horizontal: kLargePadding,
      ),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: isSelected ? 0.2 : 1),
        borderRadius: BorderRadius.circular(kSmallBorderRadius),
      ),
      child: TextIcon(
        option,
        icon: icon,
        size: kSoLargeFont,
        hideText: widget.isExpanded && _hasAnySelection && !isSelected,
        markdown: option.contains("\$"),
        disabled: widget.disabled,
        color: isSelected
            ? accent
            : !_hasAnySelection
            ? null
            : context.secondary,
        onPressed: widget.disabled ? null : () => _handleTap(index),
      ),
    );
  }
}
