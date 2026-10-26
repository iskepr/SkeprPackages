import "dart:async";

import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";

class TextIcon extends StatefulWidget {
  const TextIcon(
    this.title, {
    super.key,
    required this.icon,
    this.size = kMediumFont,
    this.fontFamily,
    this.color,
    this.tooltipTitle,
    this.hideText = false,
    this.disabled = false,
    this.markdown = false,
    this.onPressed,
    this.onLongPress,
    this.withBG,
  });

  final String title;
  final IconData icon;
  final double size;
  final String? fontFamily;
  final Color? color;
  final String? tooltipTitle;
  final bool hideText, disabled, markdown;
  final bool? withBG;
  final void Function()? onPressed, onLongPress;

  @override
  State<TextIcon> createState() => _TextIconState();
}

class _TextIconState extends State<TextIcon> {
  static _TextIconState? _currentOpenState;
  bool _isOpened = false;
  Timer? _timer;

  void _close() {
    if (mounted && _isOpened) {
      setState(() => _isOpened = false);
      _timer?.cancel();
    }
  }

  void _handleTap() {
    if (_isOpened) {
      _close();
    } else {
      _currentOpenState?._close();

      setState(() {
        _isOpened = true;
        _currentOpenState = this;
      });

      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 3), () {
        _close();
        if (_currentOpenState == this) _currentOpenState = null;
      });
    }
  }

  double get _responsiveFontSize {
    int spaces = 0;
    for (int i = 0; i < widget.title.length; i++) {
      if (widget.title.codeUnitAt(i) == 32) spaces++; // 32 كود space
    }
    final int wordCount = spaces + 1;

    if (wordCount <= 8) {
      return widget.size * 0.9;
    } else if (wordCount <= 15) {
      return widget.size * 0.85;
    } else {
      return widget.size * 0.70;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showText = !widget.hideText || _isOpened;

    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedScale(
          duration: kAnimationFasterDuration,
          curve: kCurveEaseInOut,
          scale: _isOpened ? 1.1 : 1,
          child: Tooltip(
            message: widget.tooltipTitle ?? widget.title,
            child: Icon(widget.icon, size: widget.size, color: widget.color),
          ),
        ),

        Flexible(
          child: AnimatedSwitcher(
            duration: kAnimationDuration,
            switchInCurve: kCurveEaseInOut,
            switchOutCurve: kCurveEaseInOut,
            layoutBuilder: (currentChild, previousChildren) => Stack(
              alignment: AlignmentDirectional.centerStart,
              clipBehavior: Clip.none,
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            ),
            transitionBuilder: (child, animation) {
              return SizeTransition(
                sizeFactor: animation,
                axis: Axis.horizontal,
                axisAlignment: 0,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: showText
                ? Center(
                    child: Padding(
                      key: const ValueKey("text"),
                      padding: EdgeInsetsDirectional.only(
                        start: widget.size * 0.3,
                      ),
                      child: widget.markdown
                          ? SkeprMarkdown(
                              widget.title,
                              padding: EdgeInsets.zero,
                              color: widget.color,
                              mathBgBox: false,
                              maxWidth:
                                  MediaQuery.sizeOf(context).width -
                                  (widget.size * 4),
                              fontSize: _responsiveFontSize,
                            )
                          : Text(
                              widget.title,
                              softWrap: true,
                              style: TextStyle(
                                fontSize: widget.size * 0.8,
                                color: widget.color,
                                fontFamily: widget.fontFamily,
                              ),
                            ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey("empty")),
          ),
        ),
      ],
    );

    if (widget.withBG == true) {
      child = Container(
        padding: EdgeInsets.symmetric(
          vertical: kSmallPadding * (widget.size / 20),
          horizontal: kLargePadding * (widget.size / 15),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kCircleBorderRadius),
          color: widget.color?.withOpacity(0.2),
        ),
        child: child,
      );
    }

    if (!widget.disabled &&
        (widget.hideText ||
            widget.onPressed != null ||
            widget.onLongPress != null)) {
      return GestureDetector(
        onLongPress: () => widget.onLongPress?.call(),
        onTap: () {
          widget.onPressed?.call();
          if (widget.hideText) _handleTap();
        },
        behavior: HitTestBehavior.opaque,
        child: child,
      );
    }

    return child;
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_currentOpenState == this) _currentOpenState = null;
    super.dispose();
  }
}
