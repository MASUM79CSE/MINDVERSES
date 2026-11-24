import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/features/cube_logic/domain/cube_board.dart';
import 'package:mindverse/features/cube_logic/domain/cube_energy_solver.dart';
import 'package:mindverse/features/cube_logic/domain/cube_level_factory.dart';
import 'package:mindverse/features/cube_logic/domain/cube_tile.dart';

void main() {
  group('CubeEnergySolver & Board Topology', () {
    test('Level 1 can be loaded and initial board propagation works', () {
      final level = CubeLevelFactory.build(1);
      expect(level.levelNumber, equals(1));
      expect(level.maxMoves, equals(6));
      expect(level.targetMoves, equals(3));
      expect(level.initialBoard.sources.length, equals(1));
      expect(level.initialBoard.terminals.length, equals(1));
    });

    test('All 20 levels can be built without exceptions', () {
      for (int i = 1; i <= 20; i++) {
        final level = CubeLevelFactory.build(i);
        expect(level.levelNumber, equals(i));
        expect(level.initialBoard.sources.isNotEmpty, isTrue);
        expect(level.initialBoard.terminals.isNotEmpty, isTrue);
      }
    });

    test('Tile rotation updates connections correctly', () {
      const tile = CubeTile(
        x: 0,
        y: 0,
        z: 0,
        type: ConduitType.corner,
        rotation: 0,
      );
      // Rotation 0 corner: North and East
      expect(tile.connections, containsAll([ConduitDirection.north, ConduitDirection.east]));

      final rotated = tile.copyWith(rotation: 1);
      // Rotation 1 corner: East and South
      expect(rotated.connections, containsAll([ConduitDirection.east, ConduitDirection.south]));
    });

    test('Energy propagation solves a simple board', () {
      final tiles = {
        '0_0_0': const CubeTile(x: 0, y: 0, z: 0, type: ConduitType.source),
        '1_0_0': const CubeTile(x: 1, y: 0, z: 0, type: ConduitType.straight, rotation: 1), // E-W
        '2_0_0': const CubeTile(x: 2, y: 0, z: 0, type: ConduitType.terminal),
      };
      final board = CubeBoard(width: 3, height: 1, depth: 1, tiles: tiles);
      final solvedBoard = CubeEnergySolver.solve(board);
      expect(solvedBoard.isSolved, isTrue);
    });

    test('findHint returns candidate tile on unsolved board', () {
      final level = CubeLevelFactory.build(1);
      final hint = CubeEnergySolver.findHint(level.initialBoard);
      expect(hint, isNotNull);
    });
  });
}
