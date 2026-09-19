import 'dart:typed_data';
import '../../../core/utils/hash_helper.dart';
import '../../transactions/models/transaction_model.dart';
import '../models/slip_parse_result.dart';

class DuplicateDetectionService {
  final Set<String> _scannedHashes = {};
  final Set<String> _recordedRefIds = {};

  void registerExistingTransactions(List<TransactionModel> transactions) {
    for (final tx in transactions) {
      if (tx.slipImageHash != null && tx.slipImageHash!.isNotEmpty) {
        _scannedHashes.add(tx.slipImageHash!);
      }
      if (tx.slipRefId != null && tx.slipRefId!.isNotEmpty) {
        _recordedRefIds.add(tx.slipRefId!);
      }
    }
  }

  void registerScannedHash(String hash) {
    _scannedHashes.add(hash);
  }

  void registerScannedRefId(String refId) {
    _recordedRefIds.add(refId);
  }

  /// Checks if the slip image bytes have already been scanned
  bool isImageHashDuplicate(Uint8List imageBytes) {
    final hash = HashHelper.hashBytes(imageBytes);
    return _scannedHashes.contains(hash);
  }

  /// Checks if the slip is duplicate using multi-tier verification
  bool isDuplicate(SlipParseResult slip, List<TransactionModel> existingTransactions) {
    // Tier 1: Exact image hash check
    if (slip.imageHash != null && _scannedHashes.contains(slip.imageHash)) {
      return true;
    }

    // Tier 2: Ref ID match
    if (slip.refId != null && slip.refId!.isNotEmpty && _recordedRefIds.contains(slip.refId)) {
      return true;
    }

    // Tier 3: Fuzzy heuristic match
    // If an existing transaction has the exact same amount, same recipient (or similar),
    // and the transaction time is within 3 minutes of each other
    for (final existing in existingTransactions) {
      if ((existing.amount - slip.amount).abs() < 0.01) {
        final diffMinutes = existing.dateTime.difference(slip.dateTime).inMinutes.abs();
        if (diffMinutes <= 3) {
          final normalizedNew = slip.recipientName.replaceAll(RegExp(r'\s+'), '').toLowerCase();
          final normalizedOld = existing.note.replaceAll(RegExp(r'\s+'), '').toLowerCase();
          
          if (normalizedNew.contains(normalizedOld) ||
              normalizedOld.contains(normalizedNew) ||
              (existing.slipRefId != null && existing.slipRefId == slip.refId)) {
            return true;
          }
        }
      }
    }

    return false;
  }
}
