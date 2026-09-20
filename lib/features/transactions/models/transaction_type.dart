enum TransactionType {
  expense,
  income,
  transfer;

  String get displayNameThai {
    switch (this) {
      case TransactionType.expense: return 'รายจ่าย';
      case TransactionType.income: return 'รายรับ';
      case TransactionType.transfer: return 'ย้ายเงิน';
    }
  }
}
