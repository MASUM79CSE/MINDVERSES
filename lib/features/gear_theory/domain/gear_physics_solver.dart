import 'dart:math' as math;

import 'gear.dart';
import 'gear_board.dart';

class GearPhysicsSolver {
  GearPhysicsSolver._();

  static GearBoard evaluate(GearBoard board, double driverAngle) {
    final updatedGears = Map<String, Gear>.from(board.gears);
    bool targetRotated = false;

    // Find driver gear
    Gear? driver;
    for (final g in updatedGears.values) {
      if (g.isDriver) {
        driver = g;
        break;
      }
    }

    if (driver == null) return board;

    // Update driver rotation
    updatedGears[driver.id] = driver.copyWith(rotation: driverAngle);

    // BFS / propagation through meshed gears
    final visited = <String>{driver.id};
    final queue = <Gear>[updatedGears[driver.id]!];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);

      // Find neighbors
      for (final other in updatedGears.values) {
        if (visited.contains(other.id)) continue;

        final dx = other.x - current.x;
        final dy = other.y - current.y;
        final dist = math.sqrt(dx * dx + dy * dy);

        final meshDist = GearBoard.radius(current) + GearBoard.radius(other);

        if ((dist - meshDist).abs() <= GearBoard.meshTolerance) {
          // Connected! Calculate rotation ratio: ratio = - current.teeth / other.teeth
          final ratio = current.teeth / other.teeth;
          final otherRotation = current.rotation * -ratio;

          updatedGears[other.id] = other.copyWith(rotation: otherRotation);
          visited.add(other.id);
          queue.add(updatedGears[other.id]!);

          if (other.isTarget && otherRotation.abs() > 0.01) {
            targetRotated = true;
          }
        }
      }
    }

    return GearBoard(
      width: board.width,
      height: board.height,
      gears: updatedGears,
      inventory: board.inventory,
      pegs: board.pegs,
      isSolved: targetRotated,
    );
  }
}
