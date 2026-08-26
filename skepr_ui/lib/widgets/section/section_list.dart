import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";

class SectionList<T> extends StatelessWidget {
  final List<T> listItems;
  final String? errorMessage;
  final String? emptyMessage;
  final EdgeInsets? padding;
  final int? lengthLimit;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  const SectionList({
    super.key,
    required this.listItems,
    this.errorMessage,
    this.emptyMessage,
    this.padding,
    this.lengthLimit,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (listItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(kSmallPadding),
        child: Center(
          child: Text(errorMessage ?? emptyMessage ?? "لا يوجد بيانات"),
        ),
      );
    }

    final bool isOverLimit =
        lengthLimit != null && listItems.length > lengthLimit!;

    return SizedBox(
      height: isOverLimit
          ? (lengthLimit!.toDouble()) * (kDefaultPadding * 2)
          : null,
      child: ListView.builder(
        padding: padding ?? const EdgeInsets.all(kSmallPadding),
        shrinkWrap: !isOverLimit,
        physics: isOverLimit
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        itemCount: listItems.length,
        itemBuilder: (context, index) {
          return itemBuilder(context, listItems[index], index);
        },
      ),
    );
  }
}
