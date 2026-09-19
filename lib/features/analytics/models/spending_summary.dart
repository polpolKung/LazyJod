class CategorySpending {
  final String categoryId;
  final String categoryName;
  final double amount;
  final double percentage;
  final int transactionCount;
  final int colorValue;

  const CategorySpending({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.transactionCount,
    required this.colorValue,
  });
}

class SpendingSummary {
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final List<CategorySpending> categoryBreakdown;
  final double expenseChangeFromLastMonth; // Percentage change: +15.5% or -10.2%
  final List<String> insights;

  const SpendingSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    required this.categoryBreakdown,
    required this.expenseChangeFromLastMonth,
    required this.insights,
  });

  static SpendingSummary empty() {
    return const SpendingSummary(
      totalIncome: 0.0,
      totalExpense: 0.0,
      netBalance: 0.0,
      categoryBreakdown: [],
      expenseChangeFromLastMonth: 0.0,
      insights: [],
    );
  }
}
