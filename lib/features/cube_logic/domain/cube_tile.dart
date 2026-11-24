import 'package:flutter/foundation.dart';

/// Conduit directions available on a tile face.
enum ConduitDirection { north, east, south, west }

/// Type of conduit tile, defining its internal connection topology.
enum ConduitType {
  /// Connects opposite edges (N-S or E-W).
  straight,
  /// Connects adjacent edges (clockwise pair).
  corner,
  /// Two independent non-intersecting channels.
  cross,
  /// Splits power into three directions.
  tJunction,
  /// No conduit — this is a Power Source emitter.
  source,
  /// No conduit — this is a Terminal receiver node.
  terminal,
  /// Completely blocked; cannot be rotated.
  locked,
  /// Empty passthrough block (no connections).
  empty,
}

/// Energy frequency/color (introduced at Level 10).
enum EnergyColor { white, cyan, amber, emerald }

/// A single cube tile on the board.
@immutable
class CubeTile {
  final int x;
  final int y;
  final int z;
  final ConduitType type;

  /// Current rotation state: 0, 1, 2, or 3 (clockwise 90° increments).
  final int rotation;

  /// Whether this tile can be rotated by the player.
  final bool isLocked;

  /// For source/terminal tiles: the energy color they carry.
  final EnergyColor energyColor;

  /// Whether this terminal is currently receiving energy (computed each solve tick).
  final bool isPowered;

  const CubeTile({
    required this.x,
    required this.y,
    required this.z,
    required this.type,
    this.rotation = 0,
    this.isLocked = false,
    this.energyColor = EnergyColor.white,
    this.isPowered = false,
  });

  String get id => '${x}_${y}_$z';

  /// Returns which directions this tile outputs conduit connections
  /// considering its type and rotation.
  Set<ConduitDirection> get connections {
    switch (type) {
      case ConduitType.source:
        return ConduitDirection.values.toSet();
      case ConduitType.terminal:
      case ConduitType.empty:
      case ConduitType.locked:
        return {};
      case ConduitType.straight:
        return _rotated({ConduitDirection.north, ConduitDirection.south});
      case ConduitType.corner:
        return _rotated({ConduitDirection.north, ConduitDirection.east});
      case ConduitType.cross:
        // Cross always connects all four: rotation does not change topology.
        return {ConduitDirection.north, ConduitDirection.east, ConduitDirection.south, ConduitDirection.west};
      case ConduitType.tJunction:
        return _rotated({ConduitDirection.north, ConduitDirection.east, ConduitDirection.south});
    }
  }

  Set<ConduitDirection> _rotated(Set<ConduitDirection> dirs) {
    const all = ConduitDirection.values;
    return dirs.map((d) {
      final idx = (d.index + rotation) % all.length;
      return all[idx];
    }).toSet();
  }

  CubeTile copyWith({
    int? rotation,
    bool? isPowered,
  }) {
    return CubeTile(
      x: x,
      y: y,
      z: z,
      type: type,
      rotation: rotation ?? this.rotation,
      isLocked: isLocked,
      energyColor: energyColor,
      isPowered: isPowered ?? this.isPowered,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CubeTile && x == other.x && y == other.y && z == other.z;

  @override
  int get hashCode => Object.hash(x, y, z);
}
