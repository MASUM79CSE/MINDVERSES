import '../../core/storage/local_storage_service.dart';
import '../../core/storage/storage_keys.dart';
import '../models/level_result.dart';

abstract class LevelProgressRepository {
  Future<Map<String, LevelResult>> getAllLevelResults();
  Future<LevelResult?> getLevelResult(String gameId, int levelNumber);
  Future<void> saveLevelResult(LevelResult result);
  Future<bool> isLevelUnlocked(String gameId, int levelNumber);
  Future<void> unlockNextLevel(String gameId, int currentLevel);
  Future<void> resetAllProgress();
}

class LevelProgressRepositoryImpl implements LevelProgressRepository {
  final LocalStorageService _storage;
  Map<String, LevelResult>? _cache;

  LevelProgressRepositoryImpl(this._storage);

  String _key(String gameId, int level) => '${gameId}_level_$level';

  @override
  Future<Map<String, LevelResult>> getAllLevelResults() async {
    if (_cache != null) return _cache!;

    final data = await _storage.readDocument(StorageKeys.levelProgressFile);
    if (data != null && data['levels'] != null) {
      final rawMap = data['levels'] as Map<String, dynamic>;
      _cache = rawMap.map(
        (key, value) => MapEntry(key, LevelResult.fromJson(value as Map<String, dynamic>)),
      );
    } else {
      _cache = {};
    }
    return _cache!;
  }

  @override
  Future<LevelResult?> getLevelResult(String gameId, int levelNumber) async {
    final all = await getAllLevelResults();
    return all[_key(gameId, levelNumber)];
  }

  @override
  Future<bool> isLevelUnlocked(String gameId, int levelNumber) async {
    // Level 1 is always unlocked by default
    if (levelNumber == 1) return true;
    final result = await getLevelResult(gameId, levelNumber);
    return result?.isUnlocked ?? false;
  }

  @override
  Future<void> saveLevelResult(LevelResult result) async {
    final all = await getAllLevelResults();
    all[result.compositeId] = result;

    final serialized = {
      'schemaVersion': 1,
      'levels': all.map((key, val) => MapEntry(key, val.toJson())),
    };

    await _storage.writeDocument(StorageKeys.levelProgressFile, serialized);
  }

  @override
  Future<void> unlockNextLevel(String gameId, int currentLevel) async {
    final nextLevelNum = currentLevel + 1;
    final existingNext = await getLevelResult(gameId, nextLevelNum);

    if (existingNext == null) {
      final unlocked = LevelResult(
        gameId: gameId,
        levelNumber: nextLevelNum,
        isUnlocked: true,
      );
      await saveLevelResult(unlocked);
    } else if (!existingNext.isUnlocked) {
      await saveLevelResult(existingNext.copyWith(isUnlocked: true));
    }
  }

  @override
  Future<void> resetAllProgress() async {
    await _storage.removeDocument(StorageKeys.levelProgressFile);
    _cache = null;
  }
}
