import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../errors/app_failure.dart';
import '../services/logger_service.dart';

/// Lightweight, atomic local document storage engine with HMAC-SHA256 signature verification.
/// Prevents save corruption, detects external tampering, and avoids native C++ NDK risks.
class LocalStorageService {
  final SharedPreferences _prefs;
  static const String _internalSalt = 'MINDVERSE_LOCAL_SALT_2026_PRODUCTION';

  LocalStorageService(this._prefs);

  /// Computes HMAC-SHA256 signature for a JSON string.
  static String computeSignature(String jsonString) {
    final key = utf8.encode(_internalSalt);
    final bytes = utf8.encode(jsonString);
    final hmac = Hmac(sha256, key);
    return hmac.convert(bytes).toString();
  }

  /// Atomically writes a JSON map to persistent key-value store with signature and backup.
  Future<void> writeDocument(String key, Map<String, dynamic> data) async {
    try {
      final jsonString = jsonEncode(data);
      final signature = computeSignature(jsonString);

      // Create backup of existing data if present
      final existingData = _prefs.getString(key);
      if (existingData != null) {
        await _prefs.setString('${key}_bak', existingData);
        final existingSig = _prefs.getString('${key}_sig');
        if (existingSig != null) {
          await _prefs.setString('${key}_bak_sig', existingSig);
        }
      }

      // Write signature and document
      await _prefs.setString('${key}_sig', signature);
      final success = await _prefs.setString(key, jsonString);

      if (!success) {
        throw const StorageFailure('Failed to commit document to persistent storage.');
      }
    } catch (e, stack) {
      LoggerService.error('Error writing document: $key', error: e, stackTrace: stack);
      throw StorageFailure('Storage write failed for key: $key', e);
    }
  }

  /// Reads and verifies document integrity via HMAC-SHA256 signature.
  /// Automatically attempts backup recovery if primary document is corrupted or missing signature.
  Future<Map<String, dynamic>?> readDocument(String key) async {
    try {
      final jsonString = _prefs.getString(key);
      final signature = _prefs.getString('${key}_sig');

      if (jsonString == null) {
        return null;
      }

      // Verify integrity
      if (signature != null && computeSignature(jsonString) == signature) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }

      // Signature mismatch or missing: Attempt fallback to backup
      LoggerService.warning('Integrity signature mismatch on $key. Attempting backup restore.');
      final backupString = _prefs.getString('${key}_bak');
      final backupSig = _prefs.getString('${key}_bak_sig');

      if (backupString != null && backupSig != null && computeSignature(backupString) == backupSig) {
        LoggerService.info('Successfully recovered $key from backup.');
        // Re-write recovered state as primary
        await _prefs.setString(key, backupString);
        await _prefs.setString('${key}_sig', backupSig);
        return jsonDecode(backupString) as Map<String, dynamic>;
      }

      throw const IntegrityFailure('Document corrupted and backup invalid or missing.');
    } catch (e, stack) {
      if (e is IntegrityFailure) rethrow;
      LoggerService.error('Error reading document: $key', error: e, stackTrace: stack);
      throw StorageFailure('Storage read failed for key: $key', e);
    }
  }

  /// Removes document and its associated backups and signatures.
  Future<void> removeDocument(String key) async {
    await _prefs.remove(key);
    await _prefs.remove('${key}_sig');
    await _prefs.remove('${key}_bak');
    await _prefs.remove('${key}_bak_sig');
  }
}
