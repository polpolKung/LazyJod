import 'package:flutter_test/flutter_test.dart';
import 'package:lazy_jod/features/transactions/services/calculator_engine.dart';

void main() {
  group('CalculatorEngine Tests', () {
    late CalculatorEngine engine;

    setUp(() {
      engine = CalculatorEngine();
    });

    test('1. Should perform simple addition', () {
      engine.appendDigit('1');
      engine.appendDigit('5');
      engine.appendDigit('0');
      engine.appendOperator('+');
      engine.appendDigit('5');
      engine.appendDigit('0');

      final result = engine.evaluate();
      expect(result, equals(200.0));
      expect(engine.expression, equals('200'));
    });

    test('2. Should respect operator precedence (multiplication before addition)', () {
      // 100 + 50 * 2 = 200
      engine.appendDigit('1');
      engine.appendDigit('0');
      engine.appendDigit('0');
      engine.appendOperator('+');
      engine.appendDigit('5');
      engine.appendDigit('0');
      engine.appendOperator('×');
      engine.appendDigit('2');

      final result = engine.evaluate();
      expect(result, equals(200.0));
    });

    test('3. Should handle decimal points and backspace', () {
      engine.appendDigit('5');
      engine.appendDecimal();
      engine.appendDigit('5');
      engine.backspace(); // removes '5' -> '5.'
      engine.appendDigit('7'); // '5.7'

      final result = engine.evaluate();
      expect(result, equals(5.7));
    });

    test('4. Should handle reset', () {
      engine.appendDigit('9');
      engine.appendDigit('9');
      engine.reset();
      expect(engine.expression, equals('0'));
    });
  });
}
