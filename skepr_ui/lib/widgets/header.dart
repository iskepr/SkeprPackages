import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";

class Header extends StatefulWidget {
  const Header({
    super.key,
    required this.start,
    required this.end,
    this.center,
    this.bg,
  });
  final Widget start;
  final Widget? center;
  final List<Widget> end;
  final Color? bg;
  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final bg = widget.bg ?? context.background;
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
            widget.start,
            if (widget.center != null)
              MyMaterial(
                padding: const EdgeInsets.all(kMediumPadding * 0.8),
                child: widget.center!,
              ),
            MyMaterial(child: Row(children: widget.end)),
          ],
        ),
      ),
    );
  }
}
