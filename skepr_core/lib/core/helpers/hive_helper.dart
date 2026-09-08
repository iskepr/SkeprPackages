import "package:flutter/foundation.dart";
import "package:hive_ce_flutter/hive_ce_flutter.dart";
import "package:path_provider/path_provider.dart";

class HiveHelper {
  static const String _syncBoxName = "sync_metadata";
  static const String _syncSuffix = "_last_sync";

  static Future<void> init({
    required List<String> boxes,
    void Function()? registerAdapters,
  }) async {
    if (kIsWeb) {
      await Hive.initFlutter();
    } else {
      final dir = await getApplicationSupportDirectory();
      await Hive.initFlutter(dir.path);
    }

    registerAdapters?.call();
    await _openAllBoxes(boxes);
  }

  static Future<void> _openAllBoxes(List<String> boxes) async {
    final allBoxes = {_syncBoxName, ...boxes};
    for (var box in allBoxes) {
      await openBoxSafely(box);
    }
  }

  static Future<void> openBoxSafely(String boxName) async {
    try {
      await Hive.openBox(boxName);
    } catch (e) {
      debugPrint("Error opening Hive box $boxName: $e. Re-creating box...");
      try {
        await Hive.deleteBoxFromDisk(boxName);
        await Hive.openBox(boxName);
      } catch (fatalError) {
        debugPrint("Fatal error creating Hive box $boxName: $fatalError");
        rethrow;
      }
    }
  }

  static Box getBox(String boxName) => Hive.box(boxName);

  static Future<void> clear({required List<String> boxes}) async {
    for (var boxName in [_syncBoxName, ...boxes]) {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).clear();
      }
    }
  }

  static Future<void> saveListData<T>(String boxName, List<T> data) async {
    final box = Hive.box(boxName);
    await box.clear();
    await box.addAll(data);
  }

  static List<T> getListData<T>(String boxName) {
    final box = Hive.box(boxName);
    if (box.isEmpty) return [];

    final result = <T>[];
    for (final value in box.values) {
      if (value is List) {
        result.addAll(value.whereType<T>());
      } else if (value is T) {
        result.add(value);
      }
    }
    return result;
  }

  static Future<void> saveData<T>(String boxName, T data, {String? key}) async {
    final box = Hive.box(boxName);
    await box.put(key ?? 0, data);
  }

  static T? getData<T>(String boxName, {String? key}) {
    final box = Hive.box(boxName);
    final data = box.get(key ?? 0);
    if (data == null) return null;
    return data as T;
  }

  static List<T> getListDataByKey<T>(String boxName, String key) {
    final box = Hive.box(boxName);
    final data = box.get(key);
    if (data == null) return [];
    return List<T>.from(data);
  }

  static Future<void> saveListDataByKey<T>(
    String boxName,
    String key,
    List<T> data,
  ) async {
    final box = Hive.box(boxName);
    await box.put(key, data);
  }

  static T? getTDataByKey<T>(String boxName, [dynamic key]) {
    final box = Hive.box(boxName);
    final data = box.get(key ?? 0);
    if (data == null) return null;
    return data as T;
  }

  static Future<void> saveTDataByKey<T>(
    T data,
    String boxName, [
    dynamic key,
  ]) async {
    final box = Hive.box(boxName);
    await box.put(key ?? 0, data);
  }

  static Future<void> saveLastSyncTime(
    String tableName,
    String isoTimestamp,
  ) async {
    final box = Hive.box(_syncBoxName);
    await box.put("$tableName$_syncSuffix", isoTimestamp);
  }

  static String? getLastSyncTime(String tableName) {
    final box = Hive.box(_syncBoxName);
    return box.get("$tableName$_syncSuffix") as String?;
  }
}
