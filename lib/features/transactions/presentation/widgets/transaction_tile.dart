import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../categories/providers/category_provider.dart';
import '../../models/transaction_model.dart';
import '../../models/transaction_type.dart';

class TransactionTile extends ConsumerWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryProvider);
    final category = categories.firstWhere(
      (c) => c.id == transaction.categoryId,
      orElse: () => categories.first,
    );

    final isExpense = transaction.type == TransactionType.expense;
    final amountPrefix = isExpense ? '-' : '+';
    final amountColor = isExpense ? AppColors.expense : AppColors.income;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Category Icon with Circle
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(category.icon, color: category.color, size: 24),
            ),
            const SizedBox(width: 14),
            // Title, Category, and Badges
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          transaction.note.isNotEmpty ? transaction.note : category.nameThai,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (transaction.isFromSlip) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: transaction.bankSource.brandColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_outlined, size: 10, color: transaction.bankSource.brandColor),
                              const SizedBox(width: 2),
                              Text(
                                transaction.bankSource.shortCode,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: transaction.bankSource.brandColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        DateFormatter.formatTimeOnly(transaction.dateTime),
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•  ${category.nameThai}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      if (transaction.tags.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            transaction.tags.map((t) => t.startsWith('#') ? t : '#$t').join(' '),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Amount
            Text(
              '$amountPrefix${CurrencyFormatter.format(transaction.amount)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
