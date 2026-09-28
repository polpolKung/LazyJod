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
                    const Text('รายจ่าย'),
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
                    const Text('รายรับ'),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: state.isIncomeScanEnabled
                            ? AppColors.income.withOpacity(0.2)
                            : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        state.isIncomeScanEnabled ? '$selectedIncomeCount' : 'ทางเลือก',
                        style: TextStyle(
                          fontSize: 10,
                          color: state.isIncomeScanEnabled ? AppColors.income : (isDark ? Colors.grey.shade400 : AppColors.textMuted),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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

            // ── TAB 2: Income Folders (Optional) ─────────────────────────
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
                      'ความเป็นส่วนตัว 100% (โฟลเดอร์รายจ่าย)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'แอปจะสแกนเฉพาะโฟลเดอร์ธนาคารที่คุณเลือก และบันทึกเป็นรายจ่ายอัตโนมัติ',
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
        // Master Enable Card for Income Slip Scanning
        Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: state.isIncomeScanEnabled
                ? (isDark ? const Color(0xFF132B1F) : AppColors.income.withOpacity(0.08))
                : (isDark ? AppColors.darkCard : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: state.isIncomeScanEnabled
                  ? AppColors.income.withOpacity(0.4)
                  : (isDark ? AppColors.darkBorder : AppColors.border),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                        Row(
                          children: [
                            Text(
                              'สแกนสลิปรายรับ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.income.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Optional',
                                style: TextStyle(fontSize: 10, color: AppColors.income, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state.isIncomeScanEnabled
                              ? 'เปิดใช้งานอยู่ — สลิปในโฟลเดอร์ที่ระบุด้านล่างจะบันทึกเป็นรายรับ'
                              : 'ปิดใช้งาน (ปกติรายรับจะไม่มีสลิป แต่หากมีอัลบั้มเก็บไว้ สามารถเปิดใช้ได้)',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: state.isIncomeScanEnabled,
                    activeColor: AppColors.income,
                    onChanged: (val) => notifier.toggleIncomeScan(val),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (!state.isIncomeScanEnabled)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_shared_outlined,
                      size: 64,
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ฟีเจอร์สแกนรายรับ (ทางเลือก / Optional)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ปกติคนเราไม่ได้บันทึกสลิปรายรับอยู่แล้ว แต่หากคุณสร้างอัลบั้มเก็บสลิปเงินเข้าไว้ เช่น "สลิปเงินเข้า" หรือ "รายรับ"\n\nให้เปิดสวิตช์ด้านบนเพื่อระบุอัลบั้มที่ต้องการ แล้วระบบจะสแกนและบันทึกเป็นรายรับให้อัตโนมัติ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () => notifier.toggleIncomeScan(true),
                      icon: const Icon(Icons.power_settings_new_rounded, color: AppColors.income),
                      label: const Text('เปิดใช้งานสแกนสลิปรายรับ', style: TextStyle(color: AppColors.income)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.income),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else ...[
          // Custom Income Folder Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Text(
                  'แนะนำ: ',
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                ),
                ...['สลิปเงินเข้า', 'สลิปขายของ', 'รายรับ', 'เงินเข้า'].map((preset) {
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
      ],
    );
  }
}
