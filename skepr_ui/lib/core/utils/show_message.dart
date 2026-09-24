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
      final ToastType type = isError == true
          ? ToastType.error
          : ToastType.success;
      ToastHelper.showToastt(message: msg, bgColor: bgColor, type: type);
    } else {
      SkeprMaterial.messengerKey.currentState?.clearSnackBars();
      SkeprMaterial.messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Center(
            child: finalIcon != null
                ? Row(
                    spacing: 5,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon),
                      Flexible(
                        child: Text(
                          msg,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
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
  static void showToastt({
    required String message,
    required Color bgColor,
    required ToastType type,
    required,
  }) => showToast(
    title: message,
    type: type,
    options: NativeToastOptions(bgColor: bgColor),
  );
}

void hideMessage() => SkeprMaterial.messengerKey.currentState?.clearSnackBars();
