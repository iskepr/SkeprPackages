import "dart:ui";

import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";

const bool kSolidPathAddsShadow = false;

const double kMaxGlassSigma = 8.0;

const bool kRespectReduceMotion = true;

const bool kUseGroupedBackdrop = true;

@immutable
class SkeprGlassSettings extends ThemeExtension<SkeprGlassSettings> {
  const SkeprGlassSettings({required this.glassEnabled});

  final bool glassEnabled;

  @override
  SkeprGlassSettings copyWith({bool? glassEnabled}) {
    return SkeprGlassSettings(glassEnabled: glassEnabled ?? this.glassEnabled);
  }

  @override
  SkeprGlassSettings lerp(covariant SkeprGlassSettings? other, double t) {
    if (other == null || t < 0.5) return this;
    return other;
  }
}

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
    final glassSettings = Theme.of(context).extension<SkeprGlassSettings>();
    final bool wantGlass =
        theme == MyMaterialTheme.glass && (glassSettings?.glassEnabled ?? true);

    if (!wantGlass) return _buildSolid(context);
    if (kRespectReduceMotion && MediaQuery.disableAnimationsOf(context)) {
      return _buildSolid(context);
    }
    if (!TickerMode.of(context)) return _buildSolid(context);

    return _buildGlass(context);
  }

  Widget _buildSolid(BuildContext context) {
    final Color baseColor =
        bg ?? ((whiteBG) ? context.foreground : context.background);

    return Container(
      padding: padding,
      margin: margin,
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: baseColor,
        border: hasBorder ? _buildBorder(context) : null,
        boxShadow: (hasShadow && kSolidPathAddsShadow)
            ? [
                BoxShadow(
                  color: context.shadow,
                  offset: const Offset(0, 2),
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: DefaultTextStyle(
        style: DefaultTextStyle.of(context).style.copyWith(color: context.text),
        child: IconTheme(
          data: IconThemeData(color: context.text),
          child: child,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GLASS PATH — six stacked optimisations.
  //
  //   1. BackdropGroup batching  → N glass widgets = 1 blur pass
  //   2. AnimatedContainer OUTSIDE the blur → no re-blur during animation
  //   3. ClipRRect BEFORE BackdropFilter     → small widget = small sample
  //   4. TileMode.decal                       → cheaper edge sampling
  //   5. sigma clamped to kMaxGlassSigma      → prevents designer blowups
  //   6. Auto-degrade on low-power / TickerMode off
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildGlass(BuildContext context) {
    final double sigma = blurStrength.clamp(0.0, kMaxGlassSigma);
    if (sigma <= 0) return _buildSolid(context);

    final ImageFilter filter = ImageFilter.blur(
      sigmaX: sigma,
      sigmaY: sigma,
      tileMode: TileMode.decal,
    );

    final Widget contentOnTop = Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: bg == null ? _glassTint(context) : null,
        color: bg,
        border: hasBorder ? _buildBorder(context) : null,
      ),
      padding: padding,
      child: DefaultTextStyle(
        style: DefaultTextStyle.of(context).style.copyWith(color: Colors.white),
        child: IconTheme(
          data: const IconThemeData(color: Colors.white),
          child: child,
        ),
      ),
    );

    final Widget blurred = ClipRRect(
      borderRadius: borderRadius,
      child: RepaintBoundary(
        child: kUseGroupedBackdrop
            ? BackdropFilter.grouped(filter: filter, child: contentOnTop)
            : BackdropFilter(filter: filter, child: contentOnTop),
      ),
    );

    if (margin == null && height == null && width == null) return blurred;
    return AnimatedContainer(
      duration: kAnimationDuration,
      curve: kCurveEaseInOut,
      margin: margin,
      height: height,
      width: width,
      child: blurred,
    );
  }

  Gradient _glassTint(BuildContext context) {
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

  Border _buildBorder(BuildContext context) {
    final side = BorderSide(color: context.border, width: 0.7);
    return Border(top: side, bottom: side);
  }
}
