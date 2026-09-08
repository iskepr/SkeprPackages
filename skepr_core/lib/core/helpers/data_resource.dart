import "package:flutter/foundation.dart";
import "package:skepr_core/local.dart";
import "package:skepr_core/skepr_core.dart";

const String kFisDeleted = "is_deleted";
const String kFupdatedAt = "updated_at";
const String kFid = "id";

// مفاتيح التخزين داخل نفس البوكس
const String kCacheMetaDependency = "__dep__";
const String kCacheMetaLastFetch = "__time__";
const String kCacheDefaultDataKey = "__data__";

class DataResource<T> {
  static Future<void> handle<T>({
    required String cacheKey,
    String? subKey,
    required Future<dynamic> Function(String? lastSyncTime) fetcher,
    required T Function(Map<String, dynamic> map) mapper,
    dynamic Function(T item)? getId,
    String remoteIdKey = kFid,
    List<T> Function(List<T> data)? processor,
    required Function(List<T> data) onLoading,
    required Function(List<T> data) onSuccess,
    required Function(String error) onError,
    bool isForceRefresh = false,
    String? dependencyKey,
    Duration? validDuration,
  }) async {
    try {
      final effectiveDataKey = subKey ?? kCacheDefaultDataKey;
      bool needsFullRefresh = isForceRefresh;

      // 1. التحقق من مفتاح التبعية
      if (dependencyKey != null) {
        try {
          final oldDepKey = HiveHelper.getData<String>(
            cacheKey,
            key: kCacheMetaDependency,
          );
          if (oldDepKey != dependencyKey) {
            needsFullRefresh = true;
          }
        } catch (_) {}
      }

      // 2. التحقق من صلاحية الكاش (TTL)
      if (validDuration != null && !needsFullRefresh) {
        try {
          final lastFetchStr = HiveHelper.getData<String>(
            cacheKey,
            key: kCacheMetaLastFetch,
          );
          if (lastFetchStr != null) {
            final lastFetch = DateTime.parse(lastFetchStr);
            if (DateTime.now().difference(lastFetch) > validDuration) {
              needsFullRefresh = true;
            }
          } else {
            needsFullRefresh = true;
          }
        } catch (_) {}
      }

      // 3. جلب الداتا المتكاشة بمفتاح محدد لتجنب التضارب
      List<T> cachedData = [];
      try {
        cachedData = HiveHelper.getListDataByKey<T>(cacheKey, effectiveDataKey);
      } catch (e) {
        cachedData = [];
      }

      final List<T> currentData = List.from(cachedData);

      String? lastSyncTime;
      if (currentData.isNotEmpty && !needsFullRefresh) {
        try {
          lastSyncTime = HiveHelper.getData<String>(
            cacheKey,
            key: kCacheMetaLastFetch,
          );
        } catch (_) {}
        onLoading(currentData);
      } else if (needsFullRefresh) {
        onLoading(currentData);
      }

      if (!await internetIsConnected) return;

      dynamic response;
      try {
        response = await fetcher(lastSyncTime);
      } catch (e) {
        debugPrint("Fetcher with lastSync failed: $e");
      }
      debugPrint(response.toString());

      final List rawList = (response is List) ? response : [];
      if (rawList.isEmpty && currentData.isNotEmpty && !needsFullRefresh) {
        onSuccess(currentData);
        return;
      }
      List<T> data;

      // دمج التعديلات لو مش تحديث كامل
      if (getId != null && currentData.isNotEmpty && !needsFullRefresh) {
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
            dataMap[newId] = mapper(row);
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

      // 4. حفظ البيانات والميتاداتا داخل نفس البوكس بمفاتيح منفصلة
      try {
        await HiveHelper.saveListDataByKey<T>(cacheKey, effectiveDataKey, data);

        if (dependencyKey != null) {
          await HiveHelper.saveData<String>(
            cacheKey,
            dependencyKey,
            key: kCacheMetaDependency,
          );
        }

        await HiveHelper.saveData<String>(
          cacheKey,
          DateTime.now().toUtc().toIso8601String(),
          key: kCacheMetaLastFetch,
        );
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
