import 'package:flutter/foundation.dart';

enum MemoryPhase { memorize, recall, success, failure }

@immutable
class MemoryMatrixBoard {
  final int gridSize;
  final List<(int, int)> sequence;
  final List<(int, int)> playerInput;
  final MemoryPhase phase;
  final bool isSolved;

  const MemoryMatrixBoard({
    required this.gridSize,
    required this.sequence,
    required this.playerInput,
    required this.phase,
    this.isSolved = false,
  });

  MemoryMatrixBoard copyWith({
    int? gridSize,
    List<(int, int)>? sequence,
    List<(int, int)>? playerInput,
    MemoryPhase? phase,
    bool? isSolved,
  }) {
    return MemoryMatrixBoard(
      gridSize: gridSize ?? this.gridSize,
      sequence: sequence ?? this.sequence,
      playerInput: playerInput ?? this.playerInput,
      phase: phase ?? this.phase,
      isSolved: isSolved ?? this.isSolved,
    );
  }
}
