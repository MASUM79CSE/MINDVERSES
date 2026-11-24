import 'package:flutter/foundation.dart';

import '../../domain/memory_board.dart';

@immutable
class MemoryMatrixState {
  final int levelNumber;
  final String title;
  final MemoryMatrixBoard board;
  final int moveCount;
  final int maxMoves;
  final int targetMoves;
  final bool isSolved;
  final bool isFailed;
  final bool isPaused;
  final bool isSavingCompletion;
  final String? completionError;
  final int earnedStars;
  final int earnedXp;
  final int earnedCoins;

  const MemoryMatrixState({
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
    this.earnedStars = 0,
    this.earnedXp = 0,
    this.earnedCoins = 0,
  });

  bool get isCompletionPending => isSavingCompletion || completionError != null;
  bool get isCompleted => isSolved || isFailed || isCompletionPending;

  MemoryMatrixState copyWith({
    int? levelNumber,
    String? title,
    MemoryMatrixBoard? board,
    int? moveCount,
    int? maxMoves,
    int? targetMoves,
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
    return MemoryMatrixState(
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
      completionError: clearCompletionError
          ? null
          : (completionError ?? this.completionError),
      earnedStars: earnedStars ?? this.earnedStars,
      earnedXp: earnedXp ?? this.earnedXp,
      earnedCoins: earnedCoins ?? this.earnedCoins,
    );
  }
}
