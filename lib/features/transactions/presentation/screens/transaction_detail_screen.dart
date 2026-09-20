import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../categories/providers/category_provider.dart';
import '../../models/transaction_type.dart';
import '../../providers/transaction_provider.dart';
import 'transaction_entry_screen.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionProvider);
    final txList = transactions.where((t) => t.id == transactionId).toList();

    if (txList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('รายละเอียด')),
        body: const Center(child: Text('ไม่พบรายการนี้')),
      );
    }

    final tx = txList.first;
    final categories = ref.watch(categoryProvider);
    final category = categories.firstWhere(
      (c) => c.id == tx.categoryId,
      orElse: () => categories.first,
    );

    final isExpense = tx.type == TransactionType.expense;
    final isTransfer = tx.type == TransactionType.transfer;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final amountPrefix = isTransfer ? '⇄ ' : (isExpense ? '-' : '+');
    final amountColor = isTransfer
        ? const Color(0xFF38BDF8)
        : (isExpense ? AppColors.expense : AppColors.income);

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดรายการ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TransactionEntryScreen(initialTransaction: tx)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.expense),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('ยืนยันการลบ'),
                  content: const Text('คุณต้องการลบรายการนี้ใช่หรือไม่?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('ยกเลิก')),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('ลบ', style: TextStyle(color: AppColors.expense)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                ref.read(transactionProvider.notifier).deleteTransaction(tx.id);
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Amount Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isTransfer
                          ? const Color(0xFF38BDF8).withOpacity(0.15)
                          : category.color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isTransfer ? Icons.swap_horiz_rounded : category.icon,
                      color: isTransfer ? const Color(0xFF38BDF8) : category.color,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tx.note.isNotEmpty ? tx.note : (isTransfer ? 'ย้ายเงินระหว่างบัญชี' : category.nameThai),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$amountPrefix${CurrencyFormatter.format(tx.amount)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: amountColor,
                    ),
                  ),
                  if (isTransfer) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '⇄ ไม่นำไปคิดรวมในรายรับ-รายจ่าย',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF38BDF8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Toggle: Switch between Expense and Transfer
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color: isTransfer ? AppColors.expense : const Color(0xFF38BDF8),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: Icon(
                  isTransfer ? Icons.arrow_upward_rounded : Icons.swap_horiz_rounded,
                  color: isTransfer ? AppColors.expense : const Color(0xFF38BDF8),
                  size: 20,
                ),
                label: Text(
                  isTransfer
                      ? 'เปลี่ยนกลับเป็น "รายจ่าย"'
                      : '⇄ เปลี่ยนเป็น "ย้ายเงิน" (ไม่คิดรายรับ-จ่าย)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isTransfer ? AppColors.expense : const Color(0xFF38BDF8),
                  ),
                ),
                onPressed: () {
                  final newType = isTransfer ? TransactionType.expense : TransactionType.transfer;
                  ref.read(transactionProvider.notifier).updateTransaction(
                    tx.copyWith(
                      type: newType,
                      categoryId: isTransfer ? 'cat_uncategorized' : 'cat_transfer',
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isTransfer
                          ? 'เปลี่ยนเป็นรายจ่ายแล้ว'
                          : 'ตั้งค่าเป็น "ย้ายเงิน" แล้ว (ไม่คิดรวมในรายรับ-จ่าย)'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Detail List Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              child: Column(
                children: [
                  _buildDetailRow('ประเภท', tx.type.displayNameThai, isDark),
                  Divider(height: 24, color: isDark ? AppColors.darkBorder : AppColors.border),
                  _buildDetailRow('หมวดหมู่', isTransfer ? 'ย้ายเงินระหว่างบัญชี' : category.nameThai, isDark),
                  Divider(height: 24, color: isDark ? AppColors.darkBorder : AppColors.border),
                  _buildDetailRow('วันที่และเวลา', DateFormatter.formatThaiDateTime(tx.dateTime), isDark),
                  Divider(height: 24, color: isDark ? AppColors.darkBorder : AppColors.border),
                  _buildDetailRow('ธนาคาร / ช่องทาง', tx.bankSource.displayNameThai, isDark),
                  if (tx.slipRefId != null && tx.slipRefId!.isNotEmpty) ...[
                    Divider(height: 24, color: isDark ? AppColors.darkBorder : AppColors.border),
                    _buildDetailRow('รหัสอ้างอิงสลิป', tx.slipRefId!, isDark),
                  ],
                  if (tx.tags.isNotEmpty) ...[
                    Divider(height: 24, color: isDark ? AppColors.darkBorder : AppColors.border),
                    _buildDetailRow('แท็ก', tx.tags.join(' '), isDark),
                  ],
                  if (tx.isFromSlip) ...[
                    Divider(height: 24, color: isDark ? AppColors.darkBorder : AppColors.border),
                    _buildDetailRow('ที่มาข้อมูล', 'สแกนอัตโนมัติจากสลิปธนาคาร', isDark),
                  ],
                ],
              ),
            ),

            // Slip Image Preview (if present)
            if (tx.slipImagePath != null && File(tx.slipImagePath!).existsSync()) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'รูปภาพสลิป',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(tx.slipImagePath!),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
