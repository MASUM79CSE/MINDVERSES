import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/core/errors/app_failure.dart';
import 'package:mindverse/core/storage/local_storage_service.dart';
import 'package:mindverse/shared/models/coin_transaction.dart';
import 'package:mindverse/shared/services/coin_economy_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_storage.dart';

void main() {
  group('CoinEconomyService Tests', () {
    late LocalStorageService storage;
    late CoinEconomyService economy;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = await createTestLocalStorage(prefs);
      economy = CoinEconomyServiceImpl(storage);
    });

    tearDown(() async {
      await storage.close();
    });

    test('initial balance defaults to 100 starting coins', () async {
      final balance = await economy.getBalance();
      expect(balance, 100);
    });

    test('recordTransaction with positive amount awards coins and updates balance', () async {
      expect(await economy.recordTransaction(
        type: CoinTransactionType.earnLevelClear,
        amount: 50,
        referenceId: 'cube_logic_1',
      ), isTrue);

      expect(await economy.getBalance(), 150);

      final history = await economy.getTransactionHistory();
      expect(history, hasLength(2));
      expect(history.first.type, CoinTransactionType.openingBalance);
      expect(history.last.amount, 50);
      expect(history.last.referenceId, 'cube_logic_1');
      expect(history.last.balanceAfter, 150);
    });

    test('recordTransaction with negative amount spends coins when sufficient', () async {
      expect(await economy.canAfford(30), isTrue);

      await economy.recordTransaction(
        type: CoinTransactionType.spendHint,
        amount: -30,
        referenceId: 'cube_logic_3_hint',
      );

      expect(await economy.getBalance(), 70);
    });

    test('recordTransaction throws EconomyFailure when spending exceeds balance', () async {
      expect(await economy.canAfford(500), isFalse);

      await expectLater(
        economy.recordTransaction(
          type: CoinTransactionType.spendHint,
          amount: -500,
          referenceId: 'failed_purchase',
        ),
        throwsA(isA<EconomyFailure>()),
      );
      expect(await economy.getBalance(), 100);
    });

    test('recordTransaction returns false for a duplicate reference and type', () async {
      expect(await economy.recordTransaction(
        type: CoinTransactionType.earnAchievement,
        amount: 100,
        referenceId: 'first_win_badge',
      ), isTrue);
      expect(await economy.getBalance(), 200);

      expect(await economy.recordTransaction(
        type: CoinTransactionType.earnAchievement,
        amount: 100,
        referenceId: 'first_win_badge',
      ), isFalse);

      expect(await economy.getBalance(), 200);
      expect(await economy.getTransactionHistory(), hasLength(2));
    });
  });
}
