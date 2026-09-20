import "dart:ui";

import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";

enum MyMaterialTheme { solid, glass }

class MyMaterial extends StatelessWidget {
  const MyMaterial({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(kCircleBorderRadius),
    ),
    this.blurStrength = 2,
    this.height,
    this.width,
    this.whiteBG = true,
    this.theme = MyMaterialTheme.solid,
    this.hasShadow = true,
    this.hasBorder = true,
    this.bg,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding, margin;
  final BorderRadius borderRadius;
  final double blurStrength;
  final double? height;
  final double? width;
  final bool whiteBG;
  final MyMaterialTheme theme;
  final bool hasShadow;
  final bool hasBorder;
  final Color? bg;

  @override
  Widget build(BuildContext context) {
    final bool isGlass = theme == MyMaterialTheme.glass;

    final decoration = BoxDecoration(
      borderRadius: borderRadius,
      gradient: bg != null ? null : _buildGradient(context, isGlass),
      color: bg,
      border: hasBorder ? _buildBorder(context) : null,
      boxShadow: (hasShadow && !isGlass)
          ? [
              BoxShadow(
                color: context.shadow,
                blurRadius: 10,
                blurStyle: BlurStyle.outer,
              ),
            ]
          : null,
    );

    Widget current = AnimatedContainer(
      duration: kAnimationDuration,
      curve: kCurveEaseInOut,
      padding: padding,
      margin: margin,
      height: height,
      width: width,
      decoration: decoration,
      child: child,
    );

    if (isGlass) {
      current = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
          child: current,
        ),
      );
    }

    return RepaintBoundary(
      child: DefaultTextStyle(
        style: DefaultTextStyle.of(
          context,
        ).style.copyWith(color: isGlass ? Colors.white : context.text),
        child: IconTheme(
          data: IconThemeData(color: isGlass ? Colors.white : context.text),
          child: current,
        ),
      ),
    );
  }

  Gradient _buildGradient(BuildContext context, bool isGlass) {
    if (isGlass) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          context.foreground.withValues(alpha: 0.3),
          Colors.transparent,
          context.foreground.withValues(alpha: 0.3),
        ],
      );
    }

    final Color baseColor = whiteBG ? context.foreground : context.background;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [baseColor, baseColor],
      stops: const [0, 1],
    );
  }

  Border _buildBorder(BuildContext context) {
    final side = BorderSide(color: context.border, width: 0.7);
    // final bool isTall = height != null && height! > 100;

    return Border(
      top: side,
      bottom: side,
      // left: isTall ? side.copyWith(width: 0.3) : BorderSide.none,
      // right: isTall ? side.copyWith(width: 0.3) : BorderSide.none,
    );
  }
}
