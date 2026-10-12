import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../transactions/models/transaction_type.dart';
import '../../../categories/models/category_model.dart';
import '../../../categories/providers/category_provider.dart';
import 'category_icon_bubble.dart';

/// Special sentinel value returned when user picks "ย้ายเงิน"
const String kTransferCategoryResult = '__transfer__';

/// Shows a bottom sheet grid of categories with Expense and Income tabs.
Future<String?> showCategoryQuickPicker(
  BuildContext context,
  WidgetRef ref, {
  String? currentCategoryId,
  TransactionType initialType = TransactionType.expense,
}) async {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _CategoryPickerSheet(
      currentCategoryId: currentCategoryId,
      initialType: initialType,
    ),
  );
}

class _CategoryPickerSheet extends ConsumerStatefulWidget {
  final String? currentCategoryId;
  final TransactionType initialType;

  const _CategoryPickerSheet({
    this.currentCategoryId,
    required this.initialType,
  });

  @override
  ConsumerState<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends ConsumerState<_CategoryPickerSheet> {
  late CategoryType _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialType == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider);
    final expenseCategories = categories.where((c) => c.type == CategoryType.expense).toList();
    final incomeCategories = categories.where((c) => c.type == CategoryType.income).toList();
    final currentList = _selectedTab == CategoryType.expense ? expenseCategories : incomeCategories;

    return DraggableScrollableSheet(
      initialChildSize: 0.70,
      minChildSize: 0.45,
      maxChildSize: 0.92,
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
          const SizedBox(height: 14),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'เลือกหมวดหมู่',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 12),

          // Segmented Tab Switcher (รายจ่าย / รายรับ)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primarySoftBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cartoonOutline, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = CategoryType.expense),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTab == CategoryType.expense
                            ? AppColors.expense
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_upward_rounded,
                            size: 15,
                            color: _selectedTab == CategoryType.expense ? Colors.white : AppColors.expense,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'รายจ่าย (${expenseCategories.length})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _selectedTab == CategoryType.expense ? Colors.white : AppColors.expense,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = CategoryType.income),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTab == CategoryType.income
                            ? AppColors.income
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_downward_rounded,
                            size: 15,
                            color: _selectedTab == CategoryType.income ? Colors.white : AppColors.income,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'รายรับ (${incomeCategories.length})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _selectedTab == CategoryType.income ? Colors.white : AppColors.income,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Categories Grid
          Expanded(
            child: currentList.isEmpty
                ? Center(
                    child: Text(
                      _selectedTab == CategoryType.income ? 'ยังไม่มีหมวดหมู่รายรับ' : 'ยังไม่มีหมวดหมู่รายจ่าย',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: currentList.length,
                    itemBuilder: (context, index) {
                      final cat = currentList[index];
                      final isSelected = cat.id == widget.currentCategoryId;
                      return GestureDetector(
                        onTap: () => Navigator.of(context).pop(cat.id),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CategoryIconBubble(
                              category: cat,
                              size: 54,
                              isSelected: isSelected,
                              showEmojiBadge: true,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              cat.nameThai,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? cat.color : AppColors.textPrimary,
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

          // ── ย้ายเงิน separator & button ────────────────────────────────────
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.transfer, width: 1.8),
                  backgroundColor: AppColors.transfer.withOpacity(0.08),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.transfer, size: 20),
                label: const Text(
                  '⇄  ย้ายเงินระหว่างบัญชี (ไม่คิดรายรับ-จ่าย)',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.transfer,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(kTransferCategoryResult),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
