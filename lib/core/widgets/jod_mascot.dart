import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Cheeky, funny quotes from "จ้อด" (Jod) the lazy sloth mascot
class JodQuotes {
  static const List<String> idleQuotes = [
    'ขี้เกียจจดใช่มั้ยล่ะ... ส่งสลิปมา เดี๋ยวจ้อดช่วยเอง 🦥',
    'ชีวิตมันเหนื่อย นอนเล่นเฉยๆ แล้วปล่อยให้จ้อดจดให้เหอะ 💤',
    'สล้อตอย่างเราไม่ขยันกดจดหรอก สแกนสลิปทีเดียวจบ! 😜',
    'อย่าลืมเช็กเงินในบัญชีนะ เดี๋ยวจะหาว่าจ้อดไม่เตือน 😏',
    'เงินทองของหายาก แต่ถ้าสลิปเข้า จ้อดก็พร้อมนับให้นะ 💰',
  ];

  static const List<String> emptyStateQuotes = [
    'ยังไม่มีรายการเลยเหรอ? ขี้เกียจเหมือนกันเลยนะเราอ่ะ 🦥',
    'โล่งจัด! แอบไปใช้เงินสด หรือขี้เกียจจดกันแน่? สแกนสลิปมาดูซิ 😜',
    'ไม่มีรายการให้ดู... นอนต่อได้ยัง? 💤',
  ];

  static const List<String> scanningQuotes = [
    'จ้อดกำลังเพ่งสลิปให้อยู่... สล้อตอาจจะช้า แต่งานละเอียดนะ 🦥💨',
    'กำลังแกะตัวหนังสือในสลิปให้อยู่ อย่าเพิ่งเร่งจ้อดนะจ๊ะ 😜',
    'จ้อดกำลังตรวจจับเงินเข้า-ออกให้... นั่งจิบชาชิลๆ รอได้เลย 🍵',
  ];

  static const List<String> budgetNearLimitQuotes = [
    'เห้ยๆ เบาได้เบา! ใช้ไปเยอะแล้วนะ กระเป๋าจะแฟบแล้ว 😜',
    'เริ่มช้อปเพลินแล้วนะ เดี๋ยวสิ้นเดือนได้กินมาม่าคู่กับจ้อดแน่! 🍜',
  ];

  static const List<String> budgetExceededQuotes = [
    'ล้นงบไปแล้วจ้าาา! โหมดตัวใครตัวมันแล้วนะเนี่ย 😭💸',
    'เกินงบแล้วนะเหวยยย! เดือนนี้พักช้อปก่อนมั้ย? 🛑',
  ];

  static String getRandomIdleQuote() {
    final rand = Random();
    return idleQuotes[rand.nextInt(idleQuotes.length)];
  }

  static String getRandomEmptyQuote() {
    final rand = Random();
    return emptyStateQuotes[rand.nextInt(emptyStateQuotes.length)];
  }
}

/// A delightful mascot widget showcasing "จ้อด" (Jod)
class JodMascotAvatar extends StatelessWidget {
  final double size;
  final bool withBorder;
  final VoidCallback? onTap;

  const JodMascotAvatar({
    super.key,
    this.size = 40,
    this.withBorder = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryMint,
        border: withBorder
            ? Border.all(color: AppColors.primary, width: size > 60 ? 3 : 2)
            : null,
        boxShadow: withBorder
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/icons/iconApp.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Text('🦥', style: TextStyle(fontSize: 22)),
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }
    return avatar;
  }
}

/// A speech bubble card showing Jod and a cheeky quote
class JodMascotCard extends StatelessWidget {
  final String? message;
  final String? title;
  final VoidCallback? onTap;

  const JodMascotCard({
    super.key,
    this.message,
    this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayMessage = message ?? JodQuotes.getRandomIdleQuote();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCard
            : AppColors.primaryLight.withOpacity(0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withOpacity(isDark ? 0.25 : 0.4),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const JodMascotAvatar(size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      title ?? 'จ้อด (Lazy Jod)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'มาสคอตสายขี้เกียจ',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  displayMessage,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
