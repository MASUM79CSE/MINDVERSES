import 'package:flutter/foundation.dart';

/// Immutable domain model representing a player's performance on a specific level.
@immutable
class LevelResult {
  final String gameId;
  final int levelNumber;
  final bool isUnlocked;
  final bool isCompleted;
  final int starsEarned;
  final bool star1Completed;
  final bool star2Efficiency;
  final bool star3Mastery;
  final int? bestMoveCount;
  final int? bestTimeSeconds;
  final int hintsUsedCount;
  final DateTime? firstCompletedAt;
  final DateTime? lastPlayedAt;
  final int playCount;

  const LevelResult({
    required this.gameId,
    required this.levelNumber,
    this.isUnlocked = false,
    this.isCompleted = false,
    this.starsEarned = 0,
    this.star1Completed = false,
    this.star2Efficiency = false,
    this.star3Mastery = false,
    this.bestMoveCount,
    this.bestTimeSeconds,
    this.hintsUsedCount = 0,
    this.firstCompletedAt,
    this.lastPlayedAt,
    this.playCount = 0,
  });

  String get compositeId => '${gameId}_level_$levelNumber';

  LevelResult copyWith({
    String? gameId,
    int? levelNumber,
    bool? isUnlocked,
    bool? isCompleted,
    int? starsEarned,
    bool? star1Completed,
    bool? star2Efficiency,
    bool? star3Mastery,
    int? bestMoveCount,
    int? bestTimeSeconds,
    int? hintsUsedCount,
    DateTime? firstCompletedAt,
    DateTime? lastPlayedAt,
    int? playCount,
  }) {
    return LevelResult(
      gameId: gameId ?? this.gameId,
      levelNumber: levelNumber ?? this.levelNumber,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isCompleted: isCompleted ?? this.isCompleted,
      starsEarned: starsEarned ?? this.starsEarned,
      star1Completed: star1Completed ?? this.star1Completed,
      star2Efficiency: star2Efficiency ?? this.star2Efficiency,
      star3Mastery: star3Mastery ?? this.star3Mastery,
      bestMoveCount: bestMoveCount ?? this.bestMoveCount,
      bestTimeSeconds: bestTimeSeconds ?? this.bestTimeSeconds,
      hintsUsedCount: hintsUsedCount ?? this.hintsUsedCount,
      firstCompletedAt: firstCompletedAt ?? this.firstCompletedAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      playCount: playCount ?? this.playCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'levelNumber': levelNumber,
      'isUnlocked': isUnlocked,
      'isCompleted': isCompleted,
      'starsEarned': starsEarned,
      'star1Completed': star1Completed,
      'star2Efficiency': star2Efficiency,
      'star3Mastery': star3Mastery,
      'bestMoveCount': bestMoveCount,
      'bestTimeSeconds': bestTimeSeconds,
      'hintsUsedCount': hintsUsedCount,
      'firstCompletedAt': firstCompletedAt?.toIso8601String(),
      'lastPlayedAt': lastPlayedAt?.toIso8601String(),
      'playCount': playCount,
    };
  }

  factory LevelResult.fromJson(Map<String, dynamic> json) {
    return LevelResult(
      gameId: json['gameId'] as String,
      levelNumber: json['levelNumber'] as int,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      starsEarned: json['starsEarned'] as int? ?? 0,
      star1Completed: json['star1Completed'] as bool? ?? false,
      star2Efficiency: json['star2Efficiency'] as bool? ?? false,
      star3Mastery: json['star3Mastery'] as bool? ?? false,
      bestMoveCount: json['bestMoveCount'] as int?,
      bestTimeSeconds: json['bestTimeSeconds'] as int?,
      hintsUsedCount: json['hintsUsedCount'] as int? ?? 0,
      firstCompletedAt: json['firstCompletedAt'] != null
          ? DateTime.parse(json['firstCompletedAt'] as String)
          : null,
      lastPlayedAt: json['lastPlayedAt'] != null
          ? DateTime.parse(json['lastPlayedAt'] as String)
          : null,
      playCount: json['playCount'] as int? ?? 0,
    );
  }
}
