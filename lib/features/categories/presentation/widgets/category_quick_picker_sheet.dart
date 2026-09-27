import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../categories/models/category_model.dart';
import '../../../categories/providers/category_provider.dart';

/// Special sentinel value returned when user picks "ย้ายเงิน"
const String kTransferCategoryResult = '__transfer__';

/// Shows a bottom sheet grid of all categories for instant one-tap selection.
/// Returns a category ID, or [kTransferCategoryResult] for ย้ายเงิน.
Future<String?> showCategoryQuickPicker(BuildContext context, WidgetRef ref, {String? currentCategoryId}) async {
  final categories = ref.read(categoryProvider);

  // Show all expense categories EXCEPT cat_transfer (that's handled by the special button below)
  final expenseCategories = categories
      .where((c) => c.type == CategoryType.expense && c.id != 'cat_transfer')
      .toList();

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.45,
      maxChildSize: 0.9,
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

          // ── ย้ายเงิน separator ──────────────────────────────────────────────
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.only(top: 10, bottom: 4, left: 20, right: 20),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 12, color: AppColors.transfer),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'ย้ายเงินระหว่างบัญชีตัวเอง — ไม่นับเป็นรายรับหรือรายจ่าย',
                    style: TextStyle(fontSize: 11, color: AppColors.transfer),
                  ),
                ),
              ],
            ),
          ),

          // ย้ายเงิน big button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.transfer, width: 1.5),
                  backgroundColor: AppColors.transfer.withOpacity(0.08),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.transfer, size: 22),
                label: const Text(
                  '⇄  ย้ายเงินระหว่างบัญชี (ไม่คิดรายรับ-จ่าย)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: AppColors.transfer,
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop(kTransferCategoryResult),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}
