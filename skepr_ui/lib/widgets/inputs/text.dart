import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";

class TextF extends StatefulWidget {
  const TextF({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.onTap,
    this.onSubmite,
    this.withButton,
    required this.disableButton,
    this.focusNode,
    this.maxLength,
    this.maxLines = 1,
    required this.isPass,
    required this.hasBorder,
    required this.wBG,
    this.bg,
    required this.textAlign,
    this.onChanged,
    required this.decoration,
    required this.desabled,
    this.validate,
    this.margin,
    required this.type,
    this.keyType,
    this.autofillHints,
  });

  final TextEditingController controller;
  final Function(String)? onSubmitted;
  final Function()? onTap, onSubmite;
  final IconData? withButton;
  final bool disableButton;
  final FocusNode? focusNode;
  final int? maxLength;
  final int? maxLines;
  final bool isPass, hasBorder, desabled;
  final bool wBG;
  final Color? bg;
  final TextAlign textAlign;
  final Function(String)? onChanged;
  final InputDecoration decoration;
  final String? Function(String?)? validate;
  final EdgeInsets? margin;
  final InputType type;
  final TextInputType? keyType;
  final Iterable<String>? autofillHints;

  @override
  State<TextF> createState() => _TextFState();
}

class _TextFState extends State<TextF> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPass;
  }

  @override
  Widget build(BuildContext context) {
    final multiLines = widget.type == InputType.textArea;

    return FormField(
      validator: widget.validate,
      initialValue: widget.controller.text,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyMaterial(
              whiteBG: widget.wBG,
              hasShadow: false,
              borderRadius: BorderRadius.circular(kSmallBorderRadius),
              hasBorder: widget.hasBorder,
              margin:
                  widget.margin ??
                  const EdgeInsets.symmetric(vertical: kSmallPadding),
              child: Row(
                crossAxisAlignment: multiLines
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.center,
                children: [
                  if (widget.withButton != null) _buildButton(context),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      obscureText: _obscureText,
                      maxLength: widget.maxLength,
                      maxLines: _obscureText ? 1 : widget.maxLines,
                      textAlign: widget.textAlign,
                      enabled: !widget.desabled,
                      onTap: widget.onTap,
                      focusNode: widget.focusNode,
                      autofillHints: widget.autofillHints,
                      keyboardType: multiLines
                          ? TextInputType.multiline
                          : widget.keyType,
                      onSubmitted: (value) {
                        widget.onSubmite?.call();
                        widget.onSubmitted?.call(widget.controller.text);
                      },
                      onChanged: (value) {
                        state.didChange(value);
                        widget.onChanged?.call(value);
                      },
                      decoration: widget.decoration.copyWith(
                        fillColor:
                            widget.bg ??
                            (state.hasError
                                ? context.error.withValues(alpha: 0.1)
                                : Colors.transparent),
                        errorText: null,
                        errorStyle: const TextStyle(height: 0, fontSize: 0),
                        suffixIcon: widget.isPass
                            ? IconButton(
                                icon: Icon(
                                  _obscureText
                                      ? LucideIcons.eye
                                      : LucideIcons.eyeOff,
                                  color: context.secondary,
                                  size: kMediumFont,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureText = !_obscureText;
                                  });
                                },
                              )
                            : widget.decoration.suffixIcon,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (state.hasError)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kSmallPadding),
                child: Text(
                  state.errorText ?? "",
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

  Widget _buildButton(BuildContext context) {
    return GestureDetector(
      onTap: widget.disableButton
          ? null
          : () {
              widget.onSubmite?.call();
              widget.onSubmitted?.call(widget.controller.text);
            },
      child: Container(
        margin: widget.disableButton
            ? null
            : const EdgeInsets.all(kSmallPadding),
        padding: widget.disableButton
            ? const EdgeInsetsDirectional.only(
                start: kLargePadding - 2,
                end: kSmallPadding,
              )
            : const EdgeInsets.all(kSmallPadding),
        decoration: BoxDecoration(
          color: widget.disableButton ? null : context.primary,
          borderRadius: BorderRadius.circular(kCircleBorderRadius),
        ),
        child: Icon(
          widget.withButton,
          color: widget.disableButton ? context.secondary : Colors.white,
          size: widget.disableButton ? kMediumFont : kLargeFont,
        ),
      ),
    );
  }
}
