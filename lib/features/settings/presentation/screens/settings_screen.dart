import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../categories/presentation/screens/category_management_screen.dart';
import '../../../categories/providers/category_provider.dart';
import '../../../ingestion/presentation/screens/album_picker_screen.dart';
import '../../../transactions/providers/transaction_provider.dart';
import '../../../transactions/services/csv_export_service.dart';
import '../../../analytics/presentation/screens/budget_setting_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    try {
      final transactions = ref.read(transactionProvider);
      final categories = ref.read(categoryProvider);

      if (transactions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่มีข้อมูลรายการสำหรับส่งออก')),
        );
        return;
      }

      final csvData = CsvExportService.exportTransactionsToCsv(
        transactions: transactions,
        categories: categories,
      );

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/meow_jot_transactions_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csvData);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'ประวัติรายการเงินจากแอป Meow Jot (เหมียวจด)',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการส่งออก CSV: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่าและการจัดการ'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Privacy Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.08),
                  AppColors.accent.withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user, color: AppColors.primary, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'ความเป็นส่วนตัวระดับสูงสุด (Privacy-First)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'สแกนเฉพาะอัลบั้มที่เลือก ประมวลผล OCR ในเครื่อง และบันทึกข้อมูลแบบ Offline 100%',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('การจัดการข้อมูล', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download_outlined, color: AppColors.primary),
                  title: const Text('ส่งออกข้อมูลเป็น CSV (Excel ภาษาไทย)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('รองรับ UTF-8 BOM เปิดใน Excel ภาษาไทยไม่เพี้ยน', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _exportCsv(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.folder_outlined, color: AppColors.secondary),
                  title: const Text('เลือกโฟลเดอร์รูปภาพสลิป', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('กำหนดโฟลเดอร์ธนาคารเป้าหมายเพื่อความเป็นส่วนตัว', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AlbumPickerScreen()));
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.category_outlined, color: Color(0xFFFAAD14)),
                  title: const Text('จัดการหมวดหมู่รายรับ-รายจ่าย', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('เพิ่ม/แก้ไขหมวดหมู่และคีย์เวิร์ดตรวจจับอัตโนมัติ', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategoryManagementScreen()));
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.income),
                  title: const Text('วางแผนงบประมาณและการแจ้งเตือน', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('ตั้งขีดจำกัดงบประมาณรายเดือนและเกณฑ์เตือน', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BudgetSettingScreen()));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text('เกี่ยวกับแอปพลิเคชัน', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.pets, color: AppColors.primary),
                  title: Text('Meow Jot (เหมียวจด)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text('เวอร์ชัน 1.0.0 (Production-Ready)'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.info_outline, color: AppColors.textMuted),
                  title: Text('สถาปัตยกรรมระบบ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text('Flutter • Riverpod • ML Kit On-Device • Local Database'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
