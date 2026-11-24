import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'bridge_joint.dart';

enum BridgeMaterialType { roadDeck, woodBeam, steelTruss, steelCable }

extension BridgeMaterialTypeExt on BridgeMaterialType {
  String get displayName => switch (this) {
        BridgeMaterialType.roadDeck => 'Road Deck',
        BridgeMaterialType.woodBeam => 'Wood Beam',
        BridgeMaterialType.steelTruss => 'Steel Truss',
        BridgeMaterialType.steelCable => 'Steel Cable',
      };

  int get costPerMeter => switch (this) {
        BridgeMaterialType.roadDeck => 50,
        BridgeMaterialType.woodBeam => 20,
        BridgeMaterialType.steelTruss => 80,
        BridgeMaterialType.steelCable => 60,
      };

  double get maxTensionKkN => switch (this) {
        BridgeMaterialType.roadDeck => 8000.0,
        BridgeMaterialType.woodBeam => 1200.0,
        BridgeMaterialType.steelTruss => 11000.0,
        BridgeMaterialType.steelCable => 9000.0,
      };

  double get maxCompressionKkN => switch (this) {
        BridgeMaterialType.roadDeck => 8000.0,
        BridgeMaterialType.woodBeam => 900.0,
        BridgeMaterialType.steelTruss => 10000.0,
        BridgeMaterialType.steelCable => 0.0, // Cables cannot carry compression
      };

  double get weightPerMeterKkN => switch (this) {
        BridgeMaterialType.roadDeck => 2.0,
        BridgeMaterialType.woodBeam => 0.5,
        BridgeMaterialType.steelTruss => 1.2,
        BridgeMaterialType.steelCable => 0.3,
      };
}

/// Immutable model representing a structural beam or cable connecting two joints.
@immutable
class BridgeMember {
  final String id;
  final String jointAId;
  final String jointBId;
  final BridgeMaterialType materialType;
  final double stressRatio; // 0.0 (0%) to 1.0+ (100%+)
  final bool isSnapped;

  const BridgeMember({
    required this.id,
    required this.jointAId,
    required this.jointBId,
    required this.materialType,
    this.stressRatio = 0.0,
    this.isSnapped = false,
  });

  bool connects(String jointId) => jointAId == jointId || jointBId == jointId;

  String otherJoint(String jointId) => jointAId == jointId ? jointBId : jointAId;

  double length(Map<String, BridgeJoint> joints) {
    final jA = joints[jointAId];
    final jB = joints[jointBId];
    if (jA == null || jB == null) return 0.0;
    final dx = jB.x - jA.x;
    final dy = jB.y - jA.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  int calculateCost(Map<String, BridgeJoint> joints) {
    final len = length(joints);
    return (len * materialType.costPerMeter).round();
  }

  BridgeMember copyWith({
    String? id,
    String? jointAId,
    String? jointBId,
    BridgeMaterialType? materialType,
    double? stressRatio,
    bool? isSnapped,
  }) {
    return BridgeMember(
      id: id ?? this.id,
      jointAId: jointAId ?? this.jointAId,
      jointBId: jointBId ?? this.jointBId,
      materialType: materialType ?? this.materialType,
      stressRatio: stressRatio ?? this.stressRatio,
      isSnapped: isSnapped ?? this.isSnapped,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BridgeMember &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
