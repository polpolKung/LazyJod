import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/ingestion/models/ocr_sync_item.dart';
import '../../features/transactions/models/transaction_model.dart';
import '../../features/categories/models/category_model.dart';
import '../../features/transactions/models/recurring_schedule.dart';
import '../../features/analytics/models/budget_model.dart';
import '../constants/app_constants.dart';

class LocalStorageService {
  static const String _prefTransactionsKey = 'lazyjod_transactions';
  static const String _prefCategoriesKey = 'lazyjod_categories';
  static const String _prefBudgetsKey = 'lazyjod_budgets';
  static const String _prefRecurringKey = 'lazyjod_recurring';
  static const String _prefScannedAssetIdsKey = 'lazyjod_scanned_asset_ids';
  static const String _prefEnableIncomeScanKey = 'lazyjod_enable_income_scan';
  static const String _prefIncomeFolderNamesKey = 'lazyjod_income_folder_names';
  static const String _prefExpenseFolderNamesKey = 'lazyjod_expense_folder_names';
  static const String _prefSelectedIncomeAlbumIdsKey = 'lazyjod_selected_income_album_ids';
  static const String _prefSelectedExpenseAlbumIdsKey = 'lazyjod_selected_expense_album_ids';

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

  // Scanned asset IDs — used to skip re-OCR on next launch
  Future<Set<String>> loadScannedAssetIds() async {
    if (_prefs == null) await init();
    final jsonStr = _prefs?.getString(_prefScannedAssetIdsKey);
    if (jsonStr == null || jsonStr.isEmpty) return {};
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.cast<String>().toSet();
    } catch (e) {
      return {};
    }
  }

  Future<void> addScannedAssetIds(Set<String> newIds) async {
    if (_prefs == null) await init();
    final existing = await loadScannedAssetIds();
    existing.addAll(newIds);
    // Keep max 10,000 IDs to avoid unbounded storage growth (drop oldest if needed)
    final trimmed = existing.length > 10000
        ? existing.skip(existing.length - 10000).toSet()
        : existing;
    await _prefs?.setString(_prefScannedAssetIdsKey, jsonEncode(trimmed.toList()));
  }

  // Scan History Limit & First Launch
  static const String _prefScanLimitKey = 'lazyjod_scan_limit';
  static const String _prefFirstLaunchKey = 'lazyjod_first_launch_done';

  Future<int> getScanHistoryLimit() async {
    if (_prefs == null) await init();
    return _prefs?.getInt(_prefScanLimitKey) ?? 50; // default to 50 for fast scanning
  }

  Future<void> setScanHistoryLimit(int limit) async {
    if (_prefs == null) await init();
    await _prefs?.setInt(_prefScanLimitKey, limit);
  }

  Future<bool> isFirstLaunch() async {
    if (_prefs == null) await init();
    return !(_prefs?.getBool(_prefFirstLaunchKey) ?? false);
  }

  Future<void> setFirstLaunchCompleted() async {
    if (_prefs == null) await init();
    await _prefs?.setBool(_prefFirstLaunchKey, true);
  }

  // ── OCR Sync Queue ────────────────────────────────────────────────────────
  static const String _prefSyncQueueKey = 'lazyjod_ocr_sync_queue';

  /// Loads all pending [OcrSyncItem]s from local storage.
  Future<List<OcrSyncItem>> loadSyncQueue() async {
    if (_prefs == null) await init();
    final jsonStr = _prefs?.getString(_prefSyncQueueKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((e) => OcrSyncItem.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('Error decoding sync queue: $e');
      return [];
    }
  }

  /// Persists [queue] to local storage, replacing any previous queue state.
  Future<void> saveSyncQueue(List<OcrSyncItem> queue) async {
    if (_prefs == null) await init();
    final list = queue.map((e) => e.toMap()).toList();
    await _prefs?.setString(_prefSyncQueueKey, jsonEncode(list));
  }

  // ── Income Slip Scanning (Optional) ──────────────────────────────────────
  Future<bool> isIncomeScanEnabled() async {
    if (_prefs == null) await init();
    return _prefs?.getBool(_prefEnableIncomeScanKey) ?? false;
  }

  Future<void> setIncomeScanEnabled(bool enabled) async {
    if (_prefs == null) await init();
    await _prefs?.setBool(_prefEnableIncomeScanKey, enabled);
  }

  // Expense & Income Folder Names
  Future<List<String>> getExpenseFolderNames() async {
    if (_prefs == null) await init();
    final list = _prefs?.getStringList(_prefExpenseFolderNamesKey);
    return list ?? List.from(AppConstants.defaultBankingFolders);
  }

  Future<void> setExpenseFolderNames(List<String> names) async {
    if (_prefs == null) await init();
    await _prefs?.setStringList(_prefExpenseFolderNamesKey, names);
  }

  Future<List<String>> getIncomeFolderNames() async {
    if (_prefs == null) await init();
    final list = _prefs?.getStringList(_prefIncomeFolderNamesKey);
    return list ?? List.from(AppConstants.defaultIncomeFolders);
  }

  Future<void> setIncomeFolderNames(List<String> names) async {
    if (_prefs == null) await init();
    await _prefs?.setStringList(_prefIncomeFolderNamesKey, names);
  }

  // Persisted Selected Album IDs for Expense and Income
  Future<Set<String>> getSelectedExpenseAlbumIds() async {
    if (_prefs == null) await init();
    final list = _prefs?.getStringList(_prefSelectedExpenseAlbumIdsKey);
    return list?.toSet() ?? {};
  }

  Future<void> setSelectedExpenseAlbumIds(Set<String> ids) async {
    if (_prefs == null) await init();
    await _prefs?.setStringList(_prefSelectedExpenseAlbumIdsKey, ids.toList());
  }

  Future<Set<String>> getSelectedIncomeAlbumIds() async {
    if (_prefs == null) await init();
    final list = _prefs?.getStringList(_prefSelectedIncomeAlbumIdsKey);
    return list?.toSet() ?? {};
  }

  Future<void> setSelectedIncomeAlbumIds(Set<String> ids) async {
    if (_prefs == null) await init();
    await _prefs?.setStringList(_prefSelectedIncomeAlbumIdsKey, ids.toList());
  }
}

