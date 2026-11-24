import 'package:flutter/foundation.dart';
import '../../domain/perspective_board.dart';

@immutable
class PerspectiveState {
  final int levelNumber;
  final String title;
  final PerspectiveBoard board;
  final int moveCount;
  final int maxMoves;
  final int targetMoves;
  final String selectedShapeId;
  final bool isSolved;
  final bool isFailed;
  final bool isPaused;
  final bool isSavingCompletion;
  final String? completionError;
  final int earnedStars;
  final int earnedXp;
  final int earnedCoins;

  const PerspectiveState({
    required this.levelNumber,
    required this.title,
    required this.board,
    required this.moveCount,
    required this.maxMoves,
    required this.targetMoves,
    required this.selectedShapeId,
    this.isSolved = false,
    this.isFailed = false,
    this.isPaused = false,
    this.isSavingCompletion = false,
    this.completionError,
    this.earnedStars = 0,
    this.earnedXp = 0,
    this.earnedCoins = 0,
  });

  bool get isCompleted => isSolved || isFailed || isSavingCompletion || completionError != null;

  PerspectiveState copyWith({
    int? levelNumber,
    String? title,
    PerspectiveBoard? board,
    int? moveCount,
    int? maxMoves,
    int? targetMoves,
    String? selectedShapeId,
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
    return PerspectiveState(
      levelNumber: levelNumber ?? this.levelNumber,
      title: title ?? this.title,
      board: board ?? this.board,
      moveCount: moveCount ?? this.moveCount,
      maxMoves: maxMoves ?? this.maxMoves,
      targetMoves: targetMoves ?? this.targetMoves,
      selectedShapeId: selectedShapeId ?? this.selectedShapeId,
      isSolved: isSolved ?? this.isSolved,
      isFailed: isFailed ?? this.isFailed,
      isPaused: isPaused ?? this.isPaused,
      isSavingCompletion: isSavingCompletion ?? this.isSavingCompletion,
      completionError: clearCompletionError ? null : (completionError ?? this.completionError),
      earnedStars: earnedStars ?? this.earnedStars,
      earnedXp: earnedXp ?? this.earnedXp,
      earnedCoins: earnedCoins ?? this.earnedCoins,
    );
  }
}
