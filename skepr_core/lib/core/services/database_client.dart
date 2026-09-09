import "package:flutter/material.dart";
import "package:skepr_core/local.dart";
import "package:skepr_core/skepr_core.dart";

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
  Future<Map<String, dynamic>> function(String name, Map<String, dynamic> body);

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
        if (onSuccess != null) onSuccess();
        if (context.mounted && pop) Navigator.pop(context);
      },
    );
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

  String toPostgrest() {
    switch (operator) {
      case FilterOperator.and:
        if (subFilters == null || subFilters!.isEmpty) return "";
        final inner = subFilters!
            .map((f) => f.toPostgrest())
            .where((s) => s.isNotEmpty)
            .join(",");
        return "and($inner)";

      case FilterOperator.or:
        if (subFilters != null && subFilters!.isNotEmpty) {
          final inner = subFilters!
              .map((f) => f.toPostgrest())
              .where((s) => s.isNotEmpty)
              .join(",");
          return "or($inner)";
        }
        return value?.toString() ?? "";

      case FilterOperator.iss:
        return "$field.is.$value";

      case FilterOperator.inList:
        final formatted = value is Iterable
            ? "(${(value as Iterable).join(',')})"
            : "($value)";
        return "$field.in.$formatted";

      case FilterOperator.notNull:
        return "$field.not.is.null";

      case FilterOperator.notEq:
        return "$field.neq.$value";

      case FilterOperator.not:
        if (subOperator != null) {
          final op = subOperator == FilterOperator.iss
              ? "is"
              : (subOperator == FilterOperator.inList
                    ? "in"
                    : subOperator!.name);
          final formatted =
              (subOperator == FilterOperator.inList && value is Iterable)
              ? "(${(value as Iterable).join(',')})"
              : "$value";
          return "$field.not.$op.$formatted";
        }
        return "$field.not.${value == null ? 'is.null' : 'eq.$value'}";

      case FilterOperator.ilike:
        return "$field.ilike.*$value*";

      default:
        return "$field.${operator.name}.$value";
    }
  }
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
