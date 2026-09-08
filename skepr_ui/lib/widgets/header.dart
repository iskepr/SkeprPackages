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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (start != null) MyMaterial(child: Row(children: start!)),

            if (title is String)
              Expanded(
                flex: center != null ? 0 : 1,
                child: Text(
                  title,
                  style: const TextStyle(fontSize: kLargeFont),
                ),
              )
            else
              title,

            if (center != null)
              MyMaterial(
                padding: const EdgeInsets.all(kMediumPadding * 0.8),
                child: center!,
              ),

            if (end != null || canPop)
              MyMaterial(
                child: Row(
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
          ],
        ),
      ),
    );
  }
}
