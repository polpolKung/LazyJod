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
import '../../../../core/widgets/jod_mascot.dart';
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
            const JodMascotAvatar(size: 34),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Lazy Jod',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                Text(
                  'เลซี่จด • สล้อตช่วยจด',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                ),
              ],
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
              // Month Selector Bar — Cute Capsule
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.cartoonOutline, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cartoonOutline.withOpacity(0.12),
                      offset: const Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                      color: AppColors.cartoonOutline,
                      onPressed: () => ref.read(selectedMonthProvider.notifier).goToPrevMonth(),
                    ),
                    Row(
                      children: [
                        const Text('📅 ', style: TextStyle(fontSize: 16)),
                        Text(
                          '$monthName $yearThai',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      color: AppColors.cartoonOutline,
                      onPressed: () => ref.read(selectedMonthProvider.notifier).goToNextMonth(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Cheeky Mascot Status Card
              JodMascotCard(
                message: budgetStatuses.any((b) => b.isExceeded)
                    ? 'ล้นงบแล้วนะเหวยยย! เดือนนี้พักช้อปก่อนมั้ย? 🛑💸'
                    : (budgetStatuses.any((b) => b.isNearLimit)
                        ? 'เห้ยๆ เบาได้เบา! ใช้ไปเยอะแล้วนะ กระเป๋าจะแฟบแล้ว 😜'
                        : (summary.totalExpense == 0
                            ? 'ยังไม่เสียเงินสักบาทในเดือนนี้! นอนต่อสบายใจ 🦥💤'
                            : 'ขี้เกียจจดใช่มั้ยล่า... ส่งสลิปมา เดี๋ยวจ้อดตรวจให้เอง! 🦥')),
              ),
              const SizedBox(height: 10),

              // Overview Cards (Balance, Income, Expense)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.cartoonOutline, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cartoonOutline.withOpacity(0.12),
                      offset: const Offset(0, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'คงเหลือสุทธิ (Net Balance)',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // Cartoon pill badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.cartoonOutline, width: 1.4),
                          ),
                          child: Text(
                            monthName,
                            style: const TextStyle(
                              color: AppColors.cartoonOutline,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      CurrencyFormatter.format(summary.netBalance),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Divider line
                    Container(height: 1, color: AppColors.divider),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8, height: 8,
                                    decoration: BoxDecoration(
                                      color: AppColors.income,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'รายรับรวม',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '+${CurrencyFormatter.format(summary.totalIncome)}',
                                style: const TextStyle(
                                  color: AppColors.income,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 36, color: AppColors.divider),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8, height: 8,
                                      decoration: BoxDecoration(
                                        color: AppColors.expense,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'รายจ่ายรวม',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '-${CurrencyFormatter.format(summary.totalExpense)}',
                                  style: const TextStyle(
                                    color: AppColors.expense,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
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
                      icon: Icons.picture_as_pdf_rounded,
                      color: const Color(0xFFAFA2DC),
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
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.cartoonOutline, width: 2.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cartoonOutline.withOpacity(0.12),
                        offset: const Offset(0, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: AppColors.accent, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          summary.insights.first,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textPrimary,
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
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.cartoonOutline, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cartoonOutline.withOpacity(0.12),
                      offset: const Offset(0, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'สัดส่วนรายจ่ายตามหมวดหมู่',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
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
                    const Text(
                      'งบประมาณรายเดือน',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
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
                      const Text(
                        'รายการวันนี้',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (todayTransactions.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.cartoonOutline, width: 1.4),
                          ),
                          child: Text(
                            '${todayTransactions.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.cartoonOutline, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cartoonOutline.withOpacity(0.12),
                      offset: const Offset(0, 4),
                      blurRadius: 0,
                    ),
                  ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.cartoonOutline, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: AppColors.cartoonOutline.withOpacity(0.12),
              offset: const Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            // Cute squircle cartoon icon pod
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color.alphaBlend(color.withOpacity(0.7), AppColors.primaryMint),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cartoonOutline, width: 1.8),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
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
