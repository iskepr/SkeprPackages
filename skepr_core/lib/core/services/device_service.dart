import "dart:io";

import "package:android_id/android_id.dart";
import "package:device_info_plus/device_info_plus.dart";
import "package:flutter/foundation.dart";

class DeviceService {
  static Future<String?> getUniqueDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        final parts = [
          webInfo.browserName.name,
          webInfo.platform ?? "",
          webInfo.vendor ?? "",
          webInfo.userAgent ?? "",
          webInfo.language ?? "",
          (webInfo.languages ?? []).join(","),
          webInfo.hardwareConcurrency?.toString() ?? "",
          webInfo.maxTouchPoints?.toString() ?? "",
          webInfo.deviceMemory?.toString() ?? "",
        ];
        final raw = parts.join("|");
        final hash = _stableHash(raw);
        return "web-$hash";
      } else if (Platform.isAndroid) {
        const androidIdPlugin = AndroidId();
        return await androidIdPlugin.getId();
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor;
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        return linuxInfo.machineId;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  static String _stableHash(String input) {
    const int fnvPrime = 0x01000193;
    int hash = 0x811c9dc5;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, "0");
  }
}
