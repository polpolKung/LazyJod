import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/local_storage_service.dart';
import '../../../core/utils/hash_helper.dart';
import '../../transactions/models/transaction_model.dart';
import '../../transactions/models/transaction_type.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../models/slip_parse_result.dart';
import '../services/duplicate_detection_service.dart';
import '../services/targeted_album_service.dart';
import '../services/thai_bank_slip_parser.dart';

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
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final ImagePicker _imagePicker = ImagePicker();
  final Ref _ref;
  final _uuid = const Uuid();

  IngestionNotifier(this._ref) : super(const IngestionState()) {
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
    final assets = await _albumService.fetchAssetsFromTargetedAlbums(
      selectedAlbumIds: selectedAlbumIds.isNotEmpty ? selectedAlbumIds : null,
      maxCount: 1000,
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

      state = state.copyWith(
        isScanning: true,
        scanProgress: 0.0,
        statusMessage: 'กำลังเตรียมรูปที่เลือก ${pickedFiles.length} รูป...',
        lastError: null,
      );

      final existingTransactions = _ref.read(transactionProvider);
      _dupService.registerExistingTransactions(existingTransactions);

      final List<SlipParseResult> parsedResults = [];
      final total = pickedFiles.length;
      int errorCount = 0;
      String? caughtError;

      for (int i = 0; i < total; i++) {
        final xfile = pickedFiles[i];
        final progress = (i + 1) / total;
        state = state.copyWith(
          scanProgress: progress,
          statusMessage: 'กำลังสแกนรูปที่ ${i + 1}/$total...',
        );

        final file = File(xfile.path);
        try {
          final bytes = await file.readAsBytes();
          final imageHash = HashHelper.hashBytes(bytes);

          final inputImage = InputImage.fromFile(file);
          final recognizedText = await _textRecognizer.processImage(inputImage);

          final slipResult = ThaiBankSlipParser.parse(
            recognizedText.text,
            imagePath: file.path,
            imageHash: imageHash,
          );

          final slipId = 'slip_${_uuid.v4()}';
          final isDup = _dupService.isDuplicate(slipResult, existingTransactions);

          parsedResults.add(slipResult.copyWith(
            id: slipId,
            isDuplicate: isDup,
          ));
        } catch (e) {
          errorCount++;
          caughtError = e.toString();
        }
      }

      final selectedIds = parsedResults.where((s) => !s.isDuplicate && s.amount > 0).map((s) => s.id!).toList();

      String msg = 'สแกนเสร็จสิ้น พบสลิป ${parsedResults.length} รายการ';
      if (parsedResults.isEmpty && errorCount > 0) {
        msg = 'เกิดข้อผิดพลาดในการประมวลผล OCR ($caughtError)';
      }

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

    final List<SlipParseResult> parsedResults = [];
    final total = newAssets.length;
    int errorCount = 0;
    String? lastError;
    final Set<String> processedAssetIds = {};

    for (int i = 0; i < total; i++) {
      final asset = newAssets[i];
      final progress = (i + 1) / total;
      state = state.copyWith(
        scanProgress: progress,
        statusMessage: 'กำลังสแกนสลิป ${i + 1}/$total...',
      );

      final file = await asset.file;
      if (file == null) continue;

      try {
        final bytes = await file.readAsBytes();
        final imageHash = HashHelper.hashBytes(bytes);

        // Run ML Kit Text Recognition on device
        final inputImage = InputImage.fromFile(file);
        final recognizedText = await _textRecognizer.processImage(inputImage);

        // Parse extracted text with Thai Banks Slip Parser
        // Use asset.createDateTime as fallback so slips keep their real date/time
        final slipResult = ThaiBankSlipParser.parse(
          recognizedText.text,
          imagePath: file.path,
          imageHash: imageHash,
          fallbackDateTime: asset.createDateTime,
        );

        final slipId = 'slip_${_uuid.v4()}';
        final isDup = _dupService.isDuplicate(slipResult, existingTransactions);

        parsedResults.add(slipResult.copyWith(
          id: slipId,
          isDuplicate: isDup,
        ));

        // Mark this asset as processed regardless of whether it's a slip
        processedAssetIds.add(asset.id);
      } catch (e) {
        errorCount++;
        lastError = e.toString();
        // Still mark as processed so we don't re-attempt a broken image next time
        processedAssetIds.add(asset.id);
      }
    }

    // Persist newly scanned asset IDs so they are skipped on next launch
    if (processedAssetIds.isNotEmpty) {
      await _storage.addScannedAssetIds(processedAssetIds);
    }

    // Default select non-duplicate slips
    final selectedIds = parsedResults.where((s) => !s.isDuplicate && s.amount > 0).map((s) => s.id!).toList();

    String resultMsg = 'สแกนตรวจภาพ $total รูป พบสลิป ${parsedResults.length} รายการ';
    if (skippedCount > 0) {
      resultMsg += ' (ข้าม $skippedCount รูปที่ตรวจแล้ว)';
    }
    if (parsedResults.isEmpty && errorCount > 0) {
      if (lastError != null && lastError.contains('download')) {
        resultMsg = 'กำลังรอ Google Play Services ติดตั้งโมเดล OCR กรุณารอสักครู่แล้วลองใหม่';
      } else {
        resultMsg = 'ตรวจพบรูป $total รูป แต่ OCR เกิดข้อผิดพลาด ($lastError)';
      }
    } else if (parsedResults.isEmpty) {
      resultMsg = 'ตรวจภาพ $total รูปในโฟลเดอร์แล้ว แต่ไม่พบรูปแบบสลิป สามารถกดเลือกรูปเองได้';
    }

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

  /// Import selected parsed slips directly into user's transactions
  Future<int> importSelectedSlips() async {
    final selectedSlips = state.parsedSlips
        .where((s) => state.selectedSlipIds.contains(s.id))
        .toList();

    final List<TransactionModel> newTransactions = [];

    for (final slip in selectedSlips) {
      newTransactions.add(TransactionModel(
        id: 'tx_${_uuid.v4()}',
        type: TransactionType.expense,
        amount: slip.amount,
        dateTime: slip.dateTime,
        categoryId: slip.suggestedCategoryId ?? 'cat_food',
        note: slip.recipientName,
        tags: [slip.bank.shortCode],
        bankSource: slip.bank,
        slipImagePath: slip.imagePath,
        slipImageHash: slip.imageHash,
        slipRefId: slip.refId,
        isFromSlip: true,
      ));
    }

    if (newTransactions.isNotEmpty) {
      await _ref.read(transactionProvider.notifier).addBatchTransactions(newTransactions);
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
        statusMessage: 'ขี้เกียจจดกำลังตรวจสลิปใหม่...',
        lastError: null,
      );

      final perm = await _albumService.requestPermission();
      if (!perm.hasAccess) {
        state = state.copyWith(isScanning: false, statusMessage: '');
        return 0;
      }

      await loadAlbums();
      final selectedAlbumIds = state.albums.where((a) => a.isSelected).map((a) => a.id).toList();
      final assets = await _albumService.fetchAssetsFromTargetedAlbums(
        selectedAlbumIds: selectedAlbumIds.isNotEmpty ? selectedAlbumIds : null,
        maxCount: 1000,
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
    _textRecognizer.close();
    super.dispose();
  }
}

final ingestionProvider = StateNotifierProvider<IngestionNotifier, IngestionState>((ref) {
  return IngestionNotifier(ref);
});
