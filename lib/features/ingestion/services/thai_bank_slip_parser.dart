import 'package:flutter/foundation.dart';
import '../../categories/models/category_model.dart';
import '../models/slip_parse_result.dart';
import '../models/thai_bank.dart';
import '../../../core/utils/date_formatter.dart';

class ThaiBankSlipParser {
  /// Main entrypoint to parse raw OCR text extracted from a slip
  static SlipParseResult parse(String rawText, {String? imagePath, String? imageHash}) {
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
      dateTime: dateTime ?? DateTime.now(),
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
    // Patterns with explicit labels
    final labeledPatterns = [
      // จำนวนเงิน / จำนวนเงิน (บาท) / ยอดเงิน / จำนวนเงินที่ชำระ
      RegExp(r'(?:จำนวนเงินที่ชำระ|จำนวนเงิน|ยอดเงิน|ยอดเงินรวม|จำนวน|amount|total amount)\s*[:\s]?\s*(?:thb|฿|baht)?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?)', caseSensitive: false),
      // ฿ 1,250.00 or THB 1,250.00
      RegExp(r'(?:thb|฿)\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?)', caseSensitive: false),
      // 1,250.00 บาท / 1250.00 THB
      RegExp(r'([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2}))\s*(?:บาท|thb|baht)', caseSensitive: false),
      // Plain number before บาท: e.g. 20 บาท
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

    // Fallback: search for numbers with 2 decimal places in reasonable ranges (e.g. 1.00 - 5,000,000.00)
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

    // Priority keywords indicating recipient (including Bangkok Bank "ไปที่")
    final recipientKeywords = [
      'ไปที่', 'ไปที่:', 'ไปยัง', 'ไปยัง:', 'ผู้รับโอน', 'ผู้รับโอน:',
      'โอนไป', 'โอนไป:', 'โอนให้', 'โอนให้:', 'โอนเข้า', 'โอนเข้า:',
      'ผู้รับเงิน', 'ชื่อผู้รับ', 'ผู้รับ:', 'ผู้รับ',
      'เข้าบัญชี', 'บัญชีผู้รับ', 'to', 'to:', 'receiver', 'beneficiary', 'payee',
      'recipient',
    ];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      for (final kw in recipientKeywords) {
        if (line.toLowerCase().startsWith(kw.toLowerCase())) {
          final remainder = line.substring(kw.length).replaceAll(RegExp(r'^[:\s]+'), '').trim();
          if (remainder.isNotEmpty && !_isAccountNumber(remainder) && !_isKeyword(remainder)) {
            return _cleanName(remainder);
          }
          // If remainder is empty or keyword, check next line
          if (i + 1 < lines.length) {
            final nextLine = lines[i + 1];
            if (!_isKeyword(nextLine) && !_isAccountNumber(nextLine)) {
              return _cleanName(nextLine);
            }
          }
        }
      }
    }

    // Secondary strategy: Collect all person/company name lines
    final List<String> candidateNames = [];
    for (final line in lines) {
      if (line.contains('บจก.') || line.contains('บริษัท') || line.contains('หจก.') ||
          line.contains('นาย ') || line.contains('นาย') ||
          line.contains('นาง ') || line.contains('นาง') ||
          line.contains('น.ส.') || line.contains('น.ส. ') ||
          line.contains('Mr.') || line.contains('Ms.') || line.contains('Mrs.')) {
        if (!_isKeyword(line) && !_isAccountNumber(line)) {
          candidateNames.add(_cleanName(line));
        }
      }
    }

    // In slips without labels (e.g. TrueMoney, MAKE by KBank):
    // First candidate is typically Sender, Second candidate is Recipient!
    if (candidateNames.length >= 2) {
      return candidateNames[1];
    } else if (candidateNames.length == 1) {
      return candidateNames[0];
    }

    // Third strategy: Find PromptPay/account destination number
    for (final line in lines) {
      final phoneMatch = RegExp(r'(0\d{2}[-\s]*\d{3}[-\s]*\d{4}|0\d{2}[-\s]*x{3}[-\s]*\d{4}|x{3}[-\s]*\d{4})', caseSensitive: false).firstMatch(line);
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
      if (category.id == 'cat_transfer' || category.id == 'cat_other_expense') continue;
      for (final kw in category.autoKeywords) {
        if (combined.contains(kw.toLowerCase())) {
          return category.id;
        }
      }
    }

    // 2. Default for P2P bank transfers, PromptPay, or individual transfers:
    // When no specific shopping/food keyword is matched, assign to Transfer!
    return 'cat_transfer';
  }

  static bool _isAccountNumber(String text) {
    return RegExp(r'^x{2,}[-\s\d]+|^[\d\-]{8,}$', caseSensitive: false).hasMatch(text.trim());
  }

  static bool _isKeyword(String text) {
    final lower = text.toLowerCase();
    return lower.contains('จำนวน') || lower.contains('amount') || lower.contains('วันที่') || lower.contains('date') || lower.contains('ค่าธรรมเนียม');
  }

  static String _cleanName(String raw) {
    return raw
        .replaceAll(RegExp(r'^(?:to|จาก|ไปยัง|ไปที่|โอนไป|โอนให้|ผู้รับโอน|ผู้รับ|ผู้โอน|ชื่อ|recipient|beneficiary|payee)[:\s]*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }
}
