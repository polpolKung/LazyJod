import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../services/analytics_service.dart';

class BudgetProgressCard extends StatelessWidget {
  final BudgetStatus status;
  final VoidCallback? onTap;

  const BudgetProgressCard({
    super.key,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color progressColor = AppColors.income;
    if (status.isExceeded) {
      progressColor = AppColors.expense;
    } else if (status.isNearLimit) {
      progressColor = AppColors.warning;
    }

    final percentClamped = (status.percentUsed / 100).clamp(0.0, 1.0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: status.isExceeded ? AppColors.expense.withOpacity(0.5) : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    status.budget.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (status.isExceeded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'เกินงบแล้ว!',
                      style: TextStyle(fontSize: 11, color: AppColors.expense, fontWeight: FontWeight.bold),
                    ),
                  )
                else if (status.isNearLimit)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ใกล้ถึงขีดจำกัด',
                      style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percentClamped,
                minHeight: 8,
                backgroundColor: const Color(0xFFF3F4F6),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ใช้ไป ${CurrencyFormatter.format(status.currentSpent)} (${status.percentUsed.toStringAsFixed(1)}%)',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  'งบ ${CurrencyFormatter.format(status.budget.monthlyLimit)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
