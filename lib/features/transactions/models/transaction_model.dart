import '../../ingestion/models/thai_bank.dart';
import 'transaction_type.dart';

class TransactionModel {
  final String id;
  final TransactionType type;
  final double amount;
  final DateTime dateTime;
  final String categoryId;
  final String note;
  final List<String> tags;
  final ThaiBank bankSource;
  final String? slipImagePath;
  final String? slipImageHash;
  final String? slipRefId;
  final bool isFromSlip;
  final bool isFromStatement;
  final bool isRecurring;
  final int? installmentMonth;
  final int? totalInstallmentMonths;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.dateTime,
    required this.categoryId,
    this.note = '',
    this.tags = const [],
    this.bankSource = ThaiBank.unknown,
    this.slipImagePath,
    this.slipImageHash,
    this.slipRefId,
    this.isFromSlip = false,
    this.isFromStatement = false,
    this.isRecurring = false,
    this.installmentMonth,
    this.totalInstallmentMonths,
  });

  TransactionModel copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    DateTime? dateTime,
    String? categoryId,
    String? note,
    List<String>? tags,
    ThaiBank? bankSource,
    String? slipImagePath,
    String? slipImageHash,
    String? slipRefId,
    bool? isFromSlip,
    bool? isFromStatement,
    bool? isRecurring,
    int? installmentMonth,
    int? totalInstallmentMonths,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      dateTime: dateTime ?? this.dateTime,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      bankSource: bankSource ?? this.bankSource,
      slipImagePath: slipImagePath ?? this.slipImagePath,
      slipImageHash: slipImageHash ?? this.slipImageHash,
      slipRefId: slipRefId ?? this.slipRefId,
      isFromSlip: isFromSlip ?? this.isFromSlip,
      isFromStatement: isFromStatement ?? this.isFromStatement,
      isRecurring: isRecurring ?? this.isRecurring,
      installmentMonth: installmentMonth ?? this.installmentMonth,
      totalInstallmentMonths: totalInstallmentMonths ?? this.totalInstallmentMonths,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'dateTime': dateTime.toIso8601String(),
      'categoryId': categoryId,
      'note': note,
      'tags': tags,
      'bankSource': bankSource.name,
      'slipImagePath': slipImagePath,
      'slipImageHash': slipImageHash,
      'slipRefId': slipRefId,
      'isFromSlip': isFromSlip,
      'isFromStatement': isFromStatement,
      'isRecurring': isRecurring,
      'installmentMonth': installmentMonth,
      'totalInstallmentMonths': totalInstallmentMonths,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      amount: (map['amount'] as num).toDouble(),
      dateTime: DateTime.parse(map['dateTime'] as String),
      categoryId: map['categoryId'] as String,
      note: map['note'] as String? ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      bankSource: ThaiBank.values.firstWhere(
        (e) => e.name == map['bankSource'],
        orElse: () => ThaiBank.unknown,
      ),
      slipImagePath: map['slipImagePath'] as String?,
      slipImageHash: map['slipImageHash'] as String?,
      slipRefId: map['slipRefId'] as String?,
      isFromSlip: map['isFromSlip'] as bool? ?? false,
      isFromStatement: map['isFromStatement'] as bool? ?? false,
      isRecurring: map['isRecurring'] as bool? ?? false,
      installmentMonth: map['installmentMonth'] as int?,
      totalInstallmentMonths: map['totalInstallmentMonths'] as int?,
    );
  }
}
