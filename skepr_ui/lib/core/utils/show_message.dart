import "dart:async";
import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";

export "package:toastification/toastification.dart";

enum MessageType { info, success, warning, error }

ToastificationItem? _activeToast;
Timer? _debounceTimer;

void showMessage(
  String msg, {
  MessageType? type,
  @Deprecated("Use `type: MessageType.xxx` instead. Will be removed.")
  bool? isError,
  bool isPersistent = false,
  IconData? icon,
}) {
  final resolved =
      type ??
      (isError == true
          ? MessageType.error
          : isError == false
          ? MessageType.success
          : MessageType.info);

  debugPrint("${resolved.name}: $msg ${DateTime.now()}");
  if (!StackTrace.current.toString().contains("error_handle")) {
    debugPrintStack(stackTrace: StackTrace.current, maxFrames: 4);
  }

  _debounceTimer?.cancel();

  _debounceTimer = Timer(const Duration(milliseconds: 50), () {
    final context = SkeprMaterial.currentContext;
    if (context == null || !context.mounted) {
      debugPrint("[showMessage] dropped, no mounted context: $msg");
      return;
    }

    final bgColor = switch (resolved) {
      MessageType.error => context.error,
      MessageType.success => context.success,
      MessageType.warning => context.warning,
      MessageType.info => context.background,
    };

    final finalIcon =
        icon ??
        switch (resolved) {
          MessageType.error => LucideIcons.circleX,
          MessageType.success => LucideIcons.circleCheck,
          MessageType.warning => LucideIcons.alertTriangle,
          MessageType.info => null,
        };

    try {
      if (_activeToast != null) {
        toastification.dismiss(_activeToast!, showRemoveAnimation: false);
        _activeToast = null;
      }
      toastification.dismissAll(delayForAnimation: false);

      _activeToast = toastification.show(
        context: context,
        type: switch (resolved) {
          MessageType.error => ToastificationType.error,
          MessageType.success => ToastificationType.success,
          MessageType.warning => ToastificationType.warning,
          MessageType.info => ToastificationType.info,
        },
        style: ToastificationStyle.fillColored,
        alignment: Alignment.topCenter,
        title: Text(msg, style: const TextStyle(color: Colors.white)),
        icon: finalIcon != null ? Icon(finalIcon, color: Colors.white) : null,
        showIcon: finalIcon != null,
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        autoCloseDuration: isPersistent
            ? const Duration(days: 365)
            : const Duration(seconds: 3),
        borderRadius: BorderRadius.circular(kCircleBorderRadius),
        sizeConstraints: const BoxConstraints(),
        padding: const EdgeInsets.symmetric(
          horizontal: kMediumPadding,
          vertical: kSmallPadding,
        ),
        showProgressBar: false,
        closeButtonShowType: CloseButtonShowType.none,
      );
    } catch (e) {
      debugPrint("[showMessage] toast unavailable: $e");
    }
  });
}

void hideMessage() {
  _debounceTimer?.cancel();
  if (_activeToast != null) {
    toastification.dismiss(_activeToast!, showRemoveAnimation: false);
    _activeToast = null;
  }
  toastification.dismissAll(delayForAnimation: false);
}
