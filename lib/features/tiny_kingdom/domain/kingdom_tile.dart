import 'package:flutter/foundation.dart';

enum BuildingType { empty, house, farm, mill, market, castle, wall }

extension BuildingTypeExt on BuildingType {
  String get displayName => switch (this) {
        BuildingType.empty => 'Empty',
        BuildingType.house => 'House',
        BuildingType.farm => 'Farm',
        BuildingType.mill => 'Mill',
        BuildingType.market => 'Market',
        BuildingType.castle => 'Castle',
        BuildingType.wall => 'Wall',
      };

  int get cost => switch (this) {
        BuildingType.empty => 0,
        BuildingType.house => 10,
        BuildingType.farm => 15,
        BuildingType.mill => 25,
        BuildingType.market => 35,
        BuildingType.castle => 100,
        BuildingType.wall => 5,
      };

  /// Base gold produced before adjacency synergies are applied.
  int get baseGold => switch (this) {
        BuildingType.empty => 0,
        BuildingType.house => 10,
        BuildingType.farm => 15,
        BuildingType.mill => 25,
        BuildingType.market => 40,
        BuildingType.castle => 100,
        BuildingType.wall => 0,
      };
}

@immutable
class KingdomTile {
  final int x;
  final int y;
  final BuildingType buildingType;
  final bool isLocked;

  const KingdomTile({
    required this.x,
    required this.y,
    this.buildingType = BuildingType.empty,
    this.isLocked = false,
  });

  String get id => '${x}_$y';

  KingdomTile copyWith({
    int? x,
    int? y,
    BuildingType? buildingType,
    bool? isLocked,
  }) {
    return KingdomTile(
      x: x ?? this.x,
      y: y ?? this.y,
      buildingType: buildingType ?? this.buildingType,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KingdomTile && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}
