import 'package:flutter/foundation.dart';
import 'cube_tile.dart';

/// Immutable snapshot of the entire Cube Logic puzzle board state.
@immutable
class CubeBoard {
  final int width;  // x-axis
  final int height; // y-axis
  final int depth;  // z-axis (number of layers)

  /// All tiles keyed by composite id 'x_y_z'.
  final Map<String, CubeTile> tiles;

  const CubeBoard({
    required this.width,
    required this.height,
    required this.depth,
    required this.tiles,
  });

  /// Returns the tile at [x, y, z] or null if out of bounds / absent.
  CubeTile? tileAt(int x, int y, int z) => tiles['${x}_${y}_$z'];

  /// Returns all source tiles.
  List<CubeTile> get sources =>
      tiles.values.where((t) => t.type == ConduitType.source).toList();

  /// Returns all terminal tiles.
  List<CubeTile> get terminals =>
      tiles.values.where((t) => t.type == ConduitType.terminal).toList();

  /// Returns true when every terminal is powered.
  bool get isSolved => terminals.isNotEmpty && terminals.every((t) => t.isPowered);

  /// Returns the number of powered terminals.
  int get poweredTerminalCount => terminals.where((t) => t.isPowered).length;

  /// Returns the number of total terminals.
  int get totalTerminalCount => terminals.length;

  /// Returns a new board with the given tile replaced.
  CubeBoard withTile(CubeTile updated) {
    final newTiles = Map<String, CubeTile>.from(tiles);
    newTiles[updated.id] = updated;
    return CubeBoard(width: width, height: height, depth: depth, tiles: newTiles);
  }

  /// Returns a new board with all powered states recalculated from [propagatePower].
  CubeBoard withPropagatedPower() {
    final powered = _computePoweredTileIds();
    final newTiles = tiles.map((key, tile) {
      if (tile.type == ConduitType.terminal) {
        return MapEntry(key, tile.copyWith(isPowered: powered.contains(key)));
      }
      return MapEntry(key, tile);
    });
    return CubeBoard(width: width, height: height, depth: depth, tiles: newTiles);
  }

  /// BFS from each source across connected conduits. Returns set of powered tile ids.
  Set<String> _computePoweredTileIds() {
    final visited = <String>{};
    final queue = <CubeTile>[];

    // Seed BFS with all source tiles
    for (final source in sources) {
      queue.add(source);
      visited.add(source.id);
    }

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      for (final dir in current.connections) {
        final neighbor = _neighborInDirection(current, dir);
        if (neighbor == null || visited.contains(neighbor.id)) continue;
        // Neighbor must connect back toward current
        final reverse = _reverse(dir);
        final neighborConns = neighbor.connections;
        final neighborIsTerminal = neighbor.type == ConduitType.terminal;
        if (neighborIsTerminal || neighborConns.contains(reverse)) {
          visited.add(neighbor.id);
          queue.add(neighbor);
        }
      }
    }

    return visited;
  }

  CubeTile? _neighborInDirection(CubeTile tile, ConduitDirection dir) {
    switch (dir) {
      case ConduitDirection.north: return tileAt(tile.x, tile.y - 1, tile.z);
      case ConduitDirection.south: return tileAt(tile.x, tile.y + 1, tile.z);
      case ConduitDirection.east:  return tileAt(tile.x + 1, tile.y, tile.z);
      case ConduitDirection.west:  return tileAt(tile.x - 1, tile.y, tile.z);
    }
  }

  ConduitDirection _reverse(ConduitDirection dir) {
    switch (dir) {
      case ConduitDirection.north: return ConduitDirection.south;
      case ConduitDirection.south: return ConduitDirection.north;
      case ConduitDirection.east:  return ConduitDirection.west;
      case ConduitDirection.west:  return ConduitDirection.east;
    }
  }
}
