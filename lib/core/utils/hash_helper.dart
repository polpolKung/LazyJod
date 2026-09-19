import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class HashHelper {
  /// Computes SHA-256 hash of image or file bytes
  static String hashBytes(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }

  /// Computes quick MD5 hash of image bytes for fast duplicate check
  static String hashBytesMd5(Uint8List bytes) {
    return md5.convert(bytes).toString();
  }

  /// Creates metadata signature when raw bytes are not immediately read
  static String createMetadataFingerprint({
    required String filename,
    required int fileSizeBytes,
    required int modifiedTimestamp,
  }) {
    final raw = '$filename|$fileSizeBytes|$modifiedTimestamp';
    return md5.convert(utf8.encode(raw)).toString();
  }

  /// Creates transaction fingerprint for fuzzy deduplication
  /// e.g. same amount + same recipient + time within 2 minutes
  static String createTransactionFingerprint({
    required double amount,
    required DateTime dateTime,
    required String recipient,
  }) {
    // Round time to 2-minute bucket
    final roundedMinutes = (dateTime.minute / 2).floor() * 2;
    final timeBucket = '${dateTime.year}-${dateTime.month}-${dateTime.day} ${dateTime.hour}:$roundedMinutes';
    final normalizedRecipient = recipient.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    final raw = '${amount.toStringAsFixed(2)}|$timeBucket|$normalizedRecipient';
    return sha256.convert(utf8.encode(raw)).toString();
  }
}
