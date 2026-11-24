import 'package:flutter/foundation.dart';

import '../../domain/maze_board.dart';

/// Immutable state for a Maze Architect gameplay session.
@immutable
class MazeArchitectState {
  final int levelNumber;
  final String title;
  final MazeBoard board;
  final int moveCount;
  final int maxMoves;
  final int targetMoves;
  final (int, int)? selectedCoord;
  final bool isSolved;
  final bool isFailed;
  final bool isPaused;
  final bool isSavingCompletion;
  final String? completionError;
  final List<MazeBoard> history;
  final int earnedStars;
  final int earnedXp;
  final int earnedCoins;

  const MazeArchitectState({
    required this.levelNumber,
    required this.title,
    required this.board,
    required this.moveCount,
    required this.maxMoves,
    required this.targetMoves,
    this.selectedCoord,
    this.isSolved = false,
    this.isFailed = false,
    this.isPaused = false,
    this.isSavingCompletion = false,
    this.completionError,
    this.history = const [],
    this.earnedStars = 0,
    this.earnedXp = 0,
    this.earnedCoins = 0,
  });

  bool get isCompletionPending => isSavingCompletion || completionError != null;
  bool get canUndo => history.isNotEmpty && !isCompleted && !isPaused;
  bool get isCompleted => isSolved || isFailed || isCompletionPending;

  MazeArchitectState copyWith({
    int? levelNumber,
    String? title,
    MazeBoard? board,
    int? moveCount,
    int? maxMoves,
    int? targetMoves,
    (int, int)? selectedCoord,
    bool clearSelected = false,
    bool? isSolved,
    bool? isFailed,
    bool? isPaused,
    bool? isSavingCompletion,
    String? completionError,
    bool clearCompletionError = false,
    List<MazeBoard>? history,
    int? earnedStars,
    int? earnedXp,
    int? earnedCoins,
  }) {
    return MazeArchitectState(
      levelNumber: levelNumber ?? this.levelNumber,
      title: title ?? this.title,
      board: board ?? this.board,
      moveCount: moveCount ?? this.moveCount,
      maxMoves: maxMoves ?? this.maxMoves,
      targetMoves: targetMoves ?? this.targetMoves,
      selectedCoord: clearSelected
          ? null
          : (selectedCoord ?? this.selectedCoord),
      isSolved: isSolved ?? this.isSolved,
      isFailed: isFailed ?? this.isFailed,
      isPaused: isPaused ?? this.isPaused,
      isSavingCompletion: isSavingCompletion ?? this.isSavingCompletion,
      completionError: clearCompletionError
          ? null
          : (completionError ?? this.completionError),
      history: history ?? this.history,
      earnedStars: earnedStars ?? this.earnedStars,
      earnedXp: earnedXp ?? this.earnedXp,
      earnedCoins: earnedCoins ?? this.earnedCoins,
    );
  }
}
