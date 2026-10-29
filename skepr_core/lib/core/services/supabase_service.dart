import "package:flutter/material.dart";
import "package:skepr_core/local.dart";
import "package:skepr_core/skepr_core.dart";
import "package:supabase_flutter/supabase_flutter.dart";

class SupabaseService extends DatabaseClient {
  static SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Session? get currentSession => _supabase.auth.currentSession;

  @override
  AppAuthUser? get currentUser {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return _mapUser(user);
  }

  @override
  Stream<AppAuthStateChange> get onAuthStateChange {
    return _supabase.auth.onAuthStateChange.map((data) {
      final event = _mapEvent(data.event);
      final user = data.session?.user;
      return AppAuthStateChange(
        event: event,
        user: user != null ? _mapUser(user) : null,
      );
    });
  }

  AppAuthUser _mapUser(User user) {
    return AppAuthUser(
      id: user.id,
      email: user.email,
      userMetadata: user.userMetadata,
    );
  }

  AppAuthEvent _mapEvent(AuthChangeEvent event) {
    switch (event) {
      case AuthChangeEvent.signedIn:
        return AppAuthEvent.signedIn;
      case AuthChangeEvent.signedOut:
        return AppAuthEvent.signedOut;
      case AuthChangeEvent.initialSession:
        return AppAuthEvent.initialSession;
      case AuthChangeEvent.tokenRefreshed:
        return AppAuthEvent.tokenRefreshed;
      case AuthChangeEvent.userUpdated:
        return AppAuthEvent.userUpdated;
      case AuthChangeEvent.passwordRecovery:
        return AppAuthEvent.passwordRecovery;
      default:
        return AppAuthEvent.unknown;
    }
  }

  @override
  Future<void> signInWithOAuth({
    required AuthProvider provider,
    String? redirectTo,
  }) async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.values.firstWhere(
        (e) => e.name.toLowerCase() == provider.name.toLowerCase(),
        orElse: () => OAuthProvider.google,
      ),
      redirectTo: redirectTo,
    );
  }

  @override
  Future<AppAuthUser?> signInWithIdToken({
    required AuthProvider provider,
    required String idToken,
  }) async {
    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.values.firstWhere(
        (e) => e.name.toLowerCase() == provider.name.toLowerCase(),
        orElse: () => OAuthProvider.google,
      ),
      idToken: idToken,
    );

    final user = response.user;
    if (user == null) return null;

    return _mapUser(user);
  }

  @override
  Future<void> init({
    required String url,
    required String anonKey,
    Map<String, String>? headers,
  }) => Supabase.initialize(
    url: url,
    anonKey: anonKey,
    authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
    headers: headers,
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
  Future<Map<String, dynamic>> function(
    String name,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _supabase.functions.invoke(name, body: body);
      return {"status": response.status, "data": response.data};
    } on FunctionException catch (e, t) {
      showError(e, "function_$name", stackTrace: t);
      return {"status": e.status, "data": e.details};
    } catch (e, t) {
      showError(e, "function_$name", stackTrace: t);
      return {"status": 500};
    }
  }

  @override
  Future<dynamic> rpc(
    String functionName, {
    Map<String, dynamic>? params,
    bool silentException = false,
  }) async {
    try {
      final response = await _supabase.rpc(
        functionName,
        params: params ?? const {},
      );
      return response;
    } on PostgrestException catch (e, t) {
      if (silentException) rethrow;
      showError(e, "rpc_$functionName", stackTrace: t);
      return null;
    } catch (e, t) {
      if (silentException) rethrow;
      showError(e, "rpc_$functionName", stackTrace: t);
      return null;
    }
  }

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
    } on PostgrestException catch (e, t) {
      showError(
        e,
        "insert_$tableName",
        stackTrace: t,
        userMessage: userMessage,
      );
      rethrow;
    } catch (e, t) {
      showError(
        e,
        "insert_$tableName",
        stackTrace: t,
        userMessage: userMessage,
      );
      rethrow;
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
            .map((f) => f.toPostgrest())
            .where((s) => s.isNotEmpty)
            .join(",");
        if (orString.isNotEmpty) {
          query = query.or(orString);
        }
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

      showError(e, "select_$tableName", stackTrace: t);
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
      showError(e, "update_$tableName", stackTrace: t);
      rethrow;
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
    } on PostgrestException catch (e, t) {
      showError(
        e,
        "upsert_$tableName",
        stackTrace: t,
        userMessage: userMessage,
      );
      rethrow;
    } catch (e, t) {
      showError(
        e,
        "upsert_$tableName",
        stackTrace: t,
        userMessage: userMessage,
      );
      rethrow;
    }
  }

  @override
  Future<void> executeDelete(
    String tableName, {
    required List<QueryFilter> filters,
    required bool isRealDelete,
  }) async {
    try {
      var query = isRealDelete
          ? _supabase.from(tableName).delete()
          : _supabase.from(tableName).update({
              kFisDeleted: true,
              kFupdatedAt: DateTime.now().toIso8601String(),
            });

      query = _applyFilters(query, filters);

      await query;
    } catch (e, t) {
      showError(e, "delete_$tableName", stackTrace: t);
      rethrow;
    }
  }

  PostgrestFilterBuilder _applyFilters(
    PostgrestFilterBuilder query,
    List<QueryFilter> filters,
  ) {
    var dynamicQuery = query;

    for (var filter in filters) {
      switch (filter.operator) {
        case FilterOperator.eq:
          if (filter.value == null) {
            dynamicQuery = dynamicQuery.filter(filter.field, "is", null);
          } else {
            dynamicQuery = dynamicQuery.eq(filter.field, filter.value);
          }
          break;
        case FilterOperator.gt:
          if (filter.value != null)
            dynamicQuery = dynamicQuery.gt(filter.field, filter.value);
          break;
        case FilterOperator.gte:
          if (filter.value != null)
            dynamicQuery = dynamicQuery.gte(filter.field, filter.value);
          break;
        case FilterOperator.lt:
          if (filter.value != null)
            dynamicQuery = dynamicQuery.lt(filter.field, filter.value);
          break;
        case FilterOperator.lte:
          if (filter.value != null)
            dynamicQuery = dynamicQuery.lte(filter.field, filter.value);
          break;
        case FilterOperator.inList:
          if (filter.value is Iterable &&
              (filter.value as Iterable).isNotEmpty) {
            dynamicQuery = dynamicQuery.inFilter(filter.field, filter.value);
          }
          break;
        case FilterOperator.iss:
          dynamicQuery = dynamicQuery.filter(filter.field, "is", filter.value);
          break;
        case FilterOperator.ilike:
          if (filter.value != null) {
            dynamicQuery = dynamicQuery.ilike(
              filter.field,
              "%${filter.value}%",
            );
          }
          break;
        case FilterOperator.notNull:
          dynamicQuery = dynamicQuery.filter(filter.field, "not.is", null);
          break;
        case FilterOperator.notEq:
          if (filter.value == null) {
            dynamicQuery = dynamicQuery.filter(filter.field, "not.is", null);
          } else {
            dynamicQuery = dynamicQuery.neq(filter.field, filter.value);
          }
          break;
        case FilterOperator.or:
          final expr = filter.subFilters != null
              ? filter.subFilters!.map((f) => f.toPostgrest()).join(",")
              : filter.value?.toString();
          if (expr != null && expr.isNotEmpty) {
            dynamicQuery = dynamicQuery.or(expr);
          }
          break;
        case FilterOperator.and:
          final expr = filter.subFilters != null
              ? filter.subFilters!.map((f) => f.toPostgrest()).join(",")
              : filter.value?.toString();
          if (expr != null && expr.isNotEmpty) {
            dynamicQuery = dynamicQuery.or("and($expr)");
          }
          break;
        case FilterOperator.not:
          if (filter.subOperator != null) {
            String supabaseOp;
            switch (filter.subOperator!) {
              case FilterOperator.eq:
                supabaseOp = "eq";
                break;
              case FilterOperator.inList:
                supabaseOp = "in";
                break;
              case FilterOperator.iss:
                supabaseOp = "is";
                break;
              default:
                supabaseOp = filter.value == null ? "is" : "eq";
            }
            if (filter.value == null) {
              dynamicQuery = dynamicQuery.filter(
                filter.field,
                "not.$supabaseOp",
                null,
              );
            } else {
              dynamicQuery = dynamicQuery.not(
                filter.field,
                supabaseOp,
                filter.value,
              );
            }
          } else {
            if (filter.value == null) {
              dynamicQuery = dynamicQuery.filter(filter.field, "not.is", null);
            } else {
              dynamicQuery = dynamicQuery.not(filter.field, "eq", filter.value);
            }
          }
          break;
      }
    }

    return dynamicQuery;
  }
}
