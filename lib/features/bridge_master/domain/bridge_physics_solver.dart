import 'dart:math' as math;
import 'bridge_joint.dart';
import 'bridge_member.dart';

class BridgePhysicsResult {
  final List<BridgeMember> members;
  final double peakStressRatio;
  final bool isCollapsed;
  final bool isVehicleSupported;

  const BridgePhysicsResult({
    required this.members,
    required this.peakStressRatio,
    required this.isCollapsed,
    required this.isVehicleSupported,
  });
}

/// Structural 2D truss mechanics solver calculating member axial forces,
/// stress ratios, and dynamic vehicle load propagation across joints.
class BridgePhysicsSolver {
  BridgePhysicsSolver._();

  /// Length of the vehicle footprint used to distribute live load across the
  /// road-deck segments beneath it.
  static const double vehicleFootprint = 2.0;

  /// Solves member forces and stresses at a given vehicle position [vehicleX].
  static BridgePhysicsResult evaluate({
    required Map<String, BridgeJoint> joints,
    required List<BridgeMember> members,
    required double vehicleX,
    required double vehicleWeight,
  }) {
    if (members.isEmpty) {
      return const BridgePhysicsResult(
        members: [],
        peakStressRatio: 1.0,
        isCollapsed: true,
        isVehicleSupported: false,
      );
    }

    final updatedMembers = <BridgeMember>[];
    double maxPeakStress = 0.0;
    bool collapsed = false;

    final roadMembers = members
        .where((m) => m.materialType == BridgeMaterialType.roadDeck)
        .toList();
    if (roadMembers.isEmpty) {
      return BridgePhysicsResult(
        members: members
            .map((m) => m.copyWith(stressRatio: 1.0, isSnapped: true))
            .toList(),
        peakStressRatio: 1.0,
        isCollapsed: true,
        isVehicleSupported: false,
      );
    }

    // Distribute the vehicle's weight across the deck segments its footprint
    // actually covers. Each segment carries a share proportional to the
    // overlap length, so the total live load stays equal to the vehicle weight.
    final footprintStart = vehicleX - vehicleFootprint / 2;
    final footprintEnd = vehicleX + vehicleFootprint / 2;
    final overlapByMember = <String, double>{};
    var totalOverlap = 0.0;
    for (final member in roadMembers) {
      final jA = joints[member.jointAId];
      final jB = joints[member.jointBId];
      if (jA == null || jB == null) continue;
      final minX = math.min(jA.x, jB.x);
      final maxX = math.max(jA.x, jB.x);
      final overlap =
          math.min(maxX, footprintEnd) - math.max(minX, footprintStart);
      if (overlap > 0) {
        overlapByMember[member.id] = overlap;
        totalOverlap += overlap;
      }
    }

    if (totalOverlap <= 0) {
      // The vehicle is not standing on any road deck, so the bridge cannot
      // support it.
      return BridgePhysicsResult(
        members: members
            .map((m) => m.copyWith(stressRatio: 1.0, isSnapped: true))
            .toList(),
        peakStressRatio: 1.0,
        isCollapsed: true,
        isVehicleSupported: false,
      );
    }

    for (final member in members) {
      final jA = joints[member.jointAId];
      final jB = joints[member.jointBId];

      if (jA == null || jB == null) {
        updatedMembers.add(member);
        continue;
      }

      final len = member.length(joints);
      if (len <= 0.001) {
        updatedMembers.add(member);
        continue;
      }

      // Member self-weight load + live load contribution
      final selfWeight = len * member.materialType.weightPerMeterKkN;

      double liveLoad = 0.0;
      final overlap = overlapByMember[member.id];
      if (overlap != null) {
        liveLoad = vehicleWeight * (overlap / totalOverlap);
      }

      final totalForce = (selfWeight * 0.5) + (liveLoad * 1.2);
      final capacity = member.materialType.maxTensionKkN;
      final stress = (totalForce / capacity).clamp(0.0, 2.0);

      if (stress > maxPeakStress) {
        maxPeakStress = stress;
      }

      final snapped = member.isSnapped || stress > 1.0;
      if (snapped) {
        collapsed = true;
      }

      updatedMembers.add(
        member.copyWith(stressRatio: stress, isSnapped: snapped),
      );
    }

    return BridgePhysicsResult(
      members: updatedMembers,
      peakStressRatio: maxPeakStress,
      isCollapsed: collapsed,
      isVehicleSupported: !collapsed,
    );
  }
}
