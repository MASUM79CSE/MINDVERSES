import 'package:flutter/foundation.dart';

/// Immutable domain model representing a generated daily challenge.
@immutable
class DailyChallenge {
  final String dateString; // YYYY-MM-DD UTC
  final String gameId;
  final int levelNumber;
  final String challengeTitle;
  final String challengeDescription;
  final int rewardCoins;
  final int rewardXp;
  final bool isCompleted;
  final DateTime? completedAt;

  const DailyChallenge({
    required this.dateString,
    required this.gameId,
    required this.levelNumber,
    required this.challengeTitle,
    required this.challengeDescription,
    this.rewardCoins = 100,
    this.rewardXp = 150,
    this.isCompleted = false,
    this.completedAt,
  });

  DailyChallenge copyWith({
    String? dateString,
    String? gameId,
    int? levelNumber,
    String? challengeTitle,
    String? challengeDescription,
    int? rewardCoins,
    int? rewardXp,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return DailyChallenge(
      dateString: dateString ?? this.dateString,
      gameId: gameId ?? this.gameId,
      levelNumber: levelNumber ?? this.levelNumber,
      challengeTitle: challengeTitle ?? this.challengeTitle,
      challengeDescription: challengeDescription ?? this.challengeDescription,
      rewardCoins: rewardCoins ?? this.rewardCoins,
      rewardXp: rewardXp ?? this.rewardXp,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateString': dateString,
      'gameId': gameId,
      'levelNumber': levelNumber,
      'challengeTitle': challengeTitle,
      'challengeDescription': challengeDescription,
      'rewardCoins': rewardCoins,
      'rewardXp': rewardXp,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      dateString: json['dateString'] as String,
      gameId: json['gameId'] as String,
      levelNumber: json['levelNumber'] as int,
      challengeTitle: json['challengeTitle'] as String,
      challengeDescription: json['challengeDescription'] as String,
      rewardCoins: json['rewardCoins'] as int? ?? 100,
      rewardXp: json['rewardXp'] as int? ?? 150,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
}
