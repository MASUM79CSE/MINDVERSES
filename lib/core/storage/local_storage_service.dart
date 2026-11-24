import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sembast/sembast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../errors/app_failure.dart';
import '../services/logger_service.dart';
import 'storage_keys.dart';

/// Transactional document storage with a one-time migration from legacy preferences.
/// Local checksums detect accidental corruption; they do not prevent device tampering.
class LocalStorageService {
  static const String _legacySalt = 'MINDVERSE_LOCAL_SALT_2026_PRODUCTION';
  static const String _schemaRecordKey = '__mindverse_storage_schema__';
  static const int _schemaVersion = 1;
  static final StoreRef<String, Map<String, dynamic>> _documents =
      StoreRef<String, Map<String, dynamic>>.main();
  static final StoreRef<String, Map<String, dynamic>> _idempotency =
      stringMapStoreFactory.store('idempotency');

  final SharedPreferences _legacyPreferences;
  final Database _database;

  LocalStorageService._(this._legacyPreferences, this._database);

  /// Opens the storage service and migrates valid legacy documents before use.
  static Future<LocalStorageService> initialize(
    SharedPreferences legacyPreferences, {
    required Database database,
  }) async {
    final storage = LocalStorageService._(legacyPreferences, database);
    await storage._migrateLegacyDocuments();
    return storage;
  }

  /// Computes the legacy HMAC used only to validate old preference documents.
  static String computeSignature(String jsonString) {
    final key = utf8.encode(_legacySalt);
    final bytes = utf8.encode(jsonString);
    return Hmac(sha256, key).convert(bytes).toString();
  }

  Future<T> runInTransaction<T>(Future<T> Function(LocalStorageTransaction transaction) action) async {
    try {
      return await _database.transaction((transaction) {
        return action(LocalStorageTransaction._(transaction, _documents, _idempotency));
      });
    } on AppFailure {
      rethrow;
    } catch (error, stackTrace) {
      LoggerService.error('Transactional storage operation failed.', error: error, stackTrace: stackTrace);
      throw StorageFailure('Transactional storage operation failed.', error);
    }
  }

  Future<void> writeDocument(String key, Map<String, dynamic> data) async {
    await runInTransaction((transaction) => transaction.writeDocument(key, data));
  }

  Future<Map<String, dynamic>?> readDocument(String key) async {
    try {
      final data = await _documents.record(key).get(_database);
      return data == null ? null : Map<String, dynamic>.from(data);
    } on AppFailure {
      rethrow;
    } catch (error, stackTrace) {
      LoggerService.error('Error reading document: $key', error: error, stackTrace: stackTrace);
      throw StorageFailure('Storage read failed for key: $key', error);
    }
  }

  Future<void> removeDocument(String key) async {
    await runInTransaction((transaction) => transaction.removeDocument(key));
  }

  /// Removes every persisted user document and idempotency claim atomically.
  ///
  /// Used by the in-app "Reset All Progress" action so rewards cannot be
  /// silently replayed from stale completion keys after a reset.
  Future<void> resetUserData() async {
    await runInTransaction((transaction) async {
      for (final key in StorageKeys.documentFiles) {
        await transaction.removeDocument(key);
      }
      await transaction.clearIdempotency();
    });
  }

  Future<void> close() => _database.close();

  Future<void> _migrateLegacyDocuments() async {
    final metadata = await _documents.record(_schemaRecordKey).get(_database);
    final currentVersion = metadata?['schemaVersion'] as int?;
    if (currentVersion != null && currentVersion > _schemaVersion) {
      throw StorageFailure(
        'Local data schema $currentVersion is newer than supported schema $_schemaVersion.',
      );
    }
    if (currentVersion == _schemaVersion) return;

    final legacyDocuments = <String, Map<String, dynamic>>{};
    for (final key in StorageKeys.documentFiles) {
      final document = _readLegacyDocument(key);
      if (document != null) legacyDocuments[key] = document;
    }

    await runInTransaction((transaction) async {
      for (final entry in legacyDocuments.entries) {
        final existing = await transaction.readDocument(entry.key);
        if (existing == null) {
          await transaction.writeDocument(entry.key, entry.value);
        }
      }
      await transaction.writeDocument(_schemaRecordKey, {
        'schemaVersion': _schemaVersion,
        'migratedAt': DateTime.now().toUtc().toIso8601String(),
      });
    });

    for (final key in StorageKeys.documentFiles) {
      for (final legacyKey in [key, '${key}_sig', '${key}_bak', '${key}_bak_sig']) {
        try {
          await _legacyPreferences.remove(legacyKey);
        } catch (error, stackTrace) {
          LoggerService.warning('Could not remove migrated preference $legacyKey: $error\n$stackTrace');
        }
      }
    }
  }

  Map<String, dynamic>? _readLegacyDocument(String key) {
    final primary = _legacyPreferences.getString(key);
    final primarySignature = _legacyPreferences.getString('${key}_sig');
    final verifiedPrimary = _decodeVerifiedLegacyDocument(primary, primarySignature);
    if (verifiedPrimary != null) return verifiedPrimary;

    final backup = _legacyPreferences.getString('${key}_bak');
    final backupSignature = _legacyPreferences.getString('${key}_bak_sig');
    final verifiedBackup = _decodeVerifiedLegacyDocument(backup, backupSignature);
    if (verifiedBackup != null) {
      LoggerService.warning('Recovered legacy document $key from its verified backup during migration.');
      return verifiedBackup;
    }

    if (primary != null || backup != null) {
      throw IntegrityFailure('Legacy document $key is corrupted and has no valid backup.');
    }
    return null;
  }

  Map<String, dynamic>? _decodeVerifiedLegacyDocument(String? jsonString, String? signature) {
    if (jsonString == null || signature == null || computeSignature(jsonString) != signature) return null;
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
    return null;
  }
}

/// Operations that participate in the same durable database transaction.
class LocalStorageTransaction {
  final Transaction _transaction;
  final StoreRef<String, Map<String, dynamic>> _documents;
  final StoreRef<String, Map<String, dynamic>> _idempotency;

  LocalStorageTransaction._(this._transaction, this._documents, this._idempotency);

  Future<Map<String, dynamic>?> readDocument(String key) async {
    final data = await _documents.record(key).get(_transaction);
    return data == null ? null : Map<String, dynamic>.from(data);
  }

  Future<void> writeDocument(String key, Map<String, dynamic> data) async {
    await _documents.record(key).put(_transaction, Map<String, dynamic>.from(data));
  }

  Future<void> removeDocument(String key) => _documents.record(key).delete(_transaction);

  /// Claims a stable completion ID once in this transaction.
  Future<bool> claimCompletion({
    required String completionId,
    required String gameId,
    required int levelNumber,
    required DateTime completedAt,
  }) {
    if (completionId.isEmpty || gameId.isEmpty || levelNumber < 1) {
      throw ArgumentError('A completion requires an ID, game ID, and positive level number.');
    }
    return claimIdempotencyKey('completion:$completionId', {
      'completionId': completionId,
      'gameId': gameId,
      'levelNumber': levelNumber,
      'completedAt': completedAt.toUtc().toIso8601String(),
    });
  }

  /// Claims [key] once in this transaction; a repeated claim returns false.
  Future<bool> claimIdempotencyKey(String key, Map<String, dynamic> data) async {
    final record = _idempotency.record(key);
    if (await record.get(_transaction) != null) return false;
    await record.put(_transaction, Map<String, dynamic>.from(data));
    return true;
  }

  /// Clears every idempotency claim recorded so far.
  Future<void> clearIdempotency() => _idempotency.delete(_transaction);
}
