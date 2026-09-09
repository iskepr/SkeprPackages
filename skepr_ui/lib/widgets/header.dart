import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";

class Header extends StatelessWidget {
  const Header({
    super.key,
    this.start,
    required this.title,
    this.center,
    this.withBackButton,
    this.end,
    this.bg,
  }) : assert(
         title is String || title is Widget,
         "title must be a String or a Widget",
       );

  final List<Widget>? start;
  final dynamic title;
  final Widget? center;
  final List<Widget>? end;
  final bool? withBackButton;
  final Color? bg;

  @override
  Widget build(BuildContext context) {
    final bool canPop = withBackButton ?? Navigator.of(context).canPop();
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final bg = this.bg ?? context.background;

    final leftSide = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (start != null) MyMaterial(child: Row(children: start!)),
        if (title != null) ...[
          if (start != null) const SizedBox(width: kSmallPadding),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: title is String
                    ? Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: kLargeFont),
                      )
                    : title,
              ),
            ),
          ),
        ],
      ],
    );

    final rightSide = (end != null || canPop)
        ? Align(
            alignment: AlignmentDirectional.centerEnd,
            child: MyMaterial(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...end ?? [],
                  if (canPop)
                    IconButton(
                      icon: const Icon(LucideIcons.chevronRight),
                      onPressed: () => context.close(),
                    ),
                ],
              ),
            ),
          )
        : const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [bg.withOpacity(0), bg],
        ),
      ),
      padding: EdgeInsets.symmetric(
        vertical: statusBarHeight == 0 ? kDefaultPadding : kSmallPadding,
        horizontal: kDefaultPadding,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          spacing: kSmallPadding,
          children: [
            Expanded(child: leftSide),

            if (center != null) center!,

            Expanded(child: rightSide),
          ],
        ),
      ),
    );
  }
}
