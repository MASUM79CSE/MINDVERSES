import 'package:flutter/foundation.dart';
import '../../domain/kingdom_board.dart';
import '../../domain/kingdom_tile.dart';

@immutable
class TinyKingdomState {
  final int levelNumber;
  final String title;
  final KingdomBoard board;
  final int turnCount;
  final int maxTurns;
  final int targetTurns;
  final BuildingType selectedBuilding;
  final bool isSolved;
  final bool isFailed;
  final bool isPaused;
  final bool isSavingCompletion;
  final String? completionError;
  final int earnedStars;
  final int earnedXp;
  final int earnedCoins;

  const TinyKingdomState({
    required this.levelNumber,
    required this.title,
    required this.board,
    required this.turnCount,
    required this.maxTurns,
    required this.targetTurns,
    this.selectedBuilding = BuildingType.house,
    this.isSolved = false,
    this.isFailed = false,
    this.isPaused = false,
    this.isSavingCompletion = false,
    this.completionError,
    this.earnedStars = 0,
    this.earnedXp = 0,
    this.earnedCoins = 0,
  });

  bool get hasPendingCompletion => isSavingCompletion || completionError != null;
  bool get isCompleted => isSolved || isFailed || hasPendingCompletion;

  TinyKingdomState copyWith({
    int? levelNumber,
    String? title,
    KingdomBoard? board,
    int? turnCount,
    int? maxTurns,
    int? targetTurns,
    BuildingType? selectedBuilding,
    bool? isSolved,
    bool? isFailed,
    bool? isPaused,
    bool? isSavingCompletion,
    String? completionError,
    bool clearCompletionError = false,
    int? earnedStars,
    int? earnedXp,
    int? earnedCoins,
  }) {
    return TinyKingdomState(
      levelNumber: levelNumber ?? this.levelNumber,
      title: title ?? this.title,
      board: board ?? this.board,
      turnCount: turnCount ?? this.turnCount,
      maxTurns: maxTurns ?? this.maxTurns,
      targetTurns: targetTurns ?? this.targetTurns,
      selectedBuilding: selectedBuilding ?? this.selectedBuilding,
      isSolved: isSolved ?? this.isSolved,
      isFailed: isFailed ?? this.isFailed,
      isPaused: isPaused ?? this.isPaused,
      isSavingCompletion: isSavingCompletion ?? this.isSavingCompletion,
      completionError: clearCompletionError ? null : completionError ?? this.completionError,
      earnedStars: earnedStars ?? this.earnedStars,
      earnedXp: earnedXp ?? this.earnedXp,
      earnedCoins: earnedCoins ?? this.earnedCoins,
    );
  }
}
