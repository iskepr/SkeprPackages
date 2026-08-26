import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";

class SectionSearchInput extends StatelessWidget {
  final bool enableSearch;
  final FocusNode focusNode;
  final TextEditingController controller;
  final bool disableButton;
  final void Function(String?) onChanged;

  const SectionSearchInput({
    super.key,
    required this.enableSearch,
    required this.focusNode,
    required this.controller,
    required this.disableButton,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: kAnimationDuration,
      crossFadeState: enableSearch
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      firstChild: Input(
        labelText: l10n.search,
        focusNode: focusNode,
        controller: controller,
        withButton: LucideIcons.search,
        disableButton: disableButton,
        hasBorder: false,
        onChanged: onChanged,
      ),
      secondChild: const SizedBox(width: double.infinity, height: 0),
    );
  }
}
