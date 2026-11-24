import 'package:flutter/foundation.dart';

enum AnchorType { none, leftBank, rightBank }

/// Immutable model representing a structural joint / vertex on the bridge grid.
@immutable
class BridgeJoint {
  final String id;
  final double x;
  final double y;
  final AnchorType anchorType;

  const BridgeJoint({
    required this.id,
    required this.x,
    required this.y,
    this.anchorType = AnchorType.none,
  });

  bool get isAnchor => anchorType != AnchorType.none;

  BridgeJoint copyWith({
    String? id,
    double? x,
    double? y,
    AnchorType? anchorType,
  }) {
    return BridgeJoint(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      anchorType: anchorType ?? this.anchorType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BridgeJoint &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
