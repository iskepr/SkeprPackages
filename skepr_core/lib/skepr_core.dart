import "package:flutter/widgets.dart";

export "core/helpers/data_resource.dart";
export "core/helpers/env_helper.dart";
export "core/helpers/hive_helper.dart";

// services
export "core/services/database_client.dart";
export "core/services/device_service.dart";
export "core/services/supabase_service.dart";
export "core/services/sound_helper.dart";

// utils
export "core/utils/check_internet.dart";

class SkeprCore {
  static void Function(
    String msg, {
    bool? isError,
    bool isPersistent,
    IconData? icon,
  })?
  showMessage;

  static void Function(dynamic err, String title, {String? userMessage})?
  showError;

  static void Function({
    required String title,
    String? subtitle,
    void Function()? onConfirm,
    void Function()? onDismiss,
    bool closeOnConfirm,
    Widget? child,
    bool easyClose,
  })?
  showCustomDialog;

  static void setup({
    void Function(
      String msg, {
      bool? isError,
      bool isPersistent,
      IconData? icon,
    })?
    showMessage,

    void Function(dynamic err, String title, {String? userMessage})? showError,

    void Function({
      required String title,
      String? subtitle,
      void Function()? onConfirm,
      void Function()? onDismiss,
      bool closeOnConfirm,
      Widget? child,
      bool easyClose,
    })?
    showCustomDialog,
  }) {
    SkeprCore.showMessage = showMessage;
    SkeprCore.showError = showError;
    SkeprCore.showCustomDialog = showCustomDialog;
  }
}
