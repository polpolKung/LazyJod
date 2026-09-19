import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../ingestion/presentation/screens/slip_scanner_screen.dart';
import '../../../ingestion/presentation/screens/statement_import_screen.dart';
import '../../../transactions/presentation/screens/transaction_entry_screen.dart';
import '../../../transactions/presentation/screens/transaction_list_screen.dart';
import '../../../transactions/presentation/widgets/transaction_tile.dart';
import '../../../transactions/providers/transaction_provider.dart';
import '../../providers/analytics_provider.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/category_pie_chart.dart';
import 'budget_setting_screen.dart';
import 'spending_insights_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final summary = ref.watch(monthlySummaryProvider);
    final budgetStatuses = ref.watch(budgetStatusesProvider);
    final transactions = ref.watch(transactionProvider);

    final monthName = DateFormatter.thaiMonthsFull[selectedMonth.month - 1];
    final yearThai = DateFormatter.toBuddhistYear(selectedMonth.year);

    final recentTransactions = transactions.take(5).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.pets, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Meow Jot',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            tooltip: 'วิเคราะห์พฤติกรรมการใช้จ่าย',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SpendingInsightsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(transactionProvider.notifier).loadTransactions();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month Selector Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => ref.read(selectedMonthProvider.notifier).goToPrevMonth(),
                    ),
                    Text(
                      '$monthName $yearThai',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => ref.read(selectedMonthProvider.notifier).goToNextMonth(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Overview Cards (Balance, Income, Expense)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF7A45), Color(0xFFFF9C6E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'คงเหลือสุทธิ (Net Balance)',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      CurrencyFormatter.format(summary.netBalance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('รายรับรวม', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  '+${CurrencyFormatter.format(summary.totalIncome)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('รายจ่ายรวม', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  '-${CurrencyFormatter.format(summary.totalExpense)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Quick Ingestion & Entry Bar
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      context: context,
                      title: 'สแกนสลิป',
                      subtitle: 'อัตโนมัติ 16 แบงก์',
                      icon: Icons.qr_code_scanner,
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SlipScannerScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickActionButton(
                      context: context,
                      title: 'จดด้วยมือ',
                      subtitle: 'พร้อมเครื่องคิดเลข',
                      icon: Icons.edit_calendar,
                      color: AppColors.secondary,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TransactionEntryScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickActionButton(
                      context: context,
                      title: 'E-Statement',
                      subtitle: 'PDF บัตรเครดิต',
                      icon: Icons.picture_as_pdf,
                      color: const Color(0xFF722ED1),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const StatementImportScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Spending Insights Teaser
              if (summary.insights.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: Color(0xFFD46B08), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          summary.insights.first,
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Category Breakdown Chart Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'สัดส่วนรายจ่ายตามหมวดหมู่',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    CategoryPieChart(
                      breakdown: summary.categoryBreakdown,
                      totalExpense: summary.totalExpense,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Monthly Budget Card Preview
              if (budgetStatuses.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'งบประมาณรายเดือน',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BudgetSettingScreen()),
                        );
                      },
                      child: const Text('จัดการงบ', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                BudgetProgressCard(
                  status: budgetStatuses.first,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BudgetSettingScreen()),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Recent Transactions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'รายการล่าสุด',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TransactionListScreen()),
                      );
                    },
                    child: const Text('ดูทั้งหมด', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Recent Transactions List
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: recentTransactions.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: Text('ยังไม่มีรายการในระบบ กดปุ่ม + เพื่อเริ่มจด', style: TextStyle(color: AppColors.textMuted)),
                        ),
                      )
                    : Column(
                        children: recentTransactions.map((tx) => TransactionTile(transaction: tx)).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
