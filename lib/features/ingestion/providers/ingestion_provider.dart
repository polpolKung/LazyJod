import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/local_storage_service.dart';
import '../../../core/services/scan_notification_service.dart';
import '../../../core/utils/hash_helper.dart';
import '../../transactions/models/transaction_model.dart';
import '../../transactions/models/transaction_type.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../models/ocr_sync_item.dart';
import '../models/slip_parse_result.dart';
import '../services/duplicate_detection_service.dart';
import '../services/hybrid_ocr_service.dart';
import '../services/ocr_sync_queue_service.dart';
import '../services/targeted_album_service.dart';
import '../services/thai_bank_slip_parser.dart';
import 'sync_queue_provider.dart';

class IngestionState {
  final bool isScanning;
  final double scanProgress;
  final String statusMessage;
  final String? lastError;
  final List<TargetedAlbumInfo> albums;
  final List<SlipParseResult> parsedSlips;
  final List<String> selectedSlipIds;
  final int totalScannedAssets;

  const IngestionState({
    this.isScanning = false,
    this.scanProgress = 0.0,
    this.statusMessage = '',
    this.lastError,
    this.albums = const [],
    this.parsedSlips = const [],
    this.selectedSlipIds = const [],
    this.totalScannedAssets = 0,
  });

  IngestionState copyWith({
    bool? isScanning,
    double? scanProgress,
    String? statusMessage,
    String? lastError,
    List<TargetedAlbumInfo>? albums,
    List<SlipParseResult>? parsedSlips,
    List<String>? selectedSlipIds,
    int? totalScannedAssets,
  }) {
    return IngestionState(
      isScanning: isScanning ?? this.isScanning,
      scanProgress: scanProgress ?? this.scanProgress,
      statusMessage: statusMessage ?? this.statusMessage,
      lastError: lastError ?? this.lastError,
      albums: albums ?? this.albums,
      parsedSlips: parsedSlips ?? this.parsedSlips,
      selectedSlipIds: selectedSlipIds ?? this.selectedSlipIds,
      totalScannedAssets: totalScannedAssets ?? this.totalScannedAssets,
    );
  }
}

class IngestionNotifier extends StateNotifier<IngestionState> {
  final TargetedAlbumService _albumService = TargetedAlbumService();
  final DuplicateDetectionService _dupService = DuplicateDetectionService();
  final LocalStorageService _storage = LocalStorageService();
  // HybridOcrService replaces the raw TextRecognizer — it runs ML Kit offline
  // and transparently upgrades to Gemini Vision when online + name is a fallback.
  final HybridOcrService _hybridOcr = HybridOcrService.instance;
  final ScanNotificationService _notif = ScanNotificationService.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final Ref _ref;
  final _uuid = const Uuid();

  late final OcrSyncQueueService _syncQueue;

  IngestionNotifier(this._ref) : super(const IngestionState()) {
    _syncQueue = OcrSyncQueueService(_storage, _ref);
    _notif.init();
    loadAlbums();
  }

  Future<void> loadAlbums() async {
    final albums = await _albumService.getAvailableAlbums();
    state = state.copyWith(albums: albums);
  }

  void toggleAlbumSelection(String albumId) {
    final updated = state.albums.map((a) {
      if (a.id == albumId) {
        return a.copyWith(isSelected: !a.isSelected);
      }
      return a;
    }).toList();
    state = state.copyWith(albums: updated);
  }

  /// 1. Scan targeted albums for slips, perform on-device OCR, and check duplicates
  Future<void> scanTargetedAlbums() async {
    state = state.copyWith(
      isScanning: true,
      scanProgress: 0.0,
      statusMessage: 'กำลังขอสิทธิ์เข้าถึงโฟลเดอร์สลิป...',
      lastError: null,
    );

    final perm = await _albumService.requestPermission();
    if (!perm.hasAccess) {
      state = state.copyWith(
        isScanning: false,
        statusMessage: 'ไม่ได้รับสิทธิ์เข้าถึงรูปภาพ กรุณาเปิดการอนุญาตในการตั้งค่าอุปกรณ์',
      );
      return;
    }

    // Refresh albums after permission granted
    await loadAlbums();

    state = state.copyWith(statusMessage: 'กำลังค้นหาภาพในโฟลเดอร์ธนาคาร...');

    final selectedAlbumIds = state.albums.where((a) => a.isSelected).map((a) => a.id).toList();
    final scanLimit = await _storage.getScanHistoryLimit();
    final assets = await _albumService.fetchAssetsFromTargetedAlbums(
      selectedAlbumIds: selectedAlbumIds.isNotEmpty ? selectedAlbumIds : null,
      maxCount: scanLimit,
    );

    if (assets.isEmpty) {
      final totalAlbums = state.albums.length;
      final selectedCount = selectedAlbumIds.length;
      state = state.copyWith(
        isScanning: false,
        totalScannedAssets: 0,
        statusMessage: 'ไม่พบรูปภาพในโฟลเดอร์ที่เลือก (พบ $totalAlbums อัลบั้ม, เลือกไว้ $selectedCount อัลบั้ม) สามารถกด "เลือกโฟลเดอร์" เพื่อเลือกเพิ่ม หรือใช้ "เลือกรูปจากแกลเลอรี"',
      );
      return;
    }

    await _processAssets(assets, skipSeenAssets: false);
  }

  /// 2. Pick slip images directly from device gallery
  Future<void> pickAndScanGallerySlips() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage();
      if (pickedFiles.isEmpty) return;

      await _notif.requestPermission();

      state = state.copyWith(
        isScanning: true,
        scanProgress: 0.0,
        statusMessage: 'กำลังเตรียมรูปที่เลือก ${pickedFiles.length} รูป...',
        lastError: null,
      );

      final existingTransactions = _ref.read(transactionProvider);
      _dupService.registerExistingTransactions(existingTransactions);

      final total = pickedFiles.length;
      final List<SlipParseResult?> results = List.filled(total, null);
      int completed = 0;
      int errorCount = 0;
      String? caughtError;

      // ── Parallel processing — max 3 concurrent OCR calls ──────────────────
      const concurrency = 3;
      final semaphore = _Semaphore(concurrency);

      await Future.wait(
        List.generate(total, (i) async {
          await semaphore.acquire();
          try {
            final xfile = pickedFiles[i];
            final file = File(xfile.path);
            final bytes = await file.readAsBytes();
            final imageHash = HashHelper.hashBytes(bytes);

            final slipResult = await _hybridOcr.process(
              imageFile: file,
              imagePath: file.path,
              imageHash: imageHash,
            );

            final slipId = 'slip_${_uuid.v4()}';
            final isDup = _dupService.isDuplicate(slipResult, existingTransactions);
            results[i] = slipResult.copyWith(id: slipId, isDuplicate: isDup);
          } catch (e) {
            errorCount++;
            caughtError = e.toString();
          } finally {
            completed++;
            semaphore.release();
            final progress = completed / total;
            final foundSoFar = results.whereType<SlipParseResult>().length;
            state = state.copyWith(
              scanProgress: progress,
              statusMessage: 'กำลังสแกนรูปที่ $completed/$total...',
            );
            await _notif.showProgress(
              current: completed,
              total: total,
              foundSoFar: foundSoFar,
            );
          }
        }),
      );

      final parsedResults = results.whereType<SlipParseResult>().toList();

      // Sort parsed slips newest first (by slip transaction dateTime)
      parsedResults.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      final selectedIds = parsedResults.where((s) => !s.isDuplicate && s.amount > 0).map((s) => s.id!).toList();

      String msg = 'สแกนเสร็จสิ้น พบสลิป ${parsedResults.length} รายการ';
      if (parsedResults.isEmpty && errorCount > 0) {
        msg = 'เกิดข้อผิดพลาดในการประมวลผล OCR ($caughtError)';
      }

      await _notif.showDone(total: total, found: parsedResults.length);

      state = state.copyWith(
        isScanning: false,
        scanProgress: 1.0,
        statusMessage: msg,
        lastError: caughtError,
        parsedSlips: parsedResults,
        selectedSlipIds: selectedIds,
        totalScannedAssets: total,
      );
    } catch (e) {
      await _notif.cancelAll();
      state = state.copyWith(
        isScanning: false,
        statusMessage: 'เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e',
        lastError: e.toString(),
      );
    }
  }

  Future<void> _processAssets(List<AssetEntity> assets, {bool skipSeenAssets = true}) async {
    final existingTransactions = _ref.read(transactionProvider);
    _dupService.registerExistingTransactions(existingTransactions);

    // Load persisted asset IDs that have already been OCR-scanned
    final seenAssetIds = skipSeenAssets ? await _storage.loadScannedAssetIds() : <String>{};

    // Filter out assets already scanned in previous sessions
    final newAssets = skipSeenAssets
        ? assets.where((a) => !seenAssetIds.contains(a.id)).toList()
        : assets;

    final skippedCount = assets.length - newAssets.length;

    if (newAssets.isEmpty) {
      state = state.copyWith(
        isScanning: false,
        scanProgress: 1.0,
        statusMessage: skippedCount > 0
            ? 'ไม่พบสลิปใหม่ (ตรวจแล้ว $skippedCount รูปก่อนหน้า)'
            : 'ไม่พบรูปแบบสลิปในโฟลเดอร์ที่เลือก',
        parsedSlips: [],
        selectedSlipIds: [],
        totalScannedAssets: 0,
      );
      return;
    }

    final total = newAssets.length;
    final List<SlipParseResult?> results = List.filled(total, null);
    final Set<String> processedAssetIds = {};
    int completed = 0;
    int errorCount = 0;
    String? lastError;

    // ── Parallel processing — max 3 concurrent OCR calls ──────────────────
    const concurrency = 3;
    final semaphore = _Semaphore(concurrency);

    await Future.wait(
      List.generate(total, (i) async {
        await semaphore.acquire();
        final asset = newAssets[i];
        try {
          final file = await asset.file;
          if (file == null) return;

          final bytes = await file.readAsBytes();
          final imageHash = HashHelper.hashBytes(bytes);

          // ── Hybrid OCR: ML Kit offline → Gemini online if name is fallback ──
          final slipResult = await _hybridOcr.process(
            imageFile: file,
            imagePath: file.path,
            imageHash: imageHash,
            fallbackDateTime: asset.createDateTime,
          );

          final slipId = 'slip_${_uuid.v4()}';
          final isDup = _dupService.isDuplicate(slipResult, existingTransactions);
          results[i] = slipResult.copyWith(id: slipId, isDuplicate: isDup);

          // Mark this asset as processed regardless of whether it's a slip
          processedAssetIds.add(asset.id);
        } catch (e) {
          errorCount++;
          lastError = e.toString();
          // Still mark as processed so we don't re-attempt a broken image next time
          processedAssetIds.add(asset.id);
        } finally {
          completed++;
          semaphore.release();
          final progress = completed / total;
          final foundSoFar = results.whereType<SlipParseResult>().length;
          state = state.copyWith(
            scanProgress: progress,
            statusMessage: 'กำลังสแกนสลิป $completed/$total...',
          );
          await _notif.showProgress(
            current: completed,
            total: total,
            foundSoFar: foundSoFar,
          );
        }
      }),
    );

    final parsedResults = results.whereType<SlipParseResult>().toList();

    // Persist newly scanned asset IDs so they are skipped on next launch
    if (processedAssetIds.isNotEmpty) {
      await _storage.addScannedAssetIds(processedAssetIds);
    }

    // Sort parsed slips newest first (by slip transaction dateTime)
    parsedResults.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    // Default select non-duplicate slips
    final selectedIds = parsedResults.where((s) => !s.isDuplicate && s.amount > 0).map((s) => s.id!).toList();

    String resultMsg = 'สแกนตรวจภาพ $total รูป พบสลิป ${parsedResults.length} รายการ';
    if (skippedCount > 0) {
      resultMsg += ' (ข้าม $skippedCount รูปที่ตรวจแล้ว)';
    }
    if (parsedResults.isEmpty && errorCount > 0) {
      if (lastError != null && lastError!.contains('download')) {
        resultMsg = 'กำลังรอ Google Play Services ติดตั้งโมเดล OCR กรุณารอสักครู่แล้วลองใหม่';
      } else {
        resultMsg = 'ตรวจพบรูป $total รูป แต่ OCR เกิดข้อผิดพลาด ($lastError)';
      }
    } else if (parsedResults.isEmpty) {
      resultMsg = 'ตรวจภาพ $total รูปในโฟลเดอร์แล้ว แต่ไม่พบรูปแบบสลิป สามารถกดเลือกรูปเองได้';
    }

    await _notif.showDone(total: total, found: parsedResults.length);

    state = state.copyWith(
      isScanning: false,
      scanProgress: 1.0,
      statusMessage: resultMsg,
      lastError: lastError,
      parsedSlips: parsedResults,
      selectedSlipIds: selectedIds,
      totalScannedAssets: total,
    );
  }

  void toggleSlipSelection(String slipId) {
    final current = List<String>.from(state.selectedSlipIds);
    if (current.contains(slipId)) {
      current.remove(slipId);
    } else {
      current.add(slipId);
    }
    state = state.copyWith(selectedSlipIds: current);
  }

  static bool isSelfTransfer(String? sender, String recipient) {
    if (sender == null || sender.isEmpty) return false;
    String clean(String s) => s
        .replaceAll(RegExp(r'^(?:นาย|นาง|น\.ส\.|นางสาว|ด\.ช\.|ด\.ญ\.|Mr\.|Ms\.)\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'[\*\s\.\-_]'), '')
        .trim()
        .toLowerCase();
    final cleanSender = clean(sender);
    final cleanRecipient = clean(recipient);
    if (cleanSender.length >= 2 && cleanRecipient.length >= 2) {
      if (cleanSender.contains(cleanRecipient) || cleanRecipient.contains(cleanSender)) {
        return true;
      }
      final minLen = cleanSender.length < cleanRecipient.length ? cleanSender.length : cleanRecipient.length;
      final checkLen = minLen >= 4 ? 4 : (minLen >= 3 ? 3 : 2);
      if (cleanSender.substring(0, checkLen) == cleanRecipient.substring(0, checkLen)) {
        return true;
      }
    }
    return false;
  }

  /// Import selected parsed slips directly into user's transactions
  Future<int> importSelectedSlips() async {
    final selectedSlips = state.parsedSlips
        .where((s) => state.selectedSlipIds.contains(s.id))
        .toList();

    final List<TransactionModel> newTransactions = [];

    for (final slip in selectedSlips) {
      final isTransfer = isSelfTransfer(slip.senderName, slip.recipientName);

      newTransactions.add(TransactionModel(
        id: 'tx_${_uuid.v4()}',
        type: isTransfer ? TransactionType.transfer : TransactionType.expense,
        amount: slip.amount,
        dateTime: slip.dateTime,
        categoryId: isTransfer ? 'cat_transfer' : (slip.suggestedCategoryId ?? 'cat_food'),
        note: isTransfer ? 'ย้ายเงิน: ${slip.recipientName}' : slip.recipientName,
        tags: isTransfer ? [slip.bank.shortCode, 'ย้ายเงิน'] : [slip.bank.shortCode],
        bankSource: slip.bank,
        slipImagePath: slip.imagePath,
        slipImageHash: slip.imageHash,
        slipRefId: slip.refId,
        isFromSlip: true,
      ));
    }

    if (newTransactions.isNotEmpty) {
      await _ref.read(transactionProvider.notifier).addBatchTransactions(newTransactions);

      // ── Background Sync: enqueue fallback-named transactions for cloud retry ──
      bool hasEnqueued = false;
      for (final tx in newTransactions) {
        final isFallback = OcrSyncQueueService.isFallbackRecipient(tx.note);
        if (isFallback && tx.slipImagePath != null && tx.slipImageHash != null) {
          await _syncQueue.enqueue(OcrSyncItem(
            transactionId: tx.id,
            imagePath:     tx.slipImagePath!,
            imageHash:     tx.slipImageHash!,
            queuedAt:      DateTime.now(),
          ));
          hasEnqueued = true;
        }
      }

      if (hasEnqueued) {
        // Silently drain queue in background if network is available
        Future(() => _syncQueue.drainQueue()).catchError((_) {});
      }
    }

    // Clear parsed list after import
    state = state.copyWith(
      parsedSlips: [],
      selectedSlipIds: [],
      statusMessage: 'นำเข้าข้อมูล ${newTransactions.length} รายการสำเร็จ!',
    );

    return newTransactions.length;
  }

  void clearStatus() {
    state = state.copyWith(statusMessage: '');
  }

  /// Auto-scan and auto-import all new slips silently when the app opens (Zero-Click)
  Future<int> autoScanAndImportOnLaunch() async {
    try {
      state = state.copyWith(
        isScanning: true,
        statusMessage: 'เหมียวจดกำลังตรวจสลิปใหม่...',
        lastError: null,
      );

      final perm = await _albumService.requestPermission();
      if (!perm.hasAccess) {
        state = state.copyWith(isScanning: false, statusMessage: '');
        return 0;
      }

      await loadAlbums();
      final selectedAlbumIds = state.albums.where((a) => a.isSelected).map((a) => a.id).toList();
      final scanLimit = await _storage.getScanHistoryLimit();
      final assets = await _albumService.fetchAssetsFromTargetedAlbums(
        selectedAlbumIds: selectedAlbumIds.isNotEmpty ? selectedAlbumIds : null,
        maxCount: scanLimit,
      );

      if (assets.isEmpty) {
        state = state.copyWith(isScanning: false, statusMessage: '');
        return 0;
      }

      await _processAssets(assets);

      // Auto-import all non-duplicate slips found (do not wait for user confirmation)
      final autoImportCount = await importSelectedSlips();
      state = state.copyWith(
        isScanning: false,
        statusMessage: autoImportCount > 0
            ? 'จดสลิปใหม่ให้แล้ว $autoImportCount รายการ ✨'
            : 'ไม่พบสลิปใหม่ในวันนี้',
      );
      return autoImportCount;
    } catch (e) {
      state = state.copyWith(isScanning: false, statusMessage: '');
      return 0;
    }
  }

  @override
  void dispose() {
    _hybridOcr.dispose();
    _notif.cancelAll();
    super.dispose();
  }
}

final ingestionProvider = StateNotifierProvider<IngestionNotifier, IngestionState>((ref) {
  return IngestionNotifier(ref);
});

/// Lightweight semaphore for limiting concurrent async tasks.
class _Semaphore {
  _Semaphore(this._maxCount) : _count = _maxCount;

  final int _maxCount;
  int _count;
  final _waiters = <Completer<void>>[];

  Future<void> acquire() async {
    if (_count > 0) {
      _count--;
      return;
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    await completer.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      final next = _waiters.removeAt(0);
      next.complete();
    } else {
      _count++;
      if (_count > _maxCount) _count = _maxCount;
    }
  }
}
