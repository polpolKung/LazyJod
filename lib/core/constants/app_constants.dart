class AppConstants {
  static const String appName = 'LazyJod (เหมียวจด)';
  static const String appTagline = 'บันทึกการเงินอัตโนมัติจากสลิปธนาคาร';
  static const String currencySymbol = '฿';
  static const String currencyCode = 'THB';
  static const String localeThai = 'th_TH';

  // Hive Box Names
  static const String boxTransactions = 'transactions_box';
  static const String boxCategories = 'categories_box';
  static const String boxBudgets = 'budgets_box';
  static const String boxSettings = 'settings_box';
  static const String boxScannedSlips = 'scanned_slips_box';
  static const String boxRecurring = 'recurring_box';

  // Default Targeted Thai Bank Photo Folder Names (Privacy-focused)
  static const List<String> defaultBankingFolders = [
    'K PLUS',
    'SCB EASY',
    'Krungthai NEXT',
    'ttb touch',
    'Bangkok Bank',
    'MyMo',
    'KMA',
    'A-Mobile',
    'KKP Mobile',
    'CIMB THAI',
    'UOB TMRW',
    'TrueMoney',
    'Banking',
    'Slips',
    'สลิป',
    'สลิปโอนเงิน',
  ];
}
