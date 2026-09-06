import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";
import "package:skepr_ui/widgets/nav_bar/nav_bar_button.dart";
import "package:skepr_ui/widgets/nav_bar/nav_bar_entity.dart";

class NavBar extends StatelessWidget {
  const NavBar({
    super.key,
    required this.currentIndex,
    required this.onPageChanged,
    required this.items,
    this.hasRightAction = false,
  });

  final int currentIndex;
  final Function(int) onPageChanged;
  final List<NavBarEntity> items;
  final bool hasRightAction;

  @override
  Widget build(BuildContext context) {
    final rightEntity = hasRightAction ? items.first : null;
    final leftItems = hasRightAction ? items.sublist(1) : items;

    void handleTap(NavBarEntity entity, int index) {
      if (entity.widget != null) {
        onPageChanged(index);
        SkeprMaterial.onScreenTracked?.call(
          entity.widget.runtimeType.toString(),
        );
      } else {
        entity.onPressed?.call();
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [context.background, context.background.withValues(alpha: 0)],
        ),
      ),
      padding: const EdgeInsets.only(
        right: kLargePadding,
        left: kLargePadding,
        bottom: kDefaultPadding,
      ),
      child: Row(
        mainAxisAlignment: hasRightAction
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.center,
        children: [
          if (rightEntity != null)
            MyMaterial(
              width: kDefaultPadding * 3.2,
              height: kDefaultPadding * 3.2,
              child: BarButton(
                icon: rightEntity.icon,
                buttonsLength: 1,
                isActive: rightEntity.isWidget && currentIndex == 0,
                onPressed: () => handleTap(rightEntity, 0),
              ),
            ),

          MyMaterial(
            padding: const EdgeInsets.symmetric(horizontal: kMediumPadding),
            height: 65,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: hasRightAction
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.spaceAround,
              children: leftItems.asMap().entries.map((entry) {
                final int actualIndex = hasRightAction
                    ? entry.key + 1
                    : entry.key;
                final entity = entry.value;

                return BarButton(
                  icon: entity.icon,
                  title: entity.title,
                  buttonsLength: leftItems.length,
                  isActive: entity.isWidget && currentIndex == actualIndex,
                  onPressed: () => handleTap(entity, actualIndex),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
