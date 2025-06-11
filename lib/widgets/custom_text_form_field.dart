import 'package:flutter/material.dart';

class CustomTextFormField extends StatelessWidget {
  final String label;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final void Function(String)? onChanged;
  final String? hintText;
  final bool filled;
  final int? maxLines;
  final String? initialValue;

  const CustomTextFormField({
    Key? key,
    required this.label,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.hintText,
    this.filled = true,
    this.maxLines,
    this.initialValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Đảm bảo rằng maxLines không quá 1 nếu obscureText là true
    final effectiveMaxLines = obscureText ? 1 : maxLines;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      validator: validator,
      maxLines: effectiveMaxLines, // Use the effective value
      initialValue: initialValue,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon:
            prefixIcon != null
                ? Icon(prefixIcon, color: theme.colorScheme.primary)
                : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
        ),
        filled: filled,
        fillColor: theme.inputDecorationTheme.fillColor,
        labelStyle: TextStyle(color: theme.colorScheme.primary),
        hintStyle: TextStyle(color: theme.colorScheme.primary.withOpacity(0.5)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
