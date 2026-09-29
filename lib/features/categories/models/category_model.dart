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

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
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
    const CategoryModel(
      id: 'cat_food',
      nameThai: 'อาหารและเครื่องดื่ม',
      nameEnglish: 'Food & Drinks',
      iconCodePoint: 0xf00ee, // ramen_dining_rounded
      colorValue: 0xFFFFA07A, // Pastel Salmon Peach
      type: CategoryType.expense,
      isDefault: true,
      emoji: '🍜',
      autoKeywords: [
        'cafe', 'coffee', 'kitchen', 'restaurant', 'food', 'bakery', 'tea',
        'เซเว่น', '7-eleven', 'lineman', 'grabfood', 'shopeefood', 'เตี๋ยว',
        'ข้าวมันไก่', 'หมูกระทะ', 'ชาบู', 'ส้มตำ', 'ชาไข่มุก', 'สุกี้',
        'กาแฟ', 'คาเฟ่', 'ร้านอาหาร', 'ร้านกาแฟ', 'เบเกอรี่', 'ชานม',
        'ไก่ทอด', 'บะหมี่', 'ก๋วยเตี๋ยว', 'ข้าวต้ม', 'อาหาร',
      ],
    ),
    const CategoryModel(
      id: 'cat_transport',
      nameThai: 'เดินทาง/คมนาคม',
      nameEnglish: 'Transportation',
      iconCodePoint: 0xf659, // commute_rounded (bus/train/car)
      colorValue: 0xFF48CAE4, // Pastel Sky Cyan
      type: CategoryType.expense,
      isDefault: true,
      emoji: '🚊',
      autoKeywords: [
        'bts', 'mrt', 'grab', 'bolt', 'ptt', 'bcp', 'shell', 'caltex',
        'ทางด่วน', 'easy pass', 'm-flow', 'น้ำมัน', 'ปั๊ม', 'แท็กซี่'
      ],
    ),
    const CategoryModel(
      id: 'cat_shopping',
      nameThai: 'ช้อปปิ้ง/ของใช้',
      nameEnglish: 'Shopping',
      iconCodePoint: 0xf016e, // shopping_bag_rounded
      colorValue: 0xFFFF85A1, // Pastel Blossom Pink
      type: CategoryType.expense,
      isDefault: true,
      emoji: '🛍️',
      autoKeywords: [
        'shopee', 'lazada', 'tiktok', 'central', 'lotus', 'big c', 'cj express',
        'วัตสัน', 'watsons', 'boots', 'uniqlo', 'zara', 'mr.diy', 'd.i.y',
        'ลาซาด้า', 'ช้อปปี้', 'ติ๊กต็อก', 'เซ็นทรัล', 'โลตัส', 'แม็กซ์แวลู',
        'บิ๊กซี', 'ท็อปส์', 'จัสโก้', 'อิเกีย', 'ฮาร์บา', 'ช้อปปิ้ง',
      ],
    ),
    const CategoryModel(
      id: 'cat_uncategorized',
      nameThai: 'รอเลือกหมวดหมู่',
      nameEnglish: 'Uncategorized',
      iconCodePoint: 0xf06e5, // psychology_alt_rounded (sloth thinking)
      colorValue: 0xFFFFB703, // Pastel Honey Sloth Gold
      type: CategoryType.expense,
      isDefault: true,
      emoji: '🦥',
      autoKeywords: [],
    ),
    const CategoryModel(
      id: 'cat_transfer',
      nameThai: 'โอนเงิน / โอนให้ผู้อื่น',
      nameEnglish: 'Transfer',
      iconCodePoint: 0xf0204, // swap_horizontal_circle_rounded
      colorValue: 0xFF5AA9E6, // Pastel Azure Blue
      type: CategoryType.expense,
      isDefault: true,
      emoji: '🔄',
      autoKeywords: [
        'โอนเงิน', 'พร้อมเพย์', 'promptpay', 'transfer', 'โอน',
        'คืนเงิน', 'ฝากเงิน', 'เติมเงิน', 'นาย', 'น.ส.', 'นาง',
      ],
    ),
    const CategoryModel(
      id: 'cat_bills',
      nameThai: 'บิลและสาธารณูปโภค',
      nameEnglish: 'Bills & Utilities',
      iconCodePoint: 0xf05a1, // electric_bolt_rounded
      colorValue: 0xFFF4A261, // Pastel Warm Amber
      type: CategoryType.expense,
      isDefault: true,
      emoji: '⚡',
      autoKeywords: [
        'การไฟฟ้า', 'pea', 'mea', 'การประปา', 'pwa', 'mwa', 'ais', 'true',
        'dtac', '3bb', 'nt', 'อินเทอร์เน็ต', 'ค่าไฟ', 'ค่าน้ำ', 'ค่าโทรศัพท์'
      ],
    ),
    const CategoryModel(
      id: 'cat_housing',
      nameThai: 'ที่อยู่อาศัย',
      nameEnglish: 'Housing & Rent',
      iconCodePoint: 0xf655, // cottage_rounded
      colorValue: 0xFFA29BFE, // Pastel Soft Lavender
      type: CategoryType.expense,
      isDefault: true,
      emoji: '🏡',
      autoKeywords: ['ค่าเช่า', 'ค่าหอ', 'คอนโด', 'ส่วนกลาง', 'นิติบุคคล', 'เฟอร์นิเจอร์', 'ikea', 'index'],
    ),
    const CategoryModel(
      id: 'cat_entertainment',
      nameThai: 'บันเทิงและสตรีมมิ่ง',
      nameEnglish: 'Entertainment',
      iconCodePoint: 0xf01cd, // sports_esports_rounded
      colorValue: 0xFFC77DFF, // Pastel Neon Lilac
      type: CategoryType.expense,
      isDefault: true,
      emoji: '🎮',
      autoKeywords: ['netflix', 'spotify', 'youtube', 'disney', 'major', 'sf cinema', 'steam', 'game', 'playstation'],
    ),
    const CategoryModel(
      id: 'cat_health',
      nameThai: 'สุขภาพและความงาม',
      nameEnglish: 'Health & Beauty',
      iconCodePoint: 0xe5e1, // spa_rounded
      colorValue: 0xFF70C1B3, // Pastel Spa Mint
      type: CategoryType.expense,
      isDefault: true,
      emoji: '🧴',
      autoKeywords: ['โรงพยาบาล', 'คลินิก', 'เภสัช', 'ยา', 'หมอฟัน', 'ฟิตเนส', 'fitness', 'เสริมสวย', 'ทำเล็บ', 'ตัดผม'],
    ),
    const CategoryModel(
      id: 'cat_pets',
      nameThai: 'สัตว์เลี้ยง (น้องสล้อต/หมา/แมว)',
      nameEnglish: 'Pets',
      iconCodePoint: 0xf680, // cruelty_free_rounded
      colorValue: 0xFFE0A96D, // Pastel Warm Caramel Mocca
      type: CategoryType.expense,
      isDefault: true,
      emoji: '🐾',
      autoKeywords: ['อาหารแมว', 'อาหารหมา', 'ทรายแมว', 'คลินิกสัตว์', 'pet shop', 'สัตวแพทย์'],
    ),
    const CategoryModel(
      id: 'cat_other_expense',
      nameThai: 'อื่นๆ (รายจ่าย)',
      nameEnglish: 'Other Expense',
      iconCodePoint: 0xf5f3, // bubble_chart_rounded
      colorValue: 0xFF8E9AAF, // Pastel Slate Sage
      type: CategoryType.expense,
      isDefault: true,
      emoji: '💬',
      autoKeywords: [],
    ),
    // Income Categories
    const CategoryModel(
      id: 'cat_salary',
      nameThai: 'เงินเดือน/ค่าจ้าง',
      nameEnglish: 'Salary & Wages',
      iconCodePoint: 0xf0027, // payments_rounded
      colorValue: 0xFF52B788, // Pastel Fresh Emerald
      type: CategoryType.income,
      isDefault: true,
      emoji: '💵',
      autoKeywords: ['เงินเดือน', 'salary', 'payroll', 'ค่าจ้างรายเดือน', 'wages'],
    ),
    const CategoryModel(
      id: 'cat_bonus',
      nameThai: 'รายได้เสริม/โบนัส',
      nameEnglish: 'Bonus & Side Hustle',
      iconCodePoint: 0xf598, // auto_awesome_rounded
      colorValue: 0xFFFEE440, // Pastel Sunshine Yellow
      type: CategoryType.income,
      isDefault: true,
      emoji: '✨',
      autoKeywords: [
        'freelance', 'ฟรีแลนซ์', 'โบนัส', 'คอมมิชชั่น', 'เงินปันผล', 'ดอกเบี้ย',
        'ขายของ', 'ค่าสินค้า', 'รายได้เสริม', 'ค่าสอน', 'commission', 'bonus', 'dividend'
      ],
    ),
    const CategoryModel(
      id: 'cat_other_income',
      nameThai: 'อื่นๆ (รายรับ)',
      nameEnglish: 'Other Income',
      iconCodePoint: 0xf0077, // price_check_rounded
      colorValue: 0xFF56CFE1, // Pastel Ocean Mint
      type: CategoryType.income,
      isDefault: true,
      emoji: '💰',
      autoKeywords: ['รายรับ', 'เงินเข้า', 'โอนเข้า', 'คืนเงิน', 'รับเงิน'],
    ),
  ];
}
