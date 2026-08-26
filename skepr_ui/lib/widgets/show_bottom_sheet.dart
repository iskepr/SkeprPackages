import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";

class MyBottomSheet extends StatefulWidget {
  const MyBottomSheet({
    super.key,
    required this.child,
    this.height = 70,
    this.bg = true,
    this.reverse = false,
    this.closeButton = false,
    this.isScrollable = false,
    this.actionButtons = const [],
  });

  final Widget child;
  final int height;
  final bool bg;
  final bool reverse;
  final bool closeButton;
  final bool isScrollable;
  final List<Widget> actionButtons;

  @override
  State<MyBottomSheet> createState() => _MyBottomSheetState();
}

class _MyBottomSheetState extends State<MyBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: widget.height / 100,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => MyMaterial(
        width: double.infinity,
        theme: MyMaterialTheme.glass,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(kMediumBorderRadius),
        ),
        child: Stack(
          children: [
            widget.isScrollable
                ? _scrollableChild(controller)
                : _buldBody(withPadding: false),

            Positioned(top: 0, left: 0, right: 0, child: _buildHeader()),
          ],
        ),
      ),
    );
  }

  Widget _buldBody({bool withPadding = true}) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.white],
          stops: [0, 0.1],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: Padding(
        padding: !withPadding
            ? EdgeInsets.zero
            : EdgeInsets.only(
                left: kDefaultPadding,
                right: kDefaultPadding,
                top: widget.closeButton || widget.actionButtons.isNotEmpty
                    ? kDefaultPadding * 2
                    : kDefaultPadding,
                bottom: kLargePadding,
              ),
        child: widget.child,
      ),
    );
  }

  Widget _scrollableChild(ScrollController controller) {
    return Positioned.fill(
      child: SingleChildScrollView(
        controller: controller,
        reverse: widget.reverse,
        child: _buldBody(),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: (widget.closeButton || widget.actionButtons.isNotEmpty)
                ? MyMaterial(
                    margin: const EdgeInsets.all(kMediumPadding),
                    child: IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => context.close(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: kMediumPadding),
          decoration: BoxDecoration(
            color: context.secondary,
            borderRadius: BorderRadius.circular(kMediumBorderRadius),
          ),
          height: 5,
          width: 40,
        ),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: widget.actionButtons.isNotEmpty
                ? MyMaterial(
                    margin: const EdgeInsets.all(kMediumPadding),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        widget.actionButtons.length,
                        (index) => widget.actionButtons[index],
                      ),
                    ),
                  )
                : (widget.closeButton
                      ? const SizedBox(width: 60)
                      : const SizedBox.shrink()),
          ),
        ),
      ],
    );
  }
}

Future<T?> showMyBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  int height = 70,
  bool reverse = false,
  bool easyClose = true,
  bool? closeButton,
  bool isScrollable = true,
  List<Widget>? actionButtons,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isDismissible: easyClose,
    enableDrag: easyClose,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: const AnimationStyle(
      curve: kCurveEaseInOut,
      reverseCurve: kCurveEaseInOut,
      duration: kAnimationDuration,
      reverseDuration: kAnimationDuration,
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: kSmallPadding,
          right: kSmallPadding,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: MyBottomSheet(
          reverse: reverse,
          height: height,
          closeButton: closeButton ?? false,
          actionButtons: actionButtons ?? [],
          isScrollable: isScrollable,
          child: child,
        ),
      );
    },
  );
}
