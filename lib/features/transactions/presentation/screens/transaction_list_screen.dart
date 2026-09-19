import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../models/transaction_model.dart';
import '../../models/transaction_type.dart';
import '../../providers/transaction_provider.dart';
import '../widgets/transaction_quick_edit_sheet.dart';
import '../widgets/transaction_tile.dart';
import 'filter_search_screen.dart';
import 'transaction_detail_screen.dart';
import 'transaction_entry_screen.dart';

class _MonthGroup {
  final int year;
  final int month;
  final Map<String, List<TransactionModel>> dayGroups = {};
  double totalExpense = 0.0;
  double totalIncome = 0.0;

  _MonthGroup({required this.year, required this.month});
}

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(filteredTransactionsProvider);
    final filter = ref.watch(transactionFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasActiveFilter = filter.searchQuery.isNotEmpty ||
        filter.type != null ||
        filter.categoryId != null ||
        filter.tag != null ||
        filter.bank != null;

    // Two-tier grouping: Month -> Day (User Request 6)
    final Map<String, _MonthGroup> monthGroups = {};
    for (final tx in transactions) {
      final monthKey = '${tx.dateTime.year}-${tx.dateTime.month.toString().padLeft(2, '0')}';
      if (!monthGroups.containsKey(monthKey)) {
        monthGroups[monthKey] = _MonthGroup(year: tx.dateTime.year, month: tx.dateTime.month);
      }
      final mGroup = monthGroups[monthKey]!;
      if (tx.type == TransactionType.expense) {
        mGroup.totalExpense += tx.amount;
      } else if (tx.type == TransactionType.income) {
        mGroup.totalIncome += tx.amount;
      }

      final dateKey = DateFormatter.formatRelativeDate(tx.dateTime);
      mGroup.dayGroups.putIfAbsent(dateKey, () => []).add(tx);
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
              itemCount: monthGroups.keys.length,
              itemBuilder: (context, monthIndex) {
                final monthKey = monthGroups.keys.elementAt(monthIndex);
                final mGroup = monthGroups[monthKey]!;
                final monthName = DateFormatter.thaiMonthsFull[mGroup.month - 1];
                final yearThai = DateFormatter.toBuddhistYear(mGroup.year);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Major Month Header Section
                    Container(
                      margin: EdgeInsets.only(top: monthIndex == 0 ? 8 : 20, left: 16, right: 16, bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.calendar_month, color: AppColors.primary, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '$monthName $yearThai',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.expense.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'จ่าย ${CurrencyFormatter.format(mGroup.totalExpense)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.expense,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Days within this Month
                    ...mGroup.dayGroups.entries.map((dayEntry) {
                      final dateKey = dayEntry.key;
                      final txList = dayEntry.value;

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
                          // Date Subheader
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateKey,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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

                          // Transaction Tiles under this date
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.border,
                              ),
                            ),
                            child: Column(
                              children: txList.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final tx = entry.value;
                                final isLast = idx == txList.length - 1;

                                return Column(
                                  children: [
                                    Dismissible(
                                      key: Key(tx.id),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                        decoration: BoxDecoration(
                                          color: AppColors.expense,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
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
                                          showTransactionQuickEditSheet(context, tx);
                                        },
                                      ),
                                    ),
                                    if (!isLast)
                                      Divider(
                                        height: 1,
                                        indent: 68,
                                        color: isDark ? AppColors.darkBorder : AppColors.border,
                                      ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      );
                    }).toList(),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.black, size: 28),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TransactionEntryScreen()),
          );
        },
      ),
    );
  }
}
