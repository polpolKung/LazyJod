import 'package:flutter_test/flutter_test.dart';
import 'package:lazy_jod/features/ingestion/models/slip_parse_result.dart';
import 'package:lazy_jod/features/ingestion/models/thai_bank.dart';
import 'package:lazy_jod/features/ingestion/models/thai_qr_parse_result.dart';
import 'package:lazy_jod/features/ingestion/services/emv_tlv.dart';
import 'package:lazy_jod/features/ingestion/services/thai_bank_slip_parser.dart';
import 'package:lazy_jod/features/ingestion/services/thai_qr_slip_parser.dart';

void main() {
  group('EmvTlv', () {
    test('round-trips tags and CRC-16', () {
      final encoded = EmvTlv.encode(const [
        EmvTag('00', '01'),
        EmvTag('54', '120.00'),
      ]);
      expect(encoded, equals('0002015406120.00'));

      final withCrc = EmvTlv.withCrc(encoded, '63');
      expect(EmvTlv.validateCrc(withCrc, crcTagId: '63'), isTrue);
      expect(EmvTlv.valueOf(EmvTlv.decode(encoded), '54'), equals('120.00'));
    });
  });

  group('ThaiQrSlipParser', () {
    test('parses PromptPay EMV payment QR (amount, merchant, phone)', () {
      final tag29 = EmvTlv.encode(const [
        EmvTag('00', ThaiQrSlipParser.promptPayAid),
        EmvTag('01', '0066812345678'),
      ]);
      final payload = EmvTlv.withCrc(
        EmvTlv.encode([
          const EmvTag('00', '01'),
          const EmvTag('01', '12'),
          EmvTag('29', tag29),
          const EmvTag('53', '764'),
          const EmvTag('54', '1550.00'),
          const EmvTag('58', 'TH'),
          const EmvTag('59', 'Cafe House'),
        ]),
        '63',
      );

      final result = ThaiQrSlipParser.parse(payload);
      expect(result, isNotNull);
      expect(result!.kind, ThaiQrKind.payment);
      expect(result.amount, 1550.00);
      expect(result.recipientName, 'Cafe House');
      expect(result.bank, ThaiBank.promptPay);
    });

    test('parses BOT slip-verify Mini-QR (bank + ref + datetime)', () {
      final inner = EmvTlv.encode(const [
        EmvTag('00', '000001'),
        EmvTag('01', '004'),
        EmvTag('02', '2026091914350012'),
      ]);
      final payload = EmvTlv.withCrc(
        EmvTlv.encode([
          EmvTag('00', inner),
          const EmvTag('51', 'TH'),
        ]),
        '91',
      );

      final result = ThaiQrSlipParser.parse(payload);
      expect(result, isNotNull);
      expect(result!.kind, ThaiQrKind.slipVerify);
      expect(result.bank, ThaiBank.kbank);
      expect(result.refId, '2026091914350012');
      expect(result.dateTime, DateTime(2026, 9, 19, 14, 35, 0));
    });

    test('parses published BOT slip-verify example payload', () {
      const wire = '004000060000010103002021900021231231212000115102TH91049C30';
      final result = ThaiQrSlipParser.parse(wire);
      expect(result, isNotNull);
      expect(result!.kind, ThaiQrKind.slipVerify);
      expect(result.bank, ThaiBank.bbl);
      expect(result.refId, '0002123123121200011');
    });

    test('parses TrueMoney slip-verify Mini-QR', () {
      final inner = EmvTlv.encode(const [
        EmvTag('00', '01'),
        EmvTag('01', '01'),
        EmvTag('02', 'P2P'),
        EmvTag('03', 'TXN0001234567'),
        EmvTag('04', '25012026'),
      ]);
      final payload = EmvTlv.withCrc(
        EmvTlv.encode([EmvTag('00', inner)]),
        '91',
        upperCase: false,
      );

      final result = ThaiQrSlipParser.parse(payload);
      expect(result, isNotNull);
      expect(result!.kind, ThaiQrKind.trueMoneySlipVerify);
      expect(result.bank, ThaiBank.trueMoney);
      expect(result.refId, 'TXN0001234567');
      expect(result.dateTime, DateTime(2026, 1, 25));
    });

    test('parses BOT bill barcode with satang amount', () {
      const payload = '|010554000000000\rCUST001\rINV99\r155000';
      final result = ThaiQrSlipParser.parse(payload);
      expect(result, isNotNull);
      expect(result!.kind, ThaiQrKind.botBarcode);
      expect(result.amount, 1550.00);
      expect(result.refId, 'INV99');
    });

    test('parses verification URL query params', () {
      const url =
          'https://confirm.example.bank/slip?ref=SCB998877&amount=890.50';
      final result = ThaiQrSlipParser.parse(url);
      expect(result!.kind, ThaiQrKind.url);
      expect(result.refId, 'SCB998877');
      expect(result.amount, 890.50);
    });

    test('recovers EMV payload from noisy OCR text', () {
      final tag29 = EmvTlv.encode(const [
        EmvTag('00', ThaiQrSlipParser.promptPayAid),
        EmvTag('01', '0066899999999'),
      ]);
      final payload = EmvTlv.withCrc(
        EmvTlv.encode([
          const EmvTag('00', '01'),
          EmvTag('29', tag29),
          const EmvTag('53', '764'),
          const EmvTag('54', '65.00'),
          const EmvTag('58', 'TH'),
        ]),
        '63',
      );
      final ocr = 'โอนเงินสำเร็จ\n${payload.split('').join(' ')}\n65.00 บาท';
      final extracted = ThaiQrSlipParser.extractPayloadsFromText(ocr);
      expect(extracted, isNotEmpty);
      final parsed = ThaiQrSlipParser.parseBest(extracted);
      expect(parsed?.amount, 65.00);
    });

    test('merges QR amount/ref with OCR merchant name', () {
      const ocrText = '''
      K PLUS
      โอนเงินสำเร็จ
      ไปยัง น.ส.สมศรี มีสุข
      จำนวนเงิน: 1.00 บาท
      ''';
      final ocr = ThaiBankSlipParser.parse(ocrText);
      expect(ocr.recipientName, contains('สมศรี'));

      final qr = ThaiQrSlipParser.parse(
        EmvTlv.withCrc(
          EmvTlv.encode(const [
            EmvTag('00', '01'),
            EmvTag('54', '1550.00'),
            EmvTag('62', '05042026'),
          ]),
          '63',
        ),
      )!;

      final merged = ThaiQrSlipParser.mergeWithOcr(ocr: ocr, qr: qr);
      expect(merged.amount, 1550.00);
      expect(merged.recipientName, contains('สมศรี'));
      expect(merged.qrPayload, isNotNull);
      expect(merged.confidenceScore, greaterThan(ocr.confidenceScore));
    });
  });
}
