import '../../categories/models/category_model.dart';
import '../../transactions/models/transaction_model.dart';
import '../../transactions/models/transaction_type.dart';
import '../models/budget_model.dart';
import '../models/spending_summary.dart';
import '../../../core/utils/currency_formatter.dart';

class BudgetStatus {
  final BudgetModel budget;
  final double currentSpent;
  final double remaining;
  final double percentUsed;
  final bool isExceeded;
  final bool isNearLimit;

  const BudgetStatus({
    required this.budget,
    required this.currentSpent,
    required this.remaining,
    required this.percentUsed,
    required this.isExceeded,
    required this.isNearLimit,
  });
}

class AnalyticsService {
  /// Computes comprehensive spending summary for a given month and year
  static SpendingSummary computeMonthlySummary({
    required List<TransactionModel> transactions,
    required List<CategoryModel> categories,
    required int year,
    required int month,
  }) {
    // Current month transactions
    final currentMonthTxs = transactions.where((tx) =>
        tx.dateTime.year == year && tx.dateTime.month == month).toList();

    // Previous month transactions
    final prevMonthDate = DateTime(year, month - 1);
    final prevMonthTxs = transactions.where((tx) =>
        tx.dateTime.year == prevMonthDate.year && tx.dateTime.month == prevMonthDate.month).toList();

    double totalIncome = 0.0;
    double totalExpense = 0.0;
    final Map<String, double> categoryAmounts = {};
    final Map<String, int> categoryCounts = {};

    for (final tx in currentMonthTxs) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        totalExpense += tx.amount;
        categoryAmounts[tx.categoryId] = (categoryAmounts[tx.categoryId] ?? 0.0) + tx.amount;
        categoryCounts[tx.categoryId] = (categoryCounts[tx.categoryId] ?? 0) + 1;
      }
    }

    double prevTotalExpense = 0.0;
    for (final tx in prevMonthTxs) {
      if (tx.type == TransactionType.expense) {
        prevTotalExpense += tx.amount;
      }
    }

    // Percentage change vs last month
    double expenseChangePercent = 0.0;
    if (prevTotalExpense > 0) {
      expenseChangePercent = ((totalExpense - prevTotalExpense) / prevTotalExpense) * 100;
    }

    // Build category breakdown
    final List<CategorySpending> breakdown = [];
    final categoryMap = {for (var c in categories) c.id: c};

    categoryAmounts.forEach((catId, amount) {
      final category = categoryMap[catId];
      final name = category?.nameThai ?? 'หมวดหมู่อื่นๆ';
      final color = category?.colorValue ?? 0xFF8C8C8C;
      final percent = totalExpense > 0 ? (amount / totalExpense) * 100 : 0.0;

      breakdown.add(CategorySpending(
        categoryId: catId,
        categoryName: name,
        amount: amount,
        percentage: percent,
        transactionCount: categoryCounts[catId] ?? 0,
        colorValue: color,
      ));
    });

    // Sort breakdown by highest spending first
    breakdown.sort((a, b) => b.amount.compareTo(a.amount));

    // Generate intelligent insights
    final insights = _generateInsights(
      totalExpense: totalExpense,
      totalIncome: totalIncome,
      breakdown: breakdown,
      changePercent: expenseChangePercent,
      hasPrevData: prevMonthTxs.isNotEmpty,
    );

    return SpendingSummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netBalance: totalIncome - totalExpense,
      categoryBreakdown: breakdown,
      expenseChangeFromLastMonth: expenseChangePercent,
      insights: insights,
    );
  }

  /// Evaluates budget statuses for the current month
  static List<BudgetStatus> evaluateBudgets({
    required List<BudgetModel> budgets,
    required List<TransactionModel> transactions,
    required int year,
    required int month,
  }) {
    final currentMonthTxs = transactions.where((tx) =>
        tx.dateTime.year == year &&
        tx.dateTime.month == month &&
        tx.type == TransactionType.expense).toList();

    return budgets.map((budget) {
      double spent = 0.0;

      if (budget.isOverallBudget) {
        spent = currentMonthTxs.fold(0.0, (sum, tx) => sum + tx.amount);
      } else if (budget.isCategoryBudget) {
        spent = currentMonthTxs
            .where((tx) => tx.categoryId == budget.categoryId)
            .fold(0.0, (sum, tx) => sum + tx.amount);
      } else if (budget.isTagBudget) {
        spent = currentMonthTxs
            .where((tx) => tx.tags.contains(budget.tag))
            .fold(0.0, (sum, tx) => sum + tx.amount);
      }

      final percentUsed = budget.monthlyLimit > 0 ? (spent / budget.monthlyLimit) * 100 : 0.0;
      final remaining = budget.monthlyLimit - spent;
      final isExceeded = spent > budget.monthlyLimit;
      final isNearLimit = percentUsed >= budget.alertThresholdPercent && !isExceeded;

      return BudgetStatus(
        budget: budget,
        currentSpent: spent,
        remaining: remaining,
        percentUsed: percentUsed,
        isExceeded: isExceeded,
        isNearLimit: isNearLimit,
      );
    }).toList();
  }

  static List<String> _generateInsights({
    required double totalExpense,
    required double totalIncome,
    required List<CategorySpending> breakdown,
    required double changePercent,
    required bool hasPrevData,
  }) {
    final List<String> insights = [];

    if (breakdown.isNotEmpty) {
      final top = breakdown.first;
      insights.add(
        'หมวดหมู่ที่คุณใช้จ่ายมากที่สุดคือ "${top.categoryName}" เป็นเงิน ${CurrencyFormatter.format(top.amount)} (${top.percentage.toStringAsFixed(1)}% ของรายจ่ายทั้งหมด)',
      );
    }

    if (hasPrevData) {
      if (changePercent > 10) {
        insights.add(
          'เดือนนี้คุณมีค่าใช้จ่ายเพิ่มขึ้น ${changePercent.toStringAsFixed(1)}% เมื่อเทียบกับเดือนที่แล้ว ควรระวังการใช้จ่ายช่วงปลายเดือน',
        );
      } else if (changePercent < -10) {
        insights.add(
          'ยอดเยี่ยม! เดือนนี้ค่าใช้จ่ายของคุณลดลง ${changePercent.abs().toStringAsFixed(1)}% เมื่อเทียบกับเดือนที่แล้ว',
        );
      }
    }

    if (totalIncome > 0 && totalExpense > totalIncome) {
      insights.add(
        'คำเตือน: รายจ่ายในเดือนนี้สูงกว่ารายรับ ${CurrencyFormatter.format(totalExpense - totalIncome)}',
      );
    } else if (totalIncome > 0 && (totalExpense / totalIncome) <= 0.5) {
      insights.add(
        'ยินดีด้วย! คุณออมเงินได้มากกว่า 50% ของรายรับในเดือนนี้',
      );
    }

    return insights;
  }
}
