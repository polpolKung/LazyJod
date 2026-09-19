import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../categories/providers/category_provider.dart';
import '../../models/budget_model.dart';
import '../../providers/analytics_provider.dart';
import '../../services/analytics_service.dart';

class BudgetSettingScreen extends ConsumerStatefulWidget {
  const BudgetSettingScreen({super.key});

  @override
  ConsumerState<BudgetSettingScreen> createState() => _BudgetSettingScreenState();
}

class _BudgetSettingScreenState extends ConsumerState<BudgetSettingScreen> {
  void _showAddOrEditBudgetDialog([BudgetModel? budget]) {
    final titleController = TextEditingController(text: budget?.title ?? '');
    final limitController = TextEditingController(
      text: budget != null ? budget.monthlyLimit.toStringAsFixed(0) : '',
    );
    String? selectedCategory = budget?.categoryId;
    double threshold = budget?.alertThresholdPercent ?? 80.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final categories = ref.watch(categoryProvider);

          return AlertDialog(
            title: Text(budget != null ? 'แก้ไขงบประมาณ' : 'ตั้งงบประมาณใหม่'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'ชื่องบประมาณ',
                      hintText: 'เช่น งบกินเที่ยว, งบช้อปปิ้ง',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: limitController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'จำนวนเงินงบประมาณ (บาท)',
                      hintText: 'เช่น 5000',
                      prefixText: '฿ ',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'หมวดหมู่ที่จำกัด (ไม่ระบุคืองบรวม)'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('งบประมาณรวมทุกหมวด')),
                      ...categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nameThai))),
                    ],
                    onChanged: (val) => setDialogState(() => selectedCategory = val),
                  ),
                  const SizedBox(height: 16),
                  Text('แจ้งเตือนเมื่อใช้เกิน: ${threshold.toInt()}%'),
                  Slider(
                    value: threshold,
                    min: 50,
                    max: 100,
                    divisions: 10,
                    label: '${threshold.toInt()}%',
                    activeColor: AppColors.primary,
                    onChanged: (val) => setDialogState(() => threshold = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('ยกเลิก')),
              ElevatedButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  final limit = double.tryParse(limitController.text.trim()) ?? 0.0;
                  if (title.isEmpty || limit <= 0) return;

                  final newBudget = BudgetModel(
                    id: budget?.id ?? 'bgt_${const Uuid().v4()}',
                    title: title,
                    monthlyLimit: limit,
                    categoryId: selectedCategory,
                    alertThresholdPercent: threshold,
                  );

                  if (budget != null) {
                    ref.read(budgetProvider.notifier).updateBudget(newBudget);
                  } else {
                    ref.read(budgetProvider.notifier).addBudget(newBudget);
                  }

                  Navigator.of(ctx).pop();
                },
                child: const Text('บันทึก'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgets = ref.watch(budgetProvider);
    final statuses = ref.watch(budgetStatusesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการงบประมาณ'),
      ),
      body: budgets.isEmpty
          ? const Center(child: Text('ยังไม่มีการตั้งงบประมาณ'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: budgets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final b = budgets[index];
                final status = statuses.firstWhere(
                  (s) => s.budget.id == b.id,
                  orElse: () => BudgetStatus(
                    budget: b,
                    currentSpent: 0,
                    remaining: b.monthlyLimit,
                    percentUsed: 0,
                    isExceeded: false,
                    isNearLimit: false,
                  ),
                );

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              b.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _showAddOrEditBudgetDialog(b),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.expense),
                            onPressed: () => ref.read(budgetProvider.notifier).deleteBudget(b.id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ใช้ไป: ${CurrencyFormatter.format(status.currentSpent)}',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          Text(
                            'งบ: ${CurrencyFormatter.format(b.monthlyLimit)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (status.percentUsed / 100).clamp(0.0, 1.0),
                          backgroundColor: const Color(0xFFF3F4F6),
                          color: status.isExceeded ? AppColors.expense : (status.isNearLimit ? AppColors.warning : AppColors.income),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'แจ้งเตือนเมื่อเกิน ${b.alertThresholdPercent.toInt()}%',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddOrEditBudgetDialog(),
      ),
    );
  }
}
