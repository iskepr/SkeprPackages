import "package:flutter/material.dart";
import "package:vibration/vibration.dart";

class VibrationService {
  static Future<void> _execute(Function(bool hasVibrator) action) async {
    try {
      final bool has = await Vibration.hasVibrator();
      if (has == true) {
        action(true);
      }
    } catch (e) {
      assert(() {
        debugPrint("Vibration Error: $e");
        return true;
      }());
    }
  }

  static void run({List<int>? pattern, int? duration}) {
    _execute((has) {
      if (pattern != null) {
        Vibration.vibrate(pattern: pattern);
      } else if (duration != null) {
        Vibration.vibrate(duration: duration);
      }
    });
  }

  static void stop() {
    _execute((has) => Vibration.cancel());
  }

  static void light() => run(duration: 50);
  static void medium() => run(duration: 150);
  static void strong() => run(duration: 300);

  static void pulse() => run(pattern: [0, 100, 100, 100]);
}
