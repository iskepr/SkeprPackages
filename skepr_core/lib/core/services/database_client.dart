import "package:flutter/material.dart";
import "package:skepr_core/local.dart";
import "package:skepr_core/skepr_core.dart";

enum AuthProvider { email, google }

enum AppAuthEvent {
  signedIn,
  signedOut,
  tokenRefreshed,
  userUpdated,
  passwordRecovery,
  initialSession,
  unknown,
}

class AppAuthUser {
  final String id;
  final String? email;
  final Map<String, dynamic>? userMetadata;

  const AppAuthUser({required this.id, this.email, this.userMetadata});
}

class AppAuthStateChange {
  final AppAuthEvent event;
  final AppAuthUser? user;

  const AppAuthStateChange({required this.event, this.user});
}

abstract class DatabaseClient {
  dynamic get currentSession;

  AppAuthUser? get currentUser;
  Stream<AppAuthStateChange> get onAuthStateChange;

  Future<void> init({
    required String url,
    required String anonKey,
    Map<String, String>? headers,
  });

  Future<dynamic> signUp({
    required String name,
    required String email,
    required String password,
  });
  Future<void> login(String email, String password);
  Future<void> resetPasswordForEmail(String email);
  Future<bool> verifyOtpAndResetPassword({
    required String email,
    required String token,
    required String newPassword,
  });
  Future<void> signOut();

  Future<void> signInWithOAuth({
    required AuthProvider provider,
    String? redirectTo,
  });
  Future<AppAuthUser?> signInWithIdToken({
    required AuthProvider provider,
    required String idToken,
  });

  Future<Map<String, dynamic>> function(String name, Map<String, dynamic> body);

  Future<dynamic> rpc(
    String functionName, {
    Map<String, dynamic>? params,
    bool silentException = false,
  });

  Future<dynamic> insert<T>(
    String tableName, {
    required dynamic data,
    List<QueryFilter>? filters,
    String? select,
    bool single = false,
    Function(dynamic)? onSuccess,
    String? userMessage,
  });

  Future<dynamic> select<T>(
    String tableName, [
    QueryOptions options = const QueryOptions(),
    bool silentException = false,
  ]);

  Future<dynamic> update(
    String tableName, {
    required List<QueryFilter> filters,
    required Map<String, dynamic> data,
    String? select,
    VoidCallback? onSuccess,
    String? userMessage,
  });

  Future<dynamic> upsert<T>(
    String tableName, {
    required dynamic data,
    List<String>? onConflict,
    String? select,
    bool single = false,
    Function(dynamic)? onSuccess,
    String? userMessage,
    bool silentException = false,
  });

  Future<void> delete(
    String tableName, {
    required List<QueryFilter> filters,
    BuildContext? context,
    String? title,
    Function(dynamic)? onSuccess,
    bool isRealDelete = true,
    bool pop = false,
  }) async {
    if (context == null || title == null) {
      await executeDelete(
        tableName,
        filters: filters,
        isRealDelete: isRealDelete,
        onSuccess: onSuccess,
      );
      return;
    }

    return SkeprCore.showCustomDialog?.call(
      title: title,
      subtitle: "هل انت متأكد؟",
      onConfirm: () async {
        await executeDelete(
          tableName,
          filters: filters,
          isRealDelete: isRealDelete,
        );
        showMessage("تم $title بنجاح", isError: false);
        if (context.mounted && pop && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
    );
  }

  @protected
  Future<void> executeDelete(
    String tableName, {
    required List<QueryFilter> filters,
    required bool isRealDelete,
    Function(dynamic)? onSuccess,
  });
}

enum FilterOperator {
  eq,
  gt,
  gte,
  lt,
  lte,
  inList,
  notEq,
  notNull,
  not,
  iss,
  ilike,
  or,
  and,
}

class QueryFilter {
  final String field;
  final FilterOperator operator;
  final dynamic value;
  final FilterOperator? subOperator;
  final List<QueryFilter>? subFilters;

  const QueryFilter({
    this.field = "",
    required this.operator,
    this.value,
    this.subOperator,
    this.subFilters,
  });
}

class QueryOptions {
  final String select;
  final List<QueryFilter> filters;
  final List<QueryFilter> orFilters;
  final int? limit;
  final int? offset;
  final String? orderBy;
  final bool ascending;
  final bool single;
  final bool maybeSingle;
  final bool countOnly;

  const QueryOptions({
    this.select = "*",
    this.filters = const [],
    this.orFilters = const [],
    this.limit,
    this.offset,
    this.orderBy,
    this.countOnly = false,
    this.ascending = false,
    this.single = false,
    this.maybeSingle = false,
  });
}
