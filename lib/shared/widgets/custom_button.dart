import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// KLE HOMECARE — Reusable Primary Button
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: (onPressed == null || isLoading) ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.primary,
        foregroundColor: foregroundColor ?? Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
      ),
      child: isLoading
        ? const SizedBox(
            width: 22, height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5, color: Colors.white),
          )
        : icon != null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            )
          : Text(label, style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }
}
