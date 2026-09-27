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
  /// Processes all pending queue items via Gemini Vision and updates the
  /// matching transactions. Clears the queue atomically when done.
  ///
  /// This method is designed to run silently in the background — it never
  /// throws and never mutates UI state directly.
  Future<void> drainQueue() async {
    final queue = await _storage.loadSyncQueue();
    final txNotifier = _ref.read(transactionProvider.notifier);
    final transactions = _ref.read(transactionProvider);

    // Also pick up any existing saved transactions that still have fallback names
    // (e.g. from previous offline sessions or slips scanned before cloud sync was ready)
    final Set<String> enqueuedTxIds = queue.map((e) => e.transactionId).toSet();
    for (final tx in transactions) {
      if (tx.slipImagePath != null &&
          isFallbackRecipient(tx.note) &&
          !enqueuedTxIds.contains(tx.id)) {
        queue.add(OcrSyncItem(
          transactionId: tx.id,
          imagePath:     tx.slipImagePath!,
          imageHash:     tx.slipImageHash ?? '',
          queuedAt:      DateTime.now(),
        ));
        enqueuedTxIds.add(tx.id);
      }
    }

    if (queue.isEmpty) return;

    debugPrint('[SyncQueue] Draining ${queue.length} pending items...');

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

        // Only update if Gemini actually returned a real person/merchant name
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
        failedItems.add(item);
      }
    }

    // Persist only the items that encountered unexpected errors
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
  static bool _isRealName(String name) {
    return !isFallbackRecipient(name);
  }

  /// Evaluates whether a recipient string is an incomplete / fallback placeholder.
  static bool isFallbackRecipient(String name) {
    if (name.isEmpty) return true;
    final clean = name.trim().toLowerCase();
    if (clean == 'prompt' || clean == 'promptpay' || clean == 'pay' || clean == 'next' || clean == 'โอนเงิน') return true;
    if (clean.startsWith('พร้อมเพย์') || clean.startsWith('โอนเงิน') || clean.startsWith('บิล')) return true;
    if (clean.contains('xxx') || clean.contains('xxx-')) return true;
    if (clean.startsWith('โอนเงิน (') || clean.startsWith('โอนเข้า') || clean.startsWith('ไปยัง') || clean.startsWith('ไปที่')) return true;
    const banks = {'kbank', 'scb', 'ktb', 'bbl', 'bay', 'gsb', 'ttb', 'tmb', 'uob', 'cimb', 'krungthai', 'kasikorn', 'bangkok bank'};
    if (banks.contains(clean)) return true;
    if (!RegExp(r'[\u0E00-\u0E7F]').hasMatch(name)) {
      const safeEngMerchants = {'grab', 'shopee', 'lazada', '7-eleven', 'truemoney', 'tiktok', 'netflix', 'apple', 'google', 'spotify', 'starbucks', 'lotus', 'big c', 'dtac', 'ais', 'true'};
      if (!safeEngMerchants.contains(clean) && clean.length < 5) return true;
    }
    return false;
  }
}
