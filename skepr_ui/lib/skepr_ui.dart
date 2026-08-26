import "package:flutter/material.dart";
import "package:skepr_ui/generated/skepr_localizations.dart";

export "package:lucide_icons_flutter/lucide_icons.dart";

// extensions
export "./core/extensions/extensions.dart";
// services
export "./core/services/vibration_services.dart";
// theme
export "./core/theme/colors.dart";
export "./core/theme/material.dart";
// utils
export "./core/utils/platform_utils.dart";
export "./core/utils/show_message.dart";
// ----------------
export "./generated/skepr_localizations.dart";
// widgets
export "./widgets/custom_list_tile.dart";
export "./widgets/inputs/input.dart";
export "./widgets/markdown.dart";
export "./widgets/section/section.dart";
export "./widgets/show_dialog.dart";
export "./widgets/text_icon.dart";

// constants
const String kSkeprWebsite = "https://skepr.me";

SkeprLocalizations get l10n => SkeprMaterial.l10n;

class SkeprMaterial {
  static BuildContext Function()? _contextGetter;
  static UserData Function()? _userInfoProvider;
  static String Function()? _appVersionProvider;
  static void Function(String screenName)? onScreenTracked;

  static void setup({
    required BuildContext Function() getContext,
    UserData Function()? userInfoProvider,
    String Function()? appVersionProvider,
    void Function(String screenName)? onScreenTracked,
  }) {
    _contextGetter = getContext;
    _userInfoProvider = userInfoProvider;
    _appVersionProvider = appVersionProvider;
    SkeprMaterial.onScreenTracked = onScreenTracked;
  }

  static BuildContext? get currentContext => _contextGetter!();
  static NavigatorState? get navigator => Navigator.maybeOf(currentContext!);
  static GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static TextDirection get textDirection => Directionality.of(currentContext!);
  static bool get isRTL => textDirection == TextDirection.rtl;

  static SkeprLocalizations get l10n => SkeprLocalizations.of(currentContext!)!;
  static bool get isArabic =>
      Localizations.localeOf(currentContext!).languageCode == "ar";

  static UserData? get currentUser => _userInfoProvider?.call();
  static String get appVersion => _appVersionProvider?.call() ?? "1.0.0";
}

class UserData {
  final int? id;
  final String name;
  final String email;
  final String type;

  const UserData({
    this.id,
    required this.name,
    required this.email,
    required this.type,
  });
}
