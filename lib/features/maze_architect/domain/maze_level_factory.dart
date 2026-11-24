import 'dart:math';

import 'maze_board.dart';
import 'maze_pathfinding_solver.dart';
import 'maze_tile.dart';

/// A recorded swap between two board coordinates.
///
/// A swap is its own inverse: applying the same pair twice restores the board.
class MazeSwap {
  final int fromX;
  final int fromY;
  final int toX;
  final int toY;

  const MazeSwap(this.fromX, this.fromY, this.toX, this.toY);

  MazeBoard apply(MazeBoard board) => board.swapTiles(fromX, fromY, toX, toY);
}

class MazeLevel {
  final int levelNumber;
  final String title;
  final int maxMoves;
  final int targetMoves;
  final MazeBoard initialBoard;

  /// Swaps that turn [initialBoard] into a solved board.
  ///
  /// Replaying the swaps in order is a guaranteed solution and is also used by
  /// tests to prove every level is solvable within [targetMoves].
  final List<MazeSwap> solution;

  const MazeLevel({
    required this.levelNumber,
    required this.title,
    required this.maxMoves,
    required this.targetMoves,
    required this.initialBoard,
    this.solution = const [],
  });
}

/// Factory constructing all 15 Maze Architect level definitions.
///
/// Each level is generated from a guaranteed-solved "snake" layout and then
/// scrambled with a deterministic sequence of swaps. Every accepted scramble
/// swap keeps the board unsolved, so the initial board never shows a valid
/// route and the recorded [MazeLevel.solution] always starts unsolved.
class MazeLevelFactory {
  MazeLevelFactory._();

  static MazeLevel build(int levelNumber) {
    switch (levelNumber) {
      case 1:
        return _build(1, 'First Pathway', 3, 3, 2);
      case 2:
        return _build(2, 'Sliding Corridor', 3, 3, 2);
      case 3:
        return _build(3, 'Twisted Turn', 3, 3, 3);
      case 4:
        return _build(4, 'Matrix Grid', 4, 4, 3);
      case 5:
        return _build(5, 'Cross Junction', 4, 4, 4);
      case 6:
        return _build(6, 'Labyrinth Gate', 4, 4, 4);
      case 7:
        return _build(7, 'Grand Hall', 5, 5, 5);
      case 8:
        return _build(8, 'Deep Maze', 5, 5, 5);
      case 9:
        return _build(9, 'Quantum Maze', 5, 5, 6);
      case 10:
        return _build(10, 'Architect Labyrinth', 5, 5, 6);
      case 11:
        return _build(11, 'Complex Web', 6, 6, 7);
      case 12:
        return _build(12, 'Infinite Loop', 6, 6, 7);
      case 13:
        return _build(13, 'Master Conduit', 6, 6, 8);
      case 14:
        return _build(14, 'Supreme Architect', 6, 6, 9);
      case 15:
        return _build(15, 'Grandmaster Labyrinth', 6, 6, 10);
      default:
        return _build(1, 'First Pathway', 3, 3, 2);
    }
  }

  /// Builds a level whose solved layout is a serpentine path visiting every
  /// cell. The path starts at the top-left corner and ends at the far corner
  /// of the final row, so the destination stays fixed while the start and
  /// destination tiles are locked against swapping.
  static MazeLevel _build(
    int levelNumber,
    String title,
    int width,
    int height,
    int scrambleSwaps,
  ) {
    final path = _snakePath(width, height);
    final solvedBoard = MazeBoard(
      width: width,
      height: height,
      tiles: _solvedTiles(path),
      startPos: path.first,
      destinationPos: path.last,
    );

    final movableCells = path.sublist(1, path.length - 1);
    final random = Random(0x5EED + levelNumber * 7919);
    final scramble = <MazeSwap>[];
    var board = solvedBoard;
    while (scramble.length < scrambleSwaps) {
      final next = _findScrambleSwap(board, movableCells, random, scramble);
      if (next == null) break;
      board = next.apply(board);
      scramble.add(next);
    }

    assert(
      scramble.isNotEmpty,
      'Level $levelNumber must start unsolved and solvable.',
    );

    final solution = scramble.reversed.toList(growable: false);
    return MazeLevel(
      levelNumber: levelNumber,
      title: title,
      maxMoves: solution.length + 6,
      targetMoves: solution.length,
      initialBoard: board,
      solution: solution,
    );
  }

  static List<(int, int)> _snakePath(int width, int height) {
    final path = <(int, int)>[];
    for (var y = 0; y < height; y++) {
      if (y.isEven) {
        for (var x = 0; x < width; x++) {
          path.add((x, y));
        }
      } else {
        for (var x = width - 1; x >= 0; x--) {
          path.add((x, y));
        }
      }
    }
    return path;
  }

  /// Assigns each cell only the openings needed to continue the snake path.
  static Map<String, MazeTile> _solvedTiles(List<(int, int)> path) {
    final tiles = <String, MazeTile>{};
    for (var i = 0; i < path.length; i++) {
      final (x, y) = path[i];
      final openings = <String>{};
      if (i > 0) openings.add(_directionBetween(path[i], path[i - 1]));
      if (i < path.length - 1) {
        openings.add(_directionBetween(path[i], path[i + 1]));
      }

      final isStart = i == 0;
      final isDestination = i == path.length - 1;
      tiles['${x}_$y'] = MazeTile(
        x: x,
        y: y,
        type: isStart
            ? MazeTileType.start
            : isDestination
            ? MazeTileType.destination
            : MazeTileType.movable,
        isOpenNorth: openings.contains('north'),
        isOpenSouth: openings.contains('south'),
        isOpenEast: openings.contains('east'),
        isOpenWest: openings.contains('west'),
        isLocked: isStart || isDestination,
      );
    }
    return tiles;
  }

  /// Direction from [from] to an adjacent cell [to].
  static String _directionBetween((int, int) from, (int, int) to) {
    if (to.$2 < from.$2) return 'north';
    if (to.$2 > from.$2) return 'south';
    if (to.$1 > from.$1) return 'east';
    return 'west';
  }

  /// Finds a deterministic swap that changes tile connectivity without
  /// accidentally solving the board.
  static MazeSwap? _findScrambleSwap(
    MazeBoard board,
    List<(int, int)> cells,
    Random random,
    List<MazeSwap> applied,
  ) {
    bool isUsable((int, int) a, (int, int) b) {
      if (a == b) return false;
      final tileA = board.tileAt(a.$1, a.$2);
      final tileB = board.tileAt(b.$1, b.$2);
      if (tileA == null || tileB == null) return false;
      if (_sameShape(tileA, tileB)) return false;

      final swap = MazeSwap(a.$1, a.$2, b.$1, b.$2);
      if (applied.isNotEmpty && _sameSwap(applied.last, swap)) return false;
      return !MazePathfindingSolver.hasValidPath(swap.apply(board));
    }

    for (var attempt = 0; attempt < 200; attempt++) {
      final a = cells[random.nextInt(cells.length)];
      final b = cells[random.nextInt(cells.length)];
      if (isUsable(a, b)) return MazeSwap(a.$1, a.$2, b.$1, b.$2);
    }

    // Deterministic fallback so generation never depends on luck.
    for (final a in cells) {
      for (final b in cells) {
        if (isUsable(a, b)) return MazeSwap(a.$1, a.$2, b.$1, b.$2);
      }
    }
    return null;
  }

  static bool _sameShape(MazeTile a, MazeTile b) =>
      a.isOpenNorth == b.isOpenNorth &&
      a.isOpenSouth == b.isOpenSouth &&
      a.isOpenEast == b.isOpenEast &&
      a.isOpenWest == b.isOpenWest;

  static bool _sameSwap(MazeSwap a, MazeSwap b) =>
      (a.fromX == b.fromX &&
          a.fromY == b.fromY &&
          a.toX == b.toX &&
          a.toY == b.toY) ||
      (a.fromX == b.toX &&
          a.fromY == b.toY &&
          a.toX == b.fromX &&
          a.toY == b.fromY);
}
