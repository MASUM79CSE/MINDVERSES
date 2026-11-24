import '../../core/storage/local_storage_service.dart';
import '../../core/storage/storage_keys.dart';
import '../models/level_result.dart';

abstract class LevelProgressRepository {
  Future<Map<String, LevelResult>> getAllLevelResults();
  Future<LevelResult?> getLevelResult(String gameId, int levelNumber);
  Future<LevelResult?> getLevelResultInTransaction(
    LocalStorageTransaction transaction,
    String gameId,
    int levelNumber,
  );
  Future<void> saveLevelResult(LevelResult result);
  Future<LevelResult> saveLevelResultInTransaction(
    LocalStorageTransaction transaction,
    LevelResult result,
  );
  Future<bool> isLevelUnlocked(String gameId, int levelNumber);
  Future<void> unlockNextLevel(String gameId, int currentLevel);
  Future<void> unlockNextLevelInTransaction(
    LocalStorageTransaction transaction,
    String gameId,
    int currentLevel,
  );
  void invalidateCache();
  Future<void> resetAllProgress();
}

class LevelProgressRepositoryImpl implements LevelProgressRepository {
  final LocalStorageService _storage;

  LevelProgressRepositoryImpl(this._storage);

  String _key(String gameId, int level) => '${gameId}_level_$level';

  @override
  Future<Map<String, LevelResult>> getAllLevelResults() async {
    // Always read the persisted document: progress can be written by another
    // repository instance (e.g. a concurrent completion), so an in-memory
    // cache would silently serve stale unlock and star data.
    final data = await _storage.readDocument(StorageKeys.levelProgressFile);
    return _decodeResults(data);
  }

  @override
  Future<LevelResult?> getLevelResult(String gameId, int levelNumber) async {
    final all = await getAllLevelResults();
    return all[_key(gameId, levelNumber)];
  }

  @override
  Future<LevelResult?> getLevelResultInTransaction(
    LocalStorageTransaction transaction,
    String gameId,
    int levelNumber,
  ) async {
    final data = await transaction.readDocument(StorageKeys.levelProgressFile);
    return _decodeResults(data)[_key(gameId, levelNumber)];
  }

  @override
  Future<bool> isLevelUnlocked(String gameId, int levelNumber) async {
    if (levelNumber == 1) return true;
    final result = await getLevelResult(gameId, levelNumber);
    return result?.isUnlocked ?? false;
  }

  @override
  Future<void> saveLevelResult(LevelResult result) async {
    await _storage.runInTransaction(
      (transaction) => saveLevelResultInTransaction(transaction, result),
    );
    invalidateCache();
  }

  @override
  Future<LevelResult> saveLevelResultInTransaction(
    LocalStorageTransaction transaction,
    LevelResult result,
  ) async {
    final data = await transaction.readDocument(StorageKeys.levelProgressFile);
    final results = _decodeResults(data);
    final merged = _mergeResult(results[result.compositeId], result);
    results[result.compositeId] = merged;
    await transaction.writeDocument(StorageKeys.levelProgressFile, _encodeResults(results));
    return merged;
  }

  @override
  Future<void> unlockNextLevel(String gameId, int currentLevel) async {
    await _storage.runInTransaction(
      (transaction) => unlockNextLevelInTransaction(transaction, gameId, currentLevel),
    );
    invalidateCache();
  }

  @override
  Future<void> unlockNextLevelInTransaction(
    LocalStorageTransaction transaction,
    String gameId,
    int currentLevel,
  ) async {
    final data = await transaction.readDocument(StorageKeys.levelProgressFile);
    final results = _decodeResults(data);
    final key = _key(gameId, currentLevel + 1);
    final existingNext = results[key];

    if (existingNext == null) {
      results[key] = LevelResult(
        gameId: gameId,
        levelNumber: currentLevel + 1,
        isUnlocked: true,
      );
    } else if (!existingNext.isUnlocked) {
      results[key] = existingNext.copyWith(isUnlocked: true);
    }

    await transaction.writeDocument(StorageKeys.levelProgressFile, _encodeResults(results));
  }

  @override
  Future<void> resetAllProgress() async {
    await _storage.runInTransaction(
      (transaction) => transaction.removeDocument(StorageKeys.levelProgressFile),
    );
    invalidateCache();
  }

  @override
  void invalidateCache() {
    // Reads are always served from storage; retained for interface compatibility.
  }

  LevelResult _mergeResult(LevelResult? existing, LevelResult attempt) {
    int? bestOf(int? previous, int? current) {
      if (previous == null) return current;
      if (current == null) return previous;
      return previous < current ? previous : current;
    }

    return attempt.copyWith(
      isUnlocked: (existing?.isUnlocked ?? false) || attempt.isUnlocked,
      isCompleted: (existing?.isCompleted ?? false) || attempt.isCompleted,
      starsEarned: (existing?.starsEarned ?? 0) > attempt.starsEarned
          ? existing!.starsEarned
          : attempt.starsEarned,
      star1Completed: (existing?.star1Completed ?? false) || attempt.star1Completed,
      star2Efficiency: (existing?.star2Efficiency ?? false) || attempt.star2Efficiency,
      star3Mastery: (existing?.star3Mastery ?? false) || attempt.star3Mastery,
      bestMoveCount: bestOf(existing?.bestMoveCount, attempt.bestMoveCount),
      bestTimeSeconds: bestOf(existing?.bestTimeSeconds, attempt.bestTimeSeconds),
      hintsUsedCount: existing?.isCompleted == true
          ? bestOf(existing!.hintsUsedCount, attempt.hintsUsedCount)!
          : attempt.hintsUsedCount,
      firstCompletedAt: existing?.firstCompletedAt ?? attempt.firstCompletedAt,
      lastPlayedAt: attempt.lastPlayedAt ?? existing?.lastPlayedAt,
      playCount: (existing?.playCount ?? 0) + (attempt.isCompleted ? 1 : 0),
    );
  }

  Map<String, LevelResult> _decodeResults(Map<String, dynamic>? data) {
    final rawLevels = data?['levels'];
    if (rawLevels is! Map) return {};
    return Map<String, dynamic>.from(rawLevels).map(
      (key, value) => MapEntry(key, LevelResult.fromJson(Map<String, dynamic>.from(value as Map))),
    );
  }

  Map<String, dynamic> _encodeResults(Map<String, LevelResult> results) {
    return {
      'schemaVersion': 1,
      'levels': results.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
}
