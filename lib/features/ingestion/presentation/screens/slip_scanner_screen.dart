import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../transactions/models/transaction_type.dart';
import '../../providers/ingestion_provider.dart';
import 'album_picker_screen.dart';
import 'statement_import_screen.dart';

class SlipScannerScreen extends ConsumerWidget {
  const SlipScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ingestionProvider);
    final notifier = ref.read(ingestionProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedExpenseAlbums = state.albums.where((a) => a.isSelected).toList();
    final selectedIncomeAlbums = state.albums.where((a) => a.isIncomeSelected).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('สแกนสลิปอัตโนมัติ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'เลือกรูปจากแกลเลอรี',
            onPressed: state.isScanning ? null : () => notifier.pickAndScanGallerySlips(),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'นำเข้า E-Statement PDF',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StatementImportScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.folder_special_outlined),
            tooltip: 'ตั้งค่าโฟลเดอร์สลิป',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AlbumPickerScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Privacy & Mode Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.primaryLight.withOpacity(0.4),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.primary.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.isIncomeScanEnabled
                        ? 'สแกนโฟลเดอร์รายจ่ายและรายรับ (Privacy-First) ประมวลผลบนเครื่อง 100%'
                        : 'สแกนเฉพาะโฟลเดอร์สลิปธนาคาร (Privacy-First) ประมวลผล OCR บนเครื่อง',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AlbumPickerScreen()),
                    );
                  },
                  child: const Text('จัดการโฟลเดอร์', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
              ],
            ),
          ),

          // Scan Progress Indicator
          if (state.isScanning) ...[
            LinearProgressIndicator(
              value: state.scanProgress > 0 ? state.scanProgress : null,
              color: AppColors.primary,
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.primaryLight,
            ),
            Container(
              padding: const EdgeInsets.all(14),
              color: Theme.of(context).cardColor,
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.statusMessage,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: isDark
                  ? AppColors.transfer.withOpacity(0.10)
                  : AppColors.transfer.withOpacity(0.06),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppColors.transfer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚡ สลับไปแอพอื่นได้เลย ระบบสแกนอยู่เบื้องหลัง — แต่อย่าปัดแอพทิ้งนะ',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.transfer : AppColors.transfer.withOpacity(0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Status Alert Banner (when not scanning and has a status message)
          if (!state.isScanning && state.statusMessage.isNotEmpty && state.parsedSlips.isEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: state.lastError != null
                    ? (isDark ? const Color(0xFF3B1515) : Colors.red.shade50)
                    : (isDark ? AppColors.darkCard : Colors.blue.shade50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: state.lastError != null
                      ? AppColors.expense.withOpacity(0.5)
                      : AppColors.primary.withOpacity(0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    state.lastError != null ? Icons.warning_amber_rounded : Icons.info_outline,
                    color: state.lastError != null ? AppColors.expense : AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.statusMessage,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Parsed Slips List or Custom Ready State
          Expanded(
            child: state.parsedSlips.isEmpty && !state.isScanning
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner_outlined,
                              color: AppColors.primary,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'พร้อมสแกนสลิปอัตโนมัติ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ระบบจะตรวจจับสลิปจากอัลบั้มที่เลือก ตรวจสอบยอด วันที่ และป้องกันสลิปซ้ำให้อัตโนมัติ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Active folders chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.folder_outlined, size: 16, color: AppColors.expense),
                                    const SizedBox(width: 6),
                                    Text(
                                      selectedExpenseAlbums.isNotEmpty
                                          ? 'รายจ่าย: ${selectedExpenseAlbums.length} โฟลเดอร์ (${selectedExpenseAlbums.take(2).map((a) => a.name).join(", ")}${selectedExpenseAlbums.length > 2 ? "..." : ""})'
                                          : 'รายจ่าย: ยังไม่ได้เลือกโฟลเดอร์',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (state.isIncomeScanEnabled) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.savings_outlined, size: 16, color: AppColors.income),
                                      const SizedBox(width: 6),
                                      Text(
                                        selectedIncomeAlbums.isNotEmpty
                                            ? 'รายรับ: ${selectedIncomeAlbums.length} โฟลเดอร์ (${selectedIncomeAlbums.take(2).map((a) => a.name).join(", ")}${selectedIncomeAlbums.length > 2 ? "..." : ""})'
                                            : 'รายรับ: ยังไม่ได้เลือกอัลบั้มรายรับ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const AlbumPickerScreen(initialTabIndex: 1),
                                        ),
                                      );
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.add_circle_outline, size: 14, color: AppColors.income),
                                        SizedBox(width: 4),
                                        Text(
                                          '+ มีอัลบั้มสลิปรายรับ? กดเปิดสแกนรายรับได้',
                                          style: TextStyle(fontSize: 11, color: AppColors.income, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Button 1: Scan Targeted Albums
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => notifier.scanTargetedAlbums(),
                              icon: const Icon(Icons.sync),
                              label: Text(
                                state.isIncomeScanEnabled
                                    ? 'เริ่มสแกนโฟลเดอร์ (รายจ่าย + รายรับ)'
                                    : 'เริ่มสแกนโฟลเดอร์ธนาคาร',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Button 2: Pick from Gallery directly
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => notifier.pickAndScanGallerySlips(),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('เลือกรูปสลิปจากแกลเลอรีโดยตรง'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.parsedSlips.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final slip = state.parsedSlips[index];
                      final isSelected = state.selectedSlipIds.contains(slip.id);
                      final isSelfTransfer = IngestionNotifier.isSelfTransfer(slip.senderName, slip.recipientName);
                      final isIncome = slip.transactionType == TransactionType.income;
                      final isTransfer = slip.transactionType == TransactionType.transfer ||
                          (!isIncome && isSelfTransfer);

                      // Colors & Labels depending on transaction type
                      final Color typeColor = isIncome
                          ? AppColors.income
                          : (isTransfer ? AppColors.transfer : AppColors.expense);

                      final String typePrefix = isIncome ? '+' : (isTransfer ? '⇄ ' : '-');

                      return Opacity(
                        opacity: slip.isDuplicate ? 0.6 : 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? typeColor : (isDark ? AppColors.darkBorder : AppColors.border),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: CheckboxListTile(
                            value: isSelected,
                            activeColor: typeColor,
                            checkColor: isIncome ? Colors.white : Colors.black,
                            onChanged: slip.isDuplicate
                                ? null
                                : (_) => notifier.toggleSlipSelection(slip.id!),
                            title: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: slip.bank.brandColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    slip.bank.displayNameThai,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                // Transaction Type Switcher Badge (User can tap to toggle type)
                                PopupMenuButton<TransactionType>(
                                  tooltip: 'เปลี่ยนประเภทรายการ',
                                  padding: EdgeInsets.zero,
                                  onSelected: (newType) {
                                    notifier.setSlipTransactionType(slip.id!, newType);
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: TransactionType.income,
                                      child: Row(
                                        children: [
                                          Icon(Icons.arrow_downward_rounded, color: AppColors.income, size: 18),
                                          SizedBox(width: 8),
                                          Text('รายรับ (Income)'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: TransactionType.expense,
                                      child: Row(
                                        children: [
                                          Icon(Icons.arrow_upward_rounded, color: AppColors.expense, size: 18),
                                          SizedBox(width: 8),
                                          Text('รายจ่าย (Expense)'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: TransactionType.transfer,
                                      child: Row(
                                        children: [
                                          Icon(Icons.swap_horiz_rounded, color: AppColors.transfer, size: 18),
                                          SizedBox(width: 8),
                                          Text('ย้ายเงิน (Transfer)'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: typeColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: typeColor.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          isIncome ? 'รายรับ' : (isTransfer ? 'ย้ายเงิน' : 'รายจ่าย'),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: typeColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Icon(Icons.arrow_drop_down, size: 14, color: typeColor),
                                      ],
                                    ),
                                  ),
                                ),
                                if (slip.isDuplicate) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'สลิปซ้ำ',
                                      style: TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  isIncome
                                      ? 'ผู้โอน: ${slip.senderName ?? 'ไม่ระบุชื่อผู้โอน'}'
                                      : 'ผู้รับ: ${slip.recipientName}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormatter.formatThaiDateTime(slip.dateTime),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                  ),
                                ),
                                if (slip.refId != null) ...[
                                  Text(
                                    'รหัส: ${slip.refId}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            secondary: Text(
                              '$typePrefix${CurrencyFormatter.format(slip.amount)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: typeColor,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action Bar
          if (state.parsedSlips.isNotEmpty)
            _buildBottomActionBar(context, state, notifier, isDark),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(
    BuildContext context,
    IngestionState state,
    IngestionNotifier notifier,
    bool isDark,
  ) {
    final selectedSlips = state.parsedSlips
        .where((s) => state.selectedSlipIds.contains(s.id))
        .toList();
    final incomeCount = selectedSlips.where((s) => s.transactionType == TransactionType.income).length;
    final expenseCount = selectedSlips.where((s) => s.transactionType == TransactionType.expense).length;

    String importLabel = 'นำเข้า (${selectedSlips.length} รายการ';
    if (incomeCount > 0 && expenseCount > 0) {
      importLabel += ': รับ $incomeCount • จ่าย $expenseCount)';
    } else if (incomeCount > 0) {
      importLabel += ': รายรับ)';
    } else {
      importLabel += ')';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => notifier.scanTargetedAlbums(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              child: const Text('สแกนอีกครั้ง'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: state.selectedSlipIds.isEmpty
                  ? null
                  : () async {
                      final count = await notifier.importSelectedSlips();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('นำเข้าสลิปสำเร็จ $count รายการ!')),
                        );
                        Navigator.of(context).pop();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(importLabel),
            ),
          ),
        ],
      ),
    );
  }
}
