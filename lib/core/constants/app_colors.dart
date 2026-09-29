import 'package:flutter/material.dart';

class AppColors {
  // ─── Brand Mint (derived from Jod mascot logo background ~#76E0B1)
  // Pastelized to soft mint pastel for UI — same hue as logo, reduced saturation
  static const Color primary = Color(0xFF6ECFAA);      // Logo mint, pastelized
  static const Color primaryLight = Color(0xFFCDF0E3); // Very soft mint tint
  static const Color primaryDark = Color(0xFF3E9E7A);  // Deeper mint for text
  static const Color primaryMint = Color(0xFFADE5CC);  // Mid mint
  static const Color primarySoftBg = Color(0xFFE4F7F0); // Barely-there mint bg

  static const Color secondary = Color(0xFF88C5D8);   // Soft sky blue (sunglasses)
  static const Color accent = Color(0xFFEDD898);       // Warm butter honey
  static const Color tonguePink = Color(0xFFF0919B);   // Soft blush pink (tongue)
  static const Color slothBrown = Color(0xFFA88060);   // Cozy sloth fur

  // ─── Financial semantic (soft, no neon)
  static const Color expense = Color(0xFFE8909A);  // Muted blush rose
  static const Color income = Color(0xFF6ECFAA);   // Same as primary (mint)
  static const Color transfer = Color(0xFF88C5D8); // Soft sky blue
  static const Color warning = Color(0xFFE8C06A);  // Warm honey

  // ─── Backgrounds — clean white with micro mint tint
  static const Color background = Color(0xFFF4FDFB); // Near-white micro mint
  static const Color surface = Color(0xFFFFFFFF);    // Pure white cards
  static const Color cardBg = Color(0xFFFFFFFF);     // Pure white
  static const Color cardBorder = Color(0xFFD8F0E8); // Hairline mint border
  static const Color border = Color(0xFFDAEFE5);
  static const Color divider = Color(0xFFEBF7F2);

  // ─── Text — warm dark (not harsh black)
  static const Color textPrimary = Color(0xFF283832);   // Deep forest slate
  static const Color textSecondary = Color(0xFF5A7A6E); // Muted sage
  static const Color textMuted = Color(0xFF94B5A8);     // Very muted

  // ─── Dark tokens (unified = same as light)
  static const Color darkBackground = Color(0xFFF4FDFB);
  static const Color darkSurface = Color(0xFFFFFFFF);
  static const Color darkCard = Color(0xFFFFFFFF);
  static const Color darkBorder = Color(0xFFD8F0E8);
  static const Color darkDivider = Color(0xFFEBF7F2);
  static const Color darkTextPrimary = Color(0xFF283832);
  static const Color darkTextSecondary = Color(0xFF5A7A6E);
  static const Color darkTextMuted = Color(0xFF94B5A8);

  // ─── 16 Thai Bank Colors
  static const Color bankKBank = Color(0xFF138F2D);
  static const Color bankSCB = Color(0xFF4E2A84);
  static const Color bankKTB = Color(0xFF00A5E5);
  static const Color bankTTB = Color(0xFF0056B3);
  static const Color bankBBL = Color(0xFF1E3A8A);
  static const Color bankGSB = Color(0xFFEB1985);
  static const Color bankBAY = Color(0xFFFFC425);
  static const Color bankBAAC = Color(0xFF285C27);
  static const Color bankKKP = Color(0xFF25477B);
  static const Color bankCIMB = Color(0xFF8B181B);
  static const Color bankUOB = Color(0xFF0A2569);
  static const Color bankTISCO = Color(0xFF1756A5);
  static const Color bankLHB = Color(0xFF0075BE);
  static const Color bankGHB = Color(0xFFF47920);
  static const Color bankTrueMoney = Color(0xFFFF6600);
  static const Color bankPromptPay = Color(0xFF003D6B);
}
