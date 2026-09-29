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
    final displayMessage = message ?? JodQuotes.getRandomIdleQuote();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cartoonOutline, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.cartoonOutline.withOpacity(0.12),
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Mascot Avatar with cartoon ink outline
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cartoonOutline, width: 1.8),
            ),
            child: const JodMascotAvatar(size: 54),
          ),
          const SizedBox(width: 14),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Cute cartoon pill badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cartoonOutline, width: 1.4),
                      ),
                      child: const Text(
                        'สล้อตสายชิลล์ 💤',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.cartoonOutline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  displayMessage,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
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
