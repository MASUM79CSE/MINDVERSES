import 'maze_board.dart';

/// Pathfinding service validating if a continuous open path exists from start to destination.
class MazePathfindingSolver {
  MazePathfindingSolver._();

  static bool hasValidPath(MazeBoard board) {
    final start = board.startPos;
    final dest = board.destinationPos;

    final visited = <String>{};
    final queue = <(int, int)>[start];
    visited.add('${start.$1}_${start.$2}');

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (current == dest) return true;

      final currentTile = board.tileAt(current.$1, current.$2);
      if (currentTile == null) continue;

      // Check North
      if (current.$2 > 0) {
        final nPos = (current.$1, current.$2 - 1);
        final nKey = '${nPos.$1}_${nPos.$2}';
        final nTile = board.tileAt(nPos.$1, nPos.$2);
        if (!visited.contains(nKey) && currentTile.connectsWith(nTile, 'north')) {
          visited.add(nKey);
          queue.add(nPos);
        }
      }

      // Check South
      if (current.$2 < board.height - 1) {
        final sPos = (current.$1, current.$2 + 1);
        final sKey = '${sPos.$1}_${sPos.$2}';
        final sTile = board.tileAt(sPos.$1, sPos.$2);
        if (!visited.contains(sKey) && currentTile.connectsWith(sTile, 'south')) {
          visited.add(sKey);
          queue.add(sPos);
        }
      }

      // Check East
      if (current.$1 < board.width - 1) {
        final ePos = (current.$1 + 1, current.$2);
        final eKey = '${ePos.$1}_${ePos.$2}';
        final eTile = board.tileAt(ePos.$1, ePos.$2);
        if (!visited.contains(eKey) && currentTile.connectsWith(eTile, 'east')) {
          visited.add(eKey);
          queue.add(ePos);
        }
      }

      // Check West
      if (current.$1 > 0) {
        final wPos = (current.$1 - 1, current.$2);
        final wKey = '${wPos.$1}_${wPos.$2}';
        final wTile = board.tileAt(wPos.$1, wPos.$2);
        if (!visited.contains(wKey) && currentTile.connectsWith(wTile, 'west')) {
          visited.add(wKey);
          queue.add(wPos);
        }
      }
    }

    return false;
  }
}
