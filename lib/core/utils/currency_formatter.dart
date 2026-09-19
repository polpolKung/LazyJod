import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat('#,##0.00', 'th_TH');
  static final NumberFormat _integerFormatter = NumberFormat('#,##0', 'th_TH');

  static String format(double amount, {bool showSymbol = true}) {
    final formatted = _formatter.format(amount);
    return showSymbol ? '${AppConstants.currencySymbol}$formatted' : formatted;
  }

  static String formatCompact(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M ${AppConstants.currencySymbol}';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k ${AppConstants.currencySymbol}';
    }
    return '${AppConstants.currencySymbol}${_integerFormatter.format(amount)}';
  }

  static double? tryParse(String input) {
    final clean = input.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(clean);
  }
}
