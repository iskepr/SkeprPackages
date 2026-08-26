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
    this.onPressed,
  });

  final String title;
  final IconData icon;
  final double size;
  final String? fontFamily;
  final Color? color;
  final String? tooltipTitle;
  final bool hideText;
  final bool disabled;
  final void Function()? onPressed;

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

  @override
  void dispose() {
    _timer?.cancel();
    if (_currentOpenState == this) _currentOpenState = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showText = !widget.hideText || _isOpened;

    final Widget child = Row(
      mainAxisSize: MainAxisSize.min,
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
        AnimatedSize(
          duration: kAnimationDuration,
          curve: kCurveEaseInOut,
          child: ClipRect(
            child: AnimatedOpacity(
              duration: kAnimationDuration,
              curve: kCurveEaseInOut,
              opacity: showText ? 1 : 0,
              child: Container(
                constraints: showText
                    ? const BoxConstraints()
                    : const BoxConstraints(maxWidth: 0),
                padding: EdgeInsetsDirectional.only(start: widget.size * 0.3),
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: widget.size * 0.8,
                    color: widget.color,
                    fontFamily: widget.fontFamily,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (!widget.disabled && (widget.hideText || widget.onPressed != null)) {
      return GestureDetector(
        onTap: () {
          if (widget.hideText) _handleTap();
          widget.onPressed?.call();
        },
        behavior: HitTestBehavior.opaque,
        child: child,
      );
    }

    return child;
  }
}
