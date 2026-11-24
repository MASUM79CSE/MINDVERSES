import 'package:flutter/foundation.dart';
import '../../domain/cube_board.dart';

/// Immutable state holder for an active Cube Logic puzzle gameplay session.
@immutable
class CubeLogicState {
  final int levelNumber;
  final String title;
  final CubeBoard board;
  final int moveCount;
  final int maxMoves;
  final int targetMoves;
  final bool isSolved;
  final bool isFailed;
  final bool isPaused;
  final bool isSavingCompletion;
  final String? completionError;
  final (int x, int y, int z)? hintTile;
  final int hintsUsedCount;
  final List<CubeBoard> history;
  final int earnedStars;
  final int earnedXp;
  final int earnedCoins;

  const CubeLogicState({
    required this.levelNumber,
    required this.title,
    required this.board,
    required this.moveCount,
    required this.maxMoves,
    required this.targetMoves,
    this.isSolved = false,
    this.isFailed = false,
    this.isPaused = false,
    this.isSavingCompletion = false,
    this.completionError,
    this.hintTile,
    this.hintsUsedCount = 0,
    this.history = const [],
    this.earnedStars = 0,
    this.earnedXp = 0,
    this.earnedCoins = 0,
  });

  bool get canUndo => history.isNotEmpty && !isCompleted;
  bool get isCompleted => isSolved || isFailed || isSavingCompletion || completionError != null;

  CubeLogicState copyWith({
    int? levelNumber,
    String? title,
    CubeBoard? board,
    int? moveCount,
    int? maxMoves,
    int? targetMoves,
    bool? isSolved,
    bool? isFailed,
    bool? isPaused,
    bool? isSavingCompletion,
    String? completionError,
    bool clearCompletionError = false,
    (int x, int y, int z)? hintTile,
    bool clearHint = false,
    int? hintsUsedCount,
    List<CubeBoard>? history,
    int? earnedStars,
    int? earnedXp,
    int? earnedCoins,
  }) {
    return CubeLogicState(
      levelNumber: levelNumber ?? this.levelNumber,
      title: title ?? this.title,
      board: board ?? this.board,
      moveCount: moveCount ?? this.moveCount,
      maxMoves: maxMoves ?? this.maxMoves,
      targetMoves: targetMoves ?? this.targetMoves,
      isSolved: isSolved ?? this.isSolved,
      isFailed: isFailed ?? this.isFailed,
      isPaused: isPaused ?? this.isPaused,
      isSavingCompletion: isSavingCompletion ?? this.isSavingCompletion,
      completionError: clearCompletionError ? null : (completionError ?? this.completionError),
      hintTile: clearHint ? null : (hintTile ?? this.hintTile),
      hintsUsedCount: hintsUsedCount ?? this.hintsUsedCount,
      history: history ?? this.history,
      earnedStars: earnedStars ?? this.earnedStars,
      earnedXp: earnedXp ?? this.earnedXp,
      earnedCoins: earnedCoins ?? this.earnedCoins,
    );
  }
}
