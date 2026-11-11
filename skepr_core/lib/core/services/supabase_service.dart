import "dart:async";
import "dart:math";

import "package:flutter/material.dart";
import "package:skepr_core/local.dart";
import "package:skepr_core/skepr_core.dart";
import "package:supabase_flutter/supabase_flutter.dart";

extension PostgrestQueryFilter on QueryFilter {
  String toPostgrest() {
    switch (operator) {
      case FilterOperator.and:
        if (subFilters == null || subFilters!.isEmpty) return "";
        final inner = _joinSubFilters(subFilters!);
        return inner.isEmpty ? "" : "and($inner)";

      case FilterOperator.or:
        if (subFilters != null && subFilters!.isNotEmpty) {
          final inner = _joinSubFilters(subFilters!);
          return inner.isEmpty ? "" : "or($inner)";
        }
        return value?.toString() ?? "";

      case FilterOperator.iss:
        return "$field.is.$value";

      case FilterOperator.inList:
        return "$field.in.${_formatInList(value)}";

      case FilterOperator.notNull:
        return "$field.not.is.null";

      case FilterOperator.eq:
        return value == null ? "$field.is.null" : "$field.eq.$value";

      case FilterOperator.notEq:
        return value == null ? "$field.not.is.null" : "$field.neq.$value";

      case FilterOperator.not:
        if (subOperator == null) {
          return "$field.not.${value == null ? 'is.null' : 'eq.$value'}";
        }
        final op = switch (subOperator!) {
          FilterOperator.iss => "is",
          FilterOperator.inList => "in",
          final o => o.name,
        };
        final formatted = subOperator == FilterOperator.inList
            ? _formatInList(value)
            : "$value";
        return "$field.not.$op.$formatted";

      case FilterOperator.ilike:
        return "$field.ilike.*$value*";

      default:
        return value == null
            ? "$field.is.null"
            : "$field.${operator.name}.$value";
    }
  }
}

String _joinSubFilters(List<QueryFilter> filters) =>
    filters.map((f) => f.toPostgrest()).where((s) => s.isNotEmpty).join(",");

String _formatInList(dynamic value) =>
    value is Iterable ? "(${value.join(',')})" : "($value)";

// ─────────────────────────────────────────────────────────────────────────────
// Supabase implementation of DatabaseClient.
// ─────────────────────────────────────────────────────────────────────────────

class SupabaseService extends DatabaseClient {
  static SupabaseClient get _supabase => Supabase.instance.client;

  // ── Retry / JWT ──────────────────────────────────────────────────────────

  static const int _kMaxAttempts = 3;
  static Future<void>? _refreshInFlight;

  /// Failures a retry can plausibly fix.
  ///
  /// Detected by string because this file also compiles for web, where
  /// `dart:io` (and thus `SocketException`) is not available.
  static bool _isTransient(Object e) {
    if (e is TimeoutException) return true;
    final s = e.toString();
    return s.contains("SocketException") ||
        s.contains("ClientException") ||
        s.contains("HandshakeException") ||
        s.contains("Connection closed before full header was received") ||
        s.contains("Software caused connection abort") ||
        s.contains("Connection reset by peer") ||
        s.contains("Failed host lookup") ||
        s.contains("Failed to fetch");
  }

  static bool _isExpiredJwt(Object e) =>
      e is PostgrestException &&
      (e.code == "PGRST303" || e.message.toLowerCase().contains("jwt expired"));

  static Future<void> _refreshOnce() {
    final running = _refreshInFlight;
    if (running != null) return running;
    final future = _performRefresh();
    _refreshInFlight = future;
    return future.whenComplete(() {
      if (identical(_refreshInFlight, future)) _refreshInFlight = null;
    });
  }

  static Future<void> _performRefresh() async {
    try {
      final refreshed = await _supabase.auth.refreshSession().timeout(
        const Duration(seconds: 15),
      );
      if (refreshed.session != null) return;
      debugPrint("[auth] refresh returned no session");
    } on AuthException catch (e) {
      if (_isDefinitiveRefreshFailure(e)) {
        debugPrint("[auth] refresh token rejected (${e.code ?? e.statusCode})");
        await _supabase.auth.signOut(scope: SignOutScope.local);
      }
      rethrow;
    }
  }

  static bool _isDefinitiveRefreshFailure(AuthException e) {
    final status = int.tryParse(e.statusCode ?? "");
    if (status == 429 || (status != null && status >= 500)) return false;
    if (status == 401 || status == 403) return true;
    const definitiveCodes = {
      "refresh_token_not_found",
      "invalid_grant",
      "session_not_found",
    };
    return definitiveCodes.contains(e.code?.toLowerCase());
  }

  Future<T> _withRetry<T>(
    Future<T> Function() action, {
    required String source,
  }) async {
    for (var attempt = 0; attempt < _kMaxAttempts; attempt++) {
      try {
        return await _withAuthRetry(action);
      } catch (e) {
        if (!_isTransient(e) || attempt == _kMaxAttempts - 1) rethrow;
        final delay = Duration(
          milliseconds: 300 * (1 << attempt) + Random().nextInt(200),
        );
        debugPrint("[net] retry $source in ${delay.inMilliseconds}ms");
        await Future<void>.delayed(delay);
      }
    }
    throw StateError("retry loop exhausted for $source");
  }

  Future<T> _withAuthRetry<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      if (!_isExpiredJwt(e)) rethrow;
      debugPrint("[auth] JWT expired, refreshing session");
      await _refreshOnce();
      return action();
    }
  }

  Future<R> _execute<R>({
    required String source,
    required Future<R> Function() action,
    bool silentException = false,
    String? userMessage,
    void Function(R result)? onSuccess,
    R Function(Object error)? onError,
  }) async {
    try {
      final result = await _withRetry(action, source: source);
      if (userMessage != null) showMessage(userMessage, isError: false);
      onSuccess?.call(result);
      return result;
    } catch (e, t) {
      if (silentException) rethrow;
      showError(e, source, stackTrace: t, userMessage: userMessage);
      if (onError != null) return onError(e);
      rethrow;
    }
  }

  // ── Auth surface ─────────────────────────────────────────────────────────

  @override
  Session? get currentSession => _supabase.auth.currentSession;

  @override
  AppAuthUser? get currentUser {
    final user = _supabase.auth.currentUser;
    return user == null ? null : _mapUser(user);
  }

  @override
  Stream<AppAuthStateChange> get onAuthStateChange =>
      _supabase.auth.onAuthStateChange.map((data) {
        final user = data.session?.user;
        return AppAuthStateChange(
          event: _mapEvent(data.event),
          user: user == null ? null : _mapUser(user),
        );
      });

  AppAuthUser _mapUser(User user) => AppAuthUser(
    id: user.id,
    email: user.email,
    userMetadata: user.userMetadata,
  );

  AppAuthEvent _mapEvent(AuthChangeEvent event) => switch (event) {
    AuthChangeEvent.signedIn => AppAuthEvent.signedIn,
    AuthChangeEvent.signedOut => AppAuthEvent.signedOut,
    AuthChangeEvent.initialSession => AppAuthEvent.initialSession,
    AuthChangeEvent.tokenRefreshed => AppAuthEvent.tokenRefreshed,
    AuthChangeEvent.userUpdated => AppAuthEvent.userUpdated,
    AuthChangeEvent.passwordRecovery => AppAuthEvent.passwordRecovery,
    _ => AppAuthEvent.unknown,
  };

  OAuthProvider _oauthProvider(AuthProvider provider) =>
      OAuthProvider.values.firstWhere(
        (e) => e.name.toLowerCase() == provider.name.toLowerCase(),
        orElse: () => OAuthProvider.google,
      );

  @override
  Future<void> signInWithOAuth({
    required AuthProvider provider,
    String? redirectTo,
  }) => _supabase.auth.signInWithOAuth(
    _oauthProvider(provider),
    redirectTo: redirectTo,
  );

  @override
  Future<AppAuthUser?> signInWithIdToken({
    required AuthProvider provider,
    required String idToken,
  }) async {
    final response = await _supabase.auth.signInWithIdToken(
      provider: _oauthProvider(provider),
      idToken: idToken,
    );
    final user = response.user;
    return user == null ? null : _mapUser(user);
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
    if (res.session == null) return false;
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    return true;
  }

  @override
  Future<void> signOut() => _supabase.auth.signOut();

  // ── Edge function ────────────────────────────────────────────────────────

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

  // ── RPC ──────────────────────────────────────────────────────────────────

  @override
  Future<dynamic> rpc(
    String functionName, {
    Map<String, dynamic>? params,
    bool silentException = false,
  }) => _execute<dynamic>(
    source: "rpc_$functionName",
    silentException: silentException,
    onError: (_) => null,
    action: () => _supabase.rpc(functionName, params: params ?? const {}),
  );

  // ── CRUD ─────────────────────────────────────────────────────────────────

  /// Shapes the raw PostgREST payload into what the caller expects:
  /// `null` when no `select` was requested, the map when `single`, otherwise
  /// a `List<T>`.
  dynamic _shape<T>(
    dynamic res, {
    required bool hasSelect,
    required bool single,
  }) {
    if (!hasSelect) return null;
    if (single) return res;
    return List<T>.from(res);
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
  }) => _execute<dynamic>(
    source: "insert_$tableName",
    userMessage: userMessage == null ? null : "تم $userMessage",
    onSuccess: onSuccess == null ? null : (r) => onSuccess(r),
    action: () async {
      dynamic query = _supabase.from(tableName).insert(data);
      if (filters != null && filters.isNotEmpty) {
        query = _applyFilters(query, filters);
      }
      if (select == null) {
        await query; // ← تنفيذ فعلي
        return null;
      }
      query = query.select(select);
      final res = await (single ? query.single() : query);
      return single ? res : List<T>.from(res);
    },
  );

  @override
  Future<dynamic> upsert<T>(
    String tableName, {
    required dynamic data,
    List<String>? onConflict,
    String? select,
    bool single = false,
    Function(dynamic)? onSuccess,
    String? userMessage,
    bool silentException = false,
  }) => _execute<dynamic>(
    source: "upsert_$tableName",
    silentException: silentException,
    userMessage: userMessage == null ? null : "تم $userMessage",
    onSuccess: onSuccess == null ? null : (r) => onSuccess(r),
    action: () async {
      dynamic query = _supabase
          .from(tableName)
          .upsert(data, onConflict: onConflict?.join(","));
      if (select == null) {
        await query;
        return null;
      }
      query = query.select(select);
      final res = await (single ? query.single() : query);
      return single ? res : List<T>.from(res);
    },
  );

  @override
  Future<dynamic> select<T>(
    String tableName, [
    QueryOptions options = const QueryOptions(),
    bool silentException = false,
  ]) => _execute<dynamic>(
    source: "select_$tableName",
    silentException: silentException,
    onError: (_) => options.single || options.maybeSingle ? null : <T>[],
    action: () async {
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
        if (orString.isNotEmpty) query = query.or(orString);
      }

      if (options.orderBy != null && options.orderBy!.isNotEmpty) {
        query = query.order(options.orderBy!, ascending: options.ascending);
      }

      if (options.offset != null) {
        final limit = options.limit ?? 10;
        query = query.range(options.offset!, options.offset! + limit - 1);
      } else if (options.limit != null) {
        query = query.limit(options.limit!);
      }

      if (options.single) return await query.single();
      if (options.maybeSingle) return await query.maybeSingle();
      return List<T>.from(await query);
    },
  );

  @override
  Future<dynamic> update(
    String tableName, {
    required List<QueryFilter> filters,
    required Map<String, dynamic> data,
    String? select,
    VoidCallback? onSuccess,
    String? userMessage,
  }) => _execute<dynamic>(
    source: "update_$tableName",
    userMessage: userMessage,
    onSuccess: onSuccess == null ? null : (_) => onSuccess(),
    action: () {
      dynamic query = _supabase.from(tableName).update(data);
      query = _applyFilters(query, filters);
      if (select != null) query = query.select(select);
      return query;
    },
  );

  @override
  Future<void> executeDelete(
    String tableName, {
    required List<QueryFilter> filters,
    required bool isRealDelete,
    Function(dynamic)? onSuccess,
  }) async {
    await _execute<dynamic>(
      source: "delete_$tableName",
      onSuccess: onSuccess == null ? null : (r) => onSuccess(r),
      action: () {
        final base = isRealDelete
            ? _supabase.from(tableName).delete()
            : _supabase.from(tableName).update({
                kFisDeleted: true,
                kFupdatedAt: DateTime.now().toIso8601String(),
              });
        return _applyFilters(base, filters);
      },
    );
  }

  // ── Filter application ───────────────────────────────────────────────────

  PostgrestFilterBuilder _applyFilters(
    PostgrestFilterBuilder query,
    List<QueryFilter> filters,
  ) {
    var q = query;
    for (final f in filters) {
      q = _applyOne(q, f);
    }
    return q;
  }

  PostgrestFilterBuilder _applyOne(PostgrestFilterBuilder q, QueryFilter f) {
    switch (f.operator) {
      case FilterOperator.eq:
        return f.value == null
            ? q.filter(f.field, "is", null)
            : q.eq(f.field, f.value);

      case FilterOperator.notEq:
        return f.value == null
            ? q.filter(f.field, "not.is", null)
            : q.neq(f.field, f.value);

      case FilterOperator.gt:
        return f.value == null ? q : q.gt(f.field, f.value);

      case FilterOperator.gte:
        return f.value == null ? q : q.gte(f.field, f.value);

      case FilterOperator.lt:
        return f.value == null ? q : q.lt(f.field, f.value);

      case FilterOperator.lte:
        return f.value == null ? q : q.lte(f.field, f.value);

      case FilterOperator.inList:
        if (f.value is! Iterable || (f.value as Iterable).isEmpty) return q;
        return q.inFilter(f.field, List<dynamic>.from(f.value as Iterable));

      case FilterOperator.iss:
        return q.filter(f.field, "is", f.value);

      case FilterOperator.ilike:
        return f.value == null ? q : q.ilike(f.field, "%${f.value}%");

      case FilterOperator.notNull:
        return q.filter(f.field, "not.is", null);

      case FilterOperator.or:
      case FilterOperator.and:
        final expr = f.subFilters != null
            ? _joinSubFilters(f.subFilters!)
            : f.value?.toString();
        if (expr == null || expr.isEmpty) return q;
        return f.operator == FilterOperator.or
            ? q.or(expr)
            : q.or("and($expr)");

      case FilterOperator.not:
        return _applyNot(q, f);
    }
  }

  PostgrestFilterBuilder _applyNot(PostgrestFilterBuilder q, QueryFilter f) {
    final sub = f.subOperator;
    if (sub == null) {
      return f.value == null
          ? q.filter(f.field, "not.is", null)
          : q.not(f.field, "eq", f.value);
    }
    final op = switch (sub) {
      FilterOperator.eq => "eq",
      FilterOperator.inList => "in",
      FilterOperator.iss => "is",
      _ => f.value == null ? "is" : "eq",
    };
    return f.value == null
        ? q.filter(f.field, "not.$op", null)
        : q.not(f.field, op, f.value);
  }
}
