import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage/storage_keys.dart';

/// Central feedback service managing haptic vibration responses according to user settings.
class FeedbackService {
  final SharedPreferences _prefs;

  FeedbackService(this._prefs);

  bool get isHapticEnabled => _prefs.getBool(StorageKeys.hapticEnabled) ?? true;
  bool get isSoundEnabled => _prefs.getBool(StorageKeys.soundEnabled) ?? true;

  Future<void> click() async {
    if (isHapticEnabled) {
      await HapticFeedback.selectionClick();
    }
  }

  Future<void> lightImpact() async {
    if (isHapticEnabled) {
      await HapticFeedback.lightImpact();
    }
  }

  Future<void> mediumImpact() async {
    if (isHapticEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  Future<void> heavyImpact() async {
    if (isHapticEnabled) {
      await HapticFeedback.heavyImpact();
    }
  }

  Future<void> success() async {
    if (isHapticEnabled) {
      await HapticFeedback.vibrate();
    }
  }
}
