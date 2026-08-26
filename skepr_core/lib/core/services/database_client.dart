import "package:flutter/material.dart";

abstract class DatabaseClient {
  dynamic get currentSession;

  Future<void> init({required String url, required String anonKey});

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
  });

  Future<void> delete(
    String tableName, {
    required List<QueryFilter> filters,
    BuildContext? context,
    String? title,
    VoidCallback? onSuccess,
    bool isRealDelete = true,
    bool pop = false,
  }) async {
    if (context == null || title == null) {
      await executeDelete(
        tableName,
        filters: filters,
        isRealDelete: isRealDelete,
      );
      if (onSuccess != null) onSuccess();
      return;
    }

    // TODO: fix show Dialog
    // return showCustomDialog(
    //   title: title,
    //   subtitle: l10n.areYouSure,
    //   onConfirm: () async {
    //     try {
    //       await executeDelete(
    //         tableName,
    //         filters: filters,
    //         isRealDelete: isRealDelete,
    //       );
    //       showMessage("تم $title بنجاح", isError: false);
    //       if (onSuccess != null) onSuccess();
    //     } catch (e, t) {
    //       showError("$e - $t", "delete_${tableName}_row", userMessage: "الحذف");
    //     }
    //     if (context.mounted && pop) context.close();
    //   },
    // );
  }

  @protected
  Future<void> executeDelete(
    String tableName, {
    required List<QueryFilter> filters,
    required bool isRealDelete,
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
}

class QueryFilter {
  final String field;
  final FilterOperator operator;
  final dynamic value;
  final FilterOperator? subOperator;

  const QueryFilter({
    required this.field,
    required this.operator,
    this.value,
    this.subOperator,
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
