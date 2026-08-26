import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:skepr_ui/skepr_ui.dart";

class NumberInput extends StatefulWidget {
  const NumberInput({
    super.key,
    required this.value,
    this.title,
    this.onChanged,
    this.min = 0,
    this.max = 100,
  });

  final double value;
  final double min;
  final double max;
  final String? title;
  final void Function(double value)? onChanged;

  @override
  State<NumberInput> createState() => _NumberInputState();
}

class _NumberInputState extends State<NumberInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.format);
  }

  @override
  void didUpdateWidget(NumberInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final String newText = widget.value.format;
      if (_controller.text != newText) {
        _controller.text = newText;
      }
    }
  }

  void _handleUpdate(double newValue) {
    final clampedValue = newValue.clamp(widget.min, widget.max);
    widget.onChanged?.call(clampedValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: widget.title != null
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.center,
      children: [
        if (widget.title != null)
          Text(widget.title!, style: const TextStyle(fontSize: kMediumFont)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(LucideIcons.minus, size: kLargeFont),
              onPressed: widget.value > widget.min
                  ? () => _handleUpdate(widget.value - 1)
                  : null,
            ),
            SizedBox(
              width: 60,
              child: TextField(
                controller: _controller,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
                ],
                style: const TextStyle(fontSize: kMediumFont),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  if (val.isEmpty) return;
                  final parsed = double.tryParse(val);
                  if (parsed != null) {
                    if (parsed > widget.max) {
                      _handleUpdate(widget.max);
                    } else if (parsed < widget.min) {
                      widget.onChanged?.call(parsed);
                    } else {
                      widget.onChanged?.call(parsed);
                    }
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.plus, size: kLargeFont),
              onPressed: widget.value < widget.max
                  ? () => _handleUpdate(widget.value + 1)
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}
