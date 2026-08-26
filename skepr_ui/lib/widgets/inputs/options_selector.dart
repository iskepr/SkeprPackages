import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";

class OptionsSelector extends StatefulWidget {
  final List<String> options;
  final int? initialValue;
  final ValueChanged<int?> onChanged;
  final bool disabled;
  final bool isExpanded;
  final Map<int, Color>? activeColors;
  final Map<int, IconData>? activeIcons;

  const OptionsSelector({
    super.key,
    required this.options,
    required this.onChanged,
    this.initialValue,
    this.disabled = false,
    this.isExpanded = false,
    this.activeColors,
    this.activeIcons,
  });

  @override
  State<OptionsSelector> createState() => _OptionsSelectorState();
}

class _OptionsSelectorState extends State<OptionsSelector> {
  int? selectedOption;

  @override
  void initState() {
    super.initState();
    selectedOption = widget.initialValue;
  }

  @override
  void didUpdateWidget(covariant OptionsSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      setState(() {
        selectedOption = widget.initialValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isExpanded) {
      return Row(
        spacing: kSmallPadding,
        children: List.generate(widget.options.length, (i) => _buildOption(i)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final List<List<int>> rows = [];
        List<int> currentRow = [];
        double currentLineWidth = 0.0;

        for (int i = 0; i < widget.options.length; i++) {
          final double itemWidth = (widget.options[i].length * 12.0) + 70.0;
          if (currentRow.isNotEmpty &&
              (currentLineWidth + itemWidth + kSmallPadding >
                  constraints.maxWidth)) {
            rows.add(currentRow);
            currentRow = [i];
            currentLineWidth = itemWidth;
          } else {
            currentRow.add(i);
            currentLineWidth +=
                itemWidth + (currentRow.length > 1 ? kSmallPadding : 0);
          }
        }
        if (currentRow.isNotEmpty) rows.add(currentRow);

        return Column(
          spacing: kSmallPadding,
          children: rows.map((rowItems) {
            return Row(
              spacing: kSmallPadding,
              children: rowItems.map((index) => _buildOption(index)).toList(),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildOption(int index) {
    final isSelected = index == selectedOption;
    final option = widget.options[index];

    Color bgColor = context.foreground;
    if (isSelected) {
      bgColor = widget.activeColors?[index] ?? context.primary;
    }

    final icon = widget.activeIcons?[index] ?? LucideIcons.dot;

    final child = AnimatedContainer(
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
        hideText: selectedOption != null && !isSelected && widget.isExpanded,
        disabled: widget.disabled,
        color: isSelected
            ? bgColor
            : selectedOption == null
            ? null
            : context.secondary,
        onPressed: widget.disabled
            ? null
            : () {
                final newValue = selectedOption == index ? null : index;
                setState(() => selectedOption = newValue);
                widget.onChanged(newValue);
              },
      ),
    );

    int flex = 1;
    if (widget.isExpanded) {
      flex = isSelected || selectedOption == null ? 1 : 0;
    } else {
      flex = option.isEmpty ? 1 : option.length + 3;
    }

    return Expanded(flex: flex, child: child);
  }
}
