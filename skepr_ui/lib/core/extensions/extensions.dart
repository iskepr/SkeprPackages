import "package:flutter/material.dart";
import "package:intl/intl.dart" hide TextDirection;

export "date_time.dart";
export "string_extensions.dart";

extension StringExtension on String {
  String get removeEl => replaceFirst("ال", "");

  String addEl(String lang) {
    if (lang == "ar") {
      return "ال$this";
    } else {
      return this;
    }
  }
}

extension DirectionalityExtension on BuildContext {
  TextDirection get reverseDirection =>
      Directionality.of(this) == TextDirection.rtl
      ? TextDirection.ltr
      : TextDirection.rtl;
}

extension TimeExtension on String {
  int? get weekDayNumber {
    return int.tryParse(this);
  }

  String get weekDayName {
    final index = weekDayNumber;
    if (index == null) return "";
    return DateFormat.EEEE().format(
      DateTime(2024, 1, (index == 1) ? 7 : index - 1),
    );
  }

  DateTime get timeFromHours {
    if (isEmpty || this == "null") return DateTime(2024, 1, 1);
    final time = split(":");
    if (time.length < 2) return DateTime(2024, 1, 1);

    final hour = int.tryParse(time[0]) ?? 0;
    final minute = int.tryParse(time[1]) ?? 0;

    return DateTime(2024, 1, 1, hour, minute);
  }
}

extension NavigationHelpers on BuildContext {
  void close() {
    if (!mounted) return;

    final navigator = Navigator.of(this);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.popUntil((route) => route.isFirst);
    }
  }
}

extension FormateNames on String {
  String userName({int length = 2}) {
    final parts = split(" ");
    final finalLength = parts.length <= length ? parts.length : length;
    final List<String> names = [];
    for (var i = 0; i < finalLength; i++) {
      names.add(parts[i]);
    }
    return names.join(" ");
  }
}
