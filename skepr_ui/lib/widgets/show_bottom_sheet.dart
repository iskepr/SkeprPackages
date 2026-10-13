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
    this.fadeHeight = 32.0,
  });

  final Widget child;
  final int height;
  final bool bg;
  final bool reverse;
  final bool closeButton;
  final bool isScrollable;
  final List<Widget> actionButtons;
  final double fadeHeight;

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
            Positioned.fill(
              child: _applyFade(
                widget.isScrollable
                    ? _scrollableChild(controller)
                    : _buildBody(withPadding: false),
              ),
            ),

            Positioned(top: 0, left: 0, right: 0, child: _buildHeader()),
          ],
        ),
      ),
    );
  }

  Widget _applyFade(Widget child) {
    final fade = widget.fadeHeight;

    return ShaderMask(
      shaderCallback: (Rect bounds) {
        final h = bounds.height;
        if (h <= 0) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.white],
            stops: [0, 1],
          ).createShader(bounds);
        }

        final stop = (fade / h).clamp(0.0, 1.0);

        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Colors.transparent, Colors.white],
          stops: [0, stop],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }

  Widget _buildBody({bool withPadding = true}) {
    return Padding(
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
    );
  }

  Widget _scrollableChild(ScrollController controller) {
    return SingleChildScrollView(
      controller: controller,
      reverse: widget.reverse,
      child: _buildBody(),
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
  double fadeHeight = 50,
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
          fadeHeight: fadeHeight,
          child: child,
        ),
      );
    },
  );
}
