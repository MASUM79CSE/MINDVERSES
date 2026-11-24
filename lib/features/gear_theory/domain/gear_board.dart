import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'gear.dart';

@immutable
class GearPeg {
  final String id;
  final double x;
  final double y;

  const GearPeg({required this.id, required this.x, required this.y});
}

@immutable
class GearBoard {
  final double width;
  final double height;
  final Map<String, Gear> gears;
  final List<Gear> inventory;
  final List<GearPeg> pegs;
  final bool isSolved;

  const GearBoard({
    required this.width,
    required this.height,
    required this.gears,
    required this.inventory,
    this.pegs = const [],
    this.isSolved = false,
  });

  static double radius(Gear gear) => gear.teeth / 8.0;
  static const double meshTolerance = 0.000001;

  Gear? gearAt(GearPeg peg) {
    for (final gear in gears.values) {
      if ((gear.x - peg.x).abs() < meshTolerance && (gear.y - peg.y).abs() < meshTolerance) {
        return gear;
      }
    }
    return null;
  }

  GearBoard placeGear(String gearId, String pegId) {
    final candidates = inventory.where((gear) => gear.id == gearId);
    final matchingPegs = pegs.where((peg) => peg.id == pegId);
    if (candidates.isEmpty || matchingPegs.isEmpty || gears.containsKey(gearId)) return this;
    final gear = candidates.first;
    if (gear.teeth <= 0) return this;
    final peg = matchingPegs.first;
    final r = radius(gear);
    if (gearAt(peg) != null || peg.x - r < 0 || peg.x + r > width || peg.y - r < 0 || peg.y + r > height) {
      return this;
    }
    for (final other in gears.values) {
      final distance = math.sqrt(math.pow(peg.x - other.x, 2) + math.pow(peg.y - other.y, 2));
      if (distance + meshTolerance < r + radius(other)) return this;
    }
    return GearBoard(
      width: width,
      height: height,
      gears: {
        ...gears,
        gear.id: gear.copyWith(x: peg.x, y: peg.y, rotation: 0),
      },
      inventory: inventory.where((item) => item.id != gearId).toList(),
      pegs: pegs,
    );
  }

  GearBoard removeGear(String pegId) {
    final matchingPegs = pegs.where((peg) => peg.id == pegId);
    if (matchingPegs.isEmpty) return this;
    final gear = gearAt(matchingPegs.first);
    if (gear == null || gear.isFixed || gear.isDriver || gear.isTarget) return this;
    return GearBoard(
      width: width,
      height: height,
      gears: Map<String, Gear>.from(gears)..remove(gear.id),
      inventory: [...inventory, gear.copyWith(x: 0, y: 0, rotation: 0)],
      pegs: pegs,
    );
  }

  GearBoard withGear(Gear updated) {
    final newGears = Map<String, Gear>.from(gears)..[updated.id] = updated;
    return GearBoard(
      width: width,
      height: height,
      gears: newGears,
      inventory: inventory,
      pegs: pegs,
      isSolved: isSolved,
    );
  }

  GearBoard withInventory(List<Gear> newInv) {
    return GearBoard(
      width: width,
      height: height,
      gears: gears,
      inventory: newInv,
      pegs: pegs,
      isSolved: isSolved,
    );
  }

  GearBoard withSolved(bool solved) {
    return GearBoard(
      width: width,
      height: height,
      gears: gears,
      inventory: inventory,
      pegs: pegs,
      isSolved: solved,
    );
  }
}
