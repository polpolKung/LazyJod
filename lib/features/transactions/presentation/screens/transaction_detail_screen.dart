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
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(category.icon, color: category.color, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tx.note.isNotEmpty ? tx.note : category.nameThai,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${isExpense ? '-' : '+'}${CurrencyFormatter.format(tx.amount)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: isExpense ? AppColors.expense : AppColors.income,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Detail List Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildDetailRow('ประเภท', tx.type.displayNameThai),
                  const Divider(height: 24),
                  _buildDetailRow('หมวดหมู่', category.nameThai),
                  const Divider(height: 24),
                  _buildDetailRow('วันที่และเวลา', DateFormatter.formatThaiDateTime(tx.dateTime)),
                  const Divider(height: 24),
                  _buildDetailRow('ธนาคาร / ช่องทาง', tx.bankSource.displayNameThai),
                  if (tx.slipRefId != null && tx.slipRefId!.isNotEmpty) ...[
                    const Divider(height: 24),
                    _buildDetailRow('รหัสอ้างอิงสลิป', tx.slipRefId!),
                  ],
                  if (tx.tags.isNotEmpty) ...[
                    const Divider(height: 24),
                    _buildDetailRow('แท็ก', tx.tags.join(' ')),
                  ],
                  if (tx.isFromSlip) ...[
                    const Divider(height: 24),
                    _buildDetailRow('ที่มาข้อมูล', 'สแกนอัตโนมัติจากสลิปธนาคาร'),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('รูปภาพสลิป', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildDetailRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
