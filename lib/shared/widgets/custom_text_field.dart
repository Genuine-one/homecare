import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// KLE HOMECARE — Reusable Text Field
class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int maxLines;
  final bool enabled;
  final void Function(String)? onChanged;
  final TextInputAction textInputAction;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:       controller,
      validator:        validator,
      obscureText:      obscureText,
      keyboardType:     keyboardType,
      maxLines:         obscureText ? 1 : maxLines,
      enabled:          enabled,
      onChanged:        onChanged,
      textInputAction:  textInputAction,
      decoration: InputDecoration(
        labelText:  label,
        hintText:   hint,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
      ),
    );
  }
}
