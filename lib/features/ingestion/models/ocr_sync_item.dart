/// A lightweight record stored in the sync queue for slips whose recipient
/// name could not be resolved to a real person/merchant name offline.
///
/// When the device comes back online the [OcrSyncQueueService] will re-process
/// the slip via Gemini Vision and patch [TransactionModel.note] in place.
class OcrSyncItem {
  /// ID of the already-saved [TransactionModel] to patch after cloud OCR.
  final String transactionId;

  /// Absolute path to the slip image on-device.
  final String imagePath;

  /// SHA-256 hash of the image bytes (used as a sanity-check guard).
  final String imageHash;

  /// UTC timestamp when this item was first enqueued.
  final DateTime queuedAt;

  const OcrSyncItem({
    required this.transactionId,
    required this.imagePath,
    required this.imageHash,
    required this.queuedAt,
  });

  Map<String, dynamic> toMap() => {
        'transactionId': transactionId,
        'imagePath': imagePath,
        'imageHash': imageHash,
        'queuedAt': queuedAt.toUtc().toIso8601String(),
      };

  factory OcrSyncItem.fromMap(Map<String, dynamic> map) => OcrSyncItem(
        transactionId: map['transactionId'] as String,
        imagePath: map['imagePath'] as String,
        imageHash: map['imageHash'] as String,
        queuedAt: DateTime.parse(map['queuedAt'] as String).toLocal(),
      );

  @override
  String toString() =>
      'OcrSyncItem(txId: $transactionId, queuedAt: $queuedAt)';
}
