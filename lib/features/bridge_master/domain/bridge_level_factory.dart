import 'bridge_joint.dart';
import 'bridge_member.dart';

class BridgeLevel {
  final int levelNumber;
  final String title;
  final int budget;
  final int targetBudget;
  final double gapWidth;
  final double vehicleWeight;
  final Map<String, BridgeJoint> anchors;
  final List<BridgeMaterialType> allowedMaterials;

  const BridgeLevel({
    required this.levelNumber,
    required this.title,
    required this.budget,
    required this.targetBudget,
    required this.gapWidth,
    required this.vehicleWeight,
    required this.anchors,
    required this.allowedMaterials,
  });
}

/// Factory constructing all 15 Bridge Master level definitions.
///
/// Values follow the approved GDD progression table (gap, vehicle weight,
/// materials, max budget, and star-2 budget target).
class BridgeLevelFactory {
  BridgeLevelFactory._();

  static BridgeLevel build(int levelNumber) {
    switch (levelNumber) {
      case 1:
        return _build(
          1,
          'First Span',
          6.0,
          800.0,
          [BridgeMaterialType.roadDeck, BridgeMaterialType.woodBeam],
          1500,
          1100,
        );
      case 2:
        return _build(
          2,
          'River Crossing',
          8.0,
          800.0,
          [BridgeMaterialType.roadDeck, BridgeMaterialType.woodBeam],
          2000,
          1450,
        );
      case 3:
        return _build(
          3,
          'Wide Ravine',
          10.0,
          1800.0,
          [BridgeMaterialType.roadDeck, BridgeMaterialType.woodBeam],
          2800,
          2100,
        );
      case 4:
        return _build(
          4,
          'Steep Gorge',
          12.0,
          1800.0,
          [
            BridgeMaterialType.roadDeck,
            BridgeMaterialType.woodBeam,
            BridgeMaterialType.steelCable,
          ],
          3500,
          2600,
        );
      case 5:
        return _build(
          5,
          'Central Pier',
          10.0,
          1800.0,
          [
            BridgeMaterialType.roadDeck,
            BridgeMaterialType.woodBeam,
            BridgeMaterialType.steelCable,
          ],
          3200,
          2400,
        );
      case 6:
        return _build(
          6,
          'Heavy Haul',
          14.0,
          4200.0,
          [
            BridgeMaterialType.roadDeck,
            BridgeMaterialType.woodBeam,
            BridgeMaterialType.steelTruss,
          ],
          4500,
          3400,
        );
      case 7:
        return _build(
          7,
          'Suspension Test',
          16.0,
          4200.0,
          BridgeMaterialType.values,
          5500,
          4100,
        );
      case 8:
        return _build(
          8,
          'Inclined Valley',
          12.0,
          1800.0,
          [
            BridgeMaterialType.roadDeck,
            BridgeMaterialType.woodBeam,
            BridgeMaterialType.steelTruss,
          ],
          4200,
          3100,
        );
      case 9:
        return _build(
          9,
          'Deep Ravine',
          18.0,
          4200.0,
          BridgeMaterialType.values,
          6500,
          4800,
        );
      case 10:
        return _build(
          10,
          'Double Convoy',
          14.0,
          4200.0,
          [
            BridgeMaterialType.roadDeck,
            BridgeMaterialType.woodBeam,
            BridgeMaterialType.steelTruss,
          ],
          5800,
          4300,
        );
      case 11:
        return _build(
          11,
          'Arch Required',
          20.0,
          4200.0,
          [
            BridgeMaterialType.roadDeck,
            BridgeMaterialType.steelTruss,
            BridgeMaterialType.steelCable,
          ],
          7500,
          5500,
        );
      case 12:
        return _build(
          12,
          'High Wind Shear',
          16.0,
          4200.0,
          BridgeMaterialType.values,
          6800,
          5000,
        );
      case 13:
        return _build(
          13,
          'Twin Chasm',
          22.0,
          4200.0,
          BridgeMaterialType.values,
          8500,
          6200,
        );
      case 14:
        return _build(
          14,
          'Uneven Anchors',
          20.0,
          6000.0,
          [
            BridgeMaterialType.roadDeck,
            BridgeMaterialType.steelTruss,
            BridgeMaterialType.steelCable,
          ],
          8800,
          6500,
        );
      case 15:
        return _build(
          15,
          'Master Viaduct',
          24.0,
          6000.0,
          BridgeMaterialType.values,
          10000,
          7400,
        );
      default:
        return build(1);
    }
  }

  static BridgeLevel _build(
    int num,
    String title,
    double gap,
    double weight,
    List<BridgeMaterialType> materials,
    int budget,
    int targetBudget,
  ) {
    return BridgeLevel(
      levelNumber: num,
      title: title,
      budget: budget,
      targetBudget: targetBudget,
      gapWidth: gap,
      vehicleWeight: weight,
      anchors: {
        'a_left': const BridgeJoint(
          id: 'a_left',
          x: 0,
          y: 5,
          anchorType: AnchorType.leftBank,
        ),
        'a_right': BridgeJoint(
          id: 'a_right',
          x: gap,
          y: 5,
          anchorType: AnchorType.rightBank,
        ),
      },
      allowedMaterials: materials,
    );
  }
}
