import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/slip_parse_result.dart';
import 'gemini_vision_proxy_service.dart';
import 'thai_bank_slip_parser.dart';

/// Routes slip-image OCR through the best available pipeline:
///
///  1. **Always** runs on-device ML Kit (offline, instant, zero-config).
///  2. **If** online **and** the recipient resolved to only a fallback
///     identifier (PromptPay number / "โอนเงิน"), attempts Gemini Vision
///     via the Backend Proxy for accurate Thai name extraction.
///  3. On any failure the offline result is returned unchanged — zero data loss.
///
/// This class is intentionally stateless so it can be used as a singleton or
/// created fresh per-scan without lifecycle concerns.
class HybridOcrService {
  HybridOcrService._();

  static final HybridOcrService instance = HybridOcrService._();

  final TextRecognizer _mlKit = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// Processes [imageFile] and returns the best [SlipParseResult] available.
  ///
  /// [imagePath]  — absolute path stored on the result (display / hash lookup).
  /// [imageHash]  — pre-computed SHA-256; avoids re-reading bytes.
  /// [fallbackDateTime] — asset creation time used when the slip has no date.
  Future<SlipParseResult> process({
    required File imageFile,
    String? imagePath,
    String? imageHash,
    DateTime? fallbackDateTime,
  }) async {
    // ── Step 1: Offline ML Kit ──────────────────────────────────────────────
    final SlipParseResult localResult = await _runLocalOcr(
      imageFile:        imageFile,
      imagePath:        imagePath,
      imageHash:        imageHash,
      fallbackDateTime: fallbackDateTime,
    );

    // ── Step 2: Route to cloud only when it adds value ──────────────────────
    if (!_isRecipientFallback(localResult.recipientName)) {
      // ML Kit already found a real person/merchant name — no cloud call needed.
      return localResult;
    }

    final online = await _isOnline();
    if (!online) {
      debugPrint('[HybridOCR] Offline — keeping local result (fallback name).');
      return localResult;
    }

    debugPrint('[HybridOCR] Online + fallback recipient → calling Gemini proxy.');
    return GeminiVisionProxyService.instance.enhance(
      imageFile:   imageFile,
      localResult: localResult,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ───────────────────────────────────────────────────────────────────────────

  Future<SlipParseResult> _runLocalOcr({
    required File imageFile,
    String? imagePath,
    String? imageHash,
    DateTime? fallbackDateTime,
  }) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognized = await _mlKit.processImage(inputImage);
    return ThaiBankSlipParser.parse(
      recognized.text,
      imagePath:        imagePath,
      imageHash:        imageHash,
      fallbackDateTime: fallbackDateTime,
    );
  }

  /// Returns true when the recipient name is a known fallback identifier
  /// rather than a real person or merchant name.
  bool _isRecipientFallback(String name) {
    if (name.isEmpty) return true;
    // ThaiBankSlipParser uses these prefixes as safe fallbacks
    if (name.startsWith('พร้อมเพย์')) return true;
    if (name.startsWith('โอนเงิน')) return true;
    return false;
  }

  Future<bool> _isOnline() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet);
    } catch (_) {
      return false;
    }
  }

  /// Call [dispose] if you create a non-singleton instance per-scan.
  void dispose() => _mlKit.close();
}
