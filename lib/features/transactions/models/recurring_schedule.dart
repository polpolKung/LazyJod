enum RecurringFrequency {
  daily,
  weekly,
  monthly,
  yearly;

  String get displayNameThai {
    switch (this) {
      case RecurringFrequency.daily: return 'ทุกวัน';
      case RecurringFrequency.weekly: return 'ทุกสัปดาห์';
      case RecurringFrequency.monthly: return 'ทุกเดือน';
      case RecurringFrequency.yearly: return 'ทุกปี';
    }
  }
}

class RecurringRule {
  final String id;
  final String title;
  final double amount;
  final String categoryId;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime lastExecutedDate;
  final bool isActive;

  const RecurringRule({
    required this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.lastExecutedDate,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'categoryId': categoryId,
      'frequency': frequency.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'lastExecutedDate': lastExecutedDate.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory RecurringRule.fromMap(Map<String, dynamic> map) {
    return RecurringRule(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['categoryId'] as String,
      frequency: RecurringFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => RecurringFrequency.monthly,
      ),
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate'] as String) : null,
      lastExecutedDate: DateTime.parse(map['lastExecutedDate'] as String),
      isActive: map['isActive'] as bool? ?? true,
    );
  }
}
