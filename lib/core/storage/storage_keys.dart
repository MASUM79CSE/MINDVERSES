/// Centralized persistence keys for SharedPreferences and local document storage.
class StorageKeys {
  StorageKeys._();

  // SharedPreferences Keys
  static const String hasCompletedOnboarding = 'mv_has_completed_onboarding';
  static const String soundEnabled = 'mv_sound_enabled';
  static const String musicEnabled = 'mv_music_enabled';
  static const String hapticEnabled = 'mv_haptic_enabled';
  static const String themeMode = 'mv_theme_mode';

  // Document Storage Filenames
  static const String playerProfileFile = 'player_profile.json';
  static const String levelProgressFile = 'level_progress.json';
  static const String achievementsFile = 'achievements.json';
  static const String coinLedgerFile = 'coin_ledger.json';
  static const String dailyChallengeFile = 'daily_challenge.json';

  static const List<String> documentFiles = [
    playerProfileFile,
    levelProgressFile,
    achievementsFile,
    coinLedgerFile,
    dailyChallengeFile,
  ];
}
