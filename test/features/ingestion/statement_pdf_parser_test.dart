import 'package:flutter_test/flutter_test.dart';
import 'package:lazy_jod/features/ingestion/services/statement_pdf_parser.dart';

void main() {
  group('StatementPdfParser Tests', () {
    test('1. Should parse regular credit card transaction row', () {
      const sampleStatement = '''
      15/09/2026 16/09/2026 GRABFOOD BANGKOK TH 345.00
      ''';

      final records = StatementPdfParser.parseStatementText(sampleStatement);

      expect(records.length, equals(1));
      expect(records[0].description, contains('GRABFOOD'));
      expect(records[0].amount, equals(345.00));
      expect(records[0].transactionDate.day, equals(15));
      expect(records[0].transactionDate.month, equals(9));
      expect(records[0].isInstallment, isFalse);
      expect(records[0].isCashback, isFalse);
    });

    test('2. Should parse installment transactions (ยอดผ่อนชำระ 0% x เดือน)', () {
      const sampleStatement = '''
      12/09/2026 13/09/2026 APPLE STORE TH 0% 10M (3/10) 2,490.00
      ''';

      final records = StatementPdfParser.parseStatementText(sampleStatement);

      expect(records.length, equals(1));
      expect(records[0].description, contains('APPLE STORE'));
      expect(records[0].amount, equals(2490.00));
      expect(records[0].isInstallment, isTrue);
      expect(records[0].currentInstallmentMonth, equals(3));
      expect(records[0].totalInstallmentMonths, equals(10));
    });

    test('3. Should parse cashback reward entries (เครดิตเงินคืน)', () {
      const sampleStatement = '''
      10/09/2026 10/09/2026 CASHBACK REWARD 1% -120.00 CR
      ''';

      final records = StatementPdfParser.parseStatementText(sampleStatement);

      expect(records.length, equals(1));
      expect(records[0].description, contains('CASHBACK'));
      expect(records[0].amount, equals(120.00));
      expect(records[0].isCashback, isTrue);
    });
  });
}
