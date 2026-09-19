class StatementRecord {
  final String id;
  final DateTime transactionDate;
  final DateTime? postingDate;
  final String description;
  final double amount;
  final bool isInstallment;
  final int? currentInstallmentMonth;
  final int? totalInstallmentMonths;
  final bool isCashback;
  final String? cardLast4;
  final String? suggestedCategoryId;

  const StatementRecord({
    required this.id,
    required this.transactionDate,
    this.postingDate,
    required this.description,
    required this.amount,
    this.isInstallment = false,
    this.currentInstallmentMonth,
    this.totalInstallmentMonths,
    this.isCashback = false,
    this.cardLast4,
    this.suggestedCategoryId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transactionDate': transactionDate.toIso8601String(),
      'postingDate': postingDate?.toIso8601String(),
      'description': description,
      'amount': amount,
      'isInstallment': isInstallment,
      'currentInstallmentMonth': currentInstallmentMonth,
      'totalInstallmentMonths': totalInstallmentMonths,
      'isCashback': isCashback,
      'cardLast4': cardLast4,
      'suggestedCategoryId': suggestedCategoryId,
    };
  }
}
