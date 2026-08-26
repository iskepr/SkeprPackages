import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";

export "package:skepr_ui/core/models/select_entity.dart";
export "package:skepr_ui/core/utils/validators.dart";
export "package:skepr_ui/widgets/button.dart";
export "package:skepr_ui/widgets/inputs/radio_input.dart";
export "package:skepr_ui/widgets/inputs/select_input.dart";
export "package:skepr_ui/widgets/inputs/text.dart";

enum InputType { text, textArea, select, number }

class Input extends StatefulWidget {
  const Input({
    super.key,
    this.labelText,
    this.controller,
    this.validate,
    this.type = InputType.text,
    this.bg,
    this.minLength,
    this.maxLength,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.items,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.withButton,
    this.disableButton = false,
    this.focusNode,
    this.onSubmite,
    this.value = "",
    this.valueDouble = 0,
    this.isPass = false,
    this.hasBorder = true,
    this.whiteBG,
    this.disabled = false,
    this.margin,
    this.axis = Axis.horizontal,
    this.keyType = TextInputType.text,
    this.autofillHints,
    this.fullWidth = false,
  });

  final String? labelText, value;
  final TextEditingController? controller;
  final String? Function(String?)? validate;
  final List<SelectEntity>? items;
  final Function(String)? onSubmitted;
  final Function()? onTap, onSubmite;
  final IconData? withButton;
  final bool disableButton;
  final FocusNode? focusNode;
  final int? minLength;
  final int? maxLength;
  final int? maxLines;
  final double valueDouble;
  final InputType type;
  final bool isPass, hasBorder;
  final bool? whiteBG;
  final bool disabled;
  final Color? bg;
  final TextAlign textAlign;
  final ValueChanged<String?>? onChanged;
  final EdgeInsets? margin;
  final Axis? axis;
  final TextInputType keyType;
  final Iterable<String>? autofillHints;
  final bool fullWidth;

  @override
  State<Input> createState() => _InputState();
}

class _InputState extends State<Input> {
  bool whiteBG = true;
  @override
  void initState() {
    super.initState();
    whiteBG = widget.whiteBG ?? !widget.hasBorder;
  }

  InputDecoration _decoration() {
    final color = widget.bg ?? Colors.transparent;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        (widget.maxLines == null || widget.maxLines! > 1)
            ? kMediumBorderRadius
            : kCircleBorderRadius,
      ),
      borderSide: const BorderSide(color: Colors.transparent),
    );

    return InputDecoration(
      isDense: true,
      hintText: widget.labelText,
      hintStyle: const TextStyle(fontSize: kSmallFont),
      labelStyle: const TextStyle(color: Colors.grey),
      border: border,
      disabledBorder: border,
      enabledBorder: border,
      focusedBorder: border,
      hoverColor: Colors.transparent,
      filled: true,
      fillColor: color,
      counterText: "",
      contentPadding: EdgeInsets.symmetric(
        vertical: kMediumPadding,
        horizontal: widget.withButton != null ? 0 : kSmallPadding,
      ),
      constraints: const BoxConstraints(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == InputType.select) {
      return SelectInput(
        whiteBG: whiteBG,
        hasBorder: widget.hasBorder,
        title: widget.labelText!,
        value: widget.value,
        items: widget.items!,
        onChanged: widget.onChanged!,
        validator: widget.validate,
      );
    }

    return TextF(
      controller: widget.controller!,
      isPass: widget.isPass,
      hasBorder: widget.hasBorder,
      wBG: whiteBG,
      bg: widget.bg,
      margin: widget.margin,
      textAlign: widget.textAlign,
      decoration: _decoration(),
      desabled: widget.disabled,
      validate: widget.validate,
      withButton: widget.withButton,
      disableButton: widget.disableButton,
      focusNode: widget.focusNode,
      maxLength: widget.maxLength,
      maxLines: widget.type == InputType.textArea ? null : 1,
      onChanged: widget.onChanged,
      onSubmite: widget.onSubmite,
      onSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      type: widget.type,
      keyType: widget.keyType,
      autofillHints: widget.autofillHints,
    );
  }
}
