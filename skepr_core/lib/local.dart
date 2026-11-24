import "package:flutter/widgets.dart";
import "package:skepr_core/skepr_core.dart";

void showMessage(
  String msg, {
  bool? isError,
  bool isPersistent = false,
  IconData? icon,
}) => SkeprCore.showMessage;
void showError(
  dynamic err,
  String title, {
  String? userMessage,
  StackTrace? stackTrace,
}) {
  debugPrint("error Stack show error");
  debugPrintStack(stackTrace: StackTrace.current, maxFrames: 4);
  debugPrint("--------------------------------------");
  return SkeprCore.showError?.call(
    err,
    title,
    userMessage: userMessage,
    stackTrace: stackTrace,
  );
}
