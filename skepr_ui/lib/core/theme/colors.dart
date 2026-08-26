import "package:flutter/material.dart";

// Fonts Family
const String kFontsPath = "assets/fonts/";
const String kMainFont = "MiSans";

// Fonts Size
const double kSoSmallFont = 12;
const double kSmallFont = 14;
const double kMediumFont = 16;
const double kLargeFont = 20;
const double kSoLargeFont = 24;

// Paddings
const double kSmallPadding = 5;
const double kMediumPadding = 10;
const double kLargePadding = 15;
const double kDefaultPadding = 20;

// Border Radius
const double kSoSmallBorderRadius = 15;
const double kSmallBorderRadius = 26;
const double kMediumBorderRadius = 30;
const double kLargeBorderRadius = 50;
const double kCircleBorderRadius = 100;

// Animations Durations & Curves
const Duration kAnimationFasterDuration = Duration(milliseconds: 200);
const Duration kAnimationDuration = Duration(milliseconds: 350);
const Duration kAnimationSlowerDuration = Duration(milliseconds: 500);

const Curve kCurveEaseInOut = Curves.easeInOut;
const Curve kCurveEaseOutBack = Curves.easeOutBack;

extension ThemeContext on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  Color get primary => colorScheme.primary;
  Color get text => colorScheme.onSurface;
  Color get secondary => colorScheme.secondary;
  Color get third => colorScheme.surface;
  Color get border => colorScheme.outline;
  Color get shadow => colorScheme.shadow;
  Color get background => colorScheme.surface;
  Color get foreground => colorScheme.surfaceContainer;
  Color get error => colorScheme.error;
  Color get success => colorScheme.tertiary;
  Color get warning => Colors.orange;

  Color get cardBackground => colorScheme.surfaceContainerHigh;
}
