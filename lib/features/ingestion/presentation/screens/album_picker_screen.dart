import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/ingestion_provider.dart';

class AlbumPickerScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const AlbumPickerScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<AlbumPickerScreen> createState() => _AlbumPickerScreenState();
}

class _AlbumPickerScreenState extends ConsumerState<AlbumPickerScreen> {
  final TextEditingController _customExpenseController = TextEditingController();
  final TextEditingController _customIncomeController = TextEditingController();

  @override
  void dispose() {
    _customExpenseController.dispose();
    _customIncomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ingestionProvider);
    final notifier = ref.read(ingestionProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedExpenseCount = state.albums.where((a) => a.isSelected).length;
    final selectedIncomeCount = state.albums.where((a) => a.isIncomeSelected).length;

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('โฟลเดอร์สแกนสลิป'),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            unselectedLabelColor: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_upward_rounded, color: AppColors.expense, size: 18),
                    const SizedBox(width: 6),
                    const Text('โฟลเดอร์รายจ่าย'),
                    if (selectedExpenseCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.expense.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$selectedExpenseCount',
                          style: const TextStyle(fontSize: 11, color: AppColors.expense, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_downward_rounded, color: AppColors.income, size: 18),
                    const SizedBox(width: 6),
                    const Text('โฟลเดอร์รายรับ'),
                    if (selectedIncomeCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.income.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$selectedIncomeCount',
                          style: const TextStyle(fontSize: 11, color: AppColors.income, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ── TAB 1: Expense Folders ────────────────────────────────────
            _buildExpenseFoldersTab(context, state, notifier, isDark, selectedExpenseCount),

            // ── TAB 2: Income Folders ─────────────────────────────────────
            _buildIncomeFoldersTab(context, state, notifier, isDark, selectedIncomeCount),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseFoldersTab(
    BuildContext context,
    IngestionState state,
    IngestionNotifier notifier,
    bool isDark,
    int selectedCount,
  ) {
    return Column(
      children: [
        // Privacy Info Card
        Container(
          padding: const EdgeInsets.all(14),
          color: isDark ? AppColors.darkCard : Colors.white,
          child: Row(
            children: [
              const Icon(Icons.privacy_tip_outlined, color: AppColors.primary, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'โฟลเดอร์สลิปรายจ่าย (โอนเงินออก)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'สลิปในโฟลเดอร์ที่เลือกนี้จะถูกบันทึกเป็นรายจ่ายให้อัตโนมัติ',
                      style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),

        // Custom Expense Folder Input
        Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customExpenseController,
                  decoration: const InputDecoration(
                    hintText: 'เพิ่มชื่อโฟลเดอร์รายจ่าย เช่น MyBankSlips',
                    prefixIcon: Icon(Icons.create_new_folder_outlined, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () async {
                  final text = _customExpenseController.text.trim();
                  if (text.isNotEmpty) {
                    _customExpenseController.clear();
                    await notifier.addCustomFolderName(text, isIncome: false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('เพิ่มโฟลเดอร์รายจ่าย "$text" ในรายการค้นหาแล้ว')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
        ),

        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'เลือกโฟลเดอร์สำหรับสแกนรายจ่าย',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              Text(
                'เลือกไว้ $selectedCount โฟลเดอร์',
                style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Albums List
        Expanded(
          child: state.albums.isEmpty
              ? const Center(
                  child: Text('กำลังค้นหาอัลบั้มในอุปกรณ์ หรือไม่พบอัลบั้มภาพ'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  itemCount: state.albums.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final album = state.albums[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: album.isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkBorder : AppColors.border),
                          width: album.isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: CheckboxListTile(
                        value: album.isSelected,
                        activeColor: AppColors.primary,
                        checkColor: Colors.black,
                        onChanged: (_) => notifier.toggleAlbumSelection(album.id, isIncome: false),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                album.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (album.isBankingFolder) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'ธนาคาร',
                                  style: TextStyle(fontSize: 10, color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          '${album.assetCount} รูปภาพ',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildIncomeFoldersTab(
    BuildContext context,
    IngestionState state,
    IngestionNotifier notifier,
    bool isDark,
    int selectedCount,
  ) {
    return Column(
      children: [
        // Income Info Card
        Container(
          padding: const EdgeInsets.all(14),
          color: isDark ? AppColors.darkCard : Colors.white,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.income.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.savings_outlined, color: AppColors.income, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'โฟลเดอร์สลิปรายรับ (เงินโอนเข้า)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'สลิปที่อยู่ในโฟลเดอร์ที่เลือกนี้ จะถูกบันทึกเป็น "รายรับ" ให้อัตโนมัติ',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),

        // Custom Income Folder Input
        Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customIncomeController,
                  decoration: const InputDecoration(
                    hintText: 'เพิ่มชื่อโฟลเดอร์รายรับ เช่น สลิปเงินเข้า, รายรับ',
                    prefixIcon: Icon(Icons.add_to_photos_outlined, color: AppColors.income),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () async {
                  final text = _customIncomeController.text.trim();
                  if (text.isNotEmpty) {
                    _customIncomeController.clear();
                    await notifier.addCustomFolderName(text, isIncome: true);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('เพิ่มโฟลเดอร์รายรับ "$text" ในรายการค้นหาแล้ว')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(backgroundColor: AppColors.income),
              ),
            ],
          ),
        ),

        // Quick preset tags
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: Row(
            children: [
              Text(
                'แนะนำ: ',
                style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
              ),
              ...['สลิปเงินเข้า', 'สลิปขายของ', 'รายรับ', 'Income'].map((preset) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text(preset, style: const TextStyle(fontSize: 10)),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: () async {
                      await notifier.addCustomFolderName(preset, isIncome: true);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('เพิ่มโฟลเดอร์รายรับ "$preset" แล้ว')),
                        );
                      }
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'เลือกอัลบั้มที่จะสแกนเป็นรายรับ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              Text(
                'เลือกไว้ $selectedCount โฟลเดอร์',
                style: const TextStyle(fontSize: 12, color: AppColors.income, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Income Albums List
        Expanded(
          child: state.albums.isEmpty
              ? const Center(
                  child: Text('กำลังค้นหาอัลบั้มในอุปกรณ์...'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  itemCount: state.albums.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final album = state.albums[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: album.isIncomeSelected
                              ? AppColors.income
                              : (isDark ? AppColors.darkBorder : AppColors.border),
                          width: album.isIncomeSelected ? 1.5 : 1,
                        ),
                      ),
                      child: CheckboxListTile(
                        value: album.isIncomeSelected,
                        activeColor: AppColors.income,
                        checkColor: Colors.white,
                        onChanged: (_) => notifier.toggleAlbumSelection(album.id, isIncome: true),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                album.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (album.isIncomeFolder) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.income.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'โฟลเดอร์รายรับ',
                                  style: TextStyle(fontSize: 10, color: AppColors.income, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          '${album.assetCount} รูปภาพ',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
