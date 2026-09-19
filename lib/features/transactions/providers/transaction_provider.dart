import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/local_storage_service.dart';
import '../../categories/providers/category_provider.dart';
import '../../ingestion/models/thai_bank.dart';
import '../models/recurring_schedule.dart';
import '../models/transaction_model.dart';
import '../models/transaction_type.dart';
import '../services/recurring_transaction_service.dart';

class TransactionNotifier extends StateNotifier<List<TransactionModel>> {
  final LocalStorageService _storage;

  TransactionNotifier(this._storage) : super([]) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    final list = await _storage.loadTransactions();
    // Sort newest first
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    state = list;
  }

  Future<void> addTransaction(TransactionModel tx) async {
    final updated = [tx, ...state];
    updated.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    state = updated;
    await _storage.saveTransactions(updated);
  }

  Future<void> addBatchTransactions(List<TransactionModel> txList) async {
    final updated = [...txList, ...state];
    updated.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    state = updated;
    await _storage.saveTransactions(updated);
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    final updated = state.map((t) => t.id == tx.id ? tx : t).toList();
    updated.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    state = updated;
    await _storage.saveTransactions(updated);
  }

  Future<void> deleteTransaction(String id) async {
    final updated = state.where((t) => t.id != id).toList();
    state = updated;
    await _storage.saveTransactions(updated);
  }
}

final transactionProvider = StateNotifierProvider<TransactionNotifier, List<TransactionModel>>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return TransactionNotifier(storage);
});

// Transaction Filters
class TransactionFilterState {
  final String searchQuery;
  final TransactionType? type;
  final String? categoryId;
  final String? tag;
  final ThaiBank? bank;
  final DateTime? startDate;
  final DateTime? endDate;

  const TransactionFilterState({
    this.searchQuery = '',
    this.type,
    this.categoryId,
    this.tag,
    this.bank,
    this.startDate,
    this.endDate,
  });

  TransactionFilterState copyWith({
    String? searchQuery,
    TransactionType? type,
    String? categoryId,
    String? tag,
    ThaiBank? bank,
    DateTime? startDate,
    DateTime? endDate,
    bool clearType = false,
    bool clearCategory = false,
    bool clearTag = false,
    bool clearBank = false,
    bool clearDateRange = false,
  }) {
    return TransactionFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      type: clearType ? null : (type ?? this.type),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      tag: clearTag ? null : (tag ?? this.tag),
      bank: clearBank ? null : (bank ?? this.bank),
      startDate: clearDateRange ? null : (startDate ?? this.startDate),
      endDate: clearDateRange ? null : (endDate ?? this.endDate),
    );
  }
}

class TransactionFilterNotifier extends StateNotifier<TransactionFilterState> {
  TransactionFilterNotifier() : super(const TransactionFilterState());

  void setSearchQuery(String query) => state = state.copyWith(searchQuery: query);
  void setType(TransactionType? type) => state = state.copyWith(type: type, clearType: type == null);
  void setCategory(String? categoryId) => state = state.copyWith(categoryId: categoryId, clearCategory: categoryId == null);
  void setTag(String? tag) => state = state.copyWith(tag: tag, clearTag: tag == null);
  void setBank(ThaiBank? bank) => state = state.copyWith(bank: bank, clearBank: bank == null);
  void setDateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) {
      state = state.copyWith(clearDateRange: true);
    } else {
      state = state.copyWith(startDate: start, endDate: end);
    }
  }
  void reset() => state = const TransactionFilterState();
}

final transactionFilterProvider = StateNotifierProvider<TransactionFilterNotifier, TransactionFilterState>((ref) {
  return TransactionFilterNotifier();
});

// Filtered transactions selector
final filteredTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final transactions = ref.watch(transactionProvider);
  final filter = ref.watch(transactionFilterProvider);

  return transactions.where((tx) {
    if (filter.searchQuery.isNotEmpty) {
      final q = filter.searchQuery.toLowerCase();
      final matchNote = tx.note.toLowerCase().contains(q);
      final matchTag = tx.tags.any((t) => t.toLowerCase().contains(q));
      final matchRef = tx.slipRefId?.toLowerCase().contains(q) ?? false;
      if (!matchNote && !matchTag && !matchRef) return false;
    }

    if (filter.type != null && tx.type != filter.type) return false;
    if (filter.categoryId != null && tx.categoryId != filter.categoryId) return false;
    if (filter.tag != null && !tx.tags.contains(filter.tag)) return false;
    if (filter.bank != null && tx.bankSource != filter.bank) return false;

    if (filter.startDate != null && tx.dateTime.isBefore(filter.startDate!)) return false;
    if (filter.endDate != null && tx.dateTime.isAfter(filter.endDate!)) return false;

    return true;
  }).toList();
});
