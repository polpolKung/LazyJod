import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../providers/ingestion_provider.dart';
import 'album_picker_screen.dart';
import 'statement_import_screen.dart';

class SlipScannerScreen extends ConsumerWidget {
  const SlipScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ingestionProvider);
    final notifier = ref.read(ingestionProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('สแกนสลิปอัตโนมัติ'),
        actions: [
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
          // Privacy Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.primaryLight.withOpacity(0.4),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'สแกนเฉพาะโฟลเดอร์สลิปธนาคาร (Privacy-First) และประมวลผล OCR บนเครื่อง ไม่ส่งภาพออกภายนอก',
                    style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AlbumPickerScreen()),
                    );
                  },
                  child: const Text('เลือกโฟลเดอร์', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Scan Progress Indicator
          if (state.isScanning) ...[
            LinearProgressIndicator(value: state.scanProgress, color: AppColors.primary),
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.statusMessage,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Parsed Slips List
          Expanded(
            child: state.parsedSlips.isEmpty && !state.isScanning
                ? EmptyStateWidget(
                    title: 'พร้อมสแกนสลิปโอนเงิน',
                    message: 'ระบบจะตรวจจับสลิปจาก 16 ธนาคารไทยในอัลบั้มที่เลือก ตรวจสอบยอดเงิน วันที่ และป้องกันสลิปซ้ำให้อัตโนมัติ',
                    icon: Icons.qr_code_scanner_outlined,
                    buttonText: 'เริ่มสแกนสลิป',
                    onButtonPressed: () => notifier.scanTargetedAlbums(),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.parsedSlips.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final slip = state.parsedSlips[index];
                      final isSelected = state.selectedSlipIds.contains(slip.id);

                      return Opacity(
                        opacity: slip.isDuplicate ? 0.6 : 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: CheckboxListTile(
                            value: isSelected,
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
                                Text(
                                  slip.bank.displayNameThai,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                if (slip.isDuplicate) ...[
                                  const SizedBox(width: 8),
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
                                  'ผู้รับ: ${slip.recipientName}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormatter.formatThaiDateTime(slip.dateTime),
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                                if (slip.refId != null) ...[
                                  Text(
                                    'รหัส: ${slip.refId}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ],
                            ),
                            secondary: Text(
                              CurrencyFormatter.format(slip.amount),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.expense,
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => notifier.scanTargetedAlbums(),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('นำเข้าสลิปสำเร็จ $count รายการ!')),
                              );
                              Navigator.of(context).pop();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('นำเข้า (${state.selectedSlipIds.length} รายการ)'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
