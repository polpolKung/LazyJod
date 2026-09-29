import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/category_model.dart';

/// A delightfully styled, cute pastel squircle bubble for category icons.
/// Matches the pastel theme and sloth aesthetic of Lazy Jod.
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
    final effectiveColor = isTransfer
        ? AppColors.transfer
        : (isUncategorized
            ? AppColors.warning
            : (overrideColor ?? category?.color ?? AppColors.primary));

    final effectiveIcon = isTransfer
        ? Icons.swap_horizontal_circle_rounded
        : (isUncategorized
            ? Icons.psychology_alt_rounded
            : (overrideIcon ?? category?.icon ?? Icons.category_rounded));

    final emoji = isTransfer
        ? '🔄'
        : (isUncategorized ? '🦥' : (overrideEmoji ?? category?.emoji));

    final borderRadius = BorderRadius.circular(size * 0.34);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: isSelected
                ? effectiveColor.withOpacity(0.26)
                : Color.alphaBlend(effectiveColor.withOpacity(0.12), AppColors.surface),
            border: Border.all(
              color: isSelected
                  ? effectiveColor
                  : Color.alphaBlend(effectiveColor.withOpacity(0.40), AppColors.cardBorder),
              width: isSelected ? 2.2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? effectiveColor.withOpacity(0.25)
                    : Colors.black.withOpacity(0.03),
                blurRadius: isSelected ? 8 : 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              effectiveIcon,
              color: effectiveColor,
              size: size * 0.52,
            ),
          ),
        ),
        if (showEmojiBadge && emoji != null && emoji.isNotEmpty)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: effectiveColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Text(
                emoji,
                style: TextStyle(fontSize: size * 0.28),
              ),
            ),
          ),
      ],
    );
  }
}
