import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../categories/providers/category_provider.dart'
    show localStorageServiceProvider;
import '../services/ocr_sync_queue_service.dart';

// ── OcrSyncQueueService provider ─────────────────────────────────────────────
final ocrSyncQueueServiceProvider = Provider<OcrSyncQueueService>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return OcrSyncQueueService(storage, ref);
});

// ── Connectivity stream ───────────────────────────────────────────────────────
/// Emits a new [List<ConnectivityResult>] every time the network state changes.
final connectivityStreamProvider =
    StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

// ── Background Sync Trigger ───────────────────────────────────────────────────
/// Watches the connectivity stream and automatically calls
/// [OcrSyncQueueService.drainQueue] whenever the device goes from offline
/// to online. This provider must be "warmed up" (read once) at app startup
/// to activate the listener.
///
/// It is intentionally a [Provider<void>] (not a FutureProvider) so it does
/// not cause rebuilds across the widget tree — it's a fire-and-forget side
/// effect watcher.
final syncQueueProvider = Provider<void>((ref) {
  bool wasOffline = false;

  ref.listen<AsyncValue<List<ConnectivityResult>>>(
    connectivityStreamProvider,
    (previous, next) {
      next.whenData((results) {
        final isOnline = results.any((r) =>
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.ethernet);

        if (isOnline && wasOffline) {
          debugPrint('[SyncQueue] Connectivity restored — triggering queue drain.');
          final syncService = ref.read(ocrSyncQueueServiceProvider);
          // Run in a detached Future so the listener returns immediately.
          Future(() => syncService.drainQueue()).catchError((e) {
            debugPrint('[SyncQueue] drainQueue error: $e');
          });
        }

        wasOffline = !isOnline;
      });
    },
    fireImmediately: true,
  );
});
