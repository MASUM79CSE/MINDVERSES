import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/features/bridge_master/domain/bridge_joint.dart';
import 'package:mindverse/features/bridge_master/domain/bridge_level_factory.dart';
import 'package:mindverse/features/bridge_master/domain/bridge_member.dart';
import 'package:mindverse/features/bridge_master/domain/bridge_physics_solver.dart';

void main() {
  group('Bridge Master Domain & Physics Solver', () {
    test('Builds all 15 Bridge Master levels successfully', () {
      for (int i = 1; i <= 15; i++) {
        final level = BridgeLevelFactory.build(i);
        expect(level.levelNumber, equals(i));
        expect(level.anchors.length, equals(2));
        expect(level.budget, greaterThan(0));
        expect(level.gapWidth, greaterThan(0));
      }
    });

    test('level parameters match the GDD progression table', () {
      const expected = [
        (1, 6.0, 800.0, 1500, 1100),
        (2, 8.0, 800.0, 2000, 1450),
        (3, 10.0, 1800.0, 2800, 2100),
        (4, 12.0, 1800.0, 3500, 2600),
        (5, 10.0, 1800.0, 3200, 2400),
        (6, 14.0, 4200.0, 4500, 3400),
        (7, 16.0, 4200.0, 5500, 4100),
        (8, 12.0, 1800.0, 4200, 3100),
        (9, 18.0, 4200.0, 6500, 4800),
        (10, 14.0, 4200.0, 5800, 4300),
        (11, 20.0, 4200.0, 7500, 5500),
        (12, 16.0, 4200.0, 6800, 5000),
        (13, 22.0, 4200.0, 8500, 6200),
        (14, 20.0, 6000.0, 8800, 6500),
        (15, 24.0, 6000.0, 10000, 7400),
      ];
      for (final (levelNumber, gap, weight, budget, target) in expected) {
        final level = BridgeLevelFactory.build(levelNumber);
        expect(level.gapWidth, gap, reason: 'level $levelNumber gap');
        expect(level.vehicleWeight, weight, reason: 'level $levelNumber weight');
        expect(level.budget, budget, reason: 'level $levelNumber budget');
        expect(
          level.targetBudget,
          target,
          reason: 'level $levelNumber star-2 target',
        );
      }
    });

    test('every level is solvable with a road deck', () {
      for (int i = 1; i <= 15; i++) {
        final level = BridgeLevelFactory.build(i);
        const deck = BridgeMember(
          id: 'deck',
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
          reason: 'level $i should be solvable',
        );
        expect(result.peakStressRatio, lessThanOrEqualTo(1.0));
      }
    });

    test('Calculates member cost based on length and material rate', () {
      const jA = BridgeJoint(id: 'j1', x: 0, y: 0);
      const jB = BridgeJoint(id: 'j2', x: 4, y: 0);
      final joints = {'j1': jA, 'j2': jB};

      const member = BridgeMember(
        id: 'm1',
        jointAId: 'j1',
        jointBId: 'j2',
        materialType: BridgeMaterialType.roadDeck,
      );

      expect(member.length(joints), equals(4.0));
      // Road deck = 50 per meter -> 4 * 50 = 200
      expect(member.calculateCost(joints), equals(200));
    });

    test('Evaluates physics stress under load', () {
      const jA = BridgeJoint(id: 'j1', x: 0, y: 5, anchorType: AnchorType.leftBank);
      const jB = BridgeJoint(id: 'j2', x: 8, y: 5, anchorType: AnchorType.rightBank);
      final joints = {'j1': jA, 'j2': jB};

      const member = BridgeMember(
        id: 'm1',
        jointAId: 'j1',
        jointBId: 'j2',
        materialType: BridgeMaterialType.roadDeck,
      );

      final result = BridgePhysicsSolver.evaluate(
        joints: joints,
        members: [member],
        vehicleX: 4.0,
        vehicleWeight: 100.0,
      );

      expect(result.members.length, equals(1));
      expect(result.isCollapsed, isFalse);
      expect(result.peakStressRatio, greaterThan(0.0));
    });

    test('vehicle outside the road deck is unsupported', () {
      const joints = {
        'j1': BridgeJoint(id: 'j1', x: 2, y: 5),
        'j2': BridgeJoint(id: 'j2', x: 4, y: 5),
      };
      const deck = BridgeMember(
        id: 'm1',
        jointAId: 'j1',
        jointBId: 'j2',
        materialType: BridgeMaterialType.roadDeck,
      );

      final result = BridgePhysicsSolver.evaluate(
        joints: joints,
        members: [deck],
        vehicleX: 0.0,
        vehicleWeight: 100.0,
      );

      expect(result.isCollapsed, isTrue);
      expect(result.isVehicleSupported, isFalse);
    });
  });
}
