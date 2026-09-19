import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../categories/models/category_model.dart';
import '../../../categories/providers/category_provider.dart';
import '../../../ingestion/models/thai_bank.dart';
import '../../models/transaction_model.dart';
import '../../models/transaction_type.dart';
import '../../providers/transaction_provider.dart';
import '../widgets/in_app_calculator_pad.dart';

class TransactionEntryScreen extends ConsumerStatefulWidget {
  final TransactionModel? initialTransaction;

  const TransactionEntryScreen({super.key, this.initialTransaction});

  @override
  ConsumerState<TransactionEntryScreen> createState() => _TransactionEntryScreenState();
}

class _TransactionEntryScreenState extends ConsumerState<TransactionEntryScreen> {
  late TransactionType _type;
  late double _amount;
  late DateTime _dateTime;
  late String _selectedCategoryId;
  late TextEditingController _noteController;
  late TextEditingController _tagController;
  List<String> _tags = [];
  ThaiBank _selectedBank = ThaiBank.unknown;
  bool _showCalculator = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initialTransaction;
    if (init != null) {
      _type = init.type;
      _amount = init.amount;
      _dateTime = init.dateTime;
      _selectedCategoryId = init.categoryId;
      _noteController = TextEditingController(text: init.note);
      _tags = List.from(init.tags);
      _selectedBank = init.bankSource;
    } else {
      _type = TransactionType.expense;
      _amount = 0.0;
      _dateTime = DateTime.now();
      _selectedCategoryId = 'cat_food';
      _noteController = TextEditingController();
    }
    _tagController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final text = _tagController.text.trim();
    if (text.isNotEmpty) {
      final tag = text.startsWith('#') ? text : '#$text';
      if (!_tags.contains(tag)) {
        setState(() {
          _tags.add(tag);
          _tagController.clear();
        });
      }
    }
  }

  void _save() {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาระบุจำนวนเงินที่มากกว่า 0 บาท')),
      );
      return;
    }

    final newTx = TransactionModel(
      id: widget.initialTransaction?.id ?? 'tx_${const Uuid().v4()}',
      type: _type,
      amount: _amount,
      dateTime: _dateTime,
      categoryId: _selectedCategoryId,
      note: _noteController.text.trim(),
      tags: _tags,
      bankSource: _selectedBank,
      isFromSlip: widget.initialTransaction?.isFromSlip ?? false,
      slipImagePath: widget.initialTransaction?.slipImagePath,
      slipRefId: widget.initialTransaction?.slipRefId,
    );

    if (widget.initialTransaction != null) {
      ref.read(transactionProvider.notifier).updateTransaction(newTx);
    } else {
      ref.read(transactionProvider.notifier).addTransaction(newTx);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider);
    final filteredCategories = categories.where((c) =>
      _type == TransactionType.income ? c.type == CategoryType.income : c.type == CategoryType.expense
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialTransaction != null ? 'แก้ไขรายการ' : 'บันทึกรายการใหม่'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.primary, size: 28),
            onPressed: _save,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Selector (Segmented)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildTypeTab(TransactionType.expense, 'รายจ่าย', AppColors.expense),
                      _buildTypeTab(TransactionType.income, 'รายรับ', AppColors.income),
                      _buildTypeTab(TransactionType.transfer, 'โอนเงิน', AppColors.transfer),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Amount Field with Calculator Trigger
                InkWell(
                  onTap: () => setState(() => _showCalculator = true),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'จำนวนเงิน',
                          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                        ),
                        Row(
                          children: [
                            Text(
                              CurrencyFormatter.format(_amount),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: _type == TransactionType.expense ? AppColors.expense : AppColors.income,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.calculate_outlined, color: AppColors.primary),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Category Selection Grid
                const Text(
                  'หมวดหมู่',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: filteredCategories.map((cat) {
                    final isSelected = cat.id == _selectedCategoryId;
                    return ChoiceChip(
                      label: Text(cat.nameThai),
                      avatar: Icon(cat.icon, size: 18, color: isSelected ? Colors.white : cat.color),
                      selected: isSelected,
                      selectedColor: cat.color,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategoryId = cat.id);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Date & Time Picker
                InkWell(
                  onTap: _pickDateTime,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Text(
                              DateFormatter.formatThaiDateTime(_dateTime),
                              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Note / Description
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'บันทึกข้อความ / ชื่อร้านค้า',
                    hintText: 'เช่น ข้าวมันไก่พิเศษ, เซเว่น',
                    prefixIcon: Icon(Icons.edit_note_outlined, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),

                // Tags Input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagController,
                        decoration: const InputDecoration(
                          hintText: 'เพิ่มแท็ก เช่น #ทริปเชียงใหม่',
                          prefixIcon: Icon(Icons.tag, color: AppColors.primary),
                        ),
                        onSubmitted: (_) => _addTag(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _addTag,
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                    ),
                  ],
                ),
                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: _tags.map((t) => Chip(
                      label: Text(t, style: const TextStyle(color: AppColors.secondary, fontSize: 13)),
                      backgroundColor: AppColors.secondary.withOpacity(0.1),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => setState(() => _tags.remove(t)),
                    )).toList(),
                  ),
                ],
                const SizedBox(height: 16),

                // Bank Source (Optional)
                DropdownButtonFormField<ThaiBank>(
                  value: _selectedBank,
                  decoration: const InputDecoration(
                    labelText: 'ช่องทางชำระ / ธนาคาร',
                    prefixIcon: Icon(Icons.account_balance, color: AppColors.primary),
                  ),
                  items: ThaiBank.values.map((bank) {
                    return DropdownMenuItem(
                      value: bank,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(color: bank.brandColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(bank.displayNameThai),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBank = val);
                  },
                ),
              ],
            ),
          ),

          // Sliding In-App Calculator
          if (_showCalculator)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: InAppCalculatorPad(
                initialAmount: _amount,
                onAmountChanged: (val) => setState(() => _amount = val),
                onDone: () => setState(() => _showCalculator = false),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeTab(TransactionType t, String label, Color activeColor) {
    final isSelected = _type == t;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _type = t;
            final cat = ref.read(categoryProvider).firstWhere(
              (c) => t == TransactionType.income ? c.type == CategoryType.income : c.type == CategoryType.expense,
            );
            _selectedCategoryId = cat.id;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? activeColor : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dateTime),
      );
      if (pickedTime != null) {
        setState(() {
          _dateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }
}
