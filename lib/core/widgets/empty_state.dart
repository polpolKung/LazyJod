import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'jod_mascot.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final bool useMascot;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.buttonText,
    this.onButtonPressed,
    this.useMascot = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (useMascot) ...[
              const JodMascotAvatar(size: 84, withBorder: true),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: const Text(
                  '🦥 จ้อด (Lazy Jod)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon ?? Icons.inbox_outlined, size: 48, color: AppColors.primary),
              ),
            const SizedBox(height: 18),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: onButtonPressed,
                icon: const Icon(Icons.add, size: 18),
                label: Text(buttonText!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
