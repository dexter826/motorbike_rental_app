import 'package:flutter/material.dart';

class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool selected;
  final Function(bool) onSelected;
  final Color? selectedColor;
  final Color? backgroundColor;
  final Color? checkmarkColor;
  final TextStyle? labelStyle;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.selectedColor,
    this.backgroundColor,
    this.checkmarkColor,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(
        label,
        style:
            labelStyle ??
            TextStyle(
              color:
                  selected ? Colors.white : theme.textTheme.bodyMedium?.color,
            ),
      ),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: backgroundColor ?? theme.cardTheme.color,
      selectedColor: selectedColor ?? theme.primaryColor,
      checkmarkColor: checkmarkColor ?? Colors.white,
    );
  }
}
