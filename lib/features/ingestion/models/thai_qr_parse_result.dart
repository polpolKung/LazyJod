import 'thai_bank.dart';

enum ThaiQrKind {
  payment,
  slipVerify,
  trueMoneySlipVerify,
  botBarcode,
  url,
  unknown,
}

/// Structured fields decoded from a Thai bank slip QR / barcode payload.
class ThaiQrParseResult {
  final ThaiQrKind kind;
  final ThaiBank bank;
  final double? amount;
  final DateTime? dateTime;
  final String? recipientName;
  final String? senderName;
  final String? refId;
  final String rawPayload;
  final int score;

  const ThaiQrParseResult({
    required this.kind,
    this.bank = ThaiBank.unknown,
    this.amount,
    this.dateTime,
    this.recipientName,
    this.senderName,
    this.refId,
    required this.rawPayload,
    this.score = 0,
  });

  bool get isUseful => score > 0;
}
