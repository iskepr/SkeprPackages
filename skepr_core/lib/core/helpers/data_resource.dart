import "package:flutter/foundation.dart";
import "package:skepr_core/local.dart";
import "package:skepr_core/skepr_core.dart";

const String kFisDeleted = "is_deleted";
const String kFupdatedAt = "updated_at";
const String kFid = "id";

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
      final metaTimeKey = "${effectiveDataKey}__time__";
      final metaDepKey = "${effectiveDataKey}__dep__";

      bool needsFullRefresh = isForceRefresh;

      // 1. فحص التبعية
      if (dependencyKey != null) {
        try {
          final oldDepKey = HiveHelper.getData<String>(
            cacheKey,
            key: metaDepKey,
          );
          if (oldDepKey != dependencyKey) {
            needsFullRefresh = true;
          }
        } catch (_) {}
      }

      // 2. فحص صلاحية الكاش (TTL)
      String? lastSyncTime;
      try {
        lastSyncTime = HiveHelper.getData<String>(cacheKey, key: metaTimeKey);
      } catch (_) {}

      if (validDuration != null && !needsFullRefresh && lastSyncTime != null) {
        final lastFetch = DateTime.tryParse(lastSyncTime);
        if (lastFetch != null) {
          final diff = DateTime.now().toUtc().difference(lastFetch.toUtc());
          if (diff > validDuration) {
            needsFullRefresh = true;
          }
        } else {
          needsFullRefresh = true;
        }
      }

      // 3. جلب الكاش وعرضه فوراً لمنع تعليق الـ UI
      List<T> cachedData = [];
      try {
        cachedData = HiveHelper.getListDataByKey<T>(cacheKey, effectiveDataKey);
      } catch (_) {
        cachedData = [];
      }

      final List<T> currentData = List.from(cachedData);
      if (currentData.isNotEmpty) {
        onLoading(currentData);
      }

      // 4. لو الكاش ساري ومش مطلوب Full Refresh، والمدة لم تنتهِ
      if (!needsFullRefresh &&
          validDuration != null &&
          currentData.isNotEmpty) {
        final lastFetch = DateTime.tryParse(lastSyncTime ?? "");
        if (lastFetch != null &&
            DateTime.now().toUtc().difference(lastFetch.toUtc()) <=
                validDuration) {
          onSuccess(currentData);
          return;
        }
      }

      // 5. فحص اتصال الإنترنت
      if (kIsWeb ? false : !await internetIsConnected) {
        if (currentData.isNotEmpty) {
          onSuccess(currentData);
        } else {
          onError("لا يوجد اتصال بالإنترنت");
        }
        return;
      }

      // 6. استدعاء السيرفر
      final syncTimeForFetcher = needsFullRefresh ? null : lastSyncTime;
      dynamic response;
      try {
        response = await fetcher(syncTimeForFetcher);
      } catch (e) {
        debugPrint("DataResource Fetcher Error: $e");
        if (currentData.isNotEmpty) {
          onSuccess(currentData);
          return;
        }
        rethrow;
      }

      final List rawList = (response is List) ? response : [];

      // لو مفيش تعديلات جديدة والسيرفر رجع فاضي
      if (rawList.isEmpty && currentData.isNotEmpty && !needsFullRefresh) {
        await HiveHelper.saveData<String>(
          cacheKey,
          DateTime.now().toUtc().toIso8601String(),
          key: metaTimeKey,
        );
        onSuccess(currentData);
        return;
      }

      // 7. دمج البيانات
      List<T> data;
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

      // 8. حفظ البيانات والـ Meta بالمفاتيح الصحيحة
      try {
        await HiveHelper.saveListDataByKey<T>(cacheKey, effectiveDataKey, data);

        if (dependencyKey != null) {
          await HiveHelper.saveData<String>(
            cacheKey,
            dependencyKey,
            key: metaDepKey,
          );
        }

        await HiveHelper.saveData<String>(
          cacheKey,
          DateTime.now().toUtc().toIso8601String(),
          key: metaTimeKey,
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
