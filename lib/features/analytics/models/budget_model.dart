class BudgetModel {
  final String id;
  final String? categoryId;
  final String? tag;
  final String title;
  final double monthlyLimit;
  final double alertThresholdPercent; // default 80%

  const BudgetModel({
    required this.id,
    this.categoryId,
    this.tag,
    required this.title,
    required this.monthlyLimit,
    this.alertThresholdPercent = 80.0,
  });

  bool get isCategoryBudget => categoryId != null;
  bool get isTagBudget => tag != null;
  bool get isOverallBudget => categoryId == null && tag == null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'tag': tag,
      'title': title,
      'monthlyLimit': monthlyLimit,
      'alertThresholdPercent': alertThresholdPercent,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as String,
      categoryId: map['categoryId'] as String?,
      tag: map['tag'] as String?,
      title: map['title'] as String,
      monthlyLimit: (map['monthlyLimit'] as num).toDouble(),
      alertThresholdPercent: (map['alertThresholdPercent'] as num?)?.toDouble() ?? 80.0,
    );
  }
}
