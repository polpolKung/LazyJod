import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

/// On-device QR / 1D barcode reader for slip images.
class SlipBarcodeScanner {
  SlipBarcodeScanner._();

  static final SlipBarcodeScanner instance = SlipBarcodeScanner._();

  final BarcodeScanner _scanner = BarcodeScanner(
    formats: const [
      BarcodeFormat.qrCode,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.dataMatrix,
    ],
  );

  Future<List<String>> scanFile(File imageFile) async {
    try {
      final input = InputImage.fromFile(imageFile);
      final codes = await _scanner.processImage(input);
      return codes
          .map((b) => b.rawValue ?? b.displayValue)
          .whereType<String>()
          .where((v) => v.trim().isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[SlipBarcode] scan failed: $e');
      return const [];
    }
  }

  Future<void> dispose() => _scanner.close();
}
