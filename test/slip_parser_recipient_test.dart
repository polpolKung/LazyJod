import 'package:flutter_test/flutter_test.dart';
import 'package:lazy_jod/features/ingestion/services/thai_bank_slip_parser.dart';

/// Simulated OCR text based on actual slip images in test_slips/
/// These mirror what ML Kit Text Recognition returns from real slips.
void main() {
  group('ThaiBankSlipParser — Recipient Extraction', () {

    // ── KTB NEXT (ไปยัง pattern) ─────────────────────────────────────────
    test('KTB: extracts "น.ส. รณิดา ชินอ่อน" via ไปยัง keyword', () {
      const ocr = '''
Krungthai กรุงไทย
โอนเงินสำเร็จ
รหัสอ้างอิง Aaa86ab443fa54854
จาก
นายญานพล ท***
กรุงไทย
XXX-X-XX700-9
ไปยัง
น.ส. รณิดา ชินอ่อน
พร้อมเพย์
XXX XXX 5844
จำนวนเงิน 200.00 บาท
ค่าธรรมเนียม 0.00 บาท
วันที่ทำรายการ 30 เม.ย. 2568 - 13:32
''';
      final result = ThaiBankSlipParser.parse(ocr);
      print('[KTB-1] recipient="${result.recipientName}" amount=${result.amount}');
      expect(result.recipientName, contains('รณิดา'));
      expect(result.amount, equals(200.0));
    });

    test('KTB: extracts "นาย ญานพล ทิพวัน" via ไปยัง keyword', () {
      const ocr = '''
Krungthai กรุงไทย
โอนเงินสำเร็จ
รหัสอ้างอิง Aa428dfec5b7e46c5
จาก
นายญานพล ท***
กรุงไทย
XXX-X-XX700-9
ไปยัง
นาย ญานพล ทิพวัน
พร้อมเพย์
XXX-XXXXXXXX-2635
จำนวนเงิน 645.00 บาท
ค่าธรรมเนียม 0.00 บาท
วันที่ทำรายการ 19 ก.ย. 2569 - 16:01
''';
      final result = ThaiBankSlipParser.parse(ocr);
      print('[KTB-2] recipient="${result.recipientName}" amount=${result.amount}');
      expect(result.recipientName, contains('ทิพวัน'));
      expect(result.amount, equals(645.0));
    });

    test('KTB: extracts "น.ส. ละเมียด ฝอยทอง" via ไปยัง keyword', () {
      const ocr = '''
Krungthai กรุงไทย
โอนเงินสำเร็จ
รหัสอ้างอิง A98d43f567930454b
จาก
นายญานพล ท***
กรุงไทย
XXX-X-XX700-9
ไปยัง
น.ส. ละเมียด ฝอยทอง
พร้อมเพย์
XXX XXX 5095
จำนวนเงิน 5.00 บาท
ค่าธรรมเนียม 0.00 บาท
วันที่ทำรายการ 30 เม.ย. 2568 - 17:34
''';
      final result = ThaiBankSlipParser.parse(ocr);
      print('[KTB-3] recipient="${result.recipientName}" amount=${result.amount}');
      expect(result.recipientName, contains('ละเมียด'));
      expect(result.amount, equals(5.0));
    });

    // ── Bangkok Bank (ไปที่ pattern) ──────────────────────────────────────
    test('BBL: extracts "นายญานพล ทิพวัน" via ไปที่ keyword', () {
      const ocr = '''
Bangkok Bank
รายการสำเร็จ
18 มี.ค. 68, 19:53
จำนวนเงิน
500.00 THB
จาก
นาย ญานพล
037-7-xxx889
ธนาคารกรุงเทพ
ไปที่
นายญานพล ทิพวัน
063-xxx-9986
พร้อมเพย์
ค่าธรรมเนียม 0.00 THB
หมายเลขอ้างอิง
320892
เลขที่อ้างอิง
20250318195317240033
''';
      final result = ThaiBankSlipParser.parse(ocr);
      print('[BBL-1] recipient="${result.recipientName}" amount=${result.amount}');
      expect(result.recipientName, contains('ทิพวัน'));
      expect(result.amount, equals(500.0));
    });

    // ── PaoTang / คนละครึ่ง ───────────────────────────────────────────────
    test('PaoTang: extracts merchant "ร้านขนมครกคุณทิพย์" and user-paid amount 150', () {
      const ocr = '''
ทำรายการสำเร็จ
รหัสอ้างอิง bfd1aba201fc4be3bc23e546152afc63
19 เม.ย. 2565 15:50 น.
ญานพล ทิพวัน
G-Wallet ID: **** ******** 5356
ร้านขนมครกคุณทิพย์
อาหาร ของหวาน เครื่องดื่ม
ค่าสินค้า/บริการ 300 บาท
สิทธิคนละครึ่ง -150 บาท
จำนวนเงินที่ชำระ 150 บาท
''';
      final result = ThaiBankSlipParser.parse(ocr);
      print('[PaoTang-1] recipient="${result.recipientName}" amount=${result.amount}');
      expect(result.recipientName, contains('ขนมครก'));
      expect(result.amount, equals(150.0));
    });

    test('PaoTang: ไทยช่วยไทย — records user-paid 133.20 not subsidy 199.80', () {
      const ocr = '''
ทำรายการสำเร็จ
รหัสอ้างอิง 72bcc275b89349b19f6c9debb5727d22
1 ก.ย. 2569 15:39 น.
ญานพล ท***
G-Wallet ID: **** ******* 5356
มุษบา
อาหาร ของหวาน เครื่องดื่ม
ค่าสินค้า/บริการ 333 บาท
สิทธิไทยช่วยไทยพลัส -199.80 บาท
จำนวนเงินที่ชำระ 133.20 บาท
''';
      final result = ThaiBankSlipParser.parse(ocr);
      print('[PaoTang-2] recipient="${result.recipientName}" amount=${result.amount}');
      expect(result.recipientName, contains('มุษบา'));
      expect(result.amount, closeTo(133.20, 0.01));
    });

    // ── TrueMoney (sender = receiver, same person) ────────────────────────
    test('TrueMoney: top-up to self — should NOT produce garbled name', () {
      const ocr = '''
truemoney
฿19.00
นาย ญานพล ทิพวัน
KKP Start Saving
XXX-XXX430-6
นาย ญานพล ทิพวัน
ทรูมันนี่ วอลเล็ท
063-XXX-9986
จำนวนเงิน ฿19.00
ค่าธรรมเนียม ฿0.00
วันที่ทำรายการ 11 เม.ย. 67 12:57:19
เลขที่อ้างอิง 50029240267233
''';
      final result = ThaiBankSlipParser.parse(ocr);
      print('[TrueMoney-1] recipient="${result.recipientName}" amount=${result.amount}');
      expect(result.recipientName, isNot(equals('โอนเงิน')));
      expect(result.amount, equals(19.0));
      final name = result.recipientName;
      final allLowerLatin = RegExp(r'^[a-z]+$').hasMatch(name);
      expect(allLowerLatin, isFalse, reason: 'Name should not be all-lowercase garbled OCR');
    });

    // ── OCR Noise Rejection ───────────────────────────────────────────────
    test('Rejects OCR noise: nsolna, nsulna, UUUN', () {
      const ocr = '''
Krungthai กรุงไทย
โอนเงินสำเร็จ
nsolna
nsulna
UUUN
ไปยัง
น.ส. สมใจ รักดี
พร้อมเพย์
XXX XXX 1234
จำนวนเงิน 100.00 บาท
''';
      final result = ThaiBankSlipParser.parse(ocr);
      print('[NoiseRejection] recipient="${result.recipientName}"');
      expect(result.recipientName, isNot(equals('nsolna')));
      expect(result.recipientName, isNot(equals('nsulna')));
      expect(result.recipientName, isNot(equals('UUUN')));
      expect(result.recipientName, contains('สมใจ'));
    });

    // ── Thai prefix variants ──────────────────────────────────────────────
    test('Handles "น.ส." prefix correctly', () {
      const ocr = '''
KTB
ไปยัง
น.ส. สุดา ชมสวน
พร้อมเพย์
XXX XXX 9999
จำนวนเงิน 50.00 บาท
''';
      final result = ThaiBankSlipParser.parse(ocr);
      print('[Prefix-ns] recipient="${result.recipientName}"');
      expect(result.recipientName, contains('สุดา'));
    });

    // ── KTB Garbled OCR on device ─────────────────────────────────────────
    test('KTB Garbled OCR: rejects Krungthai, Pay, UNa nUwa nwu — falls back to promptpay account', () {
      const ocr = '''
Krungthai
Aaa86ab443fa54854
XXX-X-XX700-9
UNa nUwa nwu
Pay
XXX-XXXXXXXX-2635
645.00 บาท
''';
      final result = ThaiBankSlipParser.parse(ocr);
      print('[KTB-Garbled] recipient="${result.recipientName}" amount=${result.amount}');
      expect(result.recipientName, isNot(equals('Krungthai')));
      expect(result.recipientName, isNot(equals('Pay')));
      expect(result.recipientName, isNot(equals('UNa nUwa nwu')));
      expect(result.recipientName, contains('2635'));
      expect(result.amount, equals(645.0));
    });
  });
}
