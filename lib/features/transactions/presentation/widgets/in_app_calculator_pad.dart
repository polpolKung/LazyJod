import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../services/calculator_engine.dart';

class InAppCalculatorPad extends StatefulWidget {
  final double initialAmount;
  final ValueChanged<double> onAmountChanged;
  final VoidCallback onDone;

  const InAppCalculatorPad({
    super.key,
    required this.initialAmount,
    required this.onAmountChanged,
    required this.onDone,
  });

  @override
  State<InAppCalculatorPad> createState() => _InAppCalculatorPadState();
}

class _InAppCalculatorPadState extends State<InAppCalculatorPad> {
  late final CalculatorEngine _engine;

  @override
  void initState() {
    super.initState();
    _engine = CalculatorEngine();
    _engine.setInitialValue(widget.initialAmount);
  }

  void _onKey(String key) {
    setState(() {
      if (key == 'C') {
        _engine.reset();
      } else if (key == '⌫') {
        _engine.backspace();
      } else if (key == '=') {
        final res = _engine.evaluate();
        widget.onAmountChanged(res);
      } else if (key == '.') {
        _engine.appendDecimal();
      } else if (['+', '-', '×', '÷'].contains(key)) {
        _engine.appendOperator(key);
      } else {
        _engine.appendDigit(key);
      }
    });

    if (key != '=' && key != 'C' && key != '⌫') {
      final current = _engine.evaluate();
      widget.onAmountChanged(current);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['C', '÷', '×', '⌫'],
      ['7', '8', '9', '-'],
      ['4', '5', '6', '+'],
      ['1', '2', '3', '='],
      ['0', '00', '.', 'ตกลง'],
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Calculation expression display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerRight,
            child: Text(
              _engine.expression,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Keypad Grid
          for (final row in keys) ...[
            Row(
              children: [
                for (final key in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: _buildKeyButton(key),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKeyButton(String label) {
    final isAction = ['C', '⌫', '÷', '×', '-', '+', '='].contains(label);
    final isDone = label == 'ตกลง';

    Color bgColor = const Color(0xFFF3F4F6);
    Color textColor = AppColors.textPrimary;

    if (isDone) {
      bgColor = AppColors.primary;
      textColor = Colors.white;
    } else if (isAction) {
      bgColor = AppColors.primaryLight.withOpacity(0.5);
      textColor = AppColors.primaryDark;
    }

    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          if (isDone) {
            final res = _engine.evaluate();
            widget.onAmountChanged(res);
            widget.onDone();
          } else {
            _onKey(label);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isDone ? 15 : 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
