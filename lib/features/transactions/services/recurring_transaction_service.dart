import 'package:uuid/uuid.dart';
import '../models/recurring_schedule.dart';
import '../models/transaction_model.dart';
import '../models/transaction_type.dart';

class RecurringTransactionService {
  static const _uuid = Uuid();

  /// Checks active recurring rules and generates due transactions up to [currentDate]
  static List<TransactionModel> generateDueTransactions({
    required List<RecurringRule> rules,
    required DateTime currentDate,
    required Function(RecurringRule updatedRule) onRuleUpdated,
  }) {
    final List<TransactionModel> generated = [];

    for (final rule in rules) {
      if (!rule.isActive) continue;

      DateTime nextDue = _calculateNextDueDate(rule.lastExecutedDate, rule.frequency);

      while (nextDue.isBefore(currentDate) || nextDue.isAtSameMomentAs(currentDate)) {
        if (rule.endDate != null && nextDue.isAfter(rule.endDate!)) {
          break;
        }

        final tx = TransactionModel(
          id: 'rec_${_uuid.v4()}',
          type: TransactionType.expense,
          amount: rule.amount,
          dateTime: nextDue,
          categoryId: rule.categoryId,
          note: '[รายการประจำ] ${rule.title}',
          isRecurring: true,
        );

        generated.add(tx);

        final updatedRule = RecurringRule(
          id: rule.id,
          title: rule.title,
          amount: rule.amount,
          categoryId: rule.categoryId,
          frequency: rule.frequency,
          startDate: rule.startDate,
          endDate: rule.endDate,
          lastExecutedDate: nextDue,
          isActive: rule.isActive,
        );

        onRuleUpdated(updatedRule);
        nextDue = _calculateNextDueDate(nextDue, rule.frequency);
      }
    }

    return generated;
  }

  static DateTime _calculateNextDueDate(DateTime fromDate, RecurringFrequency freq) {
    switch (freq) {
      case RecurringFrequency.daily:
        return fromDate.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return fromDate.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        final nextMonth = fromDate.month == 12 ? 1 : fromDate.month + 1;
        final nextYear = fromDate.month == 12 ? fromDate.year + 1 : fromDate.year;
        final maxDayInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        final targetDay = fromDate.day <= maxDayInNextMonth ? fromDate.day : maxDayInNextMonth;
        return DateTime(nextYear, nextMonth, targetDay, fromDate.hour, fromDate.minute);
      case RecurringFrequency.yearly:
        return DateTime(fromDate.year + 1, fromDate.month, fromDate.day, fromDate.hour, fromDate.minute);
    }
  }
}
