import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/local_storage_service.dart';
import '../models/category_model.dart';

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

class CategoryNotifier extends StateNotifier<List<CategoryModel>> {
  final LocalStorageService _storage;

  CategoryNotifier(this._storage) : super(CategoryModel.defaultCategories) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    final list = await _storage.loadCategories();
    state = list;
  }

  Future<void> addCategory(CategoryModel category) async {
    final updated = [...state, category];
    state = updated;
    await _storage.saveCategories(updated);
  }

  Future<void> updateCategory(CategoryModel category) async {
    final updated = state.map((c) => c.id == category.id ? category : c).toList();
    state = updated;
    await _storage.saveCategories(updated);
  }

  Future<void> deleteCategory(String id) async {
    final updated = state.where((c) => c.id != id).toList();
    state = updated;
    await _storage.saveCategories(updated);
  }
}

final categoryProvider = StateNotifierProvider<CategoryNotifier, List<CategoryModel>>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return CategoryNotifier(storage);
});
