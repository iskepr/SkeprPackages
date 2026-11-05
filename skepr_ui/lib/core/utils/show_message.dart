import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";

export "package:toastification/toastification.dart";

void showMessage(
  String msg, {
  bool? isError,
  bool isPersistent = false,
  IconData? icon,
}) {
  debugPrint("${isError == true ? "Error: " : ""}$msg");
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final context = SkeprMaterial.currentContext!;

    final bgColor = isError == true
        ? context.error
        : isError == false
        ? context.success
        : context.background;

    final finalIcon =
        icon ??
        (isError == true
            ? LucideIcons.circleX
            : isError == false
            ? LucideIcons.circleCheck
            : null);

    toastification.show(
      context: context,
      type: isError == true
          ? ToastificationType.error
          : isError == false
          ? ToastificationType.success
          : ToastificationType.info,
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
  });
}

void hideMessage() => toastification.dismissAll();
