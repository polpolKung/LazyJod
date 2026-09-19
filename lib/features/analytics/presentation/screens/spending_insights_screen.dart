import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../providers/analytics_provider.dart';

class SpendingInsightsScreen extends ConsumerWidget {
  const SpendingInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(monthlySummaryProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    final monthName = DateFormatter.thaiMonthsFull[selectedMonth.month - 1];
    final isIncrease = summary.expenseChangeFromLastMonth > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('วิเคราะห์พฤติกรรมการใช้จ่าย'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Comparison Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Text(
                    'เปรียบเทียบกับเดือนที่แล้ว ($monthName)',
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isIncrease ? Icons.trending_up : Icons.trending_down,
                        color: isIncrease ? AppColors.expense : AppColors.income,
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${isIncrease ? '+' : ''}${summary.expenseChangeFromLastMonth.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: isIncrease ? AppColors.expense : AppColors.income,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isIncrease
                        ? 'คุณใช้จ่ายสูงขึ้นเมื่อเทียบกับเดือนก่อนหน้า'
                        : 'คุณสามารถควบคุมและประหยัดค่าใช้จ่ายได้ดีขึ้น!',
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // AI/Intelligent Advice Insights
            const Text(
              'คำแนะนำและการวิเคราะห์',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            if (summary.insights.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text('เมื่อคุณบันทึกรายการเพิ่มขึ้น ระบบจะวิเคราะห์พฤติกรรมให้ที่นี่', style: TextStyle(color: AppColors.textMuted)),
                ),
              )
            else
              ...summary.insights.map((insight) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.tips_and_updates_outlined, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          insight,
                          style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 16),

            // Category Breakdown Detail
            const Text(
              'รายละเอียดการใช้จ่ายตามหมวดหมู่',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: summary.categoryBreakdown.map((cat) {
                  return ListTile(
                    leading: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Color(cat.colorValue),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(cat.categoryName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text('${cat.transactionCount} รายการ', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(cat.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${cat.percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
