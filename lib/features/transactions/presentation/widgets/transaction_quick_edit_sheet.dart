import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../categories/models/category_model.dart';
import '../../../categories/presentation/widgets/category_quick_picker_sheet.dart';
import '../../../categories/providers/category_provider.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../screens/transaction_detail_screen.dart';

Future<void> showTransactionQuickEditSheet(BuildContext context, TransactionModel transaction) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _QuickEditContent(transaction: transaction),
  );
}

class _QuickEditContent extends ConsumerStatefulWidget {
  final TransactionModel transaction;

  const _QuickEditContent({required this.transaction});

  @override
  ConsumerState<_QuickEditContent> createState() => _QuickEditContentState();
}

class _QuickEditContentState extends ConsumerState<_QuickEditContent> {
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late String _selectedCategoryId;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transaction.amount.toStringAsFixed(
        widget.transaction.amount.truncateToDouble() == widget.transaction.amount ? 0 : 2,
      ),
    );
    _noteController = TextEditingController(text: widget.transaction.note);
    _selectedCategoryId = widget.transaction.categoryId;
    _selectedDate = widget.transaction.dateTime;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _save() {
    final amount = double.tryParse(_amountController.text.trim()) ?? widget.transaction.amount;
    final updated = widget.transaction.copyWith(
      amount: amount,
      note: _noteController.text.trim(),
      categoryId: _selectedCategoryId,
      dateTime: _selectedDate,
    );

    ref.read(transactionProvider.notifier).updateTransaction(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = ref.watch(categoryProvider);
    final currentCat = categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => categories.first,
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'แก้ไขด่วน',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('รายละเอียดเต็ม', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TransactionDetailScreen(transactionId: widget.transaction.id),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Amount Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            child: Row(
              children: [
                const Text(
                  '฿',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0.00',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Note / Description Field
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: 'บันทึกช่วยจำ / ชื่อผู้รับ',
              prefixIcon: const Icon(Icons.notes),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: isDark ? AppColors.darkCard : AppColors.background,
            ),
          ),
          const SizedBox(height: 12),

          // Category & Date Row
          Row(
            children: [
              // Category Button
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final newCatId = await showCategoryQuickPicker(
                      context,
                      ref,
                      currentCategoryId: _selectedCategoryId,
                    );
                    if (newCatId != null) {
                      setState(() => _selectedCategoryId = newCatId);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(currentCat.icon, size: 20, color: currentCat.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            currentCat.nameThai,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: currentCat.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Date Button
              Expanded(
                child: InkWell(
                  onTap: _pickDateTime,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            DateFormatter.formatThaiDateTime(_selectedDate),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              // Delete Button
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.expense.withOpacity(0.12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.delete_outline, color: AppColors.expense),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('ยืนยันการลบ'),
                      content: const Text('คุณต้องการลบรายการนี้ใช่หรือไม่?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('ยกเลิก')),
                        TextButton(
                          onPressed: () => Navigator.of(c).pop(true),
                          child: const Text('ลบ', style: TextStyle(color: AppColors.expense)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    ref.read(transactionProvider.notifier).deleteTransaction(widget.transaction.id);
                    if (mounted) Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(width: 12),
              // Save Button
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _save,
                  child: const Text(
                    'บันทึก',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
