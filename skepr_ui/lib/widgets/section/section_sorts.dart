import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";

class SectionSorts<T> extends StatelessWidget {
  const SectionSorts({
    super.key,
    required this.enableSorting,
    required this.selectedSort,
    required this.sorts,
    required this.isAscending,
    required this.onChanged,
  });
  final bool enableSorting;
  final int selectedSort;
  final List<SectionSortEntity<T>> sorts;
  final bool isAscending;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: kAnimationDuration,
      crossFadeState: enableSorting
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      firstChild: Container(
        height: kDefaultPadding * 1.5,
        margin: const EdgeInsets.only(bottom: kSmallPadding),
        child: ListView.builder(
          itemCount: sorts.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            final sort = sorts[index];
            final isSelected = index == selectedSort;
            return GestureDetector(
              onTap: () => onChanged(index),
              child: Container(
                height: kDefaultPadding,
                padding: const EdgeInsets.symmetric(
                  horizontal: kMediumPadding,
                  vertical: kSmallPadding,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? context.foreground : null,
                  borderRadius: BorderRadius.circular(kCircleBorderRadius),
                ),
                child: TextIcon(
                  sort.title,
                  icon: isAscending && isSelected ? sort.iconA : sort.iconD,
                  size: kDefaultPadding * 0.7,
                  disabled: true,
                ),
              ),
            );
          },
        ),
      ),
      secondChild: const SizedBox(width: double.infinity, height: 0),
    );
  }
}

class SectionSortEntity<T> {
  final String title;
  final IconData iconA;
  final IconData iconD;
  final int Function(T a, T b) compare;

  SectionSortEntity({
    required this.title,
    required this.iconA,
    required this.iconD,
    required this.compare,
  });
}
