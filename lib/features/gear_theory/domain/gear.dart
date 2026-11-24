import 'package:flutter/foundation.dart';

@immutable
class Gear {
  final String id;
  final double x;
  final double y;
  final int teeth;
  final double rotation; // current angle in radians
  final bool isDriver;
  final bool isTarget;
  final bool isFixed; // cannot be moved/removed

  const Gear({
    required this.id,
    required this.x,
    required this.y,
    required this.teeth,
    this.rotation = 0.0,
    this.isDriver = false,
    this.isTarget = false,
    this.isFixed = false,
  });

  Gear copyWith({
    String? id,
    double? x,
    double? y,
    int? teeth,
    double? rotation,
    bool? isDriver,
    bool? isTarget,
    bool? isFixed,
  }) {
    return Gear(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      teeth: teeth ?? this.teeth,
      rotation: rotation ?? this.rotation,
      isDriver: isDriver ?? this.isDriver,
      isTarget: isTarget ?? this.isTarget,
      isFixed: isFixed ?? this.isFixed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Gear && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
