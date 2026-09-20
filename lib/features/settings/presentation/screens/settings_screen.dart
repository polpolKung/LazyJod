import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/local_storage_service.dart';
import '../../../categories/presentation/screens/category_management_screen.dart';
import '../../../categories/providers/category_provider.dart';
import '../../../ingestion/presentation/screens/album_picker_screen.dart';
import '../../../transactions/providers/transaction_provider.dart';
import '../../../transactions/services/csv_export_service.dart';
import '../../../analytics/presentation/screens/budget_setting_screen.dart';
import '../../../../core/theme/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _showScanLimitDialog(BuildContext context) async {
    final storage = LocalStorageService();
    final current = await storage.getScanHistoryLimit();
    if (!context.mounted) return;

    final options = [
      (30, '⚡ 30 สลิป', 'เร็วมาก (~5 วินาที)'),
      (50, '🚀 50 สลิป (แนะนำ)', 'รวดเร็วและครอบคลุม (~10 วินาที)'),
      (100, '📦 100 สลิป', 'สำหรับคนโอนบ่อย (~20 วินาที)'),
      (300, '🗄️ 300 สลิป', 'ตรวจย้อนหลังเยอะ (~1 นาที)'),
      (500, '📚 500 สลิป', 'ตรวจย้อนหลังละเอียด (~1.5 นาที)'),
      (1000, '♾️ 1,000 สลิป (ทั้งหมด)', 'ตรวจทั้งหมด แต่อาจใช้เวลา 2-3 นาที'),
    ];

    await showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          title: const Text('จำนวนสลิปที่สแกนต่อครั้ง', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((opt) {
              final isSelected = opt.$1 == current;
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  await storage.setScanHistoryLimit(opt.$1);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('ตั้งค่าการสแกนเป็น ${opt.$2} เรียบร้อยแล้ว')),
                    );
                  }
                },
              );
            }).toList(),
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
      final file = File('${tempDir.path}/meow_jot_transactions_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csvData);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'ประวัติรายการเงินจากแอป ขี้เกียจจด (LazyJod)',
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
          // Privacy Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.12),
                  AppColors.secondary.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ความเป็นส่วนตัวระดับสูงสุด (Privacy-First)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'สแกนเฉพาะอัลบั้มที่เลือก ประมวลผล OCR ในเครื่อง และบันทึกข้อมูลแบบ Offline 100%',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

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
                  leading: const Icon(Icons.speed_rounded, color: AppColors.primary),
                  title: const Text('จำนวนสลิปที่สแกนต่อครั้ง', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('ปรับลดจำนวนสลิปเพื่อให้แอปสแกนและเปิดได้เร็วขึ้น', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showScanLimitDialog(context),
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
              children: const [
                ListTile(
                  leading: Icon(Icons.bolt_rounded, color: AppColors.primary, size: 28),
                  title: Text('ขี้เกียจจด (LazyJod)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text('เวอร์ชัน 1.1.0 (Zero-Click Auto-Accounting)'),
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

class _ThemeToggleCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: AppColors.primary,
            ),
            title: Text(
              isDark ? 'โหมดมืด (Obsidian)' : 'โหมดสว่าง',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              isDark ? 'พื้นหลังดำ สีเน้น Mint #00E599' : 'พื้นหลังขาว แนะนำสำหรับกลางวัน',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Switch(
              value: isDark,
              activeColor: AppColors.primary,
              onChanged: (val) {
                ref.read(themeProvider.notifier).setTheme(val ? ThemeMode.dark : ThemeMode.light);
              },
            ),
          ),
        ],
      ),
    );
  }
}
