import 'cube_board.dart';
import 'cube_tile.dart';

/// Service class responsible for computing energy propagation across a [CubeBoard].
class CubeEnergySolver {
  CubeEnergySolver._();

  /// Recalculates all energy conduit propagation from source nodes to terminal nodes.
  /// Respects matching energy colors and connection direction topologies.
  static CubeBoard solve(CubeBoard board) {
    return board.withPropagatedPower();
  }

  /// Calculates the hint tile position (x, y, z) that, if rotated clockwise,
  /// brings the board closer to powered terminals. Returns null if board is already solved.
  static (int x, int y, int z)? findHint(CubeBoard board) {
    if (board.isSolved) return null;

    // Search for any non-locked, non-source, non-terminal tile that, when rotated, increases powered terminals
    final currentPowered = board.poweredTerminalCount;
    for (final tile in board.tiles.values) {
      if (tile.isLocked ||
          tile.type == ConduitType.source ||
          tile.type == ConduitType.terminal ||
          tile.type == ConduitType.empty ||
          tile.type == ConduitType.locked) {
        continue;
      }

      for (int rot = 1; rot <= 3; rot++) {
        final testRot = (tile.rotation + rot) % 4;
        final testBoard = board.withTile(tile.copyWith(rotation: testRot)).withPropagatedPower();
        if (testBoard.poweredTerminalCount > currentPowered || testBoard.isSolved) {
          return (tile.x, tile.y, tile.z);
        }
      }
    }

    // Fallback: return the first rotatable tile that is currently unpowered or adjacent to a powered tile
    for (final tile in board.tiles.values) {
      if (!tile.isLocked &&
          tile.type != ConduitType.source &&
          tile.type != ConduitType.terminal &&
          tile.type != ConduitType.empty &&
          tile.type != ConduitType.locked) {
        return (tile.x, tile.y, tile.z);
      }
    }

    return null;
  }
}
