import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.bigTitle,
    required this.actionButtons,
    required this.isLoading,
    required this.listItems,
    required this.centerTitle,
  });

  final dynamic title;
  final bool bigTitle;
  final List<SectionHeaderButton> actionButtons;
  final bool isLoading;
  final List listItems;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        right: kMediumPadding,
        left: kSmallPadding,
        bottom: kSmallPadding,
      ),
      child: Stack(
        alignment: bigTitle ? Alignment.bottomCenter : Alignment.center,
        children: [
          if (title != null)
            Container(
              width: double.infinity,
              alignment: SkeprMaterial.isRTL
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  title is String
                      ? Expanded(
                          flex: listItems.isNotEmpty ? 0 : 1,
                          child: SelectableText(
                            title,
                            textAlign: (bigTitle && centerTitle)
                                ? TextAlign.center
                                : null,
                            style: TextStyle(
                              fontSize: bigTitle ? kLargeFont : kSoSmallFont,
                            ),
                          ),
                        )
                      : (title as Widget),
                  Text(
                    listItems.isNotEmpty ? " (${listItems.length})" : "",
                    style: TextStyle(
                      fontSize: kSoSmallFont,
                      color: context.secondary,
                    ),
                  ),
                ],
              ),
            ),
          if (actionButtons.isNotEmpty)
            PositionedDirectional(
              end: 0,
              bottom: bigTitle ? 0 : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(actionButtons.length, (index) {
                  final button = actionButtons[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kSmallPadding,
                    ),
                    child: Directionality(
                      textDirection: SkeprMaterial.isRTL
                          ? TextDirection.ltr
                          : TextDirection.rtl,
                      child: TextIcon(
                        button.title ?? "",
                        icon: button.icon,
                        hideText: button.hideTitle,
                        color: context.text.withValues(alpha: 0.5),
                        onPressed: isLoading ? () {} : button.onTap,
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class SectionHeaderButton {
  final void Function() onTap;
  final IconData icon;
  final String? title;
  final bool hideTitle;

  const SectionHeaderButton({
    required this.onTap,
    required this.icon,
    this.title,
    this.hideTitle = true,
  });
}
