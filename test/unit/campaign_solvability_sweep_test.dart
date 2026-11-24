import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/features/bridge_master/domain/bridge_level_factory.dart';
import 'package:mindverse/features/bridge_master/domain/bridge_member.dart';
import 'package:mindverse/features/bridge_master/domain/bridge_physics_solver.dart';
import 'package:mindverse/features/cube_logic/domain/cube_energy_solver.dart';
import 'package:mindverse/features/cube_logic/domain/cube_level_factory.dart';
import 'package:mindverse/features/gear_theory/domain/gear_level_factory.dart';
import 'package:mindverse/features/maze_architect/domain/maze_level_factory.dart';
import 'package:mindverse/features/maze_architect/domain/maze_pathfinding_solver.dart';
import 'package:mindverse/features/memory_matrix/domain/memory_matrix_level_factory.dart';
import 'package:mindverse/features/perspective/domain/perspective_level_factory.dart';
import 'package:mindverse/features/tiny_kingdom/domain/tiny_kingdom_level_factory.dart';

void main() {
  group('Comprehensive Campaign Level Solvability Sweep (90 Levels)', () {
    test('Cube Logic: All 20 campaign levels build & have valid topology', () {
      for (int i = 1; i <= 20; i++) {
        final level = CubeLevelFactory.build(i);
        expect(level.levelNumber, equals(i));
        expect(level.title.isNotEmpty, isTrue);
        expect(level.maxMoves, greaterThan(0));
        expect(level.targetMoves, lessThanOrEqualTo(level.maxMoves));
        expect(level.initialBoard.sources, isNotEmpty);
        expect(level.initialBoard.terminals, isNotEmpty);

        // Check board solver logic for unsolved boards
        if (!level.initialBoard.isSolved) {
          final hint = CubeEnergySolver.findHint(level.initialBoard);
          expect(hint, isNotNull, reason: 'Unsolved Cube Logic level $i should provide a valid move hint');
        }
      }
    });

    test('Bridge Master: All 15 campaign levels build & are physics-solvable', () {
      for (int i = 1; i <= 15; i++) {
        final level = BridgeLevelFactory.build(i);
        expect(level.levelNumber, equals(i));
        expect(level.title.isNotEmpty, isTrue);
        expect(level.anchors.length, equals(2));
        expect(level.budget, greaterThan(0));
        expect(level.targetBudget, lessThanOrEqualTo(level.budget));
        expect(level.gapWidth, greaterThan(0));
        expect(level.vehicleWeight, greaterThan(0));

        // Evaluate physics with a standard road deck
        const deck = BridgeMember(
          id: 'road_deck_span',
          jointAId: 'a_left',
          jointBId: 'a_right',
          materialType: BridgeMaterialType.roadDeck,
        );
        final result = BridgePhysicsSolver.evaluate(
          joints: level.anchors,
          members: [deck],
          vehicleX: level.gapWidth / 2,
          vehicleWeight: level.vehicleWeight,
        );
        expect(
          result.isCollapsed,
          isFalse,
          reason: 'Bridge Master level $i should be solvable with a road deck without collapsing',
        );
      }
    });

    test('Maze Architect: All 15 campaign levels build, start unsolved, and are replay-solvable', () {
      for (int i = 1; i <= 15; i++) {
        final level = MazeLevelFactory.build(i);
        expect(level.levelNumber, equals(i));
        expect(level.title.isNotEmpty, isTrue);
        expect(level.targetMoves, greaterThan(0));
        expect(level.maxMoves, greaterThanOrEqualTo(level.targetMoves));
        expect(level.solution, isNotEmpty);

        // Verify level starts unsolved
        final startSolved = MazePathfindingSolver.hasValidPath(level.initialBoard);
        expect(startSolved, isFalse, reason: 'Maze Architect level $i should start unsolved');

        // Replay solution swaps and verify resulting board is solved
        var board = level.initialBoard;
        for (final swap in level.solution) {
          board = swap.apply(board);
        }
        final endSolved = MazePathfindingSolver.hasValidPath(board);
        expect(endSolved, isTrue, reason: 'Maze Architect level $i solution sequence must solve the board');
      }
    });

    test('Gear Theory: All 10 campaign levels build & have valid parameters', () {
      for (int i = 1; i <= 10; i++) {
        final level = GearLevelFactory.build(i);
        expect(level.levelNumber, equals(i));
        expect(level.title.isNotEmpty, isTrue);
        expect(level.maxMoves, greaterThan(0));
        expect(level.targetMoves, lessThanOrEqualTo(level.maxMoves));
        expect(level.initialBoard.gears, isNotEmpty);
      }
    });

    test('Tiny Kingdom: All 10 campaign levels build & have valid grid tiles', () {
      for (int i = 1; i <= 10; i++) {
        final level = TinyKingdomLevelFactory.build(i);
        expect(level.levelNumber, equals(i));
        expect(level.title.isNotEmpty, isTrue);
        expect(level.maxTurns, greaterThan(0));
        expect(level.targetTurns, lessThanOrEqualTo(level.maxTurns));
        expect(level.initialBoard.tiles, isNotEmpty);
      }
    });

    test('Perspective: All 10 campaign levels build & have valid target projections', () {
      for (int i = 1; i <= 10; i++) {
        final level = PerspectiveLevelFactory.build(i);
        expect(level.levelNumber, equals(i));
        expect(level.title.isNotEmpty, isTrue);
        expect(level.maxMoves, greaterThan(0));
        expect(level.targetMoves, lessThanOrEqualTo(level.maxMoves));
        expect(level.initialBoard.shapes, isNotEmpty);
      }
    });

    test('Memory Matrix: All 10 campaign levels build & have valid grid & sequence', () {
      for (int i = 1; i <= 10; i++) {
        final level = MemoryMatrixLevelFactory.build(i);
        expect(level.levelNumber, equals(i));
        expect(level.title.isNotEmpty, isTrue);
        expect(level.maxMoves, greaterThan(0));
        expect(level.targetMoves, lessThanOrEqualTo(level.maxMoves));
        expect(level.initialBoard.sequence, isNotEmpty);
        expect(level.initialBoard.gridSize, greaterThan(0));
      }
    });
  });
}
