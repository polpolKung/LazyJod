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

  const CategoryModel({
    required this.id,
    required this.nameThai,
    required this.nameEnglish,
    required this.iconCodePoint,
    required this.colorValue,
    required this.type,
    this.isDefault = false,
    this.autoKeywords = const [],
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
    );
  }

  static List<CategoryModel> get defaultCategories => [
    const CategoryModel(
      id: 'cat_food',
      nameThai: 'อาหารและเครื่องดื่ม',
      nameEnglish: 'Food & Drinks',
      iconCodePoint: 0xe532, // restaurant
      colorValue: 0xFFFF7A45,
      type: CategoryType.expense,
      isDefault: true,
      autoKeywords: [
        'cafe', 'coffee', 'kitchen', 'restaurant', 'food', 'bakery', 'tea',
        'เซเว่น', '7-eleven', 'lineman', 'grabfood', 'shopeefood', 'เตี๋ยว',
        'ข้าวมันไก่', 'หมูกระทะ', 'ชาบู', 'ส้มตำ', 'ชาไข่มุก', 'สุกี้'
      ],
    ),
    const CategoryModel(
      id: 'cat_transport',
      nameThai: 'เดินทาง/คมนาคม',
      nameEnglish: 'Transportation',
      iconCodePoint: 0xe1d5, // directions_car
      colorValue: 0xFF1890FF,
      type: CategoryType.expense,
      isDefault: true,
      autoKeywords: [
        'bts', 'mrt', 'grab', 'bolt', 'ptt', 'bcp', 'shell', 'caltex',
        'ทางด่วน', 'easy pass', 'm-flow', 'น้ำมัน', 'ปั๊ม', 'แท็กซี่'
      ],
    ),
    const CategoryModel(
      id: 'cat_shopping',
      nameThai: 'ช้อปปิ้ง/ของใช้',
      nameEnglish: 'Shopping',
      iconCodePoint: 0xe59c, // shopping_bag
      colorValue: 0xFFEB2F96,
      type: CategoryType.expense,
      isDefault: true,
      autoKeywords: [
        'shopee', 'lazada', 'tiktok', 'central', 'lotus', 'big c', 'cj express',
        'วัตสัน', 'watsons', 'boots', 'uniqlo', 'zara', 'mr.diy', 'd.i.y'
      ],
    ),
    const CategoryModel(
      id: 'cat_bills',
      nameThai: 'บิลและสาธารณูปโภค',
      nameEnglish: 'Bills & Utilities',
      iconCodePoint: 0xf00b8, // receipt_long
      colorValue: 0xFFFA8C16,
      type: CategoryType.expense,
      isDefault: true,
      autoKeywords: [
        'การไฟฟ้า', 'pea', 'mea', 'การประปา', 'pwa', 'mwa', 'ais', 'true',
        'dtac', '3bb', 'nt', 'อินเทอร์เน็ต', 'ค่าไฟ', 'ค่าน้ำ', 'ค่าโทรศัพท์'
      ],
    ),
    const CategoryModel(
      id: 'cat_housing',
      nameThai: 'ที่อยู่อาศัย',
      nameEnglish: 'Housing & Rent',
      iconCodePoint: 0xe318, // home
      colorValue: 0xFF722ED1,
      type: CategoryType.expense,
      isDefault: true,
      autoKeywords: ['ค่าเช่า', 'ค่าหอ', 'คอนโด', 'ส่วนกลาง', 'นิติบุคคล', 'เฟอร์นิเจอร์', 'ikea', 'index'],
    ),
    const CategoryModel(
      id: 'cat_entertainment',
      nameThai: 'บันเทิงและสตรีมมิ่ง',
      nameEnglish: 'Entertainment',
      iconCodePoint: 0xe405, // movie
      colorValue: 0xFF13C2C2,
      type: CategoryType.expense,
      isDefault: true,
      autoKeywords: ['netflix', 'spotify', 'youtube', 'disney', 'major', 'sf cinema', 'steam', 'game', 'playstation'],
    ),
    const CategoryModel(
      id: 'cat_health',
      nameThai: 'สุขภาพและความงาม',
      nameEnglish: 'Health & Beauty',
      iconCodePoint: 0xe380, // local_hospital
      colorValue: 0xFF52C41A,
      type: CategoryType.expense,
      isDefault: true,
      autoKeywords: ['โรงพยาบาล', 'คลินิก', 'เภสัช', 'ยา', 'หมอฟัน', 'ฟิตเนส', 'fitness', 'เสริมสวย', 'ทำเล็บ', 'ตัดผม'],
    ),
    const CategoryModel(
      id: 'cat_pets',
      nameThai: 'สัตว์เลี้ยง (น้องเหมียว/หมา)',
      nameEnglish: 'Pets',
      iconCodePoint: 0xe91d, // pets
      colorValue: 0xFFFAAD14,
      type: CategoryType.expense,
      isDefault: true,
      autoKeywords: ['อาหารแมว', 'อาหารหมา', 'ทรายแมว', 'คลินิกสัตว์', 'pet shop', 'สัตวแพทย์'],
    ),
    const CategoryModel(
      id: 'cat_other_expense',
      nameThai: 'อื่นๆ (รายจ่าย)',
      nameEnglish: 'Other Expense',
      iconCodePoint: 0xe3e3, // more_horiz
      colorValue: 0xFF8C8C8C,
      type: CategoryType.expense,
      isDefault: true,
      autoKeywords: [],
    ),
    // Income Categories
    const CategoryModel(
      id: 'cat_salary',
      nameThai: 'เงินเดือน/ค่าจ้าง',
      nameEnglish: 'Salary & Wages',
      iconCodePoint: 0xe040, // account_balance_wallet
      colorValue: 0xFF52C41A,
      type: CategoryType.income,
      isDefault: true,
      autoKeywords: ['เงินเดือน', 'salary', 'payroll'],
    ),
    const CategoryModel(
      id: 'cat_bonus',
      nameThai: 'รายได้เสริม/โบนัส',
      nameEnglish: 'Bonus & Side Hustle',
      iconCodePoint: 0xf0229, // savings
      colorValue: 0xFF1890FF,
      type: CategoryType.income,
      isDefault: true,
      autoKeywords: ['freelance', 'ฟรีแลนซ์', 'โบนัส', 'คอมมิชชั่น', 'เงินปันผล', 'ดอกเบี้ย'],
    ),
    const CategoryModel(
      id: 'cat_other_income',
      nameThai: 'อื่นๆ (รายรับ)',
      nameEnglish: 'Other Income',
      iconCodePoint: 0xe047, // add_circle
      colorValue: 0xFF13C2C2,
      type: CategoryType.income,
      isDefault: true,
      autoKeywords: [],
    ),
  ];
}
