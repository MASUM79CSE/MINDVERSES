import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindverse/core/storage/local_storage_service.dart';
import 'package:mindverse/features/cube_logic/presentation/providers/cube_logic_notifier.dart';
import 'package:mindverse/shared/providers/shared_providers.dart';
import 'package:mindverse/shared/repositories/daily_challenge_repository.dart';
import 'package:mindverse/shared/services/daily_challenge_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;
  late LocalStorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = await createTestLocalStorage(prefs);
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localStorageServiceProvider.overrideWithValue(storage),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await storage.close();
  });

  test('CubeLogicNotifier initializes with level 5 data', () {
    final state = container.read(cubeLogicNotifierProvider(5));
    expect(state.levelNumber, equals(5));
    expect(state.moveCount, equals(0));
    expect(state.isSolved, isFalse);
    expect(state.isFailed, isFalse);
  });

  test('Rotating tile increments move count and enables undo', () {
    final notifier = container.read(cubeLogicNotifierProvider(5).notifier);
    notifier.rotateTile(1, 0, 0);

    final state = container.read(cubeLogicNotifierProvider(5));
    expect(state.moveCount, equals(1));
    expect(state.canUndo, isTrue);

    notifier.undo();
    final undoneState = container.read(cubeLogicNotifierProvider(5));
    expect(undoneState.moveCount, equals(0));
    expect(undoneState.canUndo, isFalse);
  });

  test('hint remains counted after its highlight is cleared', () async {
    final notifier = container.read(cubeLogicNotifierProvider(1).notifier);
    notifier.useHint();
    expect(container.read(cubeLogicNotifierProvider(1)).hintTile, isNotNull);
    notifier.rotateTile(0, 1, 0);
    expect(container.read(cubeLogicNotifierProvider(1)).hintTile, isNull);
    notifier.rotateTile(1, 0, 0);
    for (var i = 0; i < 100 && !container.read(cubeLogicNotifierProvider(1)).isSolved; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    final state = container.read(cubeLogicNotifierProvider(1));
    expect(state.isSolved, isTrue);
    expect(state.earnedStars, 2);
    final result = await container.read(levelProgressRepositoryProvider).getLevelResult('cube_logic', 1);
    expect(result!.hintsUsedCount, 1);
  });

  test('completion rewards are atomic and replay improvements are credited once', () async {
    final provider = cubeLogicNotifierProvider(1);
    final notifier = container.read(provider.notifier);
    notifier.useHint();
    notifier.rotateTile(0, 1, 0);
    notifier.rotateTile(1, 0, 0);
    notifier.rotateTile(1, 0, 0);
    for (var i = 0; i < 100 && !container.read(provider).isSolved; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(container.read(provider).isSolved, isTrue);
    var profile = await container.read(profileRepositoryProvider).getProfile();
    expect(profile.totalStars, 2);
    expect(profile.levelsCompletedCount, 1);
    expect(profile.totalXp, 200); // 150 level + 50 first-victory achievement
    expect(profile.coinBalance, 125); // first-victory achievement

    notifier.reset();
    notifier.rotateTile(1, 0, 0);
    notifier.rotateTile(1, 0, 0);
    for (var i = 0; i < 100 && !container.read(provider).isSolved; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(container.read(provider).isSolved, isTrue);
    profile = await container.read(profileRepositoryProvider).getProfile();
    expect(profile.totalStars, 3);
    expect(profile.levelsCompletedCount, 1);
    expect(profile.totalXp, 360); // 10 replay + 50 new star + 100 achievement
    expect(profile.coinBalance, 200); // 25 level bonus + 50 achievement
    final result = await container.read(levelProgressRepositoryProvider).getLevelResult('cube_logic', 1);
    expect(result!.playCount, 2);
    expect(result.starsEarned, 3);
    final ledger = await container.read(coinEconomyServiceProvider).getTransactionHistory();
    expect(ledger.where((entry) => entry.referenceId == 'cube_logic:1').length, 1);
  });

  test('daily challenge completion awards the daily claim in the same transaction', () async {
    var date = DateTime.utc(2026, 1, 1, 12);
    var challenge = DailyChallengeService.generateChallengeForDate(date);
    while (challenge.gameId != 'cube_logic' || challenge.levelNumber != 1) {
      date = date.add(const Duration(days: 1));
      challenge = DailyChallengeService.generateChallengeForDate(date);
    }
    final fixedDate = date;
    final repository = DailyChallengeRepositoryImpl(
      storage,
      container.read(profileRepositoryProvider),
      container.read(coinEconomyServiceProvider),
      container.read(achievementRepositoryProvider),
      container.read(achievementRewardServiceProvider),
      clock: () => fixedDate,
    );
    final provider = cubeLogicNotifierProvider(1);
    final dailyContainer = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
      localStorageServiceProvider.overrideWithValue(storage),
      dailyChallengeRepositoryProvider.overrideWithValue(repository),
      provider.overrideWith((ref) => CubeLogicNotifier(ref, 1, challenge: challenge)),
    ]);
    addTearDown(dailyContainer.dispose);
    final notifier = dailyContainer.read(provider.notifier);
    notifier.rotateTile(1, 0, 0);
    notifier.rotateTile(1, 0, 0);
    for (var i = 0; i < 100 && !dailyContainer.read(provider).isSolved; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(dailyContainer.read(provider).isSolved, isTrue);
    expect((await repository.getStatus(challenge.dateString)).isCompleted, isTrue);
    expect((await repository.getStatus(challenge.dateString)).currentStreak, 1);
    final ledger = await container.read(coinEconomyServiceProvider).getTransactionHistory();
    expect(ledger.where((entry) => entry.referenceId == '${challenge.dateString}:cube_logic:1'), hasLength(1));
  });

  test('Resetting level restores initial move count and state', () {
    final notifier = container.read(cubeLogicNotifierProvider(5).notifier);
    notifier.rotateTile(1, 0, 0);
    notifier.reset();

    final state = container.read(cubeLogicNotifierProvider(5));
    expect(state.moveCount, equals(0));
    expect(state.history, isEmpty);
  });
}
