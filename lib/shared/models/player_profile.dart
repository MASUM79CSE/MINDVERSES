import 'package:flutter/foundation.dart';

/// Immutable domain model representing a player's profile and progress summary.
@immutable
class PlayerProfile {
  final int schemaVersion;
  final String id;
  final String username;
  final String avatarId;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final int totalXp;
  final int playerLevel;
  final int coinBalance;
  final int totalStars;
  final int gamesPlayed;
  final int levelsCompletedCount;
  final int currentStreak;
  final int bestStreak;
  final String? lastDailyChallengeDate;

  const PlayerProfile({
    this.schemaVersion = 1,
    required this.id,
    required this.username,
    required this.avatarId,
    required this.createdAt,
    required this.lastActiveAt,
    this.totalXp = 0,
    this.playerLevel = 1,
    this.coinBalance = 100,
    this.totalStars = 0,
    this.gamesPlayed = 0,
    this.levelsCompletedCount = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastDailyChallengeDate,
  });

  factory PlayerProfile.initial({
    required String id,
    String username = 'Player1234',
    String avatarId = 'avatar_default_01',
  }) {
    final now = DateTime.now().toUtc();
    return PlayerProfile(
      id: id,
      username: username,
      avatarId: avatarId,
      createdAt: now,
      lastActiveAt: now,
      coinBalance: 100,
      playerLevel: 1,
    );
  }

  PlayerProfile copyWith({
    int? schemaVersion,
    String? id,
    String? username,
    String? avatarId,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    int? totalXp,
    int? playerLevel,
    int? coinBalance,
    int? totalStars,
    int? gamesPlayed,
    int? levelsCompletedCount,
    int? currentStreak,
    int? bestStreak,
    String? lastDailyChallengeDate,
  }) {
    return PlayerProfile(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      id: id ?? this.id,
      username: username ?? this.username,
      avatarId: avatarId ?? this.avatarId,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      totalXp: totalXp ?? this.totalXp,
      playerLevel: playerLevel ?? this.playerLevel,
      coinBalance: coinBalance ?? this.coinBalance,
      totalStars: totalStars ?? this.totalStars,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      levelsCompletedCount: levelsCompletedCount ?? this.levelsCompletedCount,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastDailyChallengeDate: lastDailyChallengeDate ?? this.lastDailyChallengeDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'id': id,
      'username': username,
      'avatarId': avatarId,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
      'totalXp': totalXp,
      'playerLevel': playerLevel,
      'coinBalance': coinBalance,
      'totalStars': totalStars,
      'gamesPlayed': gamesPlayed,
      'levelsCompletedCount': levelsCompletedCount,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'lastDailyChallengeDate': lastDailyChallengeDate,
    };
  }

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    return PlayerProfile(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      id: json['id'] as String,
      username: json['username'] as String? ?? 'Player1234',
      avatarId: json['avatarId'] as String? ?? 'avatar_default_01',
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
      totalXp: json['totalXp'] as int? ?? 0,
      playerLevel: json['playerLevel'] as int? ?? 1,
      coinBalance: json['coinBalance'] as int? ?? 100,
      totalStars: json['totalStars'] as int? ?? 0,
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      levelsCompletedCount: json['levelsCompletedCount'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      lastDailyChallengeDate: json['lastDailyChallengeDate'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username &&
          avatarId == other.avatarId &&
          totalXp == other.totalXp &&
          playerLevel == other.playerLevel &&
          coinBalance == other.coinBalance &&
          totalStars == other.totalStars &&
          currentStreak == other.currentStreak &&
          lastDailyChallengeDate == other.lastDailyChallengeDate;

  @override
  int get hashCode =>
      id.hashCode ^
      username.hashCode ^
      avatarId.hashCode ^
      totalXp.hashCode ^
      playerLevel.hashCode ^
      coinBalance.hashCode ^
      totalStars.hashCode ^
      currentStreak.hashCode ^
      lastDailyChallengeDate.hashCode;
}
