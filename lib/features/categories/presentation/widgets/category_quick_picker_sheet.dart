import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../categories/models/category_model.dart';
import '../../../categories/providers/category_provider.dart';

/// Shows a bottom sheet grid of all categories for instant one-tap selection.
Future<String?> showCategoryQuickPicker(BuildContext context, WidgetRef ref, {String? currentCategoryId}) async {
  final categories = ref.read(categoryProvider);
  final expenseCategories = categories.where((c) => c.type == CategoryType.expense).toList();

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.darkBorder,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'เลือกหมวดหมู่',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: expenseCategories.length,
              itemBuilder: (context, index) {
                final cat = expenseCategories[index];
                final isSelected = cat.id == currentCategoryId;
                return GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(cat.id),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cat.color.withOpacity(0.25)
                              : cat.color.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: cat.color, width: 2.5)
                              : null,
                        ),
                        child: Icon(cat.icon, color: cat.color, size: 26),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat.nameThai,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? cat.color : null,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}
