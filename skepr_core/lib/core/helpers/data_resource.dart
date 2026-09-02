import "package:flutter/foundation.dart";
import "package:skepr_core/local.dart";
import "package:skepr_core/skepr_core.dart";

const String kFisDeleted = "is_deleted";
const String kFupdatedAt = "updated_at";
const String kFid = "id";

class DataResource<T> {
  static Future<void> handle<T>({
    required String cacheKey,
    String? subKey,
    required Future<dynamic> Function(String? lastSyncTime) fetcher,
    required T Function(Map<String, dynamic> map) mapper,
    dynamic Function(T item)? getId,
    String remoteIdKey = "id",
    List<T> Function(List<T> data)? processor,
    required Function(List<T> data) onLoading,
    required Function(List<T> data) onSuccess,
    required Function(String error) onError,
    bool isForceRefresh = false,
  }) async {
    try {
      List<T> cachedData = [];
      try {
        if (subKey != null) {
          cachedData = HiveHelper.getListDataByKey<T>(cacheKey, subKey);
        } else {
          cachedData = HiveHelper.getListData<T>(cacheKey);
        }
      } catch (e) {
        cachedData = [];
      }

      final List<T> currentData = List.from(cachedData);
      String? lastSyncTime;

      if (currentData.isNotEmpty && !isForceRefresh) {
        try {
          final timestamps = currentData
              .map((e) {
                try {
                  final upTime = (e as dynamic).updatedAt;
                  if (upTime != null) return upTime.toString();
                } catch (_) {}
                try {
                  final crTime = (e as dynamic).createdAt;
                  if (crTime != null) return crTime.toString();
                } catch (_) {}
                return null;
              })
              .where((e) => e != null && e.isNotEmpty)
              .cast<String>()
              .toList();

          if (timestamps.isNotEmpty) {
            timestamps.sort((a, b) => b.compareTo(a));
            lastSyncTime = timestamps.first;
          }
        } catch (e) {
          debugPrint("Sync Error: $e");
        }

        onLoading(currentData);
      }

      if (!await internetIsConnected) return;

      dynamic response;
      try {
        response = await fetcher(lastSyncTime);
      } catch (e) {
        response = await fetcher(null);
      }

      final List rawList = (response is List) ? response : [];

      List<T> data;

      if (getId != null && currentData.isNotEmpty && !isForceRefresh) {
        final Map<dynamic, T> dataMap = {
          for (var item in currentData) getId(item): item,
        };

        for (var raw in rawList) {
          final row = Map<String, dynamic>.from(raw as Map);
          final isDeleted = row[kFisDeleted] == true;
          final newId = row[remoteIdKey];

          if (isDeleted) {
            dataMap.remove(newId);
          } else {
            final newItem = mapper(row);
            dataMap[newId] = newItem;
          }
        }

        data = dataMap.values.toList();
      } else {
        data = rawList
            .where((raw) => (raw as Map)[kFisDeleted] != true)
            .map<T>((raw) => mapper(Map<String, dynamic>.from(raw as Map)))
            .toList();
      }

      if (processor != null) {
        data = processor(data);
      }

      try {
        if (subKey != null) {
          await HiveHelper.saveListDataByKey(cacheKey, subKey, data);
        } else {
          final box = HiveHelper.getBox(cacheKey);
          await box.clear();
          await box.addAll(data);
        }
      } catch (e) {
        debugPrint("Hive Save Warning: $e");
      }

      onSuccess(data);
    } catch (e, t) {
      showError("$e - $t", cacheKey, userMessage: "تحديث البيانات");
      onError("حصلت مشكلة في جلب البيانات");
    }
  }
}
