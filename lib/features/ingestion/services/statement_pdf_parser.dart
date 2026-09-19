import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../categories/models/category_model.dart';
import '../models/statement_record.dart';
import '../../../core/utils/date_formatter.dart';

class StatementPdfParser {
  /// Extracts text from PDF bytes or file path and parses credit card statement entries
  static Future<List<StatementRecord>> parsePdfFile(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      return parsePdfBytes(bytes);
    } catch (e) {
      print('Error reading PDF file: $e');
      return [];
    }
  }

  /// Parses raw PDF bytes
  static List<StatementRecord> parsePdfBytes(List<int> bytes) {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String fullText = extractor.extractText();
      document.dispose();

      return parseStatementText(fullText);
    } catch (e) {
      print('Error parsing PDF content: $e');
      return [];
    }
  }

  /// Parses text lines from statement
  static List<StatementRecord> parseStatementText(String text) {
    final List<StatementRecord> records = [];
    final lines = text.split(RegExp(r'\r?\n'));

    // Regex for statement line: e.g.,
    // "15/09/2026 16/09/2026 GRABFOOD BANGKOK TH 345.00"
    // "12/09/2026 APPLE.COM/BILL 0% 10M (3/10) 2,490.00"
    // "10/09/2026 CASHBACK REWARD -50.00 CR"
    final rowRegex = RegExp(
      r'(\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4})\s+(?:(\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4})\s+)?(.+?)\s+(-?[0-9]{1,3}(?:,[0-9]{3})*\.[0-9]{2})\s*(CR|cr)?$',
    );

    int idCounter = 1;

    for (final line in lines) {
      final cleanLine = line.trim();
      if (cleanLine.isEmpty) continue;

      final match = rowRegex.firstMatch(cleanLine);
      if (match != null) {
        final txDateStr = match.group(1)!;
        final postDateStr = match.group(2);
        final desc = match.group(3)!.trim();
        final amountStr = match.group(4)!.replaceAll(',', '');
        final isCr = match.group(5) != null || amountStr.startsWith('-');

        final txDate = DateFormatter.parseThaiDate(txDateStr) ?? DateTime.now();
        final postDate = postDateStr != null ? DateFormatter.parseThaiDate(postDateStr) : null;
        double amount = double.tryParse(amountStr.replaceAll('-', '')) ?? 0.0;

        // Detect installment information: e.g. "3/10", "งวด 3/10", "0% 10M (3/10)"
        final installmentRegex = RegExp(r'(?:งวดที่?\s*|\(|\s|^)(\d{1,2})\s*[/]\s*(\d{1,2})(?:\)|\s|$)', caseSensitive: false);
        final instMatch = installmentRegex.firstMatch(desc);
        bool isInstallment = false;
        int? currentInst;
        int? totalInst;

        if (instMatch != null) {
          isInstallment = true;
          currentInst = int.tryParse(instMatch.group(1)!);
          totalInst = int.tryParse(instMatch.group(2)!);
        }

        // Detect cashback:
        final isCashback = isCr ||
            desc.toLowerCase().contains('cashback') ||
            desc.toLowerCase().contains('เครดิตเงินคืน') ||
            desc.toLowerCase().contains('คืนเงิน');

        // Suggest category
        final categoryId = _suggestCategoryForStatement(desc);

        records.add(StatementRecord(
          id: 'stmt_${DateTime.now().millisecondsSinceEpoch}_$idCounter',
          transactionDate: txDate,
          postingDate: postDate,
          description: desc,
          amount: amount,
          isInstallment: isInstallment,
          currentInstallmentMonth: currentInst,
          totalInstallmentMonths: totalInst,
          isCashback: isCashback,
          suggestedCategoryId: categoryId,
        ));

        idCounter++;
      }
    }

    return records;
  }

  static String _suggestCategoryForStatement(String desc) {
    final lower = desc.toLowerCase();
    for (final cat in CategoryModel.defaultCategories) {
      for (final kw in cat.autoKeywords) {
        if (lower.contains(kw.toLowerCase())) {
          return cat.id;
        }
      }
    }
    return 'cat_shopping';
  }
}
