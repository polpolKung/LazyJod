import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/transactions/models/transaction_model.dart';
import '../../features/categories/models/category_model.dart';
import '../../features/transactions/models/recurring_schedule.dart';
import '../../features/analytics/models/budget_model.dart';

class LocalStorageService {
  static const String _prefTransactionsKey = 'lazyjod_transactions';
  static const String _prefCategoriesKey = 'lazyjod_categories';
  static const String _prefBudgetsKey = 'lazyjod_budgets';
  static const String _prefRecurringKey = 'lazyjod_recurring';

  SharedPreferences? _prefs;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      print('SharedPreferences init error: $e');
    }
  }

  // Transactions
  Future<List<TransactionModel>> loadTransactions() async {
    if (_prefs == null) await init();
    final jsonStr = _prefs?.getString(_prefTransactionsKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => TransactionModel.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      print('Error decoding transactions: $e');
      return [];
    }
  }

  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    if (_prefs == null) await init();
    final list = transactions.map((e) => e.toMap()).toList();
    await _prefs?.setString(_prefTransactionsKey, jsonEncode(list));
  }

  // Categories
  Future<List<CategoryModel>> loadCategories() async {
    if (_prefs == null) await init();
    final jsonStr = _prefs?.getString(_prefCategoriesKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return CategoryModel.defaultCategories;
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => CategoryModel.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      return CategoryModel.defaultCategories;
    }
  }

  Future<void> saveCategories(List<CategoryModel> categories) async {
    if (_prefs == null) await init();
    final list = categories.map((e) => e.toMap()).toList();
    await _prefs?.setString(_prefCategoriesKey, jsonEncode(list));
  }

  // Budgets
  Future<List<BudgetModel>> loadBudgets() async {
    if (_prefs == null) await init();
    final jsonStr = _prefs?.getString(_prefBudgetsKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => BudgetModel.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveBudgets(List<BudgetModel> budgets) async {
    if (_prefs == null) await init();
    final list = budgets.map((e) => e.toMap()).toList();
    await _prefs?.setString(_prefBudgetsKey, jsonEncode(list));
  }

  // Recurring
  Future<List<RecurringRule>> loadRecurringRules() async {
    if (_prefs == null) await init();
    final jsonStr = _prefs?.getString(_prefRecurringKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => RecurringRule.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveRecurringRules(List<RecurringRule> rules) async {
    if (_prefs == null) await init();
    final list = rules.map((e) => e.toMap()).toList();
    await _prefs?.setString(_prefRecurringKey, jsonEncode(list));
  }
}
