import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";

class SectionFilters<T> extends StatelessWidget {
  const SectionFilters({
    super.key,
    required this.enableFilter,
    required this.selectedFilters,
    required this.toggledStates,
    required this.filters,
    required this.onChanged,
  });
  final bool enableFilter;
  final List<int> selectedFilters;
  final Map<int, bool> toggledStates;
  final List<SectionFilterEntity<T>> filters;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    final Map<String, List<int>> groupedFilters = {};
    for (int i = 0; i < filters.length; i++) {
      final groupName = filters[i].group ?? "general";
      groupedFilters.putIfAbsent(groupName, () => []).add(i);
    }

    return AnimatedCrossFade(
      duration: kAnimationDuration,
      crossFadeState: enableFilter
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      firstChild: Container(
        margin: const EdgeInsets.only(bottom: kSmallPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: groupedFilters.values.map((groupIndices) {
            return Padding(
              padding: const EdgeInsets.only(bottom: kSmallPadding),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: groupIndices.map((index) {
                    final filter = filters[index];
                    final isSelected = selectedFilters.contains(index);
                    final isToggled = toggledStates[index] ?? false;

                    final currentTitle =
                        (isToggled && filter.toggleTitle != null)
                        ? filter.toggleTitle!
                        : filter.title;
                    final currentIcon = (isToggled && filter.toggleIcon != null)
                        ? filter.toggleIcon!
                        : filter.icon;

                    return Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: kSmallPadding,
                      ),
                      child: GestureDetector(
                        onTap: () => onChanged(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: kMediumPadding,
                            vertical: kSmallPadding,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? context.foreground : null,
                            borderRadius: BorderRadius.circular(
                              kCircleBorderRadius,
                            ),
                          ),
                          child: TextIcon(
                            currentTitle,
                            icon: currentIcon,
                            size: kDefaultPadding * 0.7,
                            disabled: true,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      secondChild: const SizedBox(width: double.infinity, height: 0),
    );
  }
}

class SectionFilterEntity<T> {
  final String title;
  final IconData icon;
  final String? toggleTitle;
  final IconData? toggleIcon;
  final String? group;
  final bool Function(T item)? condition;
  final bool Function(T item)? toggleCondition;

  SectionFilterEntity({
    required this.title,
    required this.icon,
    this.toggleTitle,
    this.toggleIcon,
    this.group,
    this.condition,
    this.toggleCondition,
  });
}
