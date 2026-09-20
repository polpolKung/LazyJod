import 'dart:io';
import 'package:flutter/foundation.dart';

/// Configuration for the Gemini Vision Backend Proxy.
///
/// By default, this automatically points to your local backend:
///   - Android Emulator: http://10.0.2.2:8080
///   - iOS Simulator / Desktop / Web: http://localhost:8080
///
/// When deploying to a cloud server (e.g. Cloud Run, Railway, Render),
/// simply set [productionProxyUrl] to your public URL.
class GeminiProxyConfig {
  GeminiProxyConfig._();

  /// Production proxy URL on Cloudflare Workers.
  static const String productionProxyUrl = 'https://lazyjod-gemini-proxy.lazyjod.workers.dev';

  /// Base URL of the backend proxy wrapping Gemini Vision.
  static String get proxyBaseUrl {
    if (productionProxyUrl.isNotEmpty) {
      return productionProxyUrl;
    }
    if (!kIsWeb && Platform.isAndroid) {
      // Android Emulator maps host machine localhost to 10.0.2.2
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  /// Endpoint path for slip OCR enhancement.
  static const String enhancePath = '/api/ocr/enhance';

  /// Full URL = [proxyBaseUrl] + [enhancePath]
  static Uri get enhanceUri => Uri.parse('$proxyBaseUrl$enhancePath');

  /// HTTP request timeout for the proxy call.
  static const Duration requestTimeout = Duration(seconds: 15);

  /// Name of the multipart field that carries the image bytes.
  static const String imageFieldName = 'slip_image';

  /// Maximum number of pending items allowed in the sync queue.
  static const int maxQueueSize = 500;
}
