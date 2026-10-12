import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/local_storage_service.dart';
import '../../../categories/presentation/screens/category_management_screen.dart';
import '../../../categories/providers/category_provider.dart';
import '../../../ingestion/presentation/screens/album_picker_screen.dart';
import '../../../transactions/providers/transaction_provider.dart';
import '../../../transactions/services/csv_export_service.dart';
import '../../../analytics/presentation/screens/budget_setting_screen.dart';
import '../../../ingestion/providers/ingestion_provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/jod_mascot.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _showScanDateDialog(BuildContext context) async {
    final storage = LocalStorageService();
    final currentFromDate = await storage.getScanFromDate();
    if (!context.mounted) return;

    final now = DateTime.now();
    final options = [
      (now.subtract(const Duration(days: 7)), '⚡ 7 วันที่ผ่านมา (~1 สัปดาห์)', 'สแกนเฉพาะสลิปสัปดาห์ล่าสุด เร็วมาก'),
      (now.subtract(const Duration(days: 30)), '🚀 30 วันที่ผ่านมา (~1 เดือน)', 'สแกนสลิป 1 เดือนล่าสุด'),
      (now.subtract(const Duration(days: 90)), '📦 90 วันที่ผ่านมา (~3 เดือน)', 'แนะนำสำหรับการตรวจสลิปทั่วไป'),
      (now.subtract(const Duration(days: 180)), '🗄️ 180 วันที่ผ่านมา (~6 เดือน)', 'สแกนสลิปย้อนหลังครึ่งปี'),
      (DateTime(now.year, 1, 1), '🗓️ ตั้งแต่ต้นปีนี้ (${now.year + 543})', 'สแกนสลิปทั้งหมดของปีนี้'),
    ];

    await showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('สแกนสลิปย้อนหลังถึงวันที่', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...options.map((opt) {
                  final isSelected = opt.$1.difference(currentFromDate).inDays.abs() <= 1;
                  return ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: isSelected ? AppColors.primary.withOpacity(isDark ? 0.15 : 0.08) : null,
                    title: Text(
                      opt.$2,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary : null,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(opt.$3, style: const TextStyle(fontSize: 11)),
                    trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                    onTap: () async {
                      await storage.setScanFromDate(opt.$1);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('ตั้งค่าให้สแกนย้อนหลังถึง ${DateFormat('d MMM yyyy', 'th').format(opt.$1)} เรียบร้อยแล้ว')),
                        );
                      }
                    },
                  );
                }),
                const Divider(height: 16),
                ListTile(
                  leading: const Icon(Icons.edit_calendar_rounded, color: AppColors.primary),
                  title: const Text('เลือกวันที่ระบุเอง...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('เลือกวันที่เริ่มต้นจากปฏิทินตามที่ต้องการ', style: TextStyle(fontSize: 11)),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: currentFromDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      helpText: 'เลือกวันที่เริ่มต้นที่ต้องการสแกนย้อนหลัง',
                    );
                    if (picked != null) {
                      await storage.setScanFromDate(picked);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('ตั้งค่าให้สแกนย้อนหลังถึง ${DateFormat('d MMM yyyy', 'th').format(picked)} เรียบร้อยแล้ว')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
      final file = File('${tempDir.path}/lazy_jod_transactions_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csvData);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'ประวัติรายการเงินจากแอป Lazy Jod (เลซี่จด)',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการส่งออก CSV: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่าและการจัดการ'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme toggle
          Text(
            'ธีมและหน้าตา',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          _ThemeToggleCard(),
          const SizedBox(height: 20),

          Text(
            'การจัดการข้อมูล',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                  title: const Text('สแกนสลิปย้อนหลังถึงวันที่', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('กำหนดวันที่เริ่มต้นที่ต้องการให้แอปตรวจหาสลิป', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showScanDateDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined, color: AppColors.primary),
                  title: const Text('ส่งออกข้อมูลเป็น CSV (Excel ภาษาไทย)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('รองรับ UTF-8 BOM เปิดใน Excel ภาษาไทยไม่เพี้ยน', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _exportCsv(context, ref),
                ),
                const Divider(height: 1),
                Builder(
                  builder: (ctx) {
                    final ingestion = ref.watch(ingestionProvider);
                    final expenseCount = ingestion.albums.where((a) => a.isSelected).length;
                    final incomeCount = ingestion.albums.where((a) => a.isIncomeSelected).length;
                    return ListTile(
                      leading: const Icon(Icons.folder_special_outlined, color: AppColors.primary),
                      title: const Text('ตั้งค่าโฟลเดอร์สลิป (รายจ่าย & รายรับ)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        'รายจ่าย: $expenseCount โฟลเดอร์ • รายรับ: $incomeCount โฟลเดอร์',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AlbumPickerScreen()));
                      },
                    );
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

          Text(
            'เกี่ยวกับแอปพลิเคชัน',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const JodMascotAvatar(size: 38),
                  title: const Text('Lazy Jod (เลซี่จด)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('เวอร์ชัน 1.2.0 • มาสคอตประจำแอป "จ้อด" (Jod) 🦥'),
                ),
                const Divider(height: 1),
                const ListTile(
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

class _ThemeToggleCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
      ),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder, width: 1.2),
          ),
          child: const Center(
            child: Text('🌿', style: TextStyle(fontSize: 22)),
          ),
        ),
        title: const Text(
          'ธีมหลัก: มัทฉะพาสเทล & น้องจ้อด',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: const Text(
          'โทนสีเขียวมัทฉะนม สบายตา น่ารักสไตล์สติ๊กเกอร์เรโทร',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1),
          ),
          child: const Text(
            'ใช้งานอยู่ ✨',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
        ),
      ),
    );
  }
}
