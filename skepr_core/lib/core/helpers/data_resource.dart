import "package:flutter/foundation.dart";
import "package:skepr_core/local.dart";
import "package:skepr_core/skepr_core.dart";

const String kFisDeleted = "is_deleted";
const String kFupdatedAt = "updated_at";
const String kFid = "id";

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
      bool dependencyChanged = false;

      // 1. فحص التبعية (إذا تغيرت الشعبة أو الكورسات نجلب كل شيء من جديد)
      if (dependencyKey != null) {
        try {
          final oldDepKey = HiveHelper.getData<String>(
            cacheKey,
            key: kCacheMetaDependency,
          );
          if (oldDepKey != dependencyKey) {
            dependencyChanged = true;
          }
        } catch (_) {}
      }

      // 2. قراءة الكاش المحلي أولاً بدون انتظار
      List<T> cachedData = [];
      try {
        cachedData = HiveHelper.getListDataByKey<T>(cacheKey, effectiveDataKey);
      } catch (_) {
        cachedData = [];
      }

      final List<T> currentData = List.from(cachedData);
      final bool hasCache = currentData.isNotEmpty;

      // عرض الكاش للمستخدم فوراً لتفادي شاشات التحميل
      if (hasCache) {
        onLoading(currentData);
      }

      // 3. فحص هل نحتاج طلب بيانات من السيرفر أصلاً؟
      String? lastSyncTime;
      try {
        lastSyncTime = HiveHelper.getData<String>(
          cacheKey,
          key: kCacheMetaLastFetch,
        );
      } catch (_) {}

      bool shouldFetchFromServer =
          isForceRefresh || !hasCache || dependencyChanged;

      if (!shouldFetchFromServer &&
          validDuration != null &&
          lastSyncTime != null) {
        final lastFetch = DateTime.tryParse(lastSyncTime);
        if (lastFetch != null) {
          shouldFetchFromServer =
              DateTime.now().toUtc().difference(lastFetch) > validDuration;
        } else {
          shouldFetchFromServer = true;
        }
      }

      // إذا كان الكاش سارياً ولم تنتهِ مدته، لا داعي للاتصال بالإنترنت نهائياً
      if (!shouldFetchFromServer && hasCache) {
        onSuccess(currentData);
        return;
      }

      // إرسال الطلب (مع استخدام lastSyncTime للمزامنة الجزئية إذا لم تتغير التبعية)
      final String? effectiveSyncTime =
          (isForceRefresh || dependencyChanged || !hasCache)
          ? null
          : lastSyncTime;

      dynamic response;
      try {
        response = await fetcher(effectiveSyncTime);
      } catch (e) {
        debugPrint("Fetcher failed: $e");
        if (hasCache) {
          onSuccess(currentData);
          return;
        }
        rethrow;
      }

      final List rawList = (response is List) ? response : [];

      // إذا لم يرجع الخادم أي تعديلات جديدة
      if (rawList.isEmpty && hasCache && effectiveSyncTime != null) {
        await HiveHelper.saveData<String>(
          cacheKey,
          DateTime.now().toUtc().toIso8601String(),
          key: kCacheMetaLastFetch,
        );
        onSuccess(currentData);
        return;
      }

      List<T> finalData;

      // دمج التعديلات والمسح مع الكاش المحلي
      if (getId != null && hasCache && effectiveSyncTime != null) {
        final Map<dynamic, T> dataMap = {
          for (var item in currentData) getId(item): item,
        };

        for (var raw in rawList) {
          final row = Map<String, dynamic>.from(raw as Map);
          final isDeleted = row[kFisDeleted] == true;
          final dynamic itemId = row[remoteIdKey];

          if (isDeleted) {
            dataMap.remove(itemId);
          } else {
            dataMap[itemId] = mapper(row);
          }
        }
        finalData = dataMap.values.toList();
      } else {
        // استبدال كامل في حال الفحص لأول مرة أو التحديث القسري
        finalData = rawList
            .where((raw) => (raw as Map)[kFisDeleted] != true)
            .map<T>((raw) => mapper(Map<String, dynamic>.from(raw as Map)))
            .toList();
      }

      if (processor != null) {
        finalData = processor(finalData);
      }

      // 4. حفظ البيانات والميتاداتا
      try {
        await HiveHelper.saveListDataByKey<T>(
          cacheKey,
          effectiveDataKey,
          finalData,
        );

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

      onSuccess(finalData);
    } catch (e, t) {
      showError("$e - $t", cacheKey, userMessage: "تحديث البيانات");
      onError("حصلت مشكلة في جلب البيانات");
    }
  }
}
