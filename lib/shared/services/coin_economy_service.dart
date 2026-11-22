import '../../core/errors/app_failure.dart';
import '../../core/storage/local_storage_service.dart';
import '../../core/storage/storage_keys.dart';
import '../models/coin_transaction.dart';

abstract class CoinEconomyService {
  Future<int> getBalance();
  Future<void> recordTransaction({
    required CoinTransactionType type,
    required int amount,
    required String referenceId,
  });
  Future<List<CoinTransaction>> getTransactionHistory();
  Future<bool> canAfford(int cost);
}

class CoinEconomyServiceImpl implements CoinEconomyService {
  final LocalStorageService _storage;
  List<CoinTransaction>? _ledgerCache;
  int _currentBalance = 100; // Starting baseline

  CoinEconomyServiceImpl(this._storage);

  Future<void> _loadLedger() async {
    if (_ledgerCache != null) return;

    final data = await _storage.readDocument(StorageKeys.coinLedgerFile);
    if (data != null && data['transactions'] != null) {
      final rawList = data['transactions'] as List<dynamic>;
      _ledgerCache = rawList
          .map((item) => CoinTransaction.fromJson(item as Map<String, dynamic>))
          .toList();

      if (_ledgerCache!.isNotEmpty) {
        _currentBalance = _ledgerCache!.last.balanceAfter;
      }
    } else {
      _ledgerCache = [];
      _currentBalance = 100;
    }
  }

  @override
  Future<int> getBalance() async {
    await _loadLedger();
    return _currentBalance;
  }

  @override
  Future<bool> canAfford(int cost) async {
    final balance = await getBalance();
    return balance >= cost;
  }

  @override
  Future<void> recordTransaction({
    required CoinTransactionType type,
    required int amount,
    required String referenceId,
  }) async {
    await _loadLedger();

    // Prevent duplicate reward claims for the same reference
    if (amount > 0) {
      final alreadyClaimed = _ledgerCache!.any(
        (tx) => tx.referenceId == referenceId && tx.type == type,
      );
      if (alreadyClaimed) {
        throw EconomyFailure('Reward for reference $referenceId has already been claimed.');
      }
    }

    // Verify sufficient funds for expenditures
    if (amount < 0 && (_currentBalance + amount < 0)) {
      throw EconomyFailure('Insufficient coins: Available $_currentBalance, required ${amount.abs()}');
    }

    final newBalance = _currentBalance + amount;
    final transaction = CoinTransaction(
      transactionId: 'tx_${DateTime.now().microsecondsSinceEpoch}',
      timestamp: DateTime.now().toUtc(),
      type: type,
      amount: amount,
      balanceAfter: newBalance,
      referenceId: referenceId,
    );

    _ledgerCache!.add(transaction);
    _currentBalance = newBalance;

    final serialized = {
      'schemaVersion': 1,
      'transactions': _ledgerCache!.map((tx) => tx.toJson()).toList(),
    };

    await _storage.writeDocument(StorageKeys.coinLedgerFile, serialized);
  }

  @override
  Future<List<CoinTransaction>> getTransactionHistory() async {
    await _loadLedger();
    return List.unmodifiable(_ledgerCache!);
  }
}
