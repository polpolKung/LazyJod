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
import '../../../transactions/presentation/widgets/transaction_quick_edit_sheet.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final monthName = DateFormatter.thaiMonthsFull[selectedMonth.month - 1];
    final yearThai = DateFormatter.toBuddhistYear(selectedMonth.year);

    // Filter transactions to TODAY only (User Request 5)
    final now = DateTime.now();
    final todayTransactions = transactions.where((tx) =>
      tx.dateTime.year == now.year &&
      tx.dateTime.month == now.month &&
      tx.dateTime.day == now.day
    ).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'ขี้เกียจจด',
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
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => ref.read(selectedMonthProvider.notifier).goToNextMonth(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Overview Cards (Balance, Income, Expense) - Theme Aware (Obsidian in dark, Clean card in light)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF1E202B), Color(0xFF151620)]
                        : const [Colors.white, Color(0xFFF8FAFC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.primary.withOpacity(0.35) : AppColors.border,
                    width: isDark ? 1.2 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? AppColors.primary.withOpacity(0.12) : Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'คงเหลือสุทธิ (Net Balance)',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(isDark ? 0.18 : 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            monthName,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.format(summary.netBalance),
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontSize: 32,
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
                              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'รายรับรวม',
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '+${CurrencyFormatter.format(summary.totalIncome)}',
                                  style: const TextStyle(color: AppColors.income, fontSize: 14, fontWeight: FontWeight.bold),
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
                              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'รายจ่ายรวม',
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '-${CurrencyFormatter.format(summary.totalExpense)}',
                                  style: const TextStyle(color: AppColors.expense, fontSize: 14, fontWeight: FontWeight.bold),
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

              // Quick Actions Bar
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      context: context,
                      title: 'สแกนสลิป',
                      subtitle: '16 ธนาคาร',
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
                      subtitle: 'เครื่องคิดเลข',
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
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.accent.withOpacity(0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: AppColors.accent, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          summary.insights.first,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            height: 1.3,
                          ),
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
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สัดส่วนรายจ่ายตามหมวดหมู่',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
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
                    Text(
                      'งบประมาณรายเดือน',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
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

              // Today's Transactions Header (User Request 5)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'รายการวันนี้',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      if (todayTransactions.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${todayTransactions.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
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

              // Today's Transactions List with Quick Edit Support
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                child: todayTransactions.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.wb_sunny_outlined,
                                size: 36,
                                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'วันนี้ยังไม่มีรายการธุรกรรม',
                                style: TextStyle(
                                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: todayTransactions
                            .map((tx) => TransactionTile(
                                  transaction: tx,
                                  onTap: () => showTransactionQuickEditSheet(context, tx),
                                ))
                            .toList(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
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
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
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
