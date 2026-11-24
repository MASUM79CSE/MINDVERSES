import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/core/errors/app_failure.dart';
import 'package:mindverse/core/storage/local_storage_service.dart';
import 'package:mindverse/core/storage/storage_keys.dart';
import 'package:mindverse/shared/models/coin_transaction.dart';
import 'package:mindverse/shared/services/coin_economy_service.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences preferences;
  late LocalStorageService storage;

  Future<LocalStorageService> openMemoryStorage(SharedPreferences prefs) async {
    final database = await newDatabaseFactoryMemory().openDatabase('mindverse-test.db');
    return LocalStorageService.initialize(prefs, database: database);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    storage = await openMemoryStorage(preferences);
  });

  tearDown(() async {
    await storage.close();
  });

  test('transaction rolls back every document when an operation fails', () async {
    await storage.writeDocument('profile.json', {'coins': 100});
    await storage.writeDocument('levels.json', {'completed': 0});

    await expectLater(
      storage.runInTransaction((transaction) async {
        await transaction.writeDocument('profile.json', {'coins': 150});
        await transaction.writeDocument('levels.json', {'completed': 1});
        throw const StorageFailure('abort transaction');
      }),
      throwsA(isA<StorageFailure>()),
    );

    expect(await storage.readDocument('profile.json'), {'coins': 100});
    expect(await storage.readDocument('levels.json'), {'completed': 0});
  });

  test('concurrent transactions serialize read-modify-write updates', () async {
    await storage.writeDocument('counter.json', {'value': 0});

    await Future.wait(List.generate(40, (_) async {
      await storage.runInTransaction((transaction) async {
        final current = await transaction.readDocument('counter.json');
        await transaction.writeDocument('counter.json', {
          'value': (current!['value'] as int) + 1,
        });
      });
    }));

    expect((await storage.readDocument('counter.json'))!['value'], 40);
  });

  test('migrates verified legacy documents and recovers a valid backup', () async {
    const profileJson = '{"coinBalance":275,"username":"Legacy player"}';
    const levelJson = '{"levels":{}}';
    const achievementsJson = '{"achievements":{}}';
    const ledgerJson = '{"transactions":[]}';
    const dailyChallengeJson = '{"lastClaimedDate":"2026-11-22"}';
    SharedPreferences.setMockInitialValues({
      'player_profile.json': profileJson,
      'player_profile.json_sig': LocalStorageService.computeSignature(profileJson),
      'level_progress.json': '{"levels":"corrupt"}',
      'level_progress.json_sig': 'invalid-signature',
      'level_progress.json_bak': levelJson,
      'level_progress.json_bak_sig': LocalStorageService.computeSignature(levelJson),
      'achievements.json': achievementsJson,
      'achievements.json_sig': LocalStorageService.computeSignature(achievementsJson),
      'coin_ledger.json': ledgerJson,
      'coin_ledger.json_sig': LocalStorageService.computeSignature(ledgerJson),
      'daily_challenge.json': dailyChallengeJson,
      'daily_challenge.json_sig': LocalStorageService.computeSignature(dailyChallengeJson),
    });
    preferences = await SharedPreferences.getInstance();
    await storage.close();

    storage = await openMemoryStorage(preferences);

    expect(await storage.readDocument('player_profile.json'), {
      'coinBalance': 275,
      'username': 'Legacy player',
    });
    expect(await storage.readDocument('level_progress.json'), {'levels': {}});
    expect(await storage.readDocument('achievements.json'), {'achievements': {}});
    expect(await storage.readDocument('coin_ledger.json'), {'transactions': []});
    expect(await storage.readDocument('daily_challenge.json'), {'lastClaimedDate': '2026-11-22'});
    expect(preferences.containsKey('player_profile.json'), isFalse);
    expect(preferences.containsKey('level_progress.json_bak'), isFalse);
  });

  test('does not migrate corrupt legacy data without a recoverable backup', () async {
    SharedPreferences.setMockInitialValues({
      'player_profile.json': '{"coinBalance":999999}',
      'player_profile.json_sig': 'invalid-signature',
    });
    preferences = await SharedPreferences.getInstance();
    await storage.close();
    final database = await newDatabaseFactoryMemory().openDatabase('corrupt-legacy.db');

    await expectLater(
      LocalStorageService.initialize(preferences, database: database),
      throwsA(isA<IntegrityFailure>()),
    );
    expect(preferences.containsKey('player_profile.json'), isTrue);
    await database.close();
  });

  test('completion IDs are claimed only once under concurrent submissions', () async {
    final completedAt = DateTime.utc(2026, 11, 22);
    final claims = await Future.wait(List.generate(12, (_) {
      return storage.runInTransaction((transaction) => transaction.claimCompletion(
            completionId: 'cube_logic:1:session-42',
            gameId: 'cube_logic',
            levelNumber: 1,
            completedAt: completedAt,
          ));
    }));

    expect(claims.where((claimed) => claimed).length, 1);
  });

  test('coin reward claims are atomic and idempotent', () async {
    final economy = CoinEconomyServiceImpl(storage);

    final results = await Future.wait(List.generate(12, (_) {
      return economy.recordTransaction(
        type: CoinTransactionType.earnLevelClear,
        amount: 50,
        referenceId: 'cube_logic_1_completion',
      );
    }));

    expect(results.where((recorded) => recorded).length, 1);
    expect(await economy.getBalance(), 150);
    final history = await economy.getTransactionHistory();
    expect(history, hasLength(2));
    expect(history.first.type, CoinTransactionType.openingBalance);
    expect(history.last.type, CoinTransactionType.earnLevelClear);
    expect(history.last.balanceAfter, 150);
    expect((await storage.readDocument('player_profile.json'))!['coinBalance'], 150);
  });

  test('resetUserData clears every document and idempotency claim', () async {
    for (final key in StorageKeys.documentFiles) {
      await storage.writeDocument(key, {'schemaVersion': 1, 'value': key});
    }
    await storage.runInTransaction(
      (transaction) => transaction.claimIdempotencyKey('completion:abc', {'gameId': 'cube_logic'}),
    );

    await storage.resetUserData();

    for (final key in StorageKeys.documentFiles) {
      expect(await storage.readDocument(key), isNull, reason: '$key should be removed');
    }
    final reclaimed = await storage.runInTransaction(
      (transaction) => transaction.claimIdempotencyKey('completion:abc', {'gameId': 'cube_logic'}),
    );
    expect(reclaimed, isTrue);
  });
}
