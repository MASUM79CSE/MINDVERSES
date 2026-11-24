import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../app/config/app_constants.dart';
import '../models/daily_challenge.dart';

/// Pure domain generator for UTC-deterministic daily challenges.
/// Resistant to device clock travel and offline-compatible.
class DailyChallengeService {
  DailyChallengeService._();

  static const List<String> _games = [
    AppConstants.gameCubeLogic,
    AppConstants.gameBridgeMaster,
    AppConstants.gameMazeArchitect,
    AppConstants.gameGearTheory,
    AppConstants.gameTinyKingdom,
    AppConstants.gamePerspective,
    AppConstants.gameMemoryMatrix,
  ];

  /// Generates the daily challenge for a given UTC [date].
  static DailyChallenge generateChallengeForDate(DateTime date) {
    final utc = date.toUtc();
    final dateString = '${utc.year.toString().padLeft(4, '0')}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')}';

    // Hash the date string with app salt for a pseudo-random deterministic seed
    final bytes = utf8.encode('MINDVERSE_DAILY_CHALLENGE_$dateString');
    final digest = sha256.convert(bytes);
    final hashInt = digest.bytes[0] << 24 |
        digest.bytes[1] << 16 |
        digest.bytes[2] << 8 |
        digest.bytes[3];
    final seed = hashInt.abs();

    // Select game
    final gameIndex = seed % _games.length;
    final gameId = _games[gameIndex];

    // Select level (levels 1 to 10 for daily challenges)
    final levelNumber = ((seed ~/ _games.length) % 10) + 1;

    final (title, desc) = switch (gameId) {
      AppConstants.gameCubeLogic => (
          'Cube Logic Circuit',
          'Align the 3D energy conduits in Level $levelNumber before moves run out.',
        ),
      AppConstants.gameBridgeMaster => (
          'Bridge Master Load',
          'Construct a stable bridge in Level $levelNumber within budget.',
        ),
      AppConstants.gameMazeArchitect => (
          'Maze Architect Path',
          'Navigate modular sliding tiles in Level $levelNumber to the exit.',
        ),
      AppConstants.gameGearTheory => (
          'Gear Theory Challenge',
          'Transmit rotational energy in Level $levelNumber.',
        ),
      AppConstants.gameTinyKingdom => (
          'Tiny Kingdom Challenge',
          'Build a high-scoring settlement in Level $levelNumber.',
        ),
      AppConstants.gamePerspective => (
          'Perspective Challenge',
          'Align the fragments in Level $levelNumber.',
        ),
      AppConstants.gameMemoryMatrix => (
          'Memory Matrix Challenge',
          'Recall the sequence in Level $levelNumber.',
        ),
      _ => ('Mindverse Puzzle', 'Solve Level $levelNumber.'),
    };

    return DailyChallenge(
      dateString: dateString,
      gameId: gameId,
      levelNumber: levelNumber,
      challengeTitle: title,
      challengeDescription: desc,
      rewardCoins: 100,
      rewardXp: 150,
    );
  }

  /// Calculates new streak given previous date string and completion.
  static int calculateStreak({
    required String? lastCompletedDate,
    required String todayDate,
    required int currentStreak,
  }) {
    if (lastCompletedDate == null) {
      return 1;
    }

    if (lastCompletedDate == todayDate) {
      return currentStreak; // Already completed today
    }

    final lastDate = DateTime.parse(lastCompletedDate);
    final today = DateTime.parse(todayDate);
    final difference = today.difference(lastDate).inDays;

    if (difference < 0) {
      return currentStreak.clamp(0, 7);
    }
    if (difference == 1) {
      return (currentStreak + 1).clamp(1, 7);
    }
    return 1; // Streak broken, restart at 1
  }
}
