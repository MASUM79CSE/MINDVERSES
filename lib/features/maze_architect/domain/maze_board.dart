import 'package:flutter/foundation.dart';
import 'maze_tile.dart';

/// Immutable snapshot of the Maze Architect puzzle board state.
@immutable
class MazeBoard {
  final int width;
  final int height;
  final Map<String, MazeTile> tiles;
  final (int, int) startPos;
  final (int, int) destinationPos;

  const MazeBoard({
    required this.width,
    required this.height,
    required this.tiles,
    required this.startPos,
    required this.destinationPos,
  });

  MazeTile? tileAt(int x, int y) => tiles['${x}_$y'];

  MazeBoard withTile(MazeTile updated) {
    final newTiles = Map<String, MazeTile>.from(tiles);
    newTiles[updated.id] = updated.copyWith(x: updated.x, y: updated.y);
    return MazeBoard(
      width: width,
      height: height,
      tiles: newTiles,
      startPos: startPos,
      destinationPos: destinationPos,
    );
  }

  /// Swaps positions of two movable tiles.
  MazeBoard swapTiles(int x1, int y1, int x2, int y2) {
    final t1 = tileAt(x1, y1);
    final t2 = tileAt(x2, y2);
    if (t1 == null || t2 == null || t1.isLocked || t2.isLocked) return this;

    final newTiles = Map<String, MazeTile>.from(tiles);
    final movedT1 = t1.copyWith(x: x2, y: y2);
    final movedT2 = t2.copyWith(x: x1, y: y1);

    newTiles[movedT1.id] = movedT1;
    newTiles[movedT2.id] = movedT2;

    return MazeBoard(
      width: width,
      height: height,
      tiles: newTiles,
      startPos: startPos,
      destinationPos: destinationPos,
    );
  }
}
