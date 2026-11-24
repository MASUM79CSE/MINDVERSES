import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/features/maze_architect/domain/maze_board.dart';
import 'package:mindverse/features/maze_architect/domain/maze_level_factory.dart';
import 'package:mindverse/features/maze_architect/domain/maze_pathfinding_solver.dart';

(int, int)? firstMovable(MazeBoard board) {
  for (final tile in board.tiles.values) {
    if (!tile.isLocked) return (tile.x, tile.y);
  }
  return null;
}

void main() {
  group('Maze Architect Domain & Solver', () {
    test('Builds all 15 Maze Architect levels successfully', () {
      for (int i = 1; i <= 15; i++) {
        final level = MazeLevelFactory.build(i);
        expect(level.levelNumber, equals(i));
        expect(level.initialBoard.width, greaterThanOrEqualTo(3));
        expect(level.initialBoard.height, greaterThanOrEqualTo(3));
        expect(level.initialBoard.tiles, hasLength(
          level.initialBoard.width * level.initialBoard.height,
        ));
      }
    });

    test('every level starts unsolved', () {
      for (int i = 1; i <= 15; i++) {
        final level = MazeLevelFactory.build(i);
        expect(
          MazePathfindingSolver.hasValidPath(level.initialBoard),
          isFalse,
          reason: 'Level $i must not present an already-connected path',
        );
      }
    });

    test('every recorded solution solves the level within its move budget', () {
      for (int i = 1; i <= 15; i++) {
        final level = MazeLevelFactory.build(i);
        expect(level.solution, isNotEmpty, reason: 'Level $i needs a solution');
        expect(level.solution.length, level.targetMoves);
        expect(level.targetMoves, greaterThan(0));
        expect(level.targetMoves, lessThanOrEqualTo(level.maxMoves));

        var board = level.initialBoard;
        for (var move = 0; move < level.solution.length; move++) {
          board = level.solution[move].apply(board);
          final solved = MazePathfindingSolver.hasValidPath(board);
          if (move < level.solution.length - 1) {
            expect(
              solved,
              isFalse,
              reason:
                  'Level $i became solvable before the final solution move '
                  '(${move + 1}/${level.solution.length})',
            );
          }
        }
        expect(
          MazePathfindingSolver.hasValidPath(board),
          isTrue,
          reason: 'Level $i solution must connect start to destination',
        );
      }
    });

    test('start and destination tiles are locked against swapping', () {
      for (int i = 1; i <= 15; i++) {
        final level = MazeLevelFactory.build(i);
        final board = level.initialBoard;
        final start = board.tileAt(board.startPos.$1, board.startPos.$2)!;
        final destination = board.tileAt(
          board.destinationPos.$1,
          board.destinationPos.$2,
        )!;
        expect(start.isLocked, isTrue);
        expect(destination.isLocked, isTrue);

        final movable = firstMovable(board)!;
        final swapped = board.swapTiles(
          board.startPos.$1,
          board.startPos.$2,
          movable.$1,
          movable.$2,
        );
        expect(identical(swapped, board), isTrue);
      }
    });

    test('tiles use restricted openings instead of fully open cells', () {
      for (int i = 1; i <= 15; i++) {
        final board = MazeLevelFactory.build(i).initialBoard;
        final fullyOpen = board.tiles.values.where(
          (tile) =>
              tile.isOpenNorth &&
              tile.isOpenSouth &&
              tile.isOpenEast &&
              tile.isOpenWest,
        );
        expect(fullyOpen, isEmpty, reason: 'Level $i has fully open tiles');
      }
    });

    test('level 1 is a two-swap tutorial', () {
      expect(MazeLevelFactory.build(1).solution.length, 2);
      expect(MazeLevelFactory.build(1).targetMoves, 2);
      expect(MazeLevelFactory.build(1).maxMoves, 8);
    });
  });
}
