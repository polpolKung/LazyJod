import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../transactions/models/transaction_type.dart';
import '../models/slip_parse_result.dart';
import 'gemini_vision_proxy_service.dart';
import 'slip_barcode_scanner.dart';
import 'thai_bank_slip_parser.dart';
import 'thai_qr_slip_parser.dart';

/// Routes slip-image processing through the best available pipeline:
///
///  1. **QR / barcode first** — Thai slip Mini-QR, PromptPay EMV, BOT barcode.
///  2. **On-device ML Kit OCR** — always runs (amount, date, bank, refId).
///  3. **Merge** — QR wins for amount / ref / bank / time; OCR keeps real names.
///  4. **Gemini Vision** — when online, ALWAYS called for best Thai name extraction.
///     Offline: falls back to local OCR result.
///
/// On any failure the next stage still runs — zero data loss.
class HybridOcrService {
  HybridOcrService._();

  static final HybridOcrService instance = HybridOcrService._();

  final TextRecognizer _mlKit = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
  final SlipBarcodeScanner _barcodes = SlipBarcodeScanner.instance;

  /// Processes [imageFile] and returns the best [SlipParseResult] available.
  Future<SlipParseResult> process({
    required File imageFile,
    String? imagePath,
    String? imageHash,
    DateTime? fallbackDateTime,
    TransactionType transactionType = TransactionType.expense,
  }) async {
    final barcodeFuture = _barcodes.scanFile(imageFile);
    final ocrFuture = _runLocalOcr(
      imageFile: imageFile,
      imagePath: imagePath,
      imageHash: imageHash,
      fallbackDateTime: fallbackDateTime,
      transactionType: transactionType,
    );

    final barcodePayloads = await barcodeFuture;
    var localResult = await ocrFuture;

    final textPayloads = ThaiQrSlipParser.extractPayloadsFromText(
      localResult.rawOcrText,
    );
    final qr = ThaiQrSlipParser.parseBest([
      ...barcodePayloads,
      ...textPayloads,
    ]);

    if (qr != null && qr.isUseful) {
      localResult = ThaiQrSlipParser.mergeWithOcr(ocr: localResult, qr: qr);
      debugPrint(
        '[HybridOCR] Merged ${qr.kind.name} QR (score=${qr.score}, amount=${qr.amount}, ref=${qr.refId}).',
      );
    }

    // ── Gemini Enhancement ────────────────────────────────────────────────────
    // When online, always call Gemini for best name extraction.
    // Gemini far outperforms local OCR for Thai names and avoids returning
    // PromptPay numbers as the recipient name.
    // Local OCR result is kept for amount / date / bank / refId (reliable),
    // while Gemini's response overwrites the recipient/sender names.
    final online = await _isOnline();
    if (!online) {
      debugPrint('[HybridOCR] Offline — keeping local OCR result only.');
      return localResult;
    }

    debugPrint('[HybridOCR] Online → calling Gemini proxy for name extraction.');
    return GeminiVisionProxyService.instance.enhance(
      imageFile: imageFile,
      localResult: localResult,
    );
  }

  Future<SlipParseResult> _runLocalOcr({
    required File imageFile,
    String? imagePath,
    String? imageHash,
    DateTime? fallbackDateTime,
    TransactionType transactionType = TransactionType.expense,
  }) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognized = await _mlKit.processImage(inputImage);
    return ThaiBankSlipParser.parse(
      recognized.text,
      imagePath: imagePath,
      imageHash: imageHash,
      fallbackDateTime: fallbackDateTime,
      transactionType: transactionType,
    );
  }

  Future<bool> _isOnline() async {
    try {
      final results = await Connectivity().checkConnectivity();
      if (results.isEmpty) return false;
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _mlKit.close();
    _barcodes.dispose();
  }
}
