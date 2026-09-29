import 'package:flutter/material.dart';

enum CategoryType {
  expense,
  income,
}

class CategoryModel {
  final String id;
  final String nameThai;
  final String nameEnglish;
  final int iconCodePoint;
  final int colorValue;
  final CategoryType type;
  final bool isDefault;
  final List<String> autoKeywords; // Keywords matching recipient or merchant
  final String? emoji; // Cute mascot/category emoji

  const CategoryModel({
    required this.id,
    required this.nameThai,
    required this.nameEnglish,
    required this.iconCodePoint,
    required this.colorValue,
    required this.type,
    this.isDefault = false,
    this.autoKeywords = const [],
    this.emoji,
  });

  IconData get icon {
    switch (id) {
      case 'cat_food':
        return Icons.restaurant_rounded;
      case 'cat_transport':
        return Icons.directions_car_rounded;
      case 'cat_shopping':
        return Icons.shopping_bag_rounded;
      case 'cat_uncategorized':
        return Icons.help_outline_rounded;
      case 'cat_transfer':
        return Icons.swap_horiz_rounded;
      case 'cat_bills':
        return Icons.receipt_long_rounded;
      case 'cat_housing':
        return Icons.home_rounded;
      case 'cat_entertainment':
        return Icons.sports_esports_rounded;
      case 'cat_health':
        return Icons.favorite_rounded;
      case 'cat_pets':
        return Icons.pets_rounded;
      case 'cat_other_expense':
        return Icons.more_horiz_rounded;
      case 'cat_salary':
        return Icons.payments_rounded;
      case 'cat_bonus':
        return Icons.savings_rounded;
      case 'cat_other_income':
        return Icons.account_balance_wallet_rounded;
      default:
        return IconData(iconCodePoint, fontFamily: 'MaterialIcons');
    }
  }

  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nameThai': nameThai,
      'nameEnglish': nameEnglish,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'type': type.name,
      'isDefault': isDefault,
      'autoKeywords': autoKeywords,
      'emoji': emoji,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      nameThai: map['nameThai'] as String,
      nameEnglish: map['nameEnglish'] as String,
      iconCodePoint: map['iconCodePoint'] as int,
      colorValue: map['colorValue'] as int,
      type: map['type'] == 'income' ? CategoryType.income : CategoryType.expense,
      isDefault: map['isDefault'] as bool? ?? false,
      autoKeywords: List<String>.from(map['autoKeywords'] ?? []),
      emoji: map['emoji'] as String?,
    );
  }

  static List<CategoryModel> get defaultCategories => [
    CategoryModel(
      id: 'cat_food',
      nameThai: 'อาหารและเครื่องดื่ม',
      nameEnglish: 'Food & Drinks',
      iconCodePoint: Icons.restaurant_rounded.codePoint,
      colorValue: 0xFFFFA07A, // Pastel Salmon Peach
      type: CategoryType.expense,
      isDefault: true,
      emoji: '🍜',
      autoKeywords: const [
        'cafe', 'coffee', 'kitchen', 'restaurant', 'food', 'bakery', 'tea',
        'เซเว่น', '7-eleven', 'lineman', 'grabfood', 'shopeefood', 'เตี๋ยว',
        'ข้าวมันไก่', 'หมูกระทะ', 'ชาบู', 'ส้มตำ', 'ชาไข่มุก', 'สุกี้',
        'กาแฟ', 'คาเฟ่', 'ร้านอาหาร', 'ร้านกาแฟ', 'เบเกอรี่', 'ชานม',
        'ไก่ทอด', 'บะหมี่', 'ก๋วยเตี๋ยว', 'ข้าวต้ม', 'อาหาร',
      ],
    ),
    CategoryModel(
      id: 'cat_transport',
      nameThai: 'เดินทาง/คมนาคม',
      nameEnglish: 'Transportation',
      iconCodePoint: Icons.directions_car_rounded.codePoint,
      colorValue: 0xFF48CAE4, // Pastel Sky Cyan
      type: CategoryType.expense,
      isDefault: true,
      emoji: '🚗',
      autoKeywords: const [
        'bts', 'mrt', 'grab', 'bolt', 'ptt', 'bcp', 'shell', 'caltex',
        'ทางด่วน', 'easy pass', 'm-flow', 'น้ำมัน', 'ปั๊ม', 'แท็กซี่'
      ],
    ),
    CategoryModel(
      id: 'cat_shopping',
      nameThai: 'ช้อปปิ้ง/ของใช้',
      nameEnglish: 'Shopping',
      iconCodePoint: Icons.shopping_bag_rounded.codePoint,
      colorValue: 0xFFFF85A1, // Pastel Blossom Pink
      type: CategoryType.expense,
      isDefault: true,
      emoji: '🛍️',
      autoKeywords: const [
        'shopee', 'lazada', 'tiktok', 'central', 'lotus', 'big c', 'cj express',
        'วัตสัน', 'watsons', 'boots', 'uniqlo', 'zara', 'mr.diy', 'd.i.y',
        'ลาซาด้า', 'ช้อปปี้', 'ติ๊กต็อก', 'เซ็นทรัล', 'โลตัส', 'แม็กซ์แวลู',
        'บิ๊กซี', 'ท็อปส์', 'จัสโก้', 'อิเกีย', 'ฮาร์บา', 'ช้อปปิ้ง',
      ],
    ),
    CategoryModel(
      id: 'cat_uncategorized',
      nameThai: 'รอเลือกหมวดหมู่',
      nameEnglish: 'Uncategorized',
      iconCodePoint: Icons.help_outline_rounded.codePoint,
      colorValue: 0xFFFFB703, // Pastel Honey Sloth Gold
      type: CategoryType.expense,
      isDefault: true,
      emoji: '🦥',
      autoKeywords: const [],
    ),
    CategoryModel(
      id: 'cat_transfer',
      nameThai: 'โอนเงิน / โอนให้ผู้อื่น',
      nameEnglish: 'Transfer',
      iconCodePoint: Icons.swap_horiz_rounded.codePoint,
      colorValue: 0xFF5AA9E6, // Pastel Azure Blue
      type: CategoryType.expense,
      isDefault: true,
      emoji: '🔄',
      autoKeywords: const [
        'โอนเงิน', 'พร้อมเพย์', 'promptpay', 'transfer', 'โอน',
        'คืนเงิน', 'ฝากเงิน', 'เติมเงิน', 'นาย', 'น.ส.', 'นาง',
      ],
    ),
    CategoryModel(
      id: 'cat_bills',
      nameThai: 'บิลและสาธารณูปโภค',
      nameEnglish: 'Bills & Utilities',
      iconCodePoint: Icons.receipt_long_rounded.codePoint,
      colorValue: 0xFFF4A261, // Pastel Warm Amber
      type: CategoryType.expense,
      isDefault: true,
      emoji: '🧾',
      autoKeywords: const [
        'การไฟฟ้า', 'pea', 'mea', 'การประปา', 'pwa', 'mwa', 'ais', 'true',
        'dtac', '3bb', 'nt', 'อินเทอร์เน็ต', 'ค่าไฟ', 'ค่าน้ำ', 'ค่าโทรศัพท์'
      ],
    ),
    CategoryModel(
      id: 'cat_housing',
      nameThai: 'ที่อยู่อาศัย',
      nameEnglish: 'Housing & Rent',
      iconCodePoint: Icons.home_rounded.codePoint,
      colorValue: 0xFFA29BFE, // Pastel Soft Lavender
      type: CategoryType.expense,
      isDefault: true,
      emoji: '🏡',
      autoKeywords: const ['ค่าเช่า', 'ค่าหอ', 'คอนโด', 'ส่วนกลาง', 'นิติบุคคล', 'เฟอร์นิเจอร์', 'ikea', 'index'],
    ),
    CategoryModel(
      id: 'cat_entertainment',
      nameThai: 'บันเทิงและสตรีมมิ่ง',
      nameEnglish: 'Entertainment',
      iconCodePoint: Icons.sports_esports_rounded.codePoint,
      colorValue: 0xFFC77DFF, // Pastel Neon Lilac
      type: CategoryType.expense,
      isDefault: true,
      emoji: '🎮',
      autoKeywords: const ['netflix', 'spotify', 'youtube', 'disney', 'major', 'sf cinema', 'steam', 'game', 'playstation'],
    ),
    CategoryModel(
      id: 'cat_health',
      nameThai: 'สุขภาพและความงาม',
      nameEnglish: 'Health & Beauty',
      iconCodePoint: Icons.favorite_rounded.codePoint,
      colorValue: 0xFF70C1B3, // Pastel Spa Mint
      type: CategoryType.expense,
      isDefault: true,
      emoji: '💖',
      autoKeywords: const ['โรงพยาบาล', 'คลินิก', 'เภสัช', 'ยา', 'หมอฟัน', 'ฟิตเนส', 'fitness', 'เสริมสวย', 'ทำเล็บ', 'ตัดผม'],
    ),
    CategoryModel(
      id: 'cat_pets',
      nameThai: 'สัตว์เลี้ยง (น้องสล้อต/หมา/แมว)',
      nameEnglish: 'Pets',
      iconCodePoint: Icons.pets_rounded.codePoint,
      colorValue: 0xFFE0A96D, // Pastel Warm Caramel Mocca
      type: CategoryType.expense,
      isDefault: true,
      emoji: '🐾',
      autoKeywords: const ['อาหารแมว', 'อาหารหมา', 'ทรายแมว', 'คลินิกสัตว์', 'pet shop', 'สัตวแพทย์'],
    ),
    CategoryModel(
      id: 'cat_other_expense',
      nameThai: 'อื่นๆ (รายจ่าย)',
      nameEnglish: 'Other Expense',
      iconCodePoint: Icons.more_horiz_rounded.codePoint,
      colorValue: 0xFF8E9AAF, // Pastel Slate Sage
      type: CategoryType.expense,
      isDefault: true,
      emoji: '💬',
      autoKeywords: const [],
    ),
    // Income Categories
    CategoryModel(
      id: 'cat_salary',
      nameThai: 'เงินเดือน/ค่าจ้าง',
      nameEnglish: 'Salary & Wages',
      iconCodePoint: Icons.payments_rounded.codePoint,
      colorValue: 0xFF52B788, // Pastel Fresh Emerald
      type: CategoryType.income,
      isDefault: true,
      emoji: '💵',
      autoKeywords: const ['เงินเดือน', 'salary', 'payroll', 'ค่าจ้างรายเดือน', 'wages'],
    ),
    CategoryModel(
      id: 'cat_bonus',
      nameThai: 'รายได้เสริม/โบนัส',
      nameEnglish: 'Bonus & Side Hustle',
      iconCodePoint: Icons.savings_rounded.codePoint,
      colorValue: 0xFFFEE440, // Pastel Sunshine Yellow
      type: CategoryType.income,
      isDefault: true,
      emoji: '✨',
      autoKeywords: const [
        'freelance', 'ฟรีแลนซ์', 'โบนัส', 'คอมมิชชั่น', 'เงินปันผล', 'ดอกเบี้ย',
        'ขายของ', 'ค่าสินค้า', 'รายได้เสริม', 'ค่าสอน', 'commission', 'bonus', 'dividend'
      ],
    ),
    CategoryModel(
      id: 'cat_other_income',
      nameThai: 'อื่นๆ (รายรับ)',
      nameEnglish: 'Other Income',
      iconCodePoint: Icons.account_balance_wallet_rounded.codePoint,
      colorValue: 0xFF56CFE1, // Pastel Ocean Mint
      type: CategoryType.income,
      isDefault: true,
      emoji: '💰',
      autoKeywords: const ['รายรับ', 'เงินเข้า', 'โอนเข้า', 'คืนเงิน', 'รับเงิน'],
    ),
  ];
}
