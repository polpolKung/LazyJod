import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../transactions/models/transaction_type.dart';
import '../../providers/ingestion_provider.dart';
import '../../../../core/widgets/jod_mascot.dart';
import 'album_picker_screen.dart';
import 'statement_import_screen.dart';

class SlipScannerScreen extends ConsumerWidget {
  const SlipScannerScreen({super.key});

  void _showGalleryPickerSheet(BuildContext context, IngestionNotifier notifier) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.photo_library_outlined, color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'เลือกรูปสลิปจากแกลเลอรี',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, color: AppColors.expense, size: 22),
                  ),
                  title: const Text('สลิปรายจ่าย (Expense)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: const Text('สลิปโอนออก / ชำระค่าสินค้า / บิล', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    notifier.pickAndScanGallerySlips(transactionType: TransactionType.expense);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.income.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_downward_rounded, color: AppColors.income, size: 22),
                  ),
                  title: const Text('สลิปรายรับ (Income)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: const Text('สลิปเงินโอนเข้า / เงินเดือน / ขายของ / ได้รับเงิน', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    notifier.pickAndScanGallerySlips(transactionType: TransactionType.income);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
            onPressed: state.isScanning ? null : () => _showGalleryPickerSheet(context, notifier),
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

          // Scan Progress Indicator
          if (state.isScanning)
            LinearProgressIndicator(
              value: state.scanProgress > 0 ? state.scanProgress : null,
              color: AppColors.primary,
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.primaryLight,
            ),

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

          // Parsed Slips List, Scanning Progress View, or Ready State
          Expanded(
            child: Builder(builder: (context) {
              // ── Branch 1: Scanning in progress ─────────────────────────
              if (state.isScanning) {
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Mascot with radar rings
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withOpacity(0.12),
                              ),
                            ),
                            Container(
                              width: 112,
                              height: 112,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? AppColors.darkSurface : AppColors.primaryLight,
                                border: Border.all(color: AppColors.cartoonOutline, width: 2.0),
                              ),
                            ),
                            const JodMascotAvatar(size: 84, withBorder: true),
                            Positioned(
                              bottom: 0,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.cartoonOutline, width: 2.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.cartoonOutline.withOpacity(0.18),
                                      offset: const Offset(0, 2),
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.search_rounded, size: 20, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'น้องจ้อดกำลังตั้งใจตรวจสลิป... 🦥📄',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.statusMessage.isNotEmpty ? state.statusMessage : 'กำลังอ่านข้อมูลสลิป...',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Interactive Progress Card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.cartoonOutline, width: 2.0),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cartoonOutline.withOpacity(0.12),
                                offset: const Offset(0, 4),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'ความคืบหน้า',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${(state.scanProgress * 100).toInt()}%',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: state.scanProgress > 0 ? state.scanProgress : null,
                                  minHeight: 12,
                                  backgroundColor: isDark ? AppColors.darkSurface : AppColors.primarySoftBg,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.transfer.withOpacity(0.12)
                                      : AppColors.transfer.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.transfer.withOpacity(0.3),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.flash_on_rounded, size: 18, color: AppColors.transfer),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '⚡ สลับไปใช้แอพอื่นได้เลยนะ ระบบตรวจจับอยู่เบื้องหลัง เมื่อตรวจเสร็จจะบันทึกให้ทันที!',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // ── Branch 2: No slips yet — Ready state ───────────────────
              if (state.parsedSlips.isEmpty) {
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const JodMascotAvatar(size: 80, withBorder: true),
                        const SizedBox(height: 18),
                        Text(
                          'จ้อดพร้อมตรวจสลิปให้แล้ว! 🦥',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ขี้เกียจจดก็ปล่อยให้จ้อดดูแล... สแกนสลิปจากอัลบั้มที่เลือก ตรวจจับยอด วันที่ และป้องกันสลิปซ้ำให้อัตโนมัติ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Active folders cartoon card (tap to manage)
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AlbumPickerScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.cartoonOutline, width: 2.0),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cartoonOutline.withOpacity(0.10),
                                  offset: const Offset(0, 3),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.folder_special_rounded, size: 18, color: AppColors.cartoonOutline),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'โฟลเดอร์ที่จะสแกน',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.cartoonOutline, width: 1.2),
                                      ),
                                      child: const Text(
                                        'แตะเพื่อจัดการ ✏️',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.cartoonOutline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.folder_outlined, size: 16, color: AppColors.expense),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        selectedExpenseAlbums.isNotEmpty
                                            ? 'รายจ่าย: ${selectedExpenseAlbums.length} โฟลเดอร์ (${selectedExpenseAlbums.take(2).map((a) => a.name).join(", ")}${selectedExpenseAlbums.length > 2 ? "..." : ""})'
                                            : 'รายจ่าย: ยังไม่ได้เลือกโฟลเดอร์',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.savings_outlined, size: 16, color: AppColors.income),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        selectedIncomeAlbums.isNotEmpty
                                            ? 'รายรับ: ${selectedIncomeAlbums.length} โฟลเดอร์ (${selectedIncomeAlbums.take(2).map((a) => a.name).join(", ")}${selectedIncomeAlbums.length > 2 ? "..." : ""})'
                                            : 'รายรับ: ยังไม่ได้เลือกโฟลเดอร์ (แตะเพื่อเพิ่ม)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: selectedIncomeAlbums.isNotEmpty
                                              ? AppColors.textPrimary
                                              : AppColors.income,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Button 1: Scan Targeted Albums
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => notifier.scanTargetedAlbums(),
                            icon: const Icon(Icons.sync_rounded, color: Colors.white),
                            label: const Text('เริ่มสแกนโฟลเดอร์สลิป'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.cartoonOutline, width: 2.0),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Secondary: Pick from Gallery
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showGalleryPickerSheet(context, notifier),
                            icon: const Icon(Icons.photo_library_outlined, color: AppColors.cartoonOutline),
                            label: const Text('เลือกรูปสลิปจากแกลเลอรีโดยตรง'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.cartoonOutline,
                              side: const BorderSide(color: AppColors.cartoonOutline, width: 2.0),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // ── Branch 3: Has slips — Show results list ─────────────────
              return Column(
                children: [
                  // Quick batch switcher bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                    child: Row(
                      children: [
                        Text(
                          'ปรับประเภททั้งหมด:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        ActionChip(
                          avatar: const Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.income),
                          label: const Text('เป็นรายรับทั้งหมด', style: TextStyle(fontSize: 11, color: AppColors.income)),
                          backgroundColor: AppColors.income.withOpacity(0.12),
                          side: BorderSide(color: AppColors.income.withOpacity(0.3)),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onPressed: () => notifier.setAllSlipsTransactionType(TransactionType.income),
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(Icons.arrow_upward_rounded, size: 14, color: AppColors.expense),
                          label: const Text('เป็นรายจ่ายทั้งหมด', style: TextStyle(fontSize: 11, color: AppColors.expense)),
                          backgroundColor: AppColors.expense.withOpacity(0.12),
                          side: BorderSide(color: AppColors.expense.withOpacity(0.3)),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onPressed: () => notifier.setAllSlipsTransactionType(TransactionType.expense),
                        ),
                      ],
                    ),
                  ),
                  // Parsed slips list
                  Expanded(
                    child: ListView.separated(
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
                              onChanged: slip.isDuplicate ? null : (_) => notifier.toggleSlipSelection(slip.id!),
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
                                  PopupMenuButton<TransactionType>(
                                    tooltip: 'แตะเพื่อเปลี่ยนประเภทรายการ',
                                    padding: EdgeInsets.zero,
                                    onSelected: (newType) => notifier.setSlipTransactionType(slip.id!, newType),
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(
                                        value: TransactionType.income,
                                        child: Row(children: [
                                          Icon(Icons.arrow_downward_rounded, color: AppColors.income, size: 18),
                                          SizedBox(width: 8),
                                          Text('รายรับ (Income)'),
                                        ]),
                                      ),
                                      const PopupMenuItem(
                                        value: TransactionType.expense,
                                        child: Row(children: [
                                          Icon(Icons.arrow_upward_rounded, color: AppColors.expense, size: 18),
                                          SizedBox(width: 8),
                                          Text('รายจ่าย (Expense)'),
                                        ]),
                                      ),
                                      const PopupMenuItem(
                                        value: TransactionType.transfer,
                                        child: Row(children: [
                                          Icon(Icons.swap_horiz_rounded, color: AppColors.transfer, size: 18),
                                          SizedBox(width: 8),
                                          Text('ย้ายเงิน (Transfer)'),
                                        ]),
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
                                            style: TextStyle(fontSize: 10, color: typeColor, fontWeight: FontWeight.bold),
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
                ],
              );
            }),
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
                          SnackBar(
                            content: Text('นำเข้าสลิปสำเร็จ $count รายการ! ✨'),
                            backgroundColor: AppColors.income,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                        // Prevent black screen: Only pop if there is a parent route to pop back to
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
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
