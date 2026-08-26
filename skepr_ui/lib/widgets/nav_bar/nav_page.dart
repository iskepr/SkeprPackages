import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";
import "package:url_launcher/url_launcher.dart";

export "package:skepr_ui/widgets/header.dart";
export "package:skepr_ui/widgets/nav_bar/nav_bar.dart";
export "package:skepr_ui/widgets/nav_bar/nav_bar_entity.dart";

class NavPage extends StatelessWidget {
  const NavPage({
    super.key,
    this.child,
    this.pages,
    this.pageController,
    this.onPageChanged,
    required this.header,
    this.reverse = false,
    this.isScrollable = true,
    this.overlapHeader = false,
    this.withMyLink = true,
    this.onRefresh = Future.value,
    this.padding,
  });

  final Widget header;
  final Widget? child;
  final List<Widget>? pages;
  final PageController? pageController;
  final Function(int)? onPageChanged;
  final bool reverse, isScrollable, overlapHeader;
  final bool withMyLink;
  final EdgeInsets? padding;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double totalTopPadding = statusBarHeight + 65;

    Widget finalBody;

    if (pages != null) {
      finalBody = PageView.builder(
        controller: pageController,
        onPageChanged: onPageChanged,
        itemCount: pages!.length,
        itemBuilder: (context, index) {
          final pageContent = _buildContent(pages![index], totalTopPadding);
          return isScrollable
              ? SingleChildScrollView(
                  reverse: reverse,
                  padding: EdgeInsets.only(top: totalTopPadding),
                  child: pageContent,
                )
              : pageContent;
        },
      );
    } else {
      final pageContent = _buildContent(child!, totalTopPadding);
      finalBody = isScrollable
          ? SingleChildScrollView(
              reverse: reverse,
              padding: EdgeInsets.only(top: totalTopPadding),
              child: pageContent,
            )
          : pageContent;
    }

    return Stack(
      children: [
        Positioned.fill(child: finalBody),
        Positioned(top: 0, left: 0, right: 0, child: header),
      ],
    );
  }

  Widget _buildFooter() {
    if (!withMyLink) return const SizedBox.shrink();
    return Column(
      children: [
        TextButton(
          onPressed: () => launchUrl(Uri.parse("$kSkeprWebsite?from=app")),
          child: Center(
            child: TextIcon(
              l10n.codeBySkepr,
              icon: LucideIcons.codeXml,
              disabled: false,
              size: kLargeFont,
            ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildContent(Widget content, double topPadding) {
    return Padding(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      child: Column(
        children: [
          if (!isScrollable && !overlapHeader) SizedBox(height: topPadding),
          isScrollable ? content : Expanded(child: content),
          _buildFooter(),
        ],
      ),
    );
  }
}
