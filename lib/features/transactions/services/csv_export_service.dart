import 'dart:convert';
import 'package:csv/csv.dart';
import '../../categories/models/category_model.dart';
import '../models/transaction_model.dart';
import '../../../core/utils/date_formatter.dart';

class CsvExportService {
  /// Generates CSV string with UTF-8 BOM for Thai Excel compatibility
  static String exportTransactionsToCsv({
    required List<TransactionModel> transactions,
    required List<CategoryModel> categories,
  }) {
    final categoryMap = {for (var c in categories) c.id: c.nameThai};

    final List<List<dynamic>> rows = [
      // Header in Thai
      [
        'รหัสธุรกรรม',
        'วันที่',
        'เวลา',
        'ประเภท',
        'หมวดหมู่',
        'จำนวนเงิน (THB)',
        'บันทึก/ผู้รับเงิน',
        'แท็ก',
        'ธนาคารต้นทาง',
        'รหัสอ้างอิงสลิป',
        'นำเข้าจากสลิป',
      ],
    ];

    for (final tx in transactions) {
      final dateStr = DateFormatter.formatThaiDate(tx.dateTime, shortMonth: false, showBuddhistYear: true);
      final timeStr = DateFormatter.formatTimeOnly(tx.dateTime);
      final catName = categoryMap[tx.categoryId] ?? 'อื่นๆ';
      final bankName = tx.bankSource.displayNameThai;
      final tagsStr = tx.tags.join(', ');

      rows.add([
        tx.id,
        dateStr,
        timeStr,
        tx.type.displayNameThai,
        catName,
        tx.amount.toStringAsFixed(2),
        tx.note,
        tagsStr,
        bankName,
        tx.slipRefId ?? '',
        tx.isFromSlip ? 'ใช่' : 'ไม่ใช่',
      ]);
    }

    final csvContent = const ListToCsvConverter().convert(rows);
    
    // UTF-8 BOM (\uFEFF) is mandatory for Excel to open Thai characters properly
    return '\uFEFF$csvContent';
  }
}
