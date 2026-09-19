import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../models/transaction_model.dart';
import '../../models/transaction_type.dart';
import '../../providers/transaction_provider.dart';
import '../widgets/transaction_tile.dart';
import 'filter_search_screen.dart';
import 'transaction_detail_screen.dart';
import 'transaction_entry_screen.dart';

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(filteredTransactionsProvider);
    final filter = ref.watch(transactionFilterProvider);
    final hasActiveFilter = filter.searchQuery.isNotEmpty ||
        filter.type != null ||
        filter.categoryId != null ||
        filter.tag != null ||
        filter.bank != null;

    // Group transactions by date string
    final Map<String, List<TransactionModel>> grouped = {};
    for (final tx in transactions) {
      final key = DateFormatter.formatRelativeDate(tx.dateTime);
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการทั้งหมด'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (hasActiveFilter)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FilterSearchScreen()),
              );
            },
          ),
        ],
      ),
      body: transactions.isEmpty
          ? EmptyStateWidget(
              title: hasActiveFilter ? 'ไม่พบรายการที่ค้นหา' : 'ยังไม่มีรายการธุรกรรม',
              message: hasActiveFilter
                  ? 'ลองเปลี่ยนเงื่อนไขการค้นหา หรือรีเซ็ตตัวกรอง'
                  : 'เริ่มบันทึกรายการด้วยตนเอง หรือกดสแกนสลิปอัตโนมัติได้เลย',
              icon: Icons.receipt_long_outlined,
              buttonText: hasActiveFilter ? 'รีเซ็ตตัวกรอง' : 'บันทึกรายการ',
              onButtonPressed: () {
                if (hasActiveFilter) {
                  ref.read(transactionFilterProvider.notifier).reset();
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TransactionEntryScreen()),
                  );
                }
              },
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: grouped.keys.length,
              itemBuilder: (context, index) {
                final dateKey = grouped.keys.elementAt(index);
                final txList = grouped[dateKey]!;

                // Compute daily total expense and income
                double dayExpense = 0.0;
                double dayIncome = 0.0;
                for (final t in txList) {
                  if (t.type == TransactionType.expense) {
                    dayExpense += t.amount;
                  } else if (t.type == TransactionType.income) {
                    dayIncome += t.amount;
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Header & Subtotal
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: AppColors.background,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateKey,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Row(
                            children: [
                              if (dayIncome > 0)
                                Text(
                                  '+${CurrencyFormatter.format(dayIncome)}  ',
                                  style: const TextStyle(fontSize: 12, color: AppColors.income, fontWeight: FontWeight.w600),
                                ),
                              if (dayExpense > 0)
                                Text(
                                  '-${CurrencyFormatter.format(dayExpense)}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.expense, fontWeight: FontWeight.w600),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Transaction Tiles
                    Container(
                      color: Colors.white,
                      child: Column(
                        children: txList.map((tx) {
                          return Dismissible(
                            key: Key(tx.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              color: AppColors.expense,
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('ยืนยันการลบ'),
                                  content: const Text('คุณต้องการลบรายการนี้ใช่หรือไม่?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                      child: const Text('ยกเลิก'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      child: const Text('ลบ', style: TextStyle(color: AppColors.expense)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (_) {
                              ref.read(transactionProvider.notifier).deleteTransaction(tx.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('ลบรายการเรียบร้อยแล้ว')),
                              );
                            },
                            child: TransactionTile(
                              transaction: tx,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TransactionDetailScreen(transactionId: tx.id),
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TransactionEntryScreen()),
          );
        },
      ),
    );
  }
}
