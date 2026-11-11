import "dart:async";

import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";

Future<T?> showCustomDialog<T>({
  required String title,
  String? subtitle,
  FutureOr<T?> Function()? onConfirm,
  void Function()? onDismiss,
  bool closeOnConfirm = true,
  Widget? child,
  bool easyClose = true,
}) async {
  Future<T?> open(BuildContext ctx) {
    return showGeneralDialog<T>(
      context: ctx,
      barrierDismissible: easyClose,
      barrierLabel: title,
      transitionDuration: kAnimationFasterDuration,
      pageBuilder: (context, animation, secondaryAnimation) => CustomDialog<T>(
        title: title,
        subtitle: subtitle,
        onConfirm: onConfirm,
        closeOnConfirm: closeOnConfirm,
        child: child,
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: kCurveEaseInOut)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    ).then((value) {
      onDismiss?.call();
      return value;
    });
  }

  final context = SkeprMaterial.currentContext;
  if (context != null) return open(context);

  final completer = Completer<T?>();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final postFrameContext = SkeprMaterial.currentContext;
    if (postFrameContext != null) {
      completer.complete(await open(postFrameContext));
    } else {
      completer.complete(null);
    }
  });
  return completer.future;
}

class CustomDialog<T> extends StatefulWidget {
  const CustomDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.onConfirm,
    required this.closeOnConfirm,
    this.child,
  });

  final String title;
  final String? subtitle;
  final FutureOr<T?> Function()? onConfirm;
  final bool closeOnConfirm;
  final Widget? child;

  @override
  State<CustomDialog<T>> createState() => _CustomDialogState<T>();
}

class _CustomDialogState<T> extends State<CustomDialog<T>> {
  bool _isClosing = false;

  void _close([T? result]) {
    if (_isClosing || !mounted) return;
    if (ModalRoute.of(context)?.isActive != true) return;
    _isClosing = true;
    Navigator.of(context).pop(result);
  }

  Future<void> _confirm() async {
    final onConfirm = widget.onConfirm;
    if (onConfirm == null || _isClosing) return;
    final result = await onConfirm();
    if (widget.closeOnConfirm) _close(result);
  }

  @override
  Widget build(BuildContext context) {
    final withConfirm = widget.onConfirm != null;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding * 1.5,
      ),
      child: MyMaterial(
        theme: MyMaterialTheme.glass,
        whiteBG: false,
        borderRadius: BorderRadius.circular(kLargeBorderRadius),
        padding: const EdgeInsets.all(kLargeBorderRadius * 0.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: kLargeFont,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: kSmallPadding),
              Text(
                widget.subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: kSmallFont,
                  color: context.secondary,
                ),
              ),
            ],
            if (widget.child != null) ...[
              const SizedBox(height: kMediumPadding),
              widget.child!,
            ],
            const SizedBox(height: kMediumPadding),
            Row(
              spacing: kMediumPadding,
              children: [
                DialogButton(
                  title: withConfirm ? l10n.cancel : l10n.close,
                  color: withConfirm ? context.error : context.primary,
                  onPressed: _close,
                ),
                if (withConfirm)
                  DialogButton(
                    title: l10n.confirm,
                    color: context.primary,
                    onPressed: _confirm,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DialogButton extends StatelessWidget {
  const DialogButton({
    super.key,
    required this.title,
    required this.onPressed,
    required this.color,
  });

  final String title;
  final Color color;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: kLargePadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kCircleBorderRadius),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: kMediumFont,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
