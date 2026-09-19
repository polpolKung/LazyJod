import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../transactions/models/transaction_model.dart';
import '../../../transactions/models/transaction_type.dart';
import '../../../transactions/providers/transaction_provider.dart';
import '../../models/statement_record.dart';
import '../../services/statement_pdf_parser.dart';

class StatementImportScreen extends ConsumerStatefulWidget {
  const StatementImportScreen({super.key});

  @override
  ConsumerState<StatementImportScreen> createState() => _StatementImportScreenState();
}

class _StatementImportScreenState extends ConsumerState<StatementImportScreen> {
  bool _isLoading = false;
  List<StatementRecord> _records = [];
  final Set<String> _selectedIds = {};

  Future<void> _pickAndParsePdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isLoading = true);
        final filePath = result.files.single.path!;
        final parsed = await StatementPdfParser.parsePdfFile(filePath);

        setState(() {
          _records = parsed;
          _selectedIds.clear();
          // By default, select all valid records
          _selectedIds.addAll(parsed.map((r) => r.id));
          _isLoading = false;
        });

        if (parsed.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบรายการที่เข้าเงื่อนไขในไฟล์ PDF นี้')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการอ่านไฟล์ PDF: $e')),
      );
    }
  }

  void _importSelected() {
    final toImport = _records.where((r) => _selectedIds.contains(r.id)).toList();
    final List<TransactionModel> txList = [];
    final uuid = const Uuid();

    for (final rec in toImport) {
      final isIncome = rec.isCashback;
      txList.add(TransactionModel(
        id: 'stmt_${uuid.v4()}',
        type: isIncome ? TransactionType.income : TransactionType.expense,
        amount: rec.amount,
        dateTime: rec.transactionDate,
        categoryId: rec.suggestedCategoryId ?? 'cat_shopping',
        note: rec.description,
        tags: [
          'บัตรเครดิต',
          if (rec.isInstallment) 'ผ่อนชำระ',
          if (rec.isCashback) 'Cashback',
        ],
        isFromStatement: true,
        installmentMonth: rec.currentInstallmentMonth,
        totalInstallmentMonths: rec.totalInstallmentMonths,
      ));
    }

    if (txList.isNotEmpty) {
      ref.read(transactionProvider.notifier).addBatchTransactions(txList);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('นำเข้ารายการบัตรเครดิตสำเร็จ ${txList.length} รายการ!')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('นำเข้า E-Statement PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: _pickAndParsePdf,
            tooltip: 'เลือกไฟล์ PDF',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('กำลังแยกรายการจากไฟล์ E-Statement...'),
                ],
              ),
            )
          : _records.isEmpty
              ? EmptyStateWidget(
                  title: 'ยังไม่มีไฟล์ Statement',
                  message: 'นำเข้าไฟล์ PDF ใบแจ้งยอดบัตรเครดิต เพื่อแยกรายการค่าใช้จ่าย ยอดผ่อนชำระ 0% และเครดิตเงินคืนอัตโนมัติ',
                  icon: Icons.picture_as_pdf_outlined,
                  buttonText: 'เลือกไฟล์ PDF',
                  onButtonPressed: _pickAndParsePdf,
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: AppColors.primaryLight.withOpacity(0.3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'พบ ${ _records.length} รายการ',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                if (_selectedIds.length == _records.length) {
                                  _selectedIds.clear();
                                } else {
                                  _selectedIds.addAll(_records.map((r) => r.id));
                                }
                              });
                            },
                            child: Text(
                              _selectedIds.length == _records.length ? 'ยกเลิกทั้งหมด' : 'เลือกทั้งหมด',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _records.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final rec = _records[index];
                          final isSelected = _selectedIds.contains(rec.id);

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                              ),
                            ),
                            child: CheckboxListTile(
                              value: isSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedIds.add(rec.id);
                                  } else {
                                    _selectedIds.remove(rec.id);
                                  }
                                });
                              },
                              title: Text(
                                rec.description,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormatter.formatThaiDate(rec.transactionDate),
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                  if (rec.isInstallment) ...[
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'ยอดผ่อนชำระ (${rec.currentInstallmentMonth}/${rec.totalInstallmentMonths})',
                                        style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                  if (rec.isCashback) ...[
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.income.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'เครดิตเงินคืน (Cashback)',
                                        style: TextStyle(fontSize: 11, color: AppColors.income, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              secondary: Text(
                                '${rec.isCashback ? '+' : '-'}${CurrencyFormatter.format(rec.amount)}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: rec.isCashback ? AppColors.income : AppColors.expense,
                                ),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: AppColors.border)),
                      ),
                      child: ElevatedButton(
                        onPressed: _selectedIds.isEmpty ? null : _importSelected,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'นำเข้า (${_selectedIds.length} รายการ)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
