import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/gemini_proxy_config.dart';
import '../models/slip_parse_result.dart';
import '../models/thai_bank.dart';
import 'thai_bank_slip_parser.dart';

/// Sends a slip image to the Backend Proxy (Gemini Vision) and returns an
/// enhanced [SlipParseResult] with accurate Thai name extraction.
///
/// The proxy is expected to:
///   POST multipart/form-data  → field: "slip_image"  (raw image bytes)
///   Response JSON:
///   {
///     "recipient_name": "นายสมชาย ใจดี",   // may be null
///     "sender_name":    "นางสาวสุดา รักดี", // may be null
///     "raw_text":       "..."               // full text Gemini read
///   }
///
/// On any failure (timeout, HTTP error, JSON parse error, empty response)
/// the original [localResult] is returned unmodified — zero data loss.
class GeminiVisionProxyService {
  GeminiVisionProxyService._();

  static final GeminiVisionProxyService instance =
      GeminiVisionProxyService._();

  /// Sends [imageFile] to the proxy and merges the cloud result into
  /// [localResult]. Always returns a valid [SlipParseResult].
  Future<SlipParseResult> enhance({
    required File imageFile,
    required SlipParseResult localResult,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();

      final request = http.MultipartRequest(
        'POST',
        GeminiProxyConfig.enhanceUri,
      )
        ..files.add(http.MultipartFile.fromBytes(
          GeminiProxyConfig.imageFieldName,
          bytes,
          filename: imageFile.uri.pathSegments.last,
        ));

      final streamedResponse = await request.send().timeout(
        GeminiProxyConfig.requestTimeout,
        onTimeout: () => throw TimeoutException(
          'Gemini proxy timed out after ${GeminiProxyConfig.requestTimeout.inSeconds}s',
        ),
      );

      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode != 200) {
        debugPrint(
          '[HybridOCR] Proxy returned HTTP ${streamedResponse.statusCode}: $responseBody',
        );
        return localResult;
      }

      final json = jsonDecode(responseBody) as Map<String, dynamic>;

      final cloudRecipient = _sanitizeName(json['recipient_name']);
      final cloudSender    = _sanitizeName(json['sender_name']);
      final cloudRawText   = (json['raw_text'] as String?)?.trim() ?? '';

      // Re-parse with cloud raw text to pick up any missed fields
      // (amount, date, refId), but only if Gemini returned usable text.
      SlipParseResult merged = localResult;
      if (cloudRawText.isNotEmpty) {
        merged = ThaiBankSlipParser.parse(
          cloudRawText,
          imagePath:        localResult.imagePath,
          imageHash:        localResult.imageHash,
          fallbackDateTime: localResult.dateTime,
        );
      }

      // Prefer cloud names over local fallback names
      return merged.copyWith(
        id:            localResult.id,
        isDuplicate:   localResult.isDuplicate,
        recipientName: (cloudRecipient != null && cloudRecipient.isNotEmpty)
            ? cloudRecipient
            : merged.recipientName,
        senderName:    (cloudSender != null && cloudSender.isNotEmpty)
            ? cloudSender
            : merged.senderName,
        // Boost confidence because Gemini processed the image
        confidenceScore: (merged.confidenceScore + 0.15).clamp(0.0, 1.0),
      );
    } on TimeoutException catch (e) {
      debugPrint('[HybridOCR] Timeout: $e');
      return localResult;
    } catch (e, st) {
      debugPrint('[HybridOCR] Proxy error: $e\n$st');
      return localResult;
    }
  }

  /// Returns null if the name is blank or looks like a raw OCR artefact.
  String? _sanitizeName(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    if (s.isEmpty || s.length < 2) return null;
    return s;
  }
}
