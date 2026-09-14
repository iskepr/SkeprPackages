import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";
import "package:skepr_ui/widgets/loading.dart";

enum MyButtonTheme { solid, glass, colorful }

class Button extends StatelessWidget {
  const Button({
    super.key,
    required this.title,
    this.icon,
    this.onPressed,
    this.theme = MyButtonTheme.colorful,
    this.padding = const EdgeInsets.all(kSmallPadding),
    this.tooltipTitle,
    this.size,
    this.bg,
    this.disable = false,
    this.fullWidth = true,
    this.isLoading = false,
    this.longPress = false,
  });

  final String title;
  final IconData? icon;
  final VoidCallback? onPressed;
  final MyButtonTheme theme;
  final EdgeInsets padding;
  final String? tooltipTitle;
  final double? size;
  final Color? bg;
  final bool disable, fullWidth, isLoading, longPress;

  @override
  Widget build(BuildContext context) {
    final Widget button = theme == MyButtonTheme.colorful
        ? buildButton(context)
        : MyMaterial(child: buildButton(context));

    if (disable && tooltipTitle != null && tooltipTitle!.isNotEmpty) {
      return Tooltip(message: tooltipTitle!, child: button);
    }

    return button;
  }

  Widget buildButton(BuildContext context) {
    final bool isActionable = !disable && !isLoading && onPressed != null;
    final Color effectiveBg = disable
        ? context.secondary
        : bg ??
              (theme == MyButtonTheme.colorful
                  ? context.primary
                  : Colors.transparent);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Material(
        color: theme == MyButtonTheme.colorful
            ? effectiveBg.withValues(alpha: 0.5)
            : effectiveBg,
        borderRadius: BorderRadius.circular(
          theme == MyButtonTheme.colorful
              ? kLargeBorderRadius
              : kSmallBorderRadius,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isActionable && !longPress ? onPressed : null,
          onLongPress: isActionable && longPress ? onPressed : null,
          child: Container(
            width: fullWidth ? double.infinity : null,
            padding: padding,
            child: Center(child: _buildContent(context)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return Loading(size: 10, color: context.foreground);
    }

    if (icon != null) {
      return TextIcon(
        title,
        icon: icon!,
        size: size ?? kMediumFont,
        disabled: true,
      );
    }

    return Text(
      title,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: theme == MyButtonTheme.colorful ? Colors.white : null,
      ),
    );
  }
}
