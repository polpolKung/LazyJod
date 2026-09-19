import 'package:intl/intl.dart';

class DateFormatter {
  static const List<String> thaiMonthsShort = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
  ];

  static const List<String> thaiMonthsFull = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
  ];

  static int toBuddhistYear(int ceYear) => ceYear + 543;
  static int toChristianYear(int beYear) => beYear > 2400 ? beYear - 543 : beYear;

  static String formatThaiDate(DateTime date, {bool shortMonth = true, bool showBuddhistYear = true}) {
    final day = date.day;
    final month = shortMonth ? thaiMonthsShort[date.month - 1] : thaiMonthsFull[date.month - 1];
    final year = showBuddhistYear ? toBuddhistYear(date.year) : date.year;
    return '$day $month $year';
  }

  static String formatThaiDateTime(DateTime date) {
    final dateStr = formatThaiDate(date);
    final timeStr = DateFormat('HH:mm').format(date);
    return '$dateStr $timeStr น.';
  }

  static String formatTimeOnly(DateTime date) {
    return '${DateFormat('HH:mm').format(date)} น.';
  }

  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'วันนี้';
    if (diff == 1) return 'เมื่อวาน';
    if (diff == -1) return 'พรุ่งนี้';
    return formatThaiDate(date, shortMonth: true);
  }

  /// Parses Thai date strings like:
  /// "19 ก.ย. 69", "19 ก.ย. 2569", "19/09/2569", "19/09/2026", "19 กันยายน 2569"
  static DateTime? parseThaiDate(String text) {
    final clean = text.trim();
    
    // Pattern 1: DD/MM/YYYY or DD-MM-YYYY
    final slashRegex = RegExp(r'(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{2,4})');
    final slashMatch = slashRegex.firstMatch(clean);
    if (slashMatch != null) {
      final day = int.parse(slashMatch.group(1)!);
      final month = int.parse(slashMatch.group(2)!);
      var year = int.parse(slashMatch.group(3)!);
      if (year < 100) year += 2500; // e.g. 69 -> 2569
      year = toChristianYear(year);
      return DateTime(year, month, day);
    }

    // Pattern 2: DD [ThaiMonth] YYYY
    for (int i = 0; i < 12; i++) {
      final shortM = thaiMonthsShort[i];
      final fullM = thaiMonthsFull[i];
      if (clean.contains(shortM) || clean.contains(fullM)) {
        final month = i + 1;
        final dayRegex = RegExp(r'(\d{1,2})\s*(?:' + RegExp.escape(shortM) + '|' + RegExp.escape(fullM) + r')\s*(\d{2,4})?');
        final match = dayRegex.firstMatch(clean);
        if (match != null) {
          final day = int.parse(match.group(1)!);
          var year = match.group(2) != null ? int.parse(match.group(2)!) : DateTime.now().year + 543;
          if (year < 100) year += 2500;
          year = toChristianYear(year);
          return DateTime(year, month, day);
        }
      }
    }
    return null;
  }
}
