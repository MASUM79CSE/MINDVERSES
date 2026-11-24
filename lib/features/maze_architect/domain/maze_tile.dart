import 'package:flutter/foundation.dart';

enum MazeTileType { wall, path, start, destination, movable }

/// A single cell on the Maze Architect puzzle grid.
@immutable
class MazeTile {
  final int x;
  final int y;
  final MazeTileType type;
  final bool isOpenNorth;
  final bool isOpenSouth;
  final bool isOpenEast;
  final bool isOpenWest;
  final bool isLocked;

  const MazeTile({
    required this.x,
    required this.y,
    required this.type,
    this.isOpenNorth = false,
    this.isOpenSouth = false,
    this.isOpenEast = false,
    this.isOpenWest = false,
    this.isLocked = false,
  });

  String get id => '${x}_$y';

  bool connectsWith(MazeTile? other, String direction) {
    if (other == null) return false;
    switch (direction) {
      case 'north':
        return isOpenNorth && other.isOpenSouth;
      case 'south':
        return isOpenSouth && other.isOpenNorth;
      case 'east':
        return isOpenEast && other.isOpenWest;
      case 'west':
        return isOpenWest && other.isOpenEast;
      default:
        return false;
    }
  }

  MazeTile copyWith({
    int? x,
    int? y,
    MazeTileType? type,
    bool? isOpenNorth,
    bool? isOpenSouth,
    bool? isOpenEast,
    bool? isOpenWest,
    bool? isLocked,
  }) {
    return MazeTile(
      x: x ?? this.x,
      y: y ?? this.y,
      type: type ?? this.type,
      isOpenNorth: isOpenNorth ?? this.isOpenNorth,
      isOpenSouth: isOpenSouth ?? this.isOpenSouth,
      isOpenEast: isOpenEast ?? this.isOpenEast,
      isOpenWest: isOpenWest ?? this.isOpenWest,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MazeTile &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          type == other.type &&
          isOpenNorth == other.isOpenNorth &&
          isOpenSouth == other.isOpenSouth &&
          isOpenEast == other.isOpenEast &&
          isOpenWest == other.isOpenWest &&
          isLocked == other.isLocked;

  @override
  int get hashCode => Object.hash(
    x,
    y,
    type,
    isOpenNorth,
    isOpenSouth,
    isOpenEast,
    isOpenWest,
    isLocked,
  );
}
