import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazy_jod/core/utils/hash_helper.dart';
import 'package:lazy_jod/features/ingestion/models/slip_parse_result.dart';
import 'package:lazy_jod/features/ingestion/models/thai_bank.dart';
import 'package:lazy_jod/features/ingestion/services/duplicate_detection_service.dart';
import 'package:lazy_jod/features/transactions/models/transaction_model.dart';
import 'package:lazy_jod/features/transactions/models/transaction_type.dart';

void main() {
  group('DuplicateDetectionService Tests', () {
    late DuplicateDetectionService service;
    late List<TransactionModel> existingList;

    setUp(() {
      service = DuplicateDetectionService();
      final now = DateTime(2026, 9, 19, 14, 30);

      existingList = [
        TransactionModel(
          id: 'tx_1',
          type: TransactionType.expense,
          amount: 500.0,
          dateTime: now,
          categoryId: 'cat_food',
          note: 'ร้านส้มตำป้าณี',
          slipImageHash: 'hash_abc_123',
          slipRefId: 'REF_99990001',
          isFromSlip: true,
        ),
      ];

      service.registerExistingTransactions(existingList);
    });

    test('1. Should detect duplicate via exact image hash match', () {
      final newSlip = SlipParseResult(
        bank: ThaiBank.kbank,
        amount: 250.0,
        dateTime: DateTime(2026, 9, 19, 15, 0),
        recipientName: 'ร้านค้าใหม่',
        imageHash: 'hash_abc_123', // Matches tx_1
        rawOcrText: '',
      );

      final isDup = service.isDuplicate(newSlip, existingList);
      expect(isDup, isTrue);
    });

    test('2. Should detect duplicate via exact Ref ID match', () {
      final newSlip = SlipParseResult(
        bank: ThaiBank.scb,
        amount: 300.0,
        dateTime: DateTime(2026, 9, 19, 16, 0),
        recipientName: 'ร้านสะดวกซื้อ',
        refId: 'REF_99990001', // Matches tx_1
        rawOcrText: '',
      );

      final isDup = service.isDuplicate(newSlip, existingList);
      expect(isDup, isTrue);
    });

    test('3. Should detect duplicate via fuzzy amount, recipient and time bucket', () {
      // Same amount (500.0), same recipient ('ส้มตำป้าณี'), time within 1 minute
      final newSlip = SlipParseResult(
        bank: ThaiBank.kbank,
        amount: 500.0,
        dateTime: DateTime(2026, 9, 19, 14, 31), // 1 min diff
        recipientName: 'ส้มตำป้าณี',
        rawOcrText: '',
      );

      final isDup = service.isDuplicate(newSlip, existingList);
      expect(isDup, isTrue);
    });

    test('4. Should NOT mark different transactions as duplicate', () {
      final uniqueSlip = SlipParseResult(
        bank: ThaiBank.ktb,
        amount: 1500.0,
        dateTime: DateTime(2026, 9, 19, 17, 45),
        recipientName: 'เติมน้ำมัน ปตท',
        refId: 'REF_UNIQUE_7777',
        imageHash: 'hash_unique_999',
        rawOcrText: '',
      );

      final isDup = service.isDuplicate(uniqueSlip, existingList);
      expect(isDup, isFalse);
    });
  });
}
