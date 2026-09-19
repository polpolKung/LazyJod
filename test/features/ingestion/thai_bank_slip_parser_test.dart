import 'package:flutter_test/flutter_test.dart';
import 'package:lazy_jod/features/ingestion/models/thai_bank.dart';
import 'package:lazy_jod/features/ingestion/services/thai_bank_slip_parser.dart';

void main() {
  group('ThaiBankSlipParser Tests', () {
    test('1. Should correctly parse KBank (K PLUS) slip', () {
      const kbankSample = '''
      K PLUS
      โอนเงินสำเร็จ
      19 ก.ย. 69 14:35 น.
      จาก นายใจดี รักสงบ
      xxx-x-x1234-x
      ไปยัง น.ส.สมศรี มีสุข
      xxx-x-x5678-x
      จำนวนเงิน: 1,550.00 บาท
      ค่าธรรมเนียม: 0.00 บาท
      รหัสอ้างอิง: 2026091914350012
      ''';

      final result = ThaiBankSlipParser.parse(kbankSample);

      expect(result.bank, equals(ThaiBank.kbank));
      expect(result.amount, equals(1550.00));
      expect(result.dateTime.day, equals(19));
      expect(result.dateTime.month, equals(9));
      expect(result.dateTime.year, equals(2026));
      expect(result.dateTime.hour, equals(14));
      expect(result.dateTime.minute, equals(35));
      expect(result.recipientName, contains('สมศรี มีสุข'));
      expect(result.senderName, contains('ใจดี รักสงบ'));
      expect(result.refId, equals('2026091914350012'));
    });

    test('2. Should correctly parse SCB EASY slip', () {
      const scbSample = '''
      SCB EASY
      โอนเงินสำเร็จ
      วันที่ทำรายการ: 15/09/2026 - 19:20
      จาก: นายเอกชัย ชัยชนะ
      ไปยัง: บจก. ลาซาด้า (ประเทศไทย)
      จำนวนเงิน: ฿ 890.50
      เลขที่รายการ: 0142621934981
      ''';

      final result = ThaiBankSlipParser.parse(scbSample);

      expect(result.bank, equals(ThaiBank.scb));
      expect(result.amount, equals(890.50));
      expect(result.recipientName, contains('ลาซาด้า'));
      expect(result.refId, equals('0142621934981'));
      expect(result.suggestedCategoryId, equals('cat_shopping'));
    });

    test('3. Should correctly parse Krungthai NEXT slip', () {
      const ktbSample = '''
      Krungthai NEXT
      โอนเงินสำเร็จ
      10 ก.ย. 2569 08:15 น.
      ไปยัง: นายสมพงษ์ ข้าวมันไก่
      จำนวนเงิน: 65.00 บาท
      รหัสอ้างอิง: KTB202609100099
      ''';

      final result = ThaiBankSlipParser.parse(ktbSample);

      expect(result.bank, equals(ThaiBank.ktb));
      expect(result.amount, equals(65.00));
      expect(result.recipientName, contains('ข้าวมันไก่'));
      expect(result.suggestedCategoryId, equals('cat_food'));
    });

    test('4. Should correctly parse ttb touch slip', () {
      const ttbSample = '''
      ttb touch
      โอนเงินสำเร็จ
      05 ก.ย. 69 12:00 น.
      ไปยัง: การไฟฟ้านครหลวง
      จำนวนเงิน 1,240.00 THB
      รหัสอ้างอิง: TTB8899776655
      ''';

      final result = ThaiBankSlipParser.parse(ttbSample);

      expect(result.bank, equals(ThaiBank.ttb));
      expect(result.amount, equals(1240.00));
      expect(result.recipientName, contains('การไฟฟ้านครหลวง'));
      expect(result.suggestedCategoryId, equals('cat_bills'));
    });

    test('5. Should correctly parse Bangkok Bank (BBL) slip', () {
      const bblSample = '''
      Bangkok Bank
      รายการโอนเงินสำเร็จ
      วันที่ 01 ก.ย. 2569 เวลา 18:30:10
      ไปยัง: นายวิชัย ขับแท็กซี่
      จำนวน: 150.00 บาท
      เลขที่รายการ: BBL1122334455
      ''';

      final result = ThaiBankSlipParser.parse(bblSample);

      expect(result.bank, equals(ThaiBank.bbl));
      expect(result.amount, equals(150.00));
      expect(result.recipientName, contains('วิชัย ขับแท็กซี่'));
      expect(result.suggestedCategoryId, equals('cat_transport'));
    });

    test('6. Should correctly parse GSB (MyMo) slip', () {
      const gsbSample = '''
      MyMo by GSB
      โอนเงินสำเร็จ
      วันที่ 25 ส.ค. 2569 09:40 น.
      ไปยัง: นิติบุคคล อาคารชุด เดอะเบสท์
      จำนวนเงิน: 2,500.00 บาท
      รหัสอ้างอิง: GSB99887766
      ''';

      final result = ThaiBankSlipParser.parse(gsbSample);

      expect(result.bank, equals(ThaiBank.gsb));
      expect(result.amount, equals(2500.00));
      expect(result.suggestedCategoryId, equals('cat_housing'));
    });

    test('7. Should correctly parse Bank of Ayudhya (BAY / KMA) slip', () {
      const baySample = '''
      Krungsri KMA
      โอนเงินสำเร็จ
      20 ส.ค. 69 15:00 น.
      ไปยัง: สัตวแพทย์ รักษ์สัตว์
      จำนวนเงิน: 850.00 บาท
      รหัสอ้างอิง: BAY55443322
      ''';

      final result = ThaiBankSlipParser.parse(baySample);

      expect(result.bank, equals(ThaiBank.bay));
      expect(result.amount, equals(850.00));
      expect(result.suggestedCategoryId, equals('cat_pets'));
    });

    test('8. Should correctly parse TrueMoney Wallet slip', () {
      const trueMoneySample = '''
      TrueMoney Wallet
      ชำระเงินสำเร็จ
      18 ก.ย. 2569 20:10 น.
      ไปยัง: เซเว่น อีเลฟเว่น (7-Eleven)
      จำนวนเงิน: 189.00 บาท
      รหัสอ้างอิง: TM883719203
      ''';

      final result = ThaiBankSlipParser.parse(trueMoneySample);

      expect(result.bank, equals(ThaiBank.trueMoney));
      expect(result.amount, equals(189.00));
      expect(result.recipientName, contains('เซเว่น'));
      expect(result.suggestedCategoryId, equals('cat_food'));
    });

    test('9. Should correctly parse PromptPay QR payment slip', () {
      const promptPaySample = '''
      Thai QR Payment พร้อมเพย์
      โอนเงินสำเร็จ
      วันที่ 12 ก.ย. 2569 11:45 น.
      ผู้รับโอน: ร้านกาแฟ บ้านเพื่อน Cafe & Bakery
      จำนวนเงิน: 120.00 บาท
      รหัสอ้างอิง: 20260912998877
      ''';

      final result = ThaiBankSlipParser.parse(promptPaySample);

      expect(result.bank, equals(ThaiBank.promptPay));
      expect(result.amount, equals(120.00));
      expect(result.recipientName, contains('กาแฟ'));
      expect(result.suggestedCategoryId, equals('cat_food'));
    });

    test('10. Should detect all 16 Thai banks keywords correctly', () {
      for (final bank in ThaiBank.values) {
        if (bank == ThaiBank.unknown) continue;
        final sampleText = 'ชำระเงินผ่าน ${bank.detectionKeywords.first} ยอดเงิน 100.00 บาท';
        final detected = ThaiBankSlipParser.detectBank(sampleText);
        expect(detected, equals(bank));
      }
    });
  });
}
