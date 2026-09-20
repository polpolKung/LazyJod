import 'package:flutter/foundation.dart';
import '../../categories/models/category_model.dart';
import '../models/slip_parse_result.dart';
import '../models/thai_bank.dart';
import '../../../core/utils/date_formatter.dart';

class ThaiBankSlipParser {
  /// Main entrypoint to parse raw OCR text extracted from a slip
  static SlipParseResult parse(String rawText, {String? imagePath, String? imageHash, DateTime? fallbackDateTime}) {
    final cleanText = _normalizeText(rawText);

    final bank = detectBank(cleanText);
    final amount = extractAmount(cleanText, bank: bank);
    final dateTime = extractDateTime(cleanText);
    final recipient = extractRecipient(cleanText, bank: bank);
    final sender = extractSender(cleanText, bank: bank);
    final refId = extractRefId(cleanText, bank: bank);
    final suggestedCategory = suggestCategory(recipient, cleanText);

    // Calculate heuristic confidence score
    double score = 0.2;
    if (bank != ThaiBank.unknown) score += 0.2;
    if (amount > 0) score += 0.3;
    if (recipient.isNotEmpty && !recipient.startsWith('ไม่ระบุ')) score += 0.15;
    if (refId != null && refId.isNotEmpty) score += 0.15;

    return SlipParseResult(
      bank: bank,
      amount: amount,
      // Use OCR-extracted date first, then asset file time, then now
      dateTime: dateTime ?? fallbackDateTime ?? DateTime.now(),
      recipientName: recipient,
      senderName: sender,
      refId: refId,
      suggestedCategoryId: suggestedCategory,
      confidenceScore: score.clamp(0.0, 1.0),
      imagePath: imagePath,
      imageHash: imageHash,
      rawOcrText: rawText,
    );
  }

  static String _normalizeText(String input) {
    return input
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
  }

  /// 1. Detect Thai Bank from 16 Banks + PromptPay
  static ThaiBank detectBank(String text) {
    final lower = text.toLowerCase();

    for (final bank in ThaiBank.values) {
      if (bank == ThaiBank.unknown) continue;
      for (final kw in bank.detectionKeywords) {
        if (lower.contains(kw)) {
          return bank;
        }
      }
    }

    // Default fallback
    if (lower.contains('โอนเงินสำเร็จ') || lower.contains('รายการสำเร็จ') || lower.contains('ทำรายการสำเร็จ')) {
      return ThaiBank.promptPay;
    }

    return ThaiBank.unknown;
  }

  /// 2. Extract Transfer Amount in THB
  static double extractAmount(String text, {ThaiBank? bank}) {
    // --- Step 0: Government welfare slip detection (คนละครึ่ง / ไทยช่วยไทย / เป๋าตัง) ---
    // These slips show: ค่าสินค้า (full price), สิทธิฯ (subsidy, negative), จำนวนเงินที่ชำระ (user paid)
    // We MUST record only what the user actually paid (จำนวนเงินที่ชำระ).
    final isWelfareSlip = RegExp(
      r'คนละครึ่ง|ไทยช่วยไทย|สิทธิ(?:ไทยช่วยไทย|คนละครึ่ง|เราชนะ|รัฐ)|เป๋าตัง|paotang|g.wallet|halfhalf',
      caseSensitive: false,
    ).hasMatch(text);

    if (isWelfareSlip) {
      // Specifically look for "จำนวนเงินที่ชำระ" line — the actual user payment
      final welfarePattern = RegExp(
        r'จำนวนเงินที่ชำระ\s*[:\s]?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?)\s*บาท?',
        caseSensitive: false,
      );
      final wm = welfarePattern.firstMatch(text);
      if (wm != null) {
        final parsed = double.tryParse(wm.group(1)!.replaceAll(',', ''));
        if (parsed != null && parsed > 0) return parsed;
      }

      // Fallback: collect all positive amounts with 2 decimal places,
      // skip negative-prefixed lines (subsidy), pick the smallest positive = user share
      final lines = text.split('\n');
      final List<double> positiveAmounts = [];
      for (final line in lines) {
        // Skip subsidy lines (negative amounts)
        if (RegExp(r'[-−]\s*[0-9]').hasMatch(line)) continue;
        final m = RegExp(r'([0-9]{1,3}(?:,[0-9]{3})*\.[0-9]{2})').firstMatch(line);
        if (m != null) {
          final v = double.tryParse(m.group(1)!.replaceAll(',', ''));
          if (v != null && v > 0) positiveAmounts.add(v);
        }
      }
      if (positiveAmounts.isNotEmpty) {
        // Smallest positive amount = what the user actually paid
        positiveAmounts.sort();
        return positiveAmounts.first;
      }
    }

    // --- Step 1: Labeled patterns (priority order) ---
    // "จำนวนเงินที่ชำระ" checked first to beat plain "จำนวนเงิน"
    final labeledPatterns = [
      RegExp(r'จำนวนเงินที่ชำระ\s*[:\s]?\s*(?:thb|฿|baht)?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?)', caseSensitive: false),
      RegExp(r'(?:จำนวนเงิน|ยอดเงิน|ยอดเงินรวม|จำนวน|amount|total amount)\s*[:\s]?\s*(?:thb|฿|baht)?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?)', caseSensitive: false),
      RegExp(r'(?:thb|฿)\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?)', caseSensitive: false),
      RegExp(r'([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2}))\s*(?:บาท|thb|baht)', caseSensitive: false),
      RegExp(r'(?<!\d)([1-9][0-9]{0,4}(?:\.[0-9]{2})?)\s*(?:บาท|thb)', caseSensitive: false),
    ];

    for (final pattern in labeledPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1)!.replaceAll(',', '');
        final parsed = double.tryParse(amountStr);
        if (parsed != null && parsed > 0) return parsed;
      }
    }

    // --- Step 2: Fallback decimal scan (numbers with exactly 2 decimal places) ---
    final fallbackRegex = RegExp(r'(?<!\d|\.)([1-9][0-9]{0,2}(?:,[0-9]{3})*\.[0-9]{2})(?!\d)');
    final matches = fallbackRegex.allMatches(text);
    for (final match in matches) {
      final amountStr = match.group(1)!.replaceAll(',', '');
      final parsed = double.tryParse(amountStr);
      if (parsed != null && parsed > 0 && parsed < 10000000) {
        return parsed;
      }
    }

    return 0.0;
  }

  /// 3. Extract Transfer Date and Time
  static DateTime? extractDateTime(String text) {
    int hour = 12;
    int minute = 0;
    int second = 0;

    // Check for Time
    final timeRegex = RegExp(r'(\d{1,2})[:.](\d{2})(?:[:.](\d{2}))?');
    final timeMatch = timeRegex.firstMatch(text);
    if (timeMatch != null) {
      hour = int.tryParse(timeMatch.group(1)!) ?? 12;
      minute = int.tryParse(timeMatch.group(2)!) ?? 0;
      if (timeMatch.group(3) != null) {
        second = int.tryParse(timeMatch.group(3)!) ?? 0;
      }
    }

    // Check for Thai Date
    final parsedDate = DateFormatter.parseThaiDate(text);
    if (parsedDate != null) {
      return DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        hour,
        minute,
        second,
      );
    }

    // ISO/Standard fallback
    final isoRegex = RegExp(r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})(?:\s+(\d{1,2}):(\d{1,2})(?::(\d{1,2}))?)?');
    final match = isoRegex.firstMatch(text);
    if (match != null) {
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);
      final h = match.group(4) != null ? int.parse(match.group(4)!) : hour;
      final m = match.group(5) != null ? int.parse(match.group(5)!) : minute;
      final s = match.group(6) != null ? int.parse(match.group(6)!) : second;
      return DateTime(year, month, day, h, m, s);
    }

    return null;
  }

  /// 4. Extract Recipient / Merchant Name
  static String extractRecipient(String text, {ThaiBank? bank}) {
    final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    // Known bank-name strings to skip when looking ahead
    final bankNamePhrases = [
      'กรุงเทพ', 'กสิกร', 'ไทยพาณิชย์', 'กรุงไทย', 'กรุงศรี', 'ออมสิน',
      'ธนาคาร', 'bangkok bank', 'kasikorn', 'kbank', 'ktb', 'scb', 'bay',
      'bbl', 'gsb', 'ttb', 'tmb', 'baac', 'kkp', 'cimb', 'uob', 'tisco',
      'lhb', 'ghb', 'truemoney', 'promptpay', 'พร้อมเพย์',
      'krungthai', 'kkp start', 'next', 'ktb next', 'krungthai next',
      'pao tang', 'paotang', 'เป๋าตัง', 'make by kbank', 'make', 'dime',
    ];

    bool _isBankName(String s) {
      final lower = s.toLowerCase();
      return bankNamePhrases.any((b) => lower.contains(b));
    }

    bool _isPersonOrMerchantName(String s) {
      if (_isAccountNumber(s) || _isKeyword(s) || _isBankName(s)) return false;
      if (s.length < 3 || s.length > 55) return false;

      // Reject known OCR noise patterns: short all-lowercase latin strings without vowels
      // e.g. "nsolna", "nsulna", "UUUN", random OCR artifacts
      if (RegExp(r'^[a-z]{3,12}$').hasMatch(s)) {
        // All-lowercase short strings — must have at least 2 vowels to be a real name/word
        final vowelCount = 'aeiou'.split('').fold(0, (c, v) => c + v.allMatches(s).length);
        if (vowelCount < 2) return false;
      }
      // Reject ALL-CAPS nonsense of 2–5 chars that are not known merchants
      if (RegExp(r'^[A-Z]{2,5}$').hasMatch(s)) {
        const knownAcronyms = {'SCB', 'KTB', 'BBL', 'GSB', 'TTB', 'TMB', 'UOB', 'LHB', 'GHB', 'GRAB', 'LINE', 'TRUE', 'AIS', 'DTAC'};
        if (!knownAcronyms.contains(s.toUpperCase())) return false;
      }

      // Thai person/merchant prefix
      if (s.startsWith('นาย') || s.startsWith('นาง') || s.startsWith('น.ส.') ||
          s.startsWith('นางสาว') || s.startsWith('ด.ช.') || s.startsWith('ด.ญ.') ||
          s.contains('บจก.') || s.contains('บริษัท') || s.contains('หจก.') ||
          s.startsWith('ร้าน') || s.startsWith('Mr.') || s.startsWith('Ms.') ||
          s.startsWith('Mrs.') || s.startsWith('MR.') || s.startsWith('MS.')) {
        return true;
      }

      // Thai name: 2 or more Thai words (Firstname + Lastname)
      if (RegExp(r'^[\u0E01-\u0E2E\u0E30-\u0E4C]{2,}[\s]+[\u0E01-\u0E2E\u0E30-\u0E4C]{2,}').hasMatch(s)) {
        return true;
      }

      // Single Thai word of 4-30 chars without digits or special symbols
      if (RegExp(r'^[\u0E01-\u0E2E\u0E30-\u0E4C\s]{4,30}$').hasMatch(s) &&
          !s.contains('สำเร็จ') && !s.contains('โอนเงิน') && !s.contains('รายการ')) {
        return true;
      }

      // English proper name or known merchant:
      // Must have proper title case or uppercase words, not mixed-case OCR noise (e.g. "UNa nUwa nwu")
      if (RegExp(r'^[A-Za-z][A-Za-z0-9\s\.\(\)&,-]{2,45}$').hasMatch(s)) {
        final lower = s.toLowerCase();
        if (lower == 'to' || lower == 'from' || lower == 'amount' || lower == 'date' || lower == 'fee') return false;
        final words = s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        if (words.isEmpty) return false;
        // Single-word English names must be at least 4 chars (e.g. "Grab", "Shopee"; rejects "Pay")
        if (words.length == 1 && s.trim().length < 4) return false;
        for (final w in words) {
          final clean = w.replaceAll(RegExp(r'[,\.\(\)\&]'), '');
          if (clean.isEmpty) continue;
          // Reject words with both letters and digits (e.g. transaction IDs like "Aaa86ab443fa54854")
          if (RegExp(r'[A-Za-z]').hasMatch(clean) && RegExp(r'[0-9]').hasMatch(clean)) {
            return false;
          }
          final isTitleCase = RegExp(r'^[A-Z][a-z]+$').hasMatch(clean);
          final isAllUpper = RegExp(r'^[A-Z0-9]{2,}$').hasMatch(clean);
          final isSingleInitial = RegExp(r'^[A-Z]\.?$').hasMatch(clean);
          if (!isTitleCase && !isAllUpper && !isSingleInitial) {
            return false; // Rejects OCR artifacts like "UNa", "nUwa", "nwu"
          }
        }
        return true;
      }

      return false;
    }

    // Priority keywords indicating recipient (including Bangkok Bank "ไปที่")
    final recipientKeywords = [
      'ไปที่', 'ไปที่:', 'ไปยัง', 'ไปยัง:', 'ผู้รับโอน', 'ผู้รับโอน:',
      'โอนไป', 'โอนไป:', 'โอนให้', 'โอนให้:', 'โอนเข้า', 'โอนเข้า:',
      'ผู้รับเงิน', 'ชื่อผู้รับ', 'ผู้รับ:', 'ผู้รับ',
      'เข้าบัญชี', 'บัญชีผู้รับ', 'to', 'to:', 'receiver', 'beneficiary', 'payee',
      'recipient',
    ];

    String? fallbackAccount;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      for (final kw in recipientKeywords) {
        if (line.toLowerCase().startsWith(kw.toLowerCase())) {
          final remainder = line.substring(kw.length).replaceAll(RegExp(r'^[:\s]+'), '').trim();
          if (remainder.isNotEmpty && !_isKeyword(remainder) && !_isBankName(remainder)) {
            if (_isPersonOrMerchantName(remainder)) {
              return _cleanName(remainder);
            }
            if (_isAccountNumber(remainder) && fallbackAccount == null) {
              fallbackAccount = remainder;
            }
          }

          // Look ahead up to 4 lines specifically for a person/merchant name
          for (int j = i + 1; j < lines.length && j <= i + 4; j++) {
            final next = lines[j];
            if (_isBankName(next)) continue;
            if (_isKeyword(next)) break;
            if (_isAccountNumber(next)) {
              fallbackAccount ??= next;
              continue;
            }
            if (_isPersonOrMerchantName(next)) {
              return _cleanName(next);
            }
          }
        }
      }
    }

    // Priority Strategy 1.5: PaoTang / G-Wallet specific merchant extraction
    // In PaoTang slips, the line immediately following "G-Wallet ID:" is always the merchant name!
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains('g-wallet id') || lines[i].toLowerCase().contains('g wallet id') || lines[i].toLowerCase().contains('g-wallet')) {
        for (int j = i + 1; j < lines.length && j <= i + 3; j++) {
          final next = lines[j];
          if (_isKeyword(next) || _isBankName(next) || _isAccountNumber(next)) continue;
          if (_isPersonOrMerchantName(next)) {
            return _cleanName(next);
          }
        }
      }
    }

    // Secondary strategy: Collect all person/company name lines across the slip
    final List<String> candidateNames = [];
    for (final line in lines) {
      if (_isPersonOrMerchantName(line)) {
        candidateNames.add(_cleanName(line));
      }
    }

    // In slips without labels (e.g. TrueMoney, MAKE by KBank):
    // First candidate is typically Sender, Second candidate is Recipient!
    if (candidateNames.length >= 2) {
      return candidateNames[1];
    } else if (candidateNames.length == 1) {
      return candidateNames[0];
    }

    // Third strategy: Use account/phone number found in recipient section
    if (fallbackAccount != null) {
      return 'พร้อมเพย์ $fallbackAccount';
    }

    // Fourth strategy: Find any PromptPay/account destination number
    for (final line in lines) {
      final phoneMatch = RegExp(r'(0\d{2}[-\s]*\d{3}[-\s]*\d{4}|0\d{2}[-\s]*x{3}[-\s]*\d{4}|x{3}[-\s]*\d{4}|x{3}[-\s]*x{3,8}[-\s]*\d{3,4})', caseSensitive: false).firstMatch(line);
      if (phoneMatch != null) {
        return 'พร้อมเพย์ ${phoneMatch.group(1)}';
      }
    }

    // Fourth strategy: Check if bank is known
    if (bank != null && bank != ThaiBank.unknown) {
      return 'โอนเงิน (${bank.displayNameThai})';
    }

    return 'โอนเงิน';
  }

  /// 5. Extract Sender Name
  static String? extractSender(String text, {ThaiBank? bank}) {
    final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final senderKeywords = ['จาก', 'จาก:', 'from', 'from:', 'ผู้โอน', 'sender'];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      for (final kw in senderKeywords) {
        if (line.toLowerCase().startsWith(kw.toLowerCase())) {
          final remainder = line.substring(kw.length).replaceAll(RegExp(r'^[:\s]+'), '').trim();
          if (remainder.isNotEmpty && !_isAccountNumber(remainder)) {
            return _cleanName(remainder);
          }
          if (i + 1 < lines.length) {
            final nextLine = lines[i + 1];
            if (!_isKeyword(nextLine) && !_isAccountNumber(nextLine)) {
              return _cleanName(nextLine);
            }
          }
        }
      }
    }
    return null;
  }

  /// 6. Extract Transaction Reference Number
  static String? extractRefId(String text, {ThaiBank? bank}) {
    final refPatterns = [
      RegExp(r'(?:รหัสอ้างอิง|เลขที่รายการ|เลขอ้างอิง|หมายเลขอ้างอิง|ref(?:\s*no\.?)?|transaction\s*id)\s*[:\s]?\s*([A-Za-z0-9\-_]{6,32})', caseSensitive: false),
      RegExp(r'(?<!\d)([0-9]{12,25})(?!\d)'),
    ];

    for (final pattern in refPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  /// 7. Auto-suggest Category from Recipient or full Slip text
  static String suggestCategory(String recipient, String fullText) {
    final combined = '$recipient $fullText'.toLowerCase();

    // 1. Specific merchant & spending categories first (Food, Shopping, Transport, Bills, Health)
    for (final category in CategoryModel.defaultCategories) {
      if (category.id == 'cat_transfer' || category.id == 'cat_uncategorized' || category.id == 'cat_other_expense') continue;
      for (final kw in category.autoKeywords) {
        if (combined.contains(kw.toLowerCase())) {
          return category.id;
        }
      }
    }

    // 2. Default for P2P transfers, PromptPay, or any unrecognized slip:
    // Let the user choose the category themselves!
    return 'cat_uncategorized';
  }

  static bool _isAccountNumber(String text) {
    final clean = text.trim().replaceAll(RegExp(r'[\s\-\.\/]'), '');
    // If string is at least 6 chars and is only digits and x/X (e.g. 090xxx5844, xxx7058, 12345678)
    if (clean.length >= 6 && RegExp(r'^[0-9xX]+$').hasMatch(clean)) {
      return true;
    }
    // Starts with 2 or more x/X
    if (RegExp(r'^(?:x{2,}|X{2,})').hasMatch(text.trim())) {
      return true;
    }
    return false;
  }

  static bool _isKeyword(String text) {
    final lower = text.toLowerCase();
    return lower.contains('จำนวน') || lower.contains('amount') ||
           lower.contains('วันที่') || lower.contains('date') ||
           lower.contains('ค่าธรรมเนียม') || lower.contains('fee') ||
           lower.contains('สำเร็จ') || lower.contains('successful') ||
           lower.contains('หมายเลขอ้างอิง') || lower.contains('ref') ||
           lower.contains('บันทึกช่วยจำ') || lower.contains('memo') ||
           lower.contains('ยอดเงิน') || lower.contains('รหัสรายการ') ||
           lower.contains('รหัสอ้างอิง') || lower.contains('ค่าสินค้า') ||
           lower.contains('สิทธิ') || lower.contains('g-wallet') ||
           lower.contains('g wallet') ||
           lower.contains('pay') || lower.contains('payment') ||
           lower.contains('transfer') || lower.contains('promptpay') ||
           lower.contains('พร้อมเพย์') || lower.contains('scan') ||
           // PaoTang business category tags — NOT recipient names
           (lower.contains('อาหาร') && lower.contains('เครื่องดื่ม')) ||
           lower.contains('ของหวาน') ||
           lower.contains('ร้านอาหาร') || lower.contains('ของใช้') ||
           (lower.contains('เครื่องดื่ม') && lower.length < 30);
  }

  static String _cleanName(String raw) {
    return raw
        .replaceAll(RegExp(r'^(?:to|จาก|ไปยัง|ไปที่|โอนไป|โอนให้|ผู้รับโอน|ผู้รับ|ผู้โอน|ชื่อ|recipient|beneficiary|payee)[:\s]*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }
}
