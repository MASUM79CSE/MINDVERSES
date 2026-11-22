import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/core/errors/app_failure.dart';
import 'package:mindverse/core/storage/local_storage_service.dart';
import 'package:mindverse/shared/models/coin_transaction.dart';
import 'package:mindverse/shared/services/coin_economy_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CoinEconomyService Tests', () {
    late LocalStorageService storage;
    late CoinEconomyService economy;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = LocalStorageService(prefs);
      economy = CoinEconomyServiceImpl(storage);
    });

    test('initial balance defaults to 100 starting coins', () async {
      final balance = await economy.getBalance();
      expect(balance, 100);
    });

    test('recordTransaction with positive amount awards coins and updates balance', () async {
      await economy.recordTransaction(
        type: CoinTransactionType.earnLevelClear,
        amount: 50,
        referenceId: 'cube_logic_1',
      );

      final newBalance = await economy.getBalance();
      expect(newBalance, 150);

      final history = await economy.getTransactionHistory();
      expect(history.length, 1);
      expect(history.first.amount, 50);
      expect(history.first.referenceId, 'cube_logic_1');
      expect(history.first.balanceAfter, 150);
    });

    test('recordTransaction with negative amount spends coins when sufficient', () async {
      expect(await economy.canAfford(30), isTrue);

      await economy.recordTransaction(
        type: CoinTransactionType.spendHint,
        amount: -30,
        referenceId: 'cube_logic_3_hint',
      );

      final remaining = await economy.getBalance();
      expect(remaining, 70);
    });

    test('recordTransaction throws EconomyFailure when spending exceeds balance', () async {
      expect(await economy.canAfford(500), isFalse);

      expect(
        () => economy.recordTransaction(
          type: CoinTransactionType.spendHint,
          amount: -500,
          referenceId: 'failed_purchase',
        ),
        throwsA(isA<EconomyFailure>()),
      );
      // Balance remains unchanged
      expect(await economy.getBalance(), 100);
    });

    test('recordTransaction rejects duplicate reward claim for same referenceId', () async {
      await economy.recordTransaction(
        type: CoinTransactionType.earnAchievement,
        amount: 100,
        referenceId: 'first_win_badge',
      );
      expect(await economy.getBalance(), 200);

      // Attempt second claim with same referenceId and type
      expect(
        () => economy.recordTransaction(
          type: CoinTransactionType.earnAchievement,
          amount: 100,
          referenceId: 'first_win_badge',
        ),
        throwsA(isA<EconomyFailure>()),
      );

      expect(await economy.getBalance(), 200);
      final history = await economy.getTransactionHistory();
      expect(history.length, 1);
    });
  });
}
