import "package:intl/intl.dart";
import "package:skepr_ui/skepr_ui.dart";

extension DateTimeFormat on DateTime {
  String timeOnly([bool per = true]) {
    final isArabic = SkeprMaterial.isArabic;
    final e = isUtc ? toLocal() : this;
    final h = e.hour % 12 == 0 ? 12 : e.hour % 12;
    final p = e.hour >= 12 ? (isArabic ? "م" : "PM") : (isArabic ? "ص" : "AM");
    return "$h:${e.minute.toString().padLeft(2, "0")}${per ? " $p" : ""}";
  }

  String get timeOnlyP => timeOnly();

  String get dateOnlyy {
    final e = isUtc ? toLocal() : this;
    final now = DateTime.now();
    final String yearSuffix = now.year == e.year
        ? ""
        : "/${e.year.toString().substring(2)}";
    return "${e.day}/${e.month}$yearSuffix";
  }

  String get dateOnly {
    final e = isUtc ? toLocal() : this;
    final now = DateTime.now();
    return DateFormat("d MMMM ${now.year == e.year ? "" : "yy"}").format(e);
  }

  String get fullDateTime => "$dateOnly $timeOnlyP";

  String get smartFormat {
    final e = isUtc ? toLocal() : this;
    final now = DateTime.now();
    if (e.day == now.day && e.month == now.month && e.year == now.year) {
      return timeOnlyP;
    }
    return dateOnly;
  }

  String get fullDate {
    final e = isUtc ? toLocal() : this;
    return "${e.day}/${e.month}/${e.year}";
  }

  String get fullSmartFormat {
    final e = isUtc ? toLocal() : this;
    final now = DateTime.now();
    if (e.day == now.day && e.month == now.month && e.year == now.year) {
      return timeOnlyP;
    }
    return fullDateTime;
  }
}

extension FormateTimeDuration on Duration {
  String get formatDuration {
    if (inMinutes == 0) return l10n.notSpecified;

    final h = inHours;
    final m = inMinutes.remainder(60);

    final hoursStr = l10n.hoursCount(h);
    final minutesStr = l10n.minutesCount(m);

    if (h > 0 && m > 0) return "$hoursStr ${l10n.and} $minutesStr";
    if (h > 0) return hoursStr;
    return minutesStr;
  }
}

class DateTimeHelper {
  static DateTime get now => DateTime.now().toUtc();

  static String get nowIso => now.toIso8601String();

  static DateTime afterMinutesIso(int minutes) {
    return now.add(Duration(minutes: minutes));
  }
}
