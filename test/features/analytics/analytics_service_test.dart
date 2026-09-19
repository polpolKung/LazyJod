import 'package:flutter_test/flutter_test.dart';
import 'package:lazy_jod/features/analytics/models/budget_model.dart';
import 'package:lazy_jod/features/analytics/services/analytics_service.dart';
import 'package:lazy_jod/features/categories/models/category_model.dart';
import 'package:lazy_jod/features/transactions/models/transaction_model.dart';
import 'package:lazy_jod/features/transactions/models/transaction_type.dart';

void main() {
  group('AnalyticsService Tests', () {
    final categories = CategoryModel.defaultCategories;

    final transactions = [
      TransactionModel(
        id: '1',
        type: TransactionType.income,
        amount: 30000.0,
        dateTime: DateTime(2026, 9, 1),
        categoryId: 'cat_salary',
      ),
      TransactionModel(
        id: '2',
        type: TransactionType.expense,
        amount: 6000.0,
        dateTime: DateTime(2026, 9, 5),
        categoryId: 'cat_food',
      ),
      TransactionModel(
        id: '3',
        type: TransactionType.expense,
        amount: 4000.0,
        dateTime: DateTime(2026, 9, 10),
        categoryId: 'cat_shopping',
      ),
      // Previous month transaction
      TransactionModel(
        id: '4',
        type: TransactionType.expense,
        amount: 8000.0,
        dateTime: DateTime(2026, 8, 15),
        categoryId: 'cat_food',
      ),
    ];

    test('1. Should correctly compute monthly income, expense and net balance', () {
      final summary = AnalyticsService.computeMonthlySummary(
        transactions: transactions,
        categories: categories,
        year: 2026,
        month: 9,
      );

      expect(summary.totalIncome, equals(30000.0));
      expect(summary.totalExpense, equals(10000.0));
      expect(summary.netBalance, equals(20000.0));
      expect(summary.categoryBreakdown.length, equals(2));

      // Food should be top expense (60% of 10000)
      final foodSpending = summary.categoryBreakdown.firstWhere((c) => c.categoryId == 'cat_food');
      expect(foodSpending.amount, equals(6000.0));
      expect(foodSpending.percentage, equals(60.0));
    });

    test('2. Should compute comparison with previous month', () {
      final summary = AnalyticsService.computeMonthlySummary(
        transactions: transactions,
        categories: categories,
        year: 2026,
        month: 9,
      );

      // August expense = 8000, Sept expense = 10000 -> ((10000 - 8000) / 8000) * 100 = +25%
      expect(summary.expenseChangeFromLastMonth, equals(25.0));
    });

    test('3. Should evaluate budget limits and trigger warnings', () {
      final budgets = [
        const BudgetModel(
          id: 'b1',
          title: 'งบกินอาหาร',
          categoryId: 'cat_food',
          monthlyLimit: 7000.0,
          alertThresholdPercent: 80.0,
        ),
        const BudgetModel(
          id: 'b2',
          title: 'งบช้อปปิ้ง',
          categoryId: 'cat_shopping',
          monthlyLimit: 3000.0, // Spent is 4000 -> Exceeded!
          alertThresholdPercent: 80.0,
        ),
      ];

      final statuses = AnalyticsService.evaluateBudgets(
        budgets: budgets,
        transactions: transactions,
        year: 2026,
        month: 9,
      );

      final foodStatus = statuses.firstWhere((s) => s.budget.id == 'b1');
      expect(foodStatus.currentSpent, equals(6000.0));
      // 6000 / 7000 = 85.7% -> near limit (>= 80%)
      expect(foodStatus.isNearLimit, isTrue);
      expect(foodStatus.isExceeded, isFalse);

      final shoppingStatus = statuses.firstWhere((s) => s.budget.id == 'b2');
      expect(shoppingStatus.currentSpent, equals(4000.0));
      expect(shoppingStatus.isExceeded, isTrue);
    });
  });
}
