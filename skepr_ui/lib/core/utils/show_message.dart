import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";
import "package:toast_native_dev/toast_native_dev.dart";

void showMessage(
  String msg, {
  bool? isError,
  bool isPersistent = false,
  IconData? icon,
}) {
  debugPrint("${isError == true ? "Error: " : ""}$msg");
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final context = SkeprMaterial.currentContext!;
    bool isBottomSheetOpen = false;
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

    SkeprMaterial.navigator?.popUntil((route) {
      if (route is PopupRoute) isBottomSheetOpen = true;
      return true;
    });

    if (isBottomSheetOpen && !PlatformUtils.isDesktop) {
      ToastHelper.showToastt(msg, bgColor);
    } else {
      SkeprMaterial.messengerKey.currentState?.clearSnackBars();
      SkeprMaterial.messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Center(
            child: finalIcon != null
                ? TextIcon(
                    msg,
                    icon: finalIcon,
                    size: kLargeFont - 2,
                    color: Colors.white,
                  )
                : SelectableText(
                    msg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
          ),
          duration: isPersistent
              ? const Duration(days: 365)
              : const Duration(seconds: 3),
          margin: const EdgeInsets.all(kMediumPadding),
          padding: const EdgeInsets.all(kMediumPadding),
          behavior: SnackBarBehavior.floating,
          backgroundColor: bgColor,
        ),
      );
    }
  });
}

class ToastHelper {
  static void showToastt(String message, Color bgColor) =>
      showToast(type: ToastType.success, message: message);
}

void hideMessage() => SkeprMaterial.messengerKey.currentState?.clearSnackBars();
