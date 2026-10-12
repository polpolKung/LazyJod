import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/category_model.dart';
import '../../providers/category_provider.dart';
import '../widgets/category_icon_bubble.dart';
import 'category_edit_screen.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  final CategoryType initialType;

  const CategoryManagementScreen({
    super.key,
    this.initialType = CategoryType.expense,
  });

  @override
  ConsumerState<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends ConsumerState<CategoryManagementScreen> {
  late CategoryType _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final expenseCategories = categories.where((c) => c.type == CategoryType.expense).toList();
    final incomeCategories = categories.where((c) => c.type == CategoryType.income).toList();
    final displayedCategories = _selectedTab == CategoryType.expense ? expenseCategories : incomeCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการหมวดหมู่'),
      ),
      body: Column(
        children: [
          // Segmented Tab Switcher (รายจ่าย / รายรับ)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.primarySoftBg,
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
                      padding: const EdgeInsets.symmetric(vertical: 10),
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
                            size: 16,
                            color: _selectedTab == CategoryType.expense ? Colors.white : AppColors.expense,
                          ),
                          const SizedBox(width: 6),
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
                      padding: const EdgeInsets.symmetric(vertical: 10),
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
                            size: 16,
                            color: _selectedTab == CategoryType.income ? Colors.white : AppColors.income,
                          ),
                          const SizedBox(width: 6),
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

          // Categories List
          Expanded(
            child: displayedCategories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedTab == CategoryType.income ? Icons.savings_outlined : Icons.receipt_long_outlined,
                          size: 64,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedTab == CategoryType.income
                              ? 'ยังไม่มีหมวดหมู่รายรับ'
                              : 'ยังไม่มีหมวดหมู่รายจ่าย',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'กดปุ่ม + ด้านล่างเพื่อเพิ่มหมวดหมู่ใหม่',
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: displayedCategories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final cat = displayedCategories[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                        ),
                        child: ListTile(
                          leading: CategoryIconBubble(
                            category: cat,
                            size: 44,
                            showEmojiBadge: true,
                          ),
                          title: Text(
                            cat.nameThai,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            cat.autoKeywords.isNotEmpty
                                ? 'คีย์เวิร์ด: ${cat.autoKeywords.take(3).join(', ')}...'
                                : 'ไม่มีคีย์เวิร์ดพิเศษ',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CategoryEditScreen(
                                        initialCategory: cat,
                                        initialType: _selectedTab,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (!cat.isDefault)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.expense),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('ยืนยันการลบหมวดหมู่'),
                                        content: Text('คุณต้องการลบหมวดหมู่ "${cat.nameThai}" ใช่หรือไม่?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(false),
                                            child: const Text('ยกเลิก'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(true),
                                            child: const Text('ลบ', style: TextStyle(color: AppColors.expense)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      ref.read(categoryProvider.notifier).deleteCategory(cat.id);
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CategoryEditScreen(initialType: _selectedTab),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
