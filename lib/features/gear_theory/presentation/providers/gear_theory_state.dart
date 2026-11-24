import 'package:flutter/foundation.dart';

import '../../domain/gear_board.dart';

@immutable
class GearTheoryState {
  final int levelNumber;
  final String title;
  final GearBoard board;
  final String? selectedGearId;
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

  const GearTheoryState({
    required this.levelNumber,
    required this.title,
    required this.board,
    this.selectedGearId,
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

  GearTheoryState copyWith({
    int? levelNumber,
    String? title,
    GearBoard? board,
    String? selectedGearId,
    bool clearSelectedGear = false,
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
    return GearTheoryState(
      levelNumber: levelNumber ?? this.levelNumber,
      title: title ?? this.title,
      board: board ?? this.board,
      selectedGearId: clearSelectedGear ? null : selectedGearId ?? this.selectedGearId,
      moveCount: moveCount ?? this.moveCount,
      maxMoves: maxMoves ?? this.maxMoves,
      targetMoves: targetMoves ?? this.targetMoves,
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
