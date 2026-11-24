import 'package:flutter/foundation.dart';

@immutable
class PerspectiveShape {
  final String id;
  final double angleX;
  final double angleY;
  final double targetAngleX;
  final double targetAngleY;

  const PerspectiveShape({
    required this.id,
    required this.angleX,
    required this.angleY,
    required this.targetAngleX,
    required this.targetAngleY,
  });

  bool get isAligned {
    final diffX = (angleX - targetAngleX).abs() % (2 * 3.14159);
    final diffY = (angleY - targetAngleY).abs() % (2 * 3.14159);
    return diffX < 0.15 && diffY < 0.15;
  }

  PerspectiveShape copyWith({
    String? id,
    double? angleX,
    double? angleY,
    double? targetAngleX,
    double? targetAngleY,
  }) {
    return PerspectiveShape(
      id: id ?? this.id,
      angleX: angleX ?? this.angleX,
      angleY: angleY ?? this.angleY,
      targetAngleX: targetAngleX ?? this.targetAngleX,
      targetAngleY: targetAngleY ?? this.targetAngleY,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerspectiveShape && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
