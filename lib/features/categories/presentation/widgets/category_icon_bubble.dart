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
            // Soft shadow only — no border
            boxShadow: [
              BoxShadow(
                color: rawColor.withOpacity(isSelected ? 0.30 : 0.14),
                blurRadius: isSelected ? 10 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              effectiveIcon,
              // Icon is always white, like iOS-style solid icon
              color: Colors.white.withOpacity(isSelected ? 1.0 : 0.95),
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
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
