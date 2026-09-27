import '../../categories/models/category_model.dart';
import '../models/slip_parse_result.dart';
import '../models/thai_bank.dart';
import '../models/thai_qr_parse_result.dart';
import 'emv_tlv.dart';

/// Parses Thai bank slip QR / barcode payloads (no native plugins).
///
/// Supported envelopes:
///  - EMVCo Thai QR Payment (`000201…`, PromptPay AID `A000000677010111`)
///  - BOT slip-verify Mini-QR (tag 00 marker `000001`, CRC tag 91)
///  - TrueMoney slip-verify Mini-QR
///  - BOT bill-payment barcode (`|biller\rref1\rref2\ramount`)
///  - HTTP(S) verification URLs with `ref` / `amount` query params
///  - EMV / Mini-QR strings recovered from OCR text
class ThaiQrSlipParser {
  ThaiQrSlipParser._();

  static const promptPayAid = 'A000000677010111';
  static const billPaymentAid = 'A000000677010112';
  static const creditTransferAid = 'A000000677010114';

  static ThaiQrParseResult? parse(String payload) {
    final trimmed = payload.trim();
    if (trimmed.isEmpty) return null;

    return _parseBotBarcode(trimmed) ??
        _parseUrl(trimmed) ??
        _parseTrueMoneySlipVerify(trimmed) ??
        _parseSlipVerify(trimmed) ??
        _parseEmvPayment(trimmed);
  }

  /// Picks the richest of several payloads (image may contain payment + mini QR).
  static ThaiQrParseResult? parseBest(Iterable<String> payloads) {
    ThaiQrParseResult? best;
    for (final raw in payloads) {
      final parsed = parse(raw);
      if (parsed == null) continue;
      if (best == null || parsed.score > best.score) {
        best = parsed;
      }
    }
    return best;
  }

  /// Recovers QR payloads that OCR printed as digits / pipes instead of scanning.
  static List<String> extractPayloadsFromText(String text) {
    if (text.isEmpty) return const [];
    final compact = text.replaceAll(RegExp(r'\s+'), '');
    final found = <String>{};

    for (final match in RegExp(r'000201[0-9A-Za-z.+/=_-]{20,500}6304[0-9A-Fa-f]{4}')
        .allMatches(compact)) {
      found.add(match.group(0)!);
    }
    for (final match in RegExp(r'00\d{2}000001[0-9A-Za-z]{8,200}(?:5102TH)?9104[0-9A-Fa-f]{1,4}')
        .allMatches(compact)) {
      found.add(match.group(0)!);
    }
    for (final match in RegExp(r'\|[0-9]{10,15}').allMatches(compact)) {
      found.add(match.group(0)!);
    }
    if (compact.startsWith('|') && compact.length > 12) {
      found.add(text.trim());
    }
    return found.toList();
  }

  /// QR fields win for amount / ref / bank / time; OCR keeps human names.
  static SlipParseResult mergeWithOcr({
    required SlipParseResult ocr,
    required ThaiQrParseResult qr,
  }) {
    final qrAmount = qr.amount ?? 0;
    final amount = qrAmount > 0 ? qrAmount : ocr.amount;
    final bank = qr.bank != ThaiBank.unknown ? qr.bank : ocr.bank;
    final refId = (qr.refId != null && qr.refId!.isNotEmpty) ? qr.refId : ocr.refId;
    final dateTime = qr.dateTime ?? ocr.dateTime;

    final ocrFallback = _isFallbackName(ocr.recipientName);
    final qrName = qr.recipientName?.trim() ?? '';
    final recipient = (!ocrFallback && ocr.recipientName.isNotEmpty)
        ? ocr.recipientName
        : (qrName.isNotEmpty ? qrName : ocr.recipientName);

    var suggested = ocr.suggestedCategoryId ?? 'cat_uncategorized';
    if (suggested == 'cat_uncategorized') {
      suggested = _suggestCategory(recipient, ocr.rawOcrText);
    }

    var score = ocr.confidenceScore;
    if (qrAmount > 0) score += 0.25;
    if (refId != null && refId.isNotEmpty) score += 0.1;
    if (qr.kind == ThaiQrKind.slipVerify || qr.kind == ThaiQrKind.payment) {
      score += 0.05;
    }

    return ocr.copyWith(
      bank: bank,
      amount: amount,
      dateTime: dateTime,
      recipientName: recipient,
      senderName: ocr.senderName ?? qr.senderName,
      refId: refId,
      suggestedCategoryId: suggested,
      confidenceScore: score.clamp(0.0, 1.0),
      qrPayload: qr.rawPayload,
    );
  }

  // ── Envelope parsers ──────────────────────────────────────────────────────

  static ThaiQrParseResult? _parseEmvPayment(String payload) {
    if (!payload.startsWith('000201')) return null;
    final tags = EmvTlv.decode(payload);
    if (tags.isEmpty) return null;

    final amount = _parseAmount(EmvTlv.valueOf(tags, '54'));
    final merchantName = EmvTlv.valueOf(tags, '59')?.trim();
    final additional = EmvTlv.nested(tags, '62');
    final billNo = EmvTlv.valueOf(additional, '01');
    final ref = EmvTlv.valueOf(additional, '05') ?? billNo;

    String? proxyId;
    String? billerLabel;
    ThaiBank bank = ThaiBank.unknown;

    for (final maiId in ['29', '30', '31']) {
      final nested = EmvTlv.nested(tags, maiId);
      if (nested.isEmpty) continue;
      final aid = (EmvTlv.valueOf(nested, '00') ?? '').toUpperCase();
      if (aid.contains(promptPayAid) ||
          aid.contains(billPaymentAid) ||
          aid.contains(creditTransferAid)) {
        bank = ThaiBank.promptPay;
        proxyId = EmvTlv.valueOf(nested, '01') ??
            EmvTlv.valueOf(nested, '02') ??
            EmvTlv.valueOf(nested, '03');
        if (aid.contains(billPaymentAid)) {
          billerLabel = _formatBiller(
            EmvTlv.valueOf(nested, '01'),
            EmvTlv.valueOf(nested, '02'),
          );
        }
      }
    }

    final recipient = (merchantName != null && merchantName.isNotEmpty)
        ? merchantName
        : (billerLabel ?? _formatPromptPayProxy(proxyId));

    var score = 0;
    if (amount != null && amount > 0) score += 3;
    if (ref != null && ref.isNotEmpty) score += 2;
    if (recipient != null && recipient.isNotEmpty) score += 2;
    if (bank != ThaiBank.unknown) score += 1;
    if (score == 0) return null;

    return ThaiQrParseResult(
      kind: ThaiQrKind.payment,
      bank: bank,
      amount: amount,
      recipientName: recipient,
      refId: ref,
      rawPayload: payload,
      score: score,
    );
  }

  static ThaiQrParseResult? _parseSlipVerify(String payload) {
    var wire = payload;
    final crcIdx = wire.lastIndexOf('9104');
    if (crcIdx != -1) {
      final crc = wire.substring(crcIdx + 4);
      if (crc.isNotEmpty && crc.length < 4) {
        wire = wire.substring(0, crcIdx + 4) + crc.padLeft(4, '0');
      }
    }

    final tags = EmvTlv.decode(wire);
    final apiType = EmvTlv.nestedValue(tags, '00', '00');
    final sendingBank = EmvTlv.nestedValue(tags, '00', '01');
    final transRef = EmvTlv.nestedValue(tags, '00', '02');
    if (apiType != '000001' || sendingBank.isEmpty || transRef.isEmpty) {
      return null;
    }

    final bank = ThaiBank.fromBankCode(sendingBank);
    final dateTime = _dateTimeFromRef(transRef);
    var score = 3; // bank + ref is already useful for dedupe
    if (dateTime != null) score += 1;

    return ThaiQrParseResult(
      kind: ThaiQrKind.slipVerify,
      bank: bank == ThaiBank.unknown ? ThaiBank.promptPay : bank,
      dateTime: dateTime,
      refId: transRef,
      rawPayload: payload,
      score: score,
    );
  }

  static ThaiQrParseResult? _parseTrueMoneySlipVerify(String payload) {
    final tags = EmvTlv.decode(payload);
    final markerA = EmvTlv.nestedValue(tags, '00', '00');
    final markerB = EmvTlv.nestedValue(tags, '00', '01');
    if (markerA != '01' || markerB != '01') return null;

    final nested = EmvTlv.nested(tags, '00');
    final eventType = EmvTlv.valueOf(nested, '02');
    final txnId = EmvTlv.valueOf(nested, '03');
    final dateRaw = EmvTlv.valueOf(nested, '04');
    if (txnId == null || txnId.isEmpty) return null;

    return ThaiQrParseResult(
      kind: ThaiQrKind.trueMoneySlipVerify,
      bank: ThaiBank.trueMoney,
      dateTime: _parseDdmmyyyy(dateRaw),
      refId: txnId,
      recipientName: eventType == 'P2P' ? null : eventType,
      rawPayload: payload,
      score: 3 + (dateRaw != null ? 1 : 0),
    );
  }

  static ThaiQrParseResult? _parseBotBarcode(String payload) {
    if (!payload.startsWith('|')) return null;
    final body = payload.substring(1);
    final parts = body.split(RegExp(r'\r|\n'));
    if (parts.length < 4) return null;

    final billerId = parts[0].trim();
    final ref1 = parts[1].trim();
    final ref2 = parts[2].trim();
    final amountRaw = parts[3].trim();
    if (billerId.isEmpty || ref1.isEmpty) return null;

    double? amount;
    if (amountRaw.isNotEmpty && amountRaw != '0') {
      final satang = int.tryParse(amountRaw);
      if (satang != null) amount = satang / 100.0;
    }

    return ThaiQrParseResult(
      kind: ThaiQrKind.botBarcode,
      bank: ThaiBank.promptPay,
      amount: amount,
      recipientName: _formatBiller(billerId, ref1),
      refId: ref2.isNotEmpty ? ref2 : ref1,
      rawPayload: payload,
      score: 2 + (amount != null ? 3 : 0),
    );
  }

  static ThaiQrParseResult? _parseUrl(String payload) {
    final uri = Uri.tryParse(payload);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return null;
    }
    final params = uri.queryParameters;
    final ref = params['ref'] ??
        params['transRef'] ??
        params['reference'] ??
        params['txn'] ??
        params['id'];
    final amount = _parseAmount(params['amount'] ?? params['amt']);
    if ((ref == null || ref.isEmpty) && amount == null) return null;

    return ThaiQrParseResult(
      kind: ThaiQrKind.url,
      amount: amount,
      refId: ref,
      rawPayload: payload,
      score: (ref != null && ref.isNotEmpty ? 2 : 0) + (amount != null ? 3 : 0),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static double? _parseAmount(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = double.tryParse(raw.replaceAll(',', ''));
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  static DateTime? _dateTimeFromRef(String ref) {
    final digits = ref.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 14 && digits.startsWith('20')) {
      return _tryDate(
        int.parse(digits.substring(0, 4)),
        int.parse(digits.substring(4, 6)),
        int.parse(digits.substring(6, 8)),
        int.parse(digits.substring(8, 10)),
        int.parse(digits.substring(10, 12)),
        int.parse(digits.substring(12, 14)),
      );
    }
    if (digits.length >= 12 && digits.startsWith('20')) {
      return _tryDate(
        int.parse(digits.substring(0, 4)),
        int.parse(digits.substring(4, 6)),
        int.parse(digits.substring(6, 8)),
        int.parse(digits.substring(8, 10)),
        int.parse(digits.substring(10, 12)),
        0,
      );
    }
    return null;
  }

  static DateTime? _parseDdmmyyyy(String? raw) {
    if (raw == null || raw.length != 8) return null;
    return _tryDate(
      int.tryParse(raw.substring(4, 8)) ?? 0,
      int.tryParse(raw.substring(2, 4)) ?? 0,
      int.tryParse(raw.substring(0, 2)) ?? 0,
      0,
      0,
      0,
    );
  }

  static DateTime? _tryDate(int y, int m, int d, int h, int min, int s) {
    if (y < 2000 || y > 2100 || m < 1 || m > 12 || d < 1 || d > 31) return null;
    if (h > 23 || min > 59 || s > 59) return null;
    return DateTime(y, m, d, h, min, s);
  }

  static String? _formatPromptPayProxy(String? proxy) {
    if (proxy == null || proxy.isEmpty) return null;
    var value = proxy;
    if (value.startsWith('0066') && value.length >= 13) {
      value = '0${value.substring(4)}';
    }
    return 'พร้อมเพย์ $value';
  }

  static String _formatBiller(String? biller, String? ref1) {
    final parts = <String>[];
    if (biller != null && biller.isNotEmpty) parts.add(biller);
    if (ref1 != null && ref1.isNotEmpty) parts.add(ref1);
    return parts.isEmpty ? 'พร้อมเพย์' : 'บิล ${parts.join(' · ')}';
  }

  static bool _isFallbackName(String name) {
    return name.isEmpty ||
        name.startsWith('พร้อมเพย์') ||
        name.startsWith('โอนเงิน') ||
        name.startsWith('บิล ');
  }

  static String _suggestCategory(String recipient, String fullText) {
    final combined = '$recipient $fullText'.toLowerCase();
    for (final category in CategoryModel.defaultCategories) {
      if (category.id == 'cat_transfer' ||
          category.id == 'cat_uncategorized' ||
          category.id == 'cat_other_expense') {
        continue;
      }
      for (final kw in category.autoKeywords) {
        if (combined.contains(kw.toLowerCase())) return category.id;
      }
    }
    return 'cat_uncategorized';
  }
}
