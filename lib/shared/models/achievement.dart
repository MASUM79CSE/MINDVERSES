import 'package:flutter/foundation.dart';

/// Immutable domain model representing an achievement.
@immutable
class Achievement {
  final String id;
  final String title;
  final String description;
  final int rewardCoins;
  final int rewardXp;
  final int targetProgress;
  final int currentProgress;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final bool isRewardClaimed;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardCoins,
    required this.rewardXp,
    required this.targetProgress,
    this.currentProgress = 0,
    this.isUnlocked = false,
    this.unlockedAt,
    this.isRewardClaimed = false,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    int? rewardCoins,
    int? rewardXp,
    int? targetProgress,
    int? currentProgress,
    bool? isUnlocked,
    DateTime? unlockedAt,
    bool? isRewardClaimed,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      rewardCoins: rewardCoins ?? this.rewardCoins,
      rewardXp: rewardXp ?? this.rewardXp,
      targetProgress: targetProgress ?? this.targetProgress,
      currentProgress: currentProgress ?? this.currentProgress,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isRewardClaimed: isRewardClaimed ?? this.isRewardClaimed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'rewardCoins': rewardCoins,
      'rewardXp': rewardXp,
      'targetProgress': targetProgress,
      'currentProgress': currentProgress,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'isRewardClaimed': isRewardClaimed,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      rewardCoins: json['rewardCoins'] as int,
      rewardXp: json['rewardXp'] as int,
      targetProgress: json['targetProgress'] as int,
      currentProgress: json['currentProgress'] as int? ?? 0,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      isRewardClaimed: json['isRewardClaimed'] as bool? ?? false,
    );
  }
}
