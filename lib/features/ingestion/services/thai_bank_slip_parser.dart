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
    if (recipient.isNotEmpty && recipient != 'ไม่ระบุ') score += 0.15;
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

    // Heuristics for standard PromptPay QR transfer slip
    if (lower.contains('พร้อมเพย์') || lower.contains('promptpay') || lower.contains('thai qr')) {
      return ThaiBank.promptPay;
    }

    return ThaiBank.unknown;
  }

  /// 2. Extract Transfer Amount in THB
  static double extractAmount(String text, {ThaiBank? bank}) {
    // Patterns with explicit labels
    final labeledPatterns = [
      // จำนวนเงิน / จำนวนเงิน (บาท) / ยอดเงิน
      RegExp(r'(?:จำนวนเงิน|ยอดเงิน|ยอดเงินรวม|จำนวน|amount|total amount)\s*[:\s]?\s*(?:thb|฿|baht)?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?)', caseSensitive: false),
      // ฿ 1,250.00 or THB 1,250.00
      RegExp(r'(?:thb|฿)\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?)', caseSensitive: false),
      // 1,250.00 บาท / 1250.00 THB
      RegExp(r'([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2}))\s*(?:บาท|thb|baht)', caseSensitive: false),
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
      // Skip numbers that look like account balances or fees if clearly identified
      if (parsed != null && parsed > 0 && parsed < 10000000) {
        return parsed;
      }
    }

    return 0.0;
  }

  /// 3. Extract Slip Date and Time
  static DateTime? extractDateTime(String text) {
    // Check for Time (HH:mm or HH:mm:ss)
    final timeRegex = RegExp(r'(?:เวลา|time)?\s*([0-2]?[0-9])[:.]([0-5][0-9])(?::([0-5][0-9]))?\s*(?:น\.|hrs\.|hr)?', caseSensitive: false);
    final timeMatch = timeRegex.firstMatch(text);
    int hour = 12;
    int minute = 0;
    int second = 0;

    if (timeMatch != null) {
      hour = int.tryParse(timeMatch.group(1)!) ?? 12;
      minute = int.tryParse(timeMatch.group(2)!) ?? 0;
      if (timeMatch.group(3) != null) {
        second = int.tryParse(timeMatch.group(3)!) ?? 0;
      }
    }

    // Check for Date
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

    // Fallback: If no date found in text, return current DateTime
    return null;
  }

  /// 4. Extract Recipient / Merchant Name
  static String extractRecipient(String text, {ThaiBank? bank}) {
    final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    // Priority keywords indicating recipient
    final recipientKeywords = [
      'ไปยัง', 'ไปยัง:', 'to', 'to:', 'ผู้รับเงิน', 'ชื่อผู้รับ',
      'เข้าบัญชี', 'บัญชีผู้รับ', 'receiver', 'beneficiary'
    ];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      for (final kw in recipientKeywords) {
        if (line.toLowerCase().startsWith(kw.toLowerCase())) {
          // Check if name is on the same line
          final remainder = line.substring(kw.length).replaceAll(RegExp(r'^[:\s]+'), '').trim();
          if (remainder.isNotEmpty && !_isAccountNumber(remainder)) {
            return _cleanName(remainder);
          }
          // If not, check the next line
          if (i + 1 < lines.length) {
            final nextLine = lines[i + 1];
            if (!_isKeyword(nextLine) && !_isAccountNumber(nextLine)) {
              return _cleanName(nextLine);
            }
          }
        }
      }
    }

    // Bank-specific fallback for promptpay/qr slips
    for (final line in lines) {
      if (line.contains('บจก.') || line.contains('บริษัท') || line.contains('หจก.') ||
          line.contains('นาย ') || line.contains('นาง ') || line.contains('น.ส.') ||
          line.contains('Mr.') || line.contains('Ms.') || line.contains('Mrs.')) {
        return _cleanName(line);
      }
    }

    return 'ไม่ระบุผู้รับ';
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
      RegExp(r'(?:รหัสอ้างอิง|เลขที่รายการ|เลขอ้างอิง|ref(?:\s*no\.?)?|transaction\s*id)\s*[:\s]?\s*([A-Za-z0-9\-_]{8,30})', caseSensitive: false),
      // Format common in KBank/SCB slips: e.g. 20260919456789 or 0142621934981
      RegExp(r'(?<!\d)([0-9]{12,24})(?!\d)'),
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

    for (final category in CategoryModel.defaultCategories) {
      for (final kw in category.autoKeywords) {
        if (combined.contains(kw.toLowerCase())) {
          return category.id;
        }
      }
    }

    // Default fallback
    return 'cat_food'; // Most frequent daily expense
  }

  static bool _isAccountNumber(String text) {
    return RegExp(r'^x{2,}[-\s\d]+|^[\d\-]{8,}$', caseSensitive: false).hasMatch(text.trim());
  }

  static bool _isKeyword(String text) {
    final lower = text.toLowerCase();
    return lower.contains('จำนวน') || lower.contains('amount') || lower.contains('วันที่') || lower.contains('date');
  }

  static String _cleanName(String raw) {
    return raw
        .replaceAll(RegExp(r'^(?:to|จาก|ไปยัง|ผู้รับ|ผู้โอน|ชื่อ)[:\s]*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }
}
