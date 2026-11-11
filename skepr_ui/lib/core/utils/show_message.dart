import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";

export "package:toastification/toastification.dart";

enum MessageType { info, success, warning, error }

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

  debugPrint("${resolved.name}: $msg");
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final context = SkeprMaterial.currentContext;
    if (context == null || !context.mounted) {
      debugPrint("[showMessage] dropped, no mounted context: $msg");
      return;
    }

    final bgColor = switch (resolved) {
      MessageType.error => context.error,
      MessageType.success => context.success,
      MessageType.warning => context.warning, // لو موجود في الـ theme
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
      hideMessage();
      toastification.show(
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

void hideMessage() => toastification.dismissAll();
