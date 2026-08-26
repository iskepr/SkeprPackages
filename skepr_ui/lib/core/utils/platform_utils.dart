import "dart:io" show Platform;

import "package:flutter/foundation.dart";

class PlatformUtils {
  static bool get isWeb => kIsWeb;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isLinux => !kIsWeb && Platform.isLinux;
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  static bool get isDesktop =>
      !kIsWeb && (Platform.isMacOS || Platform.isLinux || Platform.isWindows);

  static String get platformName {
    if (kIsWeb) return "Web";
    if (Platform.isAndroid) return "Android";
    if (Platform.isIOS) return "iOS";
    if (Platform.isLinux) return "Linux";
    if (Platform.isWindows) return "Windows";
    if (Platform.isMacOS) return "MacOS";
    return "Unknown";
  }

  static void runOnlyOnNative(VoidCallback action) {
    if (!kIsWeb) action();
  }

  static void runOnlyOnMobile(VoidCallback action) {
    if (isMobile) action();
  }
}
