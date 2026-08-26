import "package:flutter/material.dart";
import "package:skepr_core/local.dart";
import "package:skepr_core/skepr_core.dart";
import "package:supabase_flutter/supabase_flutter.dart";

class SupabaseService extends DatabaseClient {
  static SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Session? get currentSession => _supabase.auth.currentSession;

  @override
  Future<void> init({required String url, required String anonKey}) =>
      Supabase.initialize(
        url: url,
        anonKey: anonKey,
        authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
      );

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) => _supabase.auth.signUp(
    password: password.trim(),
    email: email.trim().toLowerCase(),
    data: {"name": name},
  );

  @override
  Future<void> login(String email, String password) =>
      _supabase.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password.trim(),
      );
  @override
  Future<void> resetPasswordForEmail(String email) =>
      _supabase.auth.resetPasswordForEmail(email);

  @override
  Future<bool> verifyOtpAndResetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final res = await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );

    if (res.session != null) {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      return true;
    } else {
      return false;
    }
  }

  @override
  Future<void> signOut() => _supabase.auth.signOut();

  @override
  Future<dynamic> insert<T>(
    String tableName, {
    required dynamic data,
    List<QueryFilter>? filters,
    String? select,
    bool single = false,
    Function(dynamic)? onSuccess,
    String? userMessage,
  }) async {
    void onSuc([data]) {
      if (userMessage != null) {
        showMessage("تم $userMessage", isError: false);
      }
      if (onSuccess != null) onSuccess(data);
    }

    try {
      dynamic query = _supabase.from(tableName).insert(data);

      if (filters != null && filters.isNotEmpty) {
        query = _applyFilters(query, filters);
      }

      if (select == null) {
        await query;
        onSuc();
      } else {
        query = query.select(select);

        if (single) {
          final res = await query.single();
          onSuc(res);
          return res;
        } else {
          final res = await query;
          final resultData = List<T>.from(res);
          onSuc(resultData);
          return resultData;
        }
      }
    } catch (e, t) {
      showError(
        "$e - $t",
        "insert_$tableName",
        userMessage: userMessage ?? "الإضافة",
      );
      return single ? null : <T>[];
    }
  }

  @override
  Future<dynamic> select<T>(
    String tableName, [
    QueryOptions options = const QueryOptions(),
    bool silentException = false,
  ]) async {
    try {
      if (options.countOnly) {
        final res = await _supabase
            .from(tableName)
            .select(kFid)
            .count(CountOption.exact);
        return res.count;
      }

      dynamic query = _supabase.from(tableName).select(options.select);

      query = _applyFilters(query, options.filters);

      if (options.orFilters.isNotEmpty) {
        final orString = options.orFilters
            .map((f) {
              String op;
              switch (f.operator) {
                case FilterOperator.iss:
                  op = "is";
                default:
                  op = f.operator.name;
              }
              return "${f.field}.$op.${f.value}";
            })
            .join(",");
        query = query.or(orString);
      }

      if (options.orderBy != null && options.orderBy!.isNotEmpty) {
        query = query.order(options.orderBy!, ascending: options.ascending);
      }

      if (options.offset != null) {
        final limit = options.limit ?? 10;
        final to = options.offset! + limit - 1;
        query = query.range(options.offset!, to);
      } else if (options.limit != null) {
        query = query.limit(options.limit!);
      }

      if (options.single) return await query.single();
      if (options.maybeSingle) return await query.maybeSingle();

      final res = await query;
      return List<T>.from(res);
    } catch (e, t) {
      if (silentException) rethrow;

      showError("$e - $t", "select_$tableName", userMessage: "جلب البيانات");
      return options.single || options.maybeSingle ? null : <T>[];
    }
  }

  @override
  Future<dynamic> update(
    String tableName, {
    required List<QueryFilter> filters,
    required Map<String, dynamic> data,
    String? select,
    VoidCallback? onSuccess,
    String? userMessage,
  }) async {
    try {
      dynamic query = _supabase.from(tableName).update(data);
      query = _applyFilters(query, filters);

      if (select != null) query = query.select(select);
      final response = await query;

      if (userMessage != null) showMessage(userMessage, isError: false);
      if (onSuccess != null) onSuccess();
      return response;
    } catch (e, t) {
      showError("$e - $t", "update_$tableName", userMessage: "التعديل");
    }
  }

  @override
  Future<dynamic> upsert<T>(
    String tableName, {
    required dynamic data,
    List<String>? onConflict,
    String? select,
    bool single = false,
    Function(dynamic)? onSuccess,
    String? userMessage,
  }) async {
    void onSuc([data]) {
      if (userMessage != null) {
        showMessage("تم $userMessage", isError: false);
      }
      if (onSuccess != null) onSuccess(data);
    }

    try {
      dynamic query = _supabase
          .from(tableName)
          .upsert(data, onConflict: onConflict?.join(","));

      if (select == null) {
        await query;
        onSuc();
      } else {
        query = query.select(select);

        if (single) {
          final res = await query.single();
          onSuc(res);
          return res;
        } else {
          final res = await query;
          final resultData = List<T>.from(res);
          onSuc(resultData);
          return resultData;
        }
      }
    } catch (e, t) {
      showError(
        "$e - $t",
        "upsert_$tableName",
        userMessage: userMessage ?? "الحفظ",
      );
      return single ? null : <T>[];
    }
  }

  @override
  Future<void> executeDelete(
    String tableName, {
    required List<QueryFilter> filters,
    required bool isRealDelete,
  }) async {
    var query = isRealDelete
        ? _supabase.from(tableName).delete()
        : _supabase.from(tableName).update({
            kFisDeleted: true,
            kFupdatedAt: DateTime.now().toIso8601String(),
          });

    query = _applyFilters(query, filters);

    await query;
  }

  PostgrestFilterBuilder _applyFilters(
    PostgrestFilterBuilder query,
    List<QueryFilter> filters,
  ) {
    var dynamicQuery = query;

    for (var filter in filters) {
      switch (filter.operator) {
        case FilterOperator.eq:
          dynamicQuery = dynamicQuery.eq(filter.field, filter.value);
        case FilterOperator.gt:
          dynamicQuery = dynamicQuery.gt(filter.field, filter.value);
        case FilterOperator.inList:
          dynamicQuery = dynamicQuery.filter(filter.field, "in", filter.value);
        case FilterOperator.iss:
          dynamicQuery = dynamicQuery.filter(filter.field, "is", filter.value);
        case FilterOperator.ilike:
          dynamicQuery = dynamicQuery.ilike(filter.field, "%${filter.value}%");
        case FilterOperator.notNull:
          dynamicQuery = dynamicQuery.not(filter.field, "is", null);
        case FilterOperator.notEq:
          dynamicQuery = dynamicQuery.not(filter.field, "=", filter.value);
        case FilterOperator.not:
          if (filter.subOperator != null) {
            String supabaseOp;
            switch (filter.subOperator!) {
              case FilterOperator.eq:
                supabaseOp = "eq";
              case FilterOperator.inList:
                supabaseOp = "in";
              case FilterOperator.iss:
                supabaseOp = "is";
              default:
                supabaseOp = filter.value == null ? "is" : "eq";
            }
            dynamicQuery = dynamicQuery.not(
              filter.field,
              supabaseOp,
              filter.value,
            );
          }
        default:
          break;
      }
    }

    return dynamicQuery;
  }
}
