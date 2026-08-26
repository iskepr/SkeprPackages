import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";

class SelectInput extends StatefulWidget {
  const SelectInput({
    super.key,
    this.value,
    required this.title,
    required this.items,
    required this.onChanged,
    this.validator,
    required this.hasBorder,
    required this.whiteBG,
  });

  final String? value;
  final String title;
  final List<SelectEntity> items;
  final Function(String?) onChanged;
  final bool hasBorder, whiteBG;
  final String? Function(String?)? validator;

  @override
  State<SelectInput> createState() => _SelectInputState();
}

class _SelectInputState extends State<SelectInput> {
  static _SelectInputState? _currentOpenState;
  bool isExpanded = false;
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.value;
    _autoSelectIfSingleItem();
  }

  @override
  void didUpdateWidget(SelectInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _selectedValue = widget.value;
    }
    _autoSelectIfSingleItem();
  }

  void _autoSelectIfSingleItem() {
    if (widget.validator != null && widget.items.length == 1) {
      final singleValue = widget.items.first.value.toString();
      if (_selectedValue != singleValue) {
        _selectedValue = singleValue;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onChanged(singleValue);
        });
      }
    }
  }

  void _close() {
    if (mounted && isExpanded) {
      setState(() => isExpanded = false);
    }
  }

  void _handleTap() {
    if (isExpanded) {
      _close();
      if (_currentOpenState == this) _currentOpenState = null;
    } else {
      _currentOpenState?._close();

      setState(() {
        isExpanded = true;
        _currentOpenState = this;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final showHeader = widget.items.length > 5;

    return FormField<String>(
      initialValue: _selectedValue,
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (FormFieldState<String> state) {
        final String selectedName =
            widget.items
                .where((i) => i.value.toString() == _selectedValue)
                .firstOrNull
                ?.name ??
            widget.title;

        void handelSelctTap(SelectEntity item) {
          final newValue = item.value.toString();
          widget.onChanged(newValue);
          state.didChange(newValue);
          setState(() {
            isExpanded = false;
            _selectedValue = _selectedValue == newValue ? null : newValue;
          });
          if (_currentOpenState == this) _currentOpenState = null;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Section<SelectEntity>(
              title: showHeader ? widget.title : null,
              hasBorder: widget.hasBorder,
              whiteBG: widget.whiteBG,
              bg: state.hasError ? context.error.withValues(alpha: 0.1) : null,
              listData: isExpanded ? widget.items : null,
              searchMatcher: showHeader ? (item) => item.name : null,
              emptyMessage: "${l10n.nothing} ${widget.title}",
              lengthLimit: kDefultSectionListLimit,
              child: CustomListTile(
                title: selectedName,
                onTap: _handleTap,
                trailing: Icon(
                  LucideIcons.chevronDown,
                  color: context.secondary,
                ),
              ),
              itemBuilder: (c, item, index) => CustomListTile(
                title: item.name,
                trailing: item.value.toString() == _selectedValue
                    ? Icon(LucideIcons.check, color: context.primary)
                    : null,
                onTap: () => handelSelctTap(item),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kSmallPadding),
                child: Text(
                  state.errorText ?? "",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: kSoSmallFont,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    if (_currentOpenState == this) _currentOpenState = null;
    super.dispose();
  }
}
