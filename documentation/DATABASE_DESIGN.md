# MINDVERSE — Database & Persistence Design

**Document Version:** 1.0.0  
**Status:** Approved Persistence Architecture  
**Author:** Principal Software Engineer & Technical Lead  
**Last Updated:** 2026-11-15  

---

## 1. Storage Strategy & Architectural Rationale

### 1.1 Evaluated Alternatives & Selection
For local-first mobile game persistence on Android 16 (API 37) and iOS, three primary paradigms were evaluated:

1. **Native Embedded Engines (Isar / ObjectBox):** High query speed, but high vulnerability to native C++ NDK toolchain breakage, missing 16KB page alignment support on Android 15/16, and compile failures during major Android Gradle Plugin upgrades.
2. **Relational SQLite (`sqflite` / `drift`):** Excellent relational integrity, but introduces schema friction and overhead for hierarchical nested game board states and serialization of dynamic puzzle layouts.
3. **Structured Document Persistence (Selected):** Atomic JSON file storage with HMAC-SHA256 checksums paired with `SharedPreferences` for fast configuration access.
   - **Zero C++ binary risk:** Pure Dart serialization with immediate cross-platform compatibility across Android (including API 37+), iOS, macOS, Windows, and Web.
   - **Atomic durability:** Double-buffered write (`.tmp` write $\rightarrow$ file replace) prevents corrupt writes on app kill.
   - **Cloud-ready:** Direct parity with Firestore and Cloud Storage JSON document structures for future synchronization in Phase 10.

---

## 2. Complete Entity Schemas (JSON Specification)

### 2.1 Player Profile Schema (`player_profile.json`)
```json
{
  "schemaVersion": 1,
  "id": "uuid-v4-string",
  "username": "Player1234",
  "avatarId": "avatar_default_01",
  "createdAt": "2026-11-15T21:00:00.000Z",
  "lastActiveAt": "2026-11-15T21:30:00.000Z",
  "totalXp": 1450,
  "playerLevel": 4,
  "coinBalance": 350,
  "totalStars": 38,
  "gamesPlayed": 42,
  "levelsCompletedCount": 24,
  "currentStreak": 3,
  "bestStreak": 5,
  "lastDailyChallengeDate": "2026-11-15"
}
```

### 2.2 Level Progress & Results (`level_progress.json`)
```json
{
  "schemaVersion": 1,
  "levels": {
    "cube_logic_level_01": {
      "gameId": "cube_logic",
      "levelNumber": 1,
      "isUnlocked": true,
      "isCompleted": true,
      "starsEarned": 3,
      "star1Completed": true,
      "star2Efficiency": true,
      "star3Mastery": true,
      "bestMoveCount": 3,
      "bestTimeSeconds": 14,
      "hintsUsedCount": 0,
      "firstCompletedAt": "2026-11-15T21:10:00.000Z",
      "lastPlayedAt": "2026-11-15T21:10:00.000Z",
      "playCount": 1
    },
    "cube_logic_level_02": {
      "gameId": "cube_logic",
      "levelNumber": 2,
      "isUnlocked": true,
      "isCompleted": false,
      "starsEarned": 0,
      "star1Completed": false,
      "star2Efficiency": false,
      "star3Mastery": false,
      "bestMoveCount": null,
      "bestTimeSeconds": null,
      "hintsUsedCount": 0,
      "firstCompletedAt": null,
      "lastPlayedAt": null,
      "playCount": 0
    }
  }
}
```

### 2.3 Achievements State (`achievements.json`)
```json
{
  "schemaVersion": 1,
  "achievements": {
    "first_victory": {
      "id": "first_victory",
      "isUnlocked": true,
      "progress": 1,
      "target": 1,
      "unlockedAt": "2026-11-15T21:10:00.000Z",
      "rewardClaimed": true
    },
    "puzzle_master_100": {
      "id": "puzzle_master_100",
      "isUnlocked": false,
      "progress": 24,
      "target": 100,
      "unlockedAt": null,
      "rewardClaimed": false
    }
  }
}
```

### 2.4 Economy Transaction Ledger (`coin_ledger.json`)
Prevents duplicate claims, race conditions, or unverified coin rewards:
```json
{
  "schemaVersion": 1,
  "transactions": [
    {
      "transactionId": "tx_20261115_001",
      "timestamp": "2026-11-15T21:10:00.000Z",
      "type": "EARN_LEVEL_3_STAR",
      "amount": 25,
      "balanceAfter": 325,
      "referenceId": "cube_logic_level_01"
    },
    {
      "transactionId": "tx_20261115_002",
      "timestamp": "2026-11-15T21:18:00.000Z",
      "type": "SPEND_HINT",
      "amount": -30,
      "balanceAfter": 295,
      "referenceId": "cube_logic_level_04"
    }
  ]
}
```

### 2.5 User Settings Schema (`user_settings.json` / `SharedPreferences`)
```json
{
  "schemaVersion": 1,
  "soundEffectsEnabled": true,
  "musicEnabled": true,
  "hapticFeedbackEnabled": true,
  "themeMode": "dark",
  "hasCompletedOnboarding": true,
  "analyticsConsentGranted": false,
  "personalizedAdsConsentGranted": false
}
```

---

## 3. Schema Versioning & Migration Strategy

Every data file maintains a root `schemaVersion: int`. On application startup, the `StorageMigrationService` evaluates the version against the target runtime version:

```dart
class StorageMigrationService {
  Future<Map<String, dynamic>> migrate(
    String fileKey,
    Map<String, dynamic> rawData,
  ) async {
    int currentVersion = rawData['schemaVersion'] as int? ?? 0;
    
    while (currentVersion < targetSchemaVersion) {
      switch (currentVersion) {
        case 0:
          rawData = _migrateV0ToV1(rawData);
          currentVersion = 1;
          break;
        case 1:
          rawData = _migrateV1ToV2(rawData);
          currentVersion = 2;
          break;
        default:
          throw StorageException('Unsupported schema version: $currentVersion');
      }
    }
    return rawData;
  }
}
```

---

## 4. Data Integrity & Anti-Tampering Mechanism

1. **HMAC-SHA256 Verification:** Each saved document is paired with a hash file (e.g., `player_profile.json.sig`).
2. **Verification Equation:**
   $$\text{Signature} = \text{HMAC-SHA256}(\text{UTF8-Bytes}(\text{documentContent}), \text{AppInternalSalt})$$
3. **Handling Corruption / Manipulation:**
   - If signature matches: Document deserializes cleanly.
   - If signature mismatches: The system checks for the automatic backup (`player_profile.bak`). If backup is valid, it recovers gracefully; otherwise, it resets corrupted progression safely while maintaining non-corrupt settings.
