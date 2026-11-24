import 'package:flutter/foundation.dart';
import 'kingdom_tile.dart';

@immutable
class KingdomBoard {
  final int width;
  final int height;
  final Map<String, KingdomTile> tiles;
  final int gold;
  final int targetGold;
  final bool isSolved;

  const KingdomBoard({
    required this.width,
    required this.height,
    required this.tiles,
    required this.gold,
    required this.targetGold,
    this.isSolved = false,
  });

  KingdomTile? tileAt(int x, int y) => tiles['${x}_$y'];

  KingdomBoard withTile(KingdomTile updated) {
    final newTiles = Map<String, KingdomTile>.from(tiles)..[updated.id] = updated;
    // Score = base production plus adjacency synergies. Each neighbouring
    // pair is counted once (east and south neighbours only).
    var currentGold = 0;
    for (final tile in newTiles.values) {
      currentGold += tile.buildingType.baseGold;
    }
    for (final tile in newTiles.values) {
      final east = newTiles['${tile.x + 1}_${tile.y}'];
      final south = newTiles['${tile.x}_${tile.y + 1}'];
      if (east != null) {
        currentGold += _adjacencyBonus(tile.buildingType, east.buildingType);
      }
      if (south != null) {
        currentGold += _adjacencyBonus(tile.buildingType, south.buildingType);
      }
    }

    return KingdomBoard(
      width: width,
      height: height,
      tiles: newTiles,
      gold: currentGold,
      targetGold: targetGold,
      isSolved: currentGold >= targetGold,
    );
  }

  /// Synergy between two orthogonally adjacent buildings.
  static int _adjacencyBonus(BuildingType a, BuildingType b) {
    if (a == BuildingType.empty || b == BuildingType.empty) return 0;

    bool pair(BuildingType x, BuildingType y) =>
        (a == x && b == y) || (a == y && b == x);

    if (pair(BuildingType.farm, BuildingType.mill)) return 25;
    if (pair(BuildingType.house, BuildingType.market)) return 15;
    if (pair(BuildingType.farm, BuildingType.market)) return 10;
    if (pair(BuildingType.mill, BuildingType.market)) return 10;
    if (pair(BuildingType.castle, BuildingType.wall)) return 20;
    return 0;
  }
}
