import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/database/local_storage_service.dart';
import '../../transactions/models/transaction_model.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../models/ocr_sync_item.dart';
import '../models/slip_parse_result.dart';
import 'gemini_vision_proxy_service.dart';
import 'thai_bank_slip_parser.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages a lightweight offline queue of slips whose recipient name was
/// resolved to only a fallback identifier (PromptPay number / "โอนเงิน").
///
/// **Queue lifecycle**:
///   1. [enqueue] — called by [IngestionNotifier] immediately after saving a
///      transaction when the recipient is still a fallback.
///   2. [drainQueue] — called by [SyncQueueProvider] when connectivity is
///      restored. For each queued item it:
///        a. Re-processes the image via Gemini Vision.
///        b. If Gemini returns a real name, patches [TransactionModel.note]
///           via [TransactionNotifier.updateTransaction] (silent, no UI flash).
///        c. Removes the item from the queue regardless of outcome so it is
///           never retried more than once (avoids hammering the proxy).
class OcrSyncQueueService {
  OcrSyncQueueService(this._storage, this._ref);

  final LocalStorageService _storage;
  final Ref _ref;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Adds [item] to the persistent queue (capped at [maxQueueSize] entries).
  Future<void> enqueue(OcrSyncItem item) async {
    final queue = await _storage.loadSyncQueue();
    queue.add(item);

    // Drop oldest entries if we exceed the cap
    const maxQueueSize = 500;
    final trimmed = queue.length > maxQueueSize
        ? queue.sublist(queue.length - maxQueueSize)
        : queue;

    await _storage.saveSyncQueue(trimmed);
    debugPrint('[SyncQueue] Enqueued ${item.transactionId}. Queue size: ${trimmed.length}');
  }

  /// Returns how many items are waiting in the queue.
  Future<int> pendingCount() async {
    final queue = await _storage.loadSyncQueue();
    return queue.length;
  }

  /// Processes all pending queue items via Gemini Vision and updates the
  /// matching transactions. Clears the queue atomically when done.
  ///
  /// This method is designed to run silently in the background — it never
  /// throws and never mutates UI state directly.
  Future<void> drainQueue() async {
    final queue = await _storage.loadSyncQueue();
    if (queue.isEmpty) return;

    debugPrint('[SyncQueue] Draining ${queue.length} pending items...');

    final txNotifier = _ref.read(transactionProvider.notifier);
    final transactions = _ref.read(transactionProvider);

    final List<OcrSyncItem> failedItems = [];

    for (final item in queue) {
      try {
        final file = File(item.imagePath);
        if (!file.existsSync()) {
          // Image was deleted from device — skip silently
          debugPrint('[SyncQueue] Image missing for ${item.transactionId}, skipping.');
          continue;
        }

        // Find the saved transaction
        final txIndex = transactions.indexWhere((t) => t.id == item.transactionId);
        if (txIndex == -1) {
          // Transaction was deleted by user — skip
          debugPrint('[SyncQueue] Transaction ${item.transactionId} not found, skipping.');
          continue;
        }
        final tx = transactions[txIndex];

        // Re-OCR via Gemini (GeminiVisionProxyService handles all errors internally)
        final localResult = _buildLocalResultFromTransaction(tx);
        final enhanced = await GeminiVisionProxyService.instance.enhance(
          imageFile: file,
          localResult: localResult,
        );

        // Only update if Gemini actually improved the name
        if (_isRealName(enhanced.recipientName) &&
            enhanced.recipientName != tx.note) {
          final updatedTx = tx.copyWith(note: enhanced.recipientName);
          await txNotifier.updateTransaction(updatedTx);
          debugPrint(
            '[SyncQueue] Updated ${item.transactionId}: '
            '"${tx.note}" → "${enhanced.recipientName}"',
          );
        }
      } catch (e) {
        debugPrint('[SyncQueue] Error processing ${item.transactionId}: $e');
        // Keep failed items for a single retry on next connectivity event
        failedItems.add(item);
      }
    }

    // Persist only the items that encountered unexpected errors (not missing
    // images or deleted transactions — those are gone for good)
    await _storage.saveSyncQueue(failedItems);
    debugPrint(
      '[SyncQueue] Drain complete. ${queue.length - failedItems.length} updated, '
      '${failedItems.length} failed items re-queued.',
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Reconstructs a minimal [SlipParseResult] from a saved [TransactionModel]
  /// so we can pass it to [GeminiVisionProxyService.enhance].
  SlipParseResult _buildLocalResultFromTransaction(TransactionModel tx) {
    return SlipParseResult(
      bank:           tx.bankSource,
      amount:         tx.amount,
      dateTime:       tx.dateTime,
      recipientName:  tx.note,
      refId:          tx.slipRefId,
      imagePath:      tx.slipImagePath,
      imageHash:      tx.slipImageHash,
      rawOcrText:     '',
      confidenceScore: 0.5,
    );
  }

  /// Returns true when [name] looks like a real person/merchant name rather
  /// than a fallback identifier.
  bool _isRealName(String name) {
    if (name.isEmpty) return false;
    if (name.startsWith('พร้อมเพย์')) return false;
    if (name.startsWith('โอนเงิน')) return false;
    return true;
  }
}
