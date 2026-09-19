import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isPrimary;
  final bool isFullWidth;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isPrimary = true,
    this.isFullWidth = true,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? (isPrimary ? AppColors.primary : Colors.transparent);
    final effectiveFg = textColor ?? (isPrimary ? Colors.white : AppColors.primary);

    Widget content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveFg),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: 20, color: effectiveFg),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: TextStyle(
            color: effectiveFg,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 48,
      child: isPrimary
          ? ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: effectiveBg,
                foregroundColor: effectiveFg,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: content,
            )
          : OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: effectiveFg,
                side: BorderSide(color: effectiveFg, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: content,
            ),
    );
  }
}
