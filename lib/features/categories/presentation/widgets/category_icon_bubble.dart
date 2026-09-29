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

    final borderRadius = BorderRadius.circular(size * 0.32);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                effectiveColor.withOpacity(isSelected ? 0.35 : 0.22),
                effectiveColor.withOpacity(isSelected ? 0.20 : 0.08),
              ],
            ),
            border: Border.all(
              color: isSelected
                  ? effectiveColor
                  : effectiveColor.withOpacity(0.40),
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: effectiveColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
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
