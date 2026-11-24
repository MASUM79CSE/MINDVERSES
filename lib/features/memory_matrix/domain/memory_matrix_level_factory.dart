import 'memory_board.dart';

class MemoryMatrixLevel {
  final int levelNumber;
  final String title;
  final int maxMoves;
  final int targetMoves;
  final MemoryMatrixBoard initialBoard;

  const MemoryMatrixLevel({
    required this.levelNumber,
    required this.title,
    required this.maxMoves,
    required this.targetMoves,
    required this.initialBoard,
  });
}

class MemoryMatrixLevelFactory {
  MemoryMatrixLevelFactory._();

  static const int levelCount = 10;

  static MemoryMatrixLevel build(int levelNumber) {
    switch (levelNumber) {
      case 1: return _level1();
      case 2: return _level2();
      case 3: return _level3();
      case 4: return _level4();
      case 5: return _level5();
      case 6: return _level6();
      case 7: return _level7();
      case 8: return _level8();
      case 9: return _level9();
      case 10: return _level10();
      default: return _level1();
    }
  }

  static MemoryMatrixLevel _level1() {
    const sequence = [(0, 0), (1, 1), (2, 2)];
    return const MemoryMatrixLevel(
      levelNumber: 1,
      title: 'First Recall',
      maxMoves: 5,
      targetMoves: 3,
      initialBoard: MemoryMatrixBoard(
        gridSize: 3,
        sequence: sequence,
        playerInput: [],
        phase: MemoryPhase.memorize,
      ),
    );
  }

  static MemoryMatrixLevel _level2() => _buildStandardLevel(2, 'Spatial Trace', 3, 4, 6, 4);
  static MemoryMatrixLevel _level3() => _buildStandardLevel(3, 'Matrix Flash', 4, 5, 8, 5);
  static MemoryMatrixLevel _level4() => _buildStandardLevel(4, 'Deep Memory', 4, 6, 10, 6);
  static MemoryMatrixLevel _level5() => _buildStandardLevel(5, 'Neural Grid', 4, 7, 12, 7);
  static MemoryMatrixLevel _level6() => _buildStandardLevel(6, 'Quantum Recall', 5, 8, 14, 8);
  static MemoryMatrixLevel _level7() => _buildStandardLevel(7, 'Synapse Path', 5, 9, 16, 9);
  static MemoryMatrixLevel _level8() => _buildStandardLevel(8, 'Cortex Array', 5, 10, 18, 10);
  static MemoryMatrixLevel _level9() => _buildStandardLevel(9, 'Enigma Sequence', 5, 12, 20, 12);
  static MemoryMatrixLevel _level10() => _buildStandardLevel(10, 'Master Matrix', 5, 15, 25, 15);

  static MemoryMatrixLevel _buildStandardLevel(int num, String title, int grid, int seqLen, int maxMoves, int targetMoves) {
    final seq = _generateSequence(grid, seqLen, num);
    return MemoryMatrixLevel(
      levelNumber: num,
      title: title,
      maxMoves: maxMoves,
      targetMoves: targetMoves,
      initialBoard: MemoryMatrixBoard(
        gridSize: grid,
        sequence: seq,
        playerInput: const [],
        phase: MemoryPhase.memorize,
      ),
    );
  }

  /// Deterministically samples distinct grid cells so long sequences do not
  /// repeat the same five-tap pattern over and over.
  static List<(int, int)> _generateSequence(int grid, int length, int seed) {
    final cells = <(int, int)>[
      for (var y = 0; y < grid; y++)
        for (var x = 0; x < grid; x++) (x, y),
    ];

    // Small deterministic LCG keeps level layouts stable across runs and
    // platforms without depending on dart:math's implementation details.
    var state = (0x5EED + seed * 7919) & 0x7fffffff;
    int nextInt(int max) {
      state = (state * 1103515245 + 12345) & 0x7fffffff;
      return state % max;
    }

    void shuffle() {
      for (var i = cells.length - 1; i > 0; i--) {
        final j = nextInt(i + 1);
        final tmp = cells[i];
        cells[i] = cells[j];
        cells[j] = tmp;
      }
    }

    shuffle();
    final sequence = <(int, int)>[];
    var index = 0;
    while (sequence.length < length) {
      if (index == cells.length) {
        shuffle();
        index = 0;
      }
      sequence.add(cells[index]);
      index++;
    }
    return sequence;
  }
}
