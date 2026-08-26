import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";

class BarButton extends StatelessWidget {
  const BarButton({
    super.key,
    required this.icon,
    this.title,
    required this.onPressed,
    this.isActive = false,
    required this.buttonsLength,
  });

  final IconData icon;
  final String? title;
  final Function() onPressed;
  final bool isActive;
  final int buttonsLength;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? context.text.withValues(alpha: 0.8) : Colors.grey;

    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: kAnimationFasterDuration,
        curve: kCurveEaseInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: kMediumPadding * 1.2,
          vertical: kSmallPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isActive
                  ? (title != null ? 1.1 : 1.6)
                  : (title != null ? 1.0 : 1.4),
              duration: kAnimationFasterDuration,
              curve: kCurveEaseOutBack,
              child: Icon(
                icon,
                textDirection: TextDirection.ltr,
                size: kSoLargeFont,
                color: color,
              ),
            ),
            if (title != null)
              AnimatedSize(
                duration: kAnimationDuration,
                curve: kCurveEaseInOut,
                child: isActive
                    ? Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          title!,
                          style: TextStyle(
                            color: color,
                            fontSize: kSoLargeFont / 2,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}
