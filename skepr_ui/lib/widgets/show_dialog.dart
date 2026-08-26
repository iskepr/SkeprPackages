import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";

void showCustomDialog({
  required String title,
  String? subtitle,
  void Function()? onConfirm,
  void Function()? onDismiss,
  bool closeOnConfirm = true,
  Widget? child,
  bool easyClose = true,
}) {
  void buildDialog(BuildContext ctx) {
    showGeneralDialog(
      context: ctx,
      barrierDismissible: easyClose,
      barrierLabel: title,
      transitionDuration: kAnimationFasterDuration,
      pageBuilder: (context, animation, secondaryAnimation) => CustomDialog(
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
    ).then((_) {
      if (onDismiss != null) onDismiss();
    });
  }

  final context = SkeprMaterial.currentContext;
  if (context != null) {
    buildDialog(context);
  } else {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final postFrameContext = SkeprMaterial.currentContext;
      if (postFrameContext != null) buildDialog(postFrameContext);
    });
  }
}

class CustomDialog extends StatelessWidget {
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
  final void Function()? onConfirm;
  final bool closeOnConfirm;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final withConfirm = onConfirm != null;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding * 1.5,
      ),
      child: MyMaterial(
        theme: MyMaterialTheme.glass,
        borderRadius: BorderRadius.circular(kLargeBorderRadius),
        padding: const EdgeInsets.all(kLargeBorderRadius * 0.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: kLargeFont,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: kSmallPadding),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: kSmallFont,
                  color: context.secondary,
                ),
              ),
            ],
            if (child != null) ...[
              const SizedBox(height: kMediumPadding),
              child!,
            ],
            const SizedBox(height: kMediumPadding),
            Row(
              spacing: kMediumPadding,
              children: [
                DialogButton(
                  title: withConfirm ? l10n.cancel : l10n.close,
                  color: withConfirm ? context.error : context.primary,
                  onPressed: () => context.close(),
                ),
                if (withConfirm) ...[
                  DialogButton(
                    title: l10n.confirm,
                    color: context.primary,
                    onPressed: () {
                      onConfirm?.call();
                      if (closeOnConfirm) context.close();
                    },
                  ),
                ],
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
