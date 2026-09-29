import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/category_model.dart';

/// iOS-style solid-fill squircle icon bubble.
/// Uses solid mint fill (from logo) with white icon — like Image 3 reference.
/// No gradient, no semi-transparent — clean, soft, and cute.
class CategoryIconBubble extends StatelessWidget {
  final CategoryModel? category;
  final IconData? overrideIcon;
  final Color? overrideColor;
  final String? overrideEmoji;
  final double size;
  final bool isSelected;
  final bool isTransfer;
  final bool isUncategorized;
  final bool showEmojiBadge;

  const CategoryIconBubble({
    super.key,
    this.category,
    this.overrideIcon,
    this.overrideColor,
    this.overrideEmoji,
    this.size = 46,
    this.isSelected = false,
    this.isTransfer = false,
    this.isUncategorized = false,
    this.showEmojiBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    // For the solid fill: we use the category color but desaturate it
    // to match the cute pastel "iOS icon" style from reference Image 3.
    // Unselected = soft pastel fill; Selected = richer fill
    final rawColor = isTransfer
        ? AppColors.transfer
        : (isUncategorized
            ? AppColors.warning
            : (overrideColor ?? category?.color ?? AppColors.primary));

    // Blend the category color toward the primary mint to keep it cohesive
    // and prevent any single category from looking neon
    final fillColor = isSelected
        ? Color.alphaBlend(rawColor.withOpacity(0.75), AppColors.primaryMint)
        : Color.alphaBlend(rawColor.withOpacity(0.55), AppColors.primaryLight);

    final effectiveIcon = isTransfer
        ? Icons.swap_horiz_rounded
        : (isUncategorized
            ? Icons.help_outline_rounded
            : (overrideIcon ?? category?.icon ?? Icons.category_rounded));

    final emoji = isTransfer
        ? '🔄'
        : (isUncategorized ? '🦥' : (overrideEmoji ?? category?.emoji));

    final borderRadius = BorderRadius.circular(size * 0.26); // iOS squircle

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: fillColor,
            border: Border.all(
              color: AppColors.cartoonOutline,
              width: isSelected ? 2.4 : 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.cartoonOutline.withOpacity(isSelected ? 0.20 : 0.10),
                offset: const Offset(0, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              effectiveIcon,
              color: Colors.white,
              size: size * 0.50,
            ),
          ),
        ),
        if (showEmojiBadge && emoji != null && emoji.isNotEmpty)
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cartoonOutline, width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cartoonOutline.withOpacity(0.12),
                    offset: const Offset(0, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Text(
                emoji,
                style: TextStyle(fontSize: size * 0.26),
              ),
            ),
          ),
      ],
    );
  }
}
