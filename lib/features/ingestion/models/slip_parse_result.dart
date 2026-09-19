import 'thai_bank.dart';

class SlipParseResult {
  final String? id;
  final ThaiBank bank;
  final double amount;
  final DateTime dateTime;
  final String recipientName;
  final String? senderName;
  final String? refId;
  final String? suggestedCategoryId;
  final double confidenceScore;
  final String? imagePath;
  final String? imageHash;
  final String rawOcrText;
  final bool isDuplicate;

  const SlipParseResult({
    this.id,
    required this.bank,
    required this.amount,
    required this.dateTime,
    required this.recipientName,
    this.senderName,
    this.refId,
    this.suggestedCategoryId,
    this.confidenceScore = 1.0,
    this.imagePath,
    this.imageHash,
    required this.rawOcrText,
    this.isDuplicate = false,
  });

  SlipParseResult copyWith({
    String? id,
    ThaiBank? bank,
    double? amount,
    DateTime? dateTime,
    String? recipientName,
    String? senderName,
    String? refId,
    String? suggestedCategoryId,
    double? confidenceScore,
    String? imagePath,
    String? imageHash,
    String? rawOcrText,
    bool? isDuplicate,
  }) {
    return SlipParseResult(
      id: id ?? this.id,
      bank: bank ?? this.bank,
      amount: amount ?? this.amount,
      dateTime: dateTime ?? this.dateTime,
      recipientName: recipientName ?? this.recipientName,
      senderName: senderName ?? this.senderName,
      refId: refId ?? this.refId,
      suggestedCategoryId: suggestedCategoryId ?? this.suggestedCategoryId,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      imagePath: imagePath ?? this.imagePath,
      imageHash: imageHash ?? this.imageHash,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      isDuplicate: isDuplicate ?? this.isDuplicate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bank': bank.name,
      'amount': amount,
      'dateTime': dateTime.toIso8601String(),
      'recipientName': recipientName,
      'senderName': senderName,
      'refId': refId,
      'suggestedCategoryId': suggestedCategoryId,
      'confidenceScore': confidenceScore,
      'imagePath': imagePath,
      'imageHash': imageHash,
      'isDuplicate': isDuplicate,
    };
  }
}
