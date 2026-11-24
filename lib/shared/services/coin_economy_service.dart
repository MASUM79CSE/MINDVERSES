import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../core/errors/app_failure.dart';
import '../../core/storage/local_storage_service.dart';
import '../../core/storage/storage_keys.dart';
import '../models/coin_transaction.dart';
import '../models/player_profile.dart';

abstract class CoinEconomyService {
  Future<int> getBalance();
  Future<bool> recordTransaction({
    required CoinTransactionType type,
    required int amount,
    required String referenceId,
  });
  Future<bool> recordTransactionInTransaction(
    LocalStorageTransaction transaction, {
    required CoinTransactionType type,
    required int amount,
    required String referenceId,
  });
  Future<List<CoinTransaction>> getTransactionHistory();
  Future<bool> canAfford(int cost);
}

class CoinEconomyServiceImpl implements CoinEconomyService {
  static const Uuid _uuid = Uuid();

  final LocalStorageService _storage;

  CoinEconomyServiceImpl(this._storage);

  @override
  Future<int> getBalance() async {
    final profile = await _storage.readDocument(StorageKeys.playerProfileFile);
    final profileBalance = profile?['coinBalance'];
    if (profileBalance is int) return profileBalance;

    final ledger = await _storage.readDocument(StorageKeys.coinLedgerFile);
    final transactions = _transactionsFrom(ledger);
    return transactions.isEmpty ? 100 : transactions.last.balanceAfter;
  }

  @override
  Future<bool> canAfford(int cost) async => (await getBalance()) >= cost;

  @override
  Future<bool> recordTransaction({
    required CoinTransactionType type,
    required int amount,
    required String referenceId,
  }) {
    return _storage.runInTransaction(
      (transaction) => recordTransactionInTransaction(
        transaction,
        type: type,
        amount: amount,
        referenceId: referenceId,
      ),
    );
  }

  @override
  Future<bool> recordTransactionInTransaction(
    LocalStorageTransaction transaction, {
    required CoinTransactionType type,
    required int amount,
    required String referenceId,
  }) async {
    final timestamp = DateTime.now().toUtc();
    final transactionId = _uuid.v4();
    final idempotencyKey = 'coin:${jsonEncode([type.name, referenceId])}';
    final ledger = await transaction.readDocument(StorageKeys.coinLedgerFile);
    final transactions = _transactionsFrom(ledger);
    if (transactions.any((entry) => entry.type == type && entry.referenceId == referenceId)) {
      return false;
    }

    final profile = await transaction.readDocument(StorageKeys.playerProfileFile);
    final storedBalance = profile?['coinBalance'];
    final balanceBefore = storedBalance is int
        ? storedBalance
        : (transactions.isEmpty ? 100 : transactions.last.balanceAfter);
    final newBalance = balanceBefore + amount;
    if (newBalance < 0) {
      throw EconomyFailure('Insufficient coins: Available $balanceBefore, required ${amount.abs()}');
    }

    final claimed = await transaction.claimIdempotencyKey(idempotencyKey, {
      'referenceId': referenceId,
      'type': type.name,
      'claimedAt': timestamp.toIso8601String(),
    });
    if (!claimed) return false;

    if (transactions.isEmpty) {
      transactions.add(_createTransaction(
        type: CoinTransactionType.openingBalance,
        amount: balanceBefore,
        balanceAfter: balanceBefore,
        referenceId: 'opening_balance',
        timestamp: timestamp,
      ));
    } else if (transactions.last.balanceAfter != balanceBefore) {
      transactions.add(_createTransaction(
        type: CoinTransactionType.balanceReconciliation,
        amount: balanceBefore - transactions.last.balanceAfter,
        balanceAfter: balanceBefore,
        referenceId: 'profile_balance_reconciliation',
        timestamp: timestamp,
      ));
    }

    transactions.add(_createTransaction(
      type: type,
      amount: amount,
      balanceAfter: newBalance,
      referenceId: referenceId,
      timestamp: timestamp,
      transactionId: transactionId,
    ));
    await transaction.writeDocument(StorageKeys.coinLedgerFile, {
      'schemaVersion': 2,
      'transactions': transactions.map((entry) => entry.toJson()).toList(),
    });

    final updatedProfile = profile ??
        PlayerProfile.initial(id: 'usr_${timestamp.microsecondsSinceEpoch}').toJson();
    updatedProfile['coinBalance'] = newBalance;
    updatedProfile['lastActiveAt'] = timestamp.toIso8601String();
    await transaction.writeDocument(StorageKeys.playerProfileFile, updatedProfile);
    return true;
  }

  @override
  Future<List<CoinTransaction>> getTransactionHistory() async {
    final ledger = await _storage.readDocument(StorageKeys.coinLedgerFile);
    return List.unmodifiable(_transactionsFrom(ledger));
  }

  List<CoinTransaction> _transactionsFrom(Map<String, dynamic>? ledger) {
    final rawTransactions = ledger?['transactions'];
    if (rawTransactions is! List) return [];
    return rawTransactions
        .map((item) => CoinTransaction.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  CoinTransaction _createTransaction({
    required CoinTransactionType type,
    required int amount,
    required int balanceAfter,
    required String referenceId,
    required DateTime timestamp,
    String? transactionId,
  }) {
    return CoinTransaction(
      transactionId: transactionId ?? _uuid.v4(),
      timestamp: timestamp,
      type: type,
      amount: amount,
      balanceAfter: balanceAfter,
      referenceId: referenceId,
    );
  }
}
