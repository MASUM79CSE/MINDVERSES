import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/features/gear_theory/domain/gear.dart';
import 'package:mindverse/features/gear_theory/domain/gear_board.dart';
import 'package:mindverse/features/gear_theory/domain/gear_level_factory.dart';
import 'package:mindverse/features/gear_theory/domain/gear_physics_solver.dart';

void main() {
  group('Gear Theory Domain & Factory', () {
    test('each factory level starts disconnected and can be bridged', () {
      for (var i = 1; i <= GearLevelFactory.levelCount; i++) {
        final level = GearLevelFactory.build(i);
        final initial = level.initialBoard;
        expect(level.levelNumber, i);
        expect(GearPhysicsSolver.evaluate(initial, 0.5).isSolved, isFalse, reason: 'level $i');
        final gear = initial.inventory.first;
        final placed = initial.placeGear(gear.id, 'bridge');
        expect(placed.gears.containsKey(gear.id), isTrue, reason: 'level $i');
        final solved = GearPhysicsSolver.evaluate(placed, 0.5);
        expect(solved.isSolved, isTrue, reason: 'level $i');
        expect(solved.pegs, initial.pegs);
        expect(solved.gears['g_target']!.rotation, closeTo(i == 1 ? 0.5 : 1 / 3, 0.000001));
      }
    });

    test(
      'placement rejects overlaps, out of bounds, occupied and unknown pegs without consuming inventory',
      () {
        const board = GearBoard(
          width: 10,
          height: 10,
          gears: {'fixed': Gear(id: 'fixed', x: 2, y: 5, teeth: 16, isFixed: true)},
          inventory: [Gear(id: 'small', x: 0, y: 0, teeth: 8)],
          pegs: [
            GearPeg(id: 'overlap', x: 4, y: 5),
            GearPeg(id: 'outside', x: 0, y: 1),
            GearPeg(id: 'occupied', x: 2, y: 5),
            GearPeg(id: 'valid', x: 5, y: 5),
          ],
        );
        for (final peg in ['overlap', 'outside', 'occupied', 'missing']) {
          expect(identical(board.placeGear('small', peg), board), isTrue, reason: peg);
        }
        expect(identical(board.placeGear('missing', 'valid'), board), isTrue);
        expect(identical(board.removeGear('occupied'), board), isTrue);
        final placed = board.placeGear('small', 'valid');
        expect(placed.inventory, isEmpty);
        expect(identical(placed.placeGear('small', 'valid'), placed), isTrue);
        final removed = placed.removeGear('valid');
        expect(removed.inventory.single.id, 'small');
        expect(removed.gears.keys, ['fixed']);
        expect(removed.pegs, board.pegs);
      },
    );

    test('solver transmits opposite rotation and tooth ratio only at a lawful mesh distance', () {
      GearBoard makeBoard(double x) => GearBoard(
        width: 12,
        height: 10,
        gears: {
          'driver': const Gear(id: 'driver', x: 2, y: 5, teeth: 16, isDriver: true),
          'target': Gear(id: 'target', x: x, y: 5, teeth: 24, isTarget: true),
        },
        inventory: const [],
      );
      final meshed = GearPhysicsSolver.evaluate(makeBoard(7), 0.6);
      expect(meshed.isSolved, isTrue);
      expect(meshed.gears['target']!.rotation, closeTo(-0.4, 0.000001));
      expect(GearPhysicsSolver.evaluate(makeBoard(6.5), 0.6).isSolved, isFalse);
      expect(GearPhysicsSolver.evaluate(makeBoard(7.5), 0.6).isSolved, isFalse);
    });
  });
}
