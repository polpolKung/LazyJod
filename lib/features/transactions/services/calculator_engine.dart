class CalculatorEngine {
  String _expression = '0';

  String get expression => _expression;

  void reset() {
    _expression = '0';
  }

  void setInitialValue(double value) {
    if (value == 0) {
      _expression = '0';
    } else if (value == value.roundToDouble()) {
      _expression = value.toInt().toString();
    } else {
      _expression = value.toString();
    }
  }

  void appendDigit(String digit) {
    if (_expression == '0') {
      _expression = digit;
    } else {
      _expression += digit;
    }
  }

  void appendDecimal() {
    // Find the last number token in the expression
    final tokens = _expression.split(RegExp(r'[\+\-\×\÷]'));
    final lastToken = tokens.isNotEmpty ? tokens.last : '';
    if (!lastToken.contains('.')) {
      if (lastToken.isEmpty) {
        _expression += '0.';
      } else {
        _expression += '.';
      }
    }
  }

  void appendOperator(String op) {
    if (_expression.isEmpty) return;
    final lastChar = _expression[_expression.length - 1];
    if (['+', '-', '×', '÷'].contains(lastChar)) {
      // Replace last operator
      _expression = _expression.substring(0, _expression.length - 1) + op;
    } else {
      // If there's already a full expression, evaluate first or chain
      _expression += op;
    }
  }

  void backspace() {
    if (_expression.length <= 1) {
      _expression = '0';
    } else {
      _expression = _expression.substring(0, _expression.length - 1);
    }
  }

  double evaluate() {
    try {
      final sanitized = _expression.replaceAll('×', '*').replaceAll('÷', '/');
      final result = _evaluateSimpleExpression(sanitized);
      setInitialValue(result);
      return result;
    } catch (e) {
      return 0.0;
    }
  }

  /// Evaluates simple binary operations with standard operator precedence (+, -, *, /)
  static double _evaluateSimpleExpression(String expr) {
    if (expr.isEmpty) return 0.0;

    // Tokenize numbers and operators
    final List<double> numbers = [];
    final List<String> operators = [];

    final regex = RegExp(r'([0-9]+\.?[0-9]*)|([\+\-\*/])');
    final matches = regex.allMatches(expr);

    for (final match in matches) {
      final token = match.group(0)!;
      if (['+', '-', '*', '/'].contains(token)) {
        operators.add(token);
      } else {
        numbers.add(double.tryParse(token) ?? 0.0);
      }
    }

    if (numbers.isEmpty) return 0.0;
    if (operators.isEmpty) return numbers.first;

    // Pass 1: Multiplication and Division
    int i = 0;
    while (i < operators.length) {
      if (operators[i] == '*' || operators[i] == '/') {
        final op = operators[i];
        final left = numbers[i];
        final right = (i + 1 < numbers.length) ? numbers[i + 1] : 0.0;
        double res = 0.0;
        if (op == '*') {
          res = left * right;
        } else if (op == '/') {
          res = right != 0 ? left / right : 0.0;
        }
        numbers[i] = res;
        numbers.removeAt(i + 1);
        operators.removeAt(i);
      } else {
        i++;
      }
    }

    // Pass 2: Addition and Subtraction
    double total = numbers.isNotEmpty ? numbers[0] : 0.0;
    for (int j = 0; j < operators.length; j++) {
      final op = operators[j];
      final nextNum = (j + 1 < numbers.length) ? numbers[j + 1] : 0.0;
      if (op == '+') {
        total += nextNum;
      } else if (op == '-') {
        total -= nextNum;
      }
    }

    return total;
  }
}
