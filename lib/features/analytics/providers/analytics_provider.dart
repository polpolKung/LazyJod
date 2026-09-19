import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/local_storage_service.dart';
import '../../categories/providers/category_provider.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../models/budget_model.dart';
import '../models/spending_summary.dart';
import '../services/analytics_service.dart';

// Current Selected Month & Year for Dashboard
class SelectedMonthState {
  final int year;
  final int month;

  const SelectedMonthState(this.year, this.month);

  SelectedMonthState nextMonth() {
    if (month == 12) return SelectedMonthState(year + 1, 1);
    return SelectedMonthState(year, month + 1);
  }

  SelectedMonthState prevMonth() {
    if (month == 1) return SelectedMonthState(year - 1, 12);
    return SelectedMonthState(year, month - 1);
  }
}

final selectedMonthProvider = StateNotifierProvider<SelectedMonthNotifier, SelectedMonthState>((ref) {
  final now = DateTime.now();
  return SelectedMonthNotifier(SelectedMonthState(now.year, now.month));
});

class SelectedMonthNotifier extends StateNotifier<SelectedMonthState> {
  SelectedMonthNotifier(super.state);

  void setMonth(int year, int month) => state = SelectedMonthState(year, month);
  void goToNextMonth() => state = state.nextMonth();
  void goToPrevMonth() => state = state.prevMonth();
}

// Monthly Summary Provider
final monthlySummaryProvider = Provider<SpendingSummary>((ref) {
  final transactions = ref.watch(transactionProvider);
  final categories = ref.watch(categoryProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);

  return AnalyticsService.computeMonthlySummary(
    transactions: transactions,
    categories: categories,
    year: selectedMonth.year,
    month: selectedMonth.month,
  );
});

// Budget Notifier
class BudgetNotifier extends StateNotifier<List<BudgetModel>> {
  final LocalStorageService _storage;

  BudgetNotifier(this._storage) : super([]) {
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    final list = await _storage.loadBudgets();
    if (list.isEmpty) {
      // Default overall budget
      final defaultBudget = const BudgetModel(
        id: 'budget_overall_default',
        title: 'งบประมาณรายจ่ายรวมประจำเดือน',
        monthlyLimit: 15000.0,
        alertThresholdPercent: 80.0,
      );
      state = [defaultBudget];
      await _storage.saveBudgets(state);
    } else {
      state = list;
    }
  }

  Future<void> addBudget(BudgetModel budget) async {
    final updated = [...state, budget];
    state = updated;
    await _storage.saveBudgets(updated);
  }

  Future<void> updateBudget(BudgetModel budget) async {
    final updated = state.map((b) => b.id == budget.id ? budget : b).toList();
    state = updated;
    await _storage.saveBudgets(updated);
  }

  Future<void> deleteBudget(String id) async {
    final updated = state.where((b) => b.id != id).toList();
    state = updated;
    await _storage.saveBudgets(updated);
  }
}

final budgetProvider = StateNotifierProvider<BudgetNotifier, List<BudgetModel>>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return BudgetNotifier(storage);
});

// Budget Statuses Provider
final budgetStatusesProvider = Provider<List<BudgetStatus>>((ref) {
  final budgets = ref.watch(budgetProvider);
  final transactions = ref.watch(transactionProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);

  return AnalyticsService.evaluateBudgets(
    budgets: budgets,
    transactions: transactions,
    year: selectedMonth.year,
    month: selectedMonth.month,
  );
});
