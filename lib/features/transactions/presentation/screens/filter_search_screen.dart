import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../categories/providers/category_provider.dart';
import '../../../ingestion/models/thai_bank.dart';
import '../../models/transaction_type.dart';
import '../../providers/transaction_provider.dart';

class FilterSearchScreen extends ConsumerStatefulWidget {
  const FilterSearchScreen({super.key});

  @override
  ConsumerState<FilterSearchScreen> createState() => _FilterSearchScreenState();
}

class _FilterSearchScreenState extends ConsumerState<FilterSearchScreen> {
  late TextEditingController _searchController;
  TransactionType? _type;
  String? _categoryId;
  ThaiBank? _bank;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(transactionFilterProvider);
    _searchController = TextEditingController(text: filter.searchQuery);
    _type = filter.type;
    _categoryId = filter.categoryId;
    _bank = filter.bank;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _apply() {
    final notifier = ref.read(transactionFilterProvider.notifier);
    notifier.setSearchQuery(_searchController.text.trim());
    notifier.setType(_type);
    notifier.setCategory(_categoryId);
    notifier.setBank(_bank);
    Navigator.of(context).pop();
  }

  void _reset() {
    ref.read(transactionFilterProvider.notifier).reset();
    setState(() {
      _searchController.clear();
      _type = null;
      _categoryId = null;
      _bank = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ค้นหาและตัวกรอง'),
        actions: [
          TextButton(
            onPressed: _reset,
            child: const Text('รีเซ็ต', style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อร้านค้า บันทึก หรือรหัสสลิป',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchController.clear()),
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // Transaction Type
            const Text(
              'ประเภทธุรกรรม',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterChip('ทั้งหมด', _type == null, () => setState(() => _type = null)),
                _buildFilterChip('รายจ่าย', _type == TransactionType.expense, () => setState(() => _type = TransactionType.expense)),
                _buildFilterChip('รายรับ', _type == TransactionType.income, () => setState(() => _type = TransactionType.income)),
              ],
            ),
            const SizedBox(height: 24),

            // Categories
            const Text(
              'หมวดหมู่',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip('ทุกหมวดหมู่', _categoryId == null, () => setState(() => _categoryId = null)),
                ...categories.map((cat) => _buildFilterChip(
                      cat.nameThai,
                      _categoryId == cat.id,
                      () => setState(() => _categoryId = cat.id),
                    )),
              ],
            ),
            const SizedBox(height: 24),

            // Bank Sources
            const Text(
              'ธนาคารต้นทาง',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip('ทุกธนาคาร', _bank == null, () => setState(() => _bank = null)),
                ...ThaiBank.values
                    .where((b) => b != ThaiBank.unknown)
                    .map((b) => _buildFilterChip(
                          b.displayNameThai,
                          _bank == b,
                          () => setState(() => _bank = b),
                          color: b.brandColor,
                        )),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: ElevatedButton(
          onPressed: _apply,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('ใช้ตัวกรอง', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, {Color? color}) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color ?? AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => onTap(),
    );
  }
}
