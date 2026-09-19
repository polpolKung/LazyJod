import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
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
  final List<TargetedAlbumInfo> albums;
  final List<SlipParseResult> parsedSlips;
  final List<String> selectedSlipIds;

  const IngestionState({
    this.isScanning = false,
    this.scanProgress = 0.0,
    this.statusMessage = '',
    this.albums = const [],
    this.parsedSlips = const [],
    this.selectedSlipIds = const [],
  });

  IngestionState copyWith({
    bool? isScanning,
    double? scanProgress,
    String? statusMessage,
    List<TargetedAlbumInfo>? albums,
    List<SlipParseResult>? parsedSlips,
    List<String>? selectedSlipIds,
  }) {
    return IngestionState(
      isScanning: isScanning ?? this.isScanning,
      scanProgress: scanProgress ?? this.scanProgress,
      statusMessage: statusMessage ?? this.statusMessage,
      albums: albums ?? this.albums,
      parsedSlips: parsedSlips ?? this.parsedSlips,
      selectedSlipIds: selectedSlipIds ?? this.selectedSlipIds,
    );
  }
}

class IngestionNotifier extends StateNotifier<IngestionState> {
  final TargetedAlbumService _albumService = TargetedAlbumService();
  final DuplicateDetectionService _dupService = DuplicateDetectionService();
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
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

  /// Scan targeted albums for slips, perform on-device OCR, and check duplicates
  Future<void> scanTargetedAlbums() async {
    state = state.copyWith(
      isScanning: true,
      scanProgress: 0.0,
      statusMessage: 'กำลังขอสิทธิ์เข้าถึงโฟลเดอร์สลิป...',
    );

    final perm = await _albumService.requestPermission();
    if (!perm.hasAccess) {
      state = state.copyWith(
        isScanning: false,
        statusMessage: 'ไม่ได้รับสิทธิ์เข้าถึงรูปภาพ',
      );
      return;
    }

    state = state.copyWith(statusMessage: 'กำลังค้นหาภาพในโฟลเดอร์ธนาคาร...');

    final selectedAlbumIds = state.albums.where((a) => a.isSelected).map((a) => a.id).toList();
    final assets = await _albumService.fetchAssetsFromTargetedAlbums(
      selectedAlbumIds: selectedAlbumIds.isNotEmpty ? selectedAlbumIds : null,
      maxCount: 30,
    );

    if (assets.isEmpty) {
      state = state.copyWith(
        isScanning: false,
        statusMessage: 'ไม่พบรูปภาพในโฟลเดอร์ธนาคารที่กำหนด',
      );
      return;
    }

    // Initialize duplicate detector with existing transactions
    final existingTransactions = _ref.read(transactionProvider);
    _dupService.registerExistingTransactions(existingTransactions);

    final List<SlipParseResult> parsedResults = [];
    final total = assets.length;

    for (int i = 0; i < total; i++) {
      final asset = assets[i];
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

        // Parse extracted text with 16 Thai Banks Slip Parser
        final slipResult = ThaiBankSlipParser.parse(
          recognizedText.text,
          imagePath: file.path,
          imageHash: imageHash,
        );

        final slipId = 'slip_${_uuid.v4()}';
        final isDup = _dupService.isDuplicate(slipResult, existingTransactions);

        final finalizedResult = slipResult.copyWith(
          id: slipId,
          isDuplicate: isDup,
        );

        parsedResults.add(finalizedResult);
      } catch (e) {
        print('Error OCR processing asset ${asset.id}: $e');
      }
    }

    // Default select non-duplicate slips
    final selectedIds = parsedResults.where((s) => !s.isDuplicate && s.amount > 0).map((s) => s.id!).toList();

    state = state.copyWith(
      isScanning: false,
      scanProgress: 1.0,
      statusMessage: 'สแกนเสร็จสิ้น พบสลิป ${parsedResults.length} รายการ',
      parsedSlips: parsedResults,
      selectedSlipIds: selectedIds,
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

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }
}

final ingestionProvider = StateNotifierProvider<IngestionNotifier, IngestionState>((ref) {
  return IngestionNotifier(ref);
});
