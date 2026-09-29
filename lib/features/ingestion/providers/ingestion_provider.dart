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
    final expenseFolders = await _storage.getExpenseFolderNames();
    final incomeFolders = await _storage.getIncomeFolderNames();
    _albumService.setExpenseFolderNames(expenseFolders);
    _albumService.setIncomeFolderNames(incomeFolders);

    final savedExpenseIds = await _storage.getSelectedExpenseAlbumIds();
    final savedIncomeIds = await _storage.getSelectedIncomeAlbumIds();

    // Check if user has ever explicitly configured albums.
    // null  → first launch → getAvailableAlbums uses conservative auto-select.
    // Set   → configured  → getAvailableAlbums uses ONLY those IDs (explicit-only).
    final isConfigured = await _storage.isScanAlbumsConfigured();
    final albums = await _albumService.getAvailableAlbums(
      savedExpenseIds: isConfigured ? savedExpenseIds : null,
      savedIncomeIds: isConfigured ? savedIncomeIds : null,
    );
    state = state.copyWith(albums: albums);
  }

  Future<void> toggleAlbumSelection(String albumId, {bool isIncome = false}) async {
    final updated = state.albums.map((a) {
      if (a.id == albumId) {
        if (isIncome) {
          final newIncomeVal = !a.isIncomeSelected;
          // If selected for income, deselect from expense
          return a.copyWith(
            isIncomeSelected: newIncomeVal,
            isSelected: newIncomeVal ? false : a.isSelected,
          );
        } else {
          final newExpenseVal = !a.isSelected;
          // If selected for expense, deselect from income
          return a.copyWith(
            isSelected: newExpenseVal,
            isIncomeSelected: newExpenseVal ? false : a.isIncomeSelected,
          );
        }
      }
      return a;
    }).toList();

    state = state.copyWith(albums: updated);

    // Persist selections
    final selectedIncome = updated.where((a) => a.isIncomeSelected).map((a) => a.id).toSet();
    final selectedExpense = updated.where((a) => a.isSelected).map((a) => a.id).toSet();
    await _storage.setSelectedIncomeAlbumIds(selectedIncome);
    await _storage.setSelectedExpenseAlbumIds(selectedExpense);
    // Mark as explicitly configured — from now on, ONLY explicit IDs are used (even if empty)
    await _storage.setScanAlbumsConfigured(true);
  }

  Future<void> confirmAlbumSelection() async {
    final selectedIncome = state.albums.where((a) => a.isIncomeSelected).map((a) => a.id).toSet();
    final selectedExpense = state.albums.where((a) => a.isSelected).map((a) => a.id).toSet();
    await _storage.setSelectedIncomeAlbumIds(selectedIncome);
    await _storage.setSelectedExpenseAlbumIds(selectedExpense);
    await _storage.setScanAlbumsConfigured(true);
  }

  Future<void> addCustomFolderName(String name, {bool isIncome = false}) async {
    if (isIncome) {
      _albumService.addIncomeFolderName(name);
      await _storage.setIncomeFolderNames(_albumService.incomeFolderNames);
    } else {
      _albumService.addTargetedFolderName(name);
      await _storage.setExpenseFolderNames(_albumService.targetedFolderNames);
    }
    await loadAlbums();
  }

  /// Change a slip's transaction type manually (e.g. from review screen)
  void setSlipTransactionType(String slipId, TransactionType newType) {
    final updated = state.parsedSlips.map((slip) {
      if (slip.id == slipId) {
        final newCategory = ThaiBankSlipParser.suggestCategory(
          slip.recipientName,
          slip.rawOcrText,
          transactionType: newType,
          sender: slip.senderName,
        );
        return slip.copyWith(
          transactionType: newType,
          suggestedCategoryId: newCategory,
        );
      }
      return slip;
    }).toList();

    state = state.copyWith(parsedSlips: updated);
  }

  /// Batch update all parsed slips to a specific transaction type
  void setAllSlipsTransactionType(TransactionType newType) {
    final updated = state.parsedSlips.map((slip) {
      final newCategory = ThaiBankSlipParser.suggestCategory(
        slip.recipientName,
        slip.rawOcrText,
        transactionType: newType,
        sender: slip.senderName,
      );
      return slip.copyWith(
        transactionType: newType,
        suggestedCategoryId: newCategory,
      );
    }).toList();

    state = state.copyWith(parsedSlips: updated);
  }

  /// 1. Scan targeted albums for slips (both Expense and Income),
  /// perform on-device OCR, and check duplicates
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
    await _notif.requestPermission();

    state = state.copyWith(statusMessage: 'กำลังค้นหาภาพในโฟลเดอร์ที่เลือก...');

    final selectedExpenseIds = state.albums.where((a) => a.isSelected).map((a) => a.id).toList();
    final selectedIncomeIds = state.albums.where((a) => a.isIncomeSelected).map((a) => a.id).toList();

    final scanLimit = await _storage.getScanHistoryLimit();
    final scannables = await _albumService.fetchAssetsToScan(
      selectedExpenseAlbumIds: selectedExpenseIds.isNotEmpty ? selectedExpenseIds : null,
      selectedIncomeAlbumIds: selectedIncomeIds.isNotEmpty ? selectedIncomeIds : null,
      maxCount: scanLimit,
    );

    if (scannables.isEmpty) {
      final totalAlbums = state.albums.length;
      final selectedCount = selectedExpenseIds.length + selectedIncomeIds.length;
      state = state.copyWith(
        isScanning: false,
        totalScannedAssets: 0,
        statusMessage: 'ไม่พบรูปภาพในโฟลเดอร์ที่เลือก (พบ $totalAlbums อัลบั้ม, เลือกไว้ $selectedCount อัลบั้ม) สามารถกด "เลือกโฟลเดอร์" เพื่อเลือกเพิ่ม หรือใช้ "เลือกรูปจากแกลเลอรี"',
      );
      return;
    }

    await _processScannableAssets(scannables, skipSeenAssets: false);
  }

  /// 2. Pick slip images directly from device gallery with intentional transaction type
  Future<void> pickAndScanGallerySlips({TransactionType transactionType = TransactionType.expense}) async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage();
      if (pickedFiles.isEmpty) return;

      await _notif.requestPermission();

      final typeLabel = transactionType == TransactionType.income ? 'รายรับ' : 'รายจ่าย';

      state = state.copyWith(
        isScanning: true,
        scanProgress: 0.0,
        statusMessage: 'กำลังเตรียมรูปสลิป$typeLabel ${pickedFiles.length} รูป...',
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
              transactionType: transactionType,
            );

            final slipId = 'slip_${_uuid.v4()}';
            final isDup = _dupService.isDuplicate(slipResult, existingTransactions);
            results[i] = slipResult.copyWith(
              id: slipId,
              isDuplicate: isDup,
              transactionType: transactionType,
            );
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

  Future<void> _processScannableAssets(List<ScannableAsset> scannables, {bool skipSeenAssets = true}) async {
    final existingTransactions = _ref.read(transactionProvider);
    _dupService.registerExistingTransactions(existingTransactions);

    // Load persisted asset IDs that have already been OCR-scanned
    final seenAssetIds = skipSeenAssets ? await _storage.loadScannedAssetIds() : <String>{};

    // Filter out assets already scanned in previous sessions
    final newScannables = skipSeenAssets
        ? scannables.where((s) => !seenAssetIds.contains(s.asset.id)).toList()
        : scannables;

    final skippedCount = scannables.length - newScannables.length;

    if (newScannables.isEmpty) {
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

    final total = newScannables.length;
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
        final scannable = newScannables[i];
        final asset = scannable.asset;
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
            transactionType: scannable.targetType,
          );

          final slipId = 'slip_${_uuid.v4()}';
          final isDup = _dupService.isDuplicate(slipResult, existingTransactions);
          results[i] = slipResult.copyWith(
            id: slipId,
            isDuplicate: isDup,
            transactionType: scannable.targetType,
          );

          processedAssetIds.add(asset.id);
        } catch (e) {
          errorCount++;
          lastError = e.toString();
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
      final isSelf = isSelfTransfer(slip.senderName, slip.recipientName);
      final txType = isSelf ? TransactionType.transfer : slip.transactionType;

      String note;
      String categoryId;
      List<String> tags;

      if (txType == TransactionType.income) {
        final sender = (slip.senderName != null && slip.senderName!.isNotEmpty)
            ? slip.senderName!
            : null;
        note = sender != null ? 'รับเงินจาก: $sender' : 'รายรับ (${slip.recipientName})';
        categoryId = slip.suggestedCategoryId ?? 'cat_other_income';
        tags = [slip.bank.shortCode, 'รายรับ'];
      } else if (txType == TransactionType.transfer) {
        note = 'ย้ายเงิน: ${slip.recipientName}';
        categoryId = 'cat_transfer';
        tags = [slip.bank.shortCode, 'ย้ายเงิน'];
      } else {
        note = slip.recipientName;
        categoryId = slip.suggestedCategoryId ?? 'cat_food';
        tags = [slip.bank.shortCode];
      }

      newTransactions.add(TransactionModel(
        id: 'tx_${_uuid.v4()}',
        type: txType,
        amount: slip.amount,
        dateTime: slip.dateTime,
        categoryId: categoryId,
        note: note,
        tags: tags,
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
        statusMessage: 'จ้อดกำลังช่วยตรวจสลิปใหม่อยู่... 🦥',
        lastError: null,
      );

      final perm = await _albumService.requestPermission();
      if (!perm.hasAccess) {
        state = state.copyWith(isScanning: false, statusMessage: '');
        return 0;
      }

      await loadAlbums();
      await _notif.requestPermission();
      final selectedExpenseIds = state.albums.where((a) => a.isSelected).map((a) => a.id).toList();
      final selectedIncomeIds = state.albums.where((a) => a.isIncomeSelected).map((a) => a.id).toList();

      final scanLimit = await _storage.getScanHistoryLimit();
      final scannables = await _albumService.fetchAssetsToScan(
        selectedExpenseAlbumIds: selectedExpenseIds.isNotEmpty ? selectedExpenseIds : null,
        selectedIncomeAlbumIds: selectedIncomeIds.isNotEmpty ? selectedIncomeIds : null,
        maxCount: scanLimit,
      );

      if (scannables.isEmpty) {
        state = state.copyWith(isScanning: false, statusMessage: '');
        return 0;
      }

      await _processScannableAssets(scannables);

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
