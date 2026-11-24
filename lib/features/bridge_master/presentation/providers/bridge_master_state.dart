import 'package:flutter/foundation.dart';

import '../../domain/bridge_joint.dart';
import '../../domain/bridge_member.dart';

/// Immutable state for a Bridge Master gameplay session.
@immutable
class BridgeMasterState {
  final int levelNumber;
  final String title;
  final int budget;
  final int targetBudget;
  final double gapWidth;
  final double vehicleWeight;
  final Map<String, BridgeJoint> joints;
  final List<BridgeMember> members;
  final BridgeMaterialType selectedMaterial;
  final bool isSimulating;
  final double vehicleX;
  final double peakStressRatio;
  final bool isSolved;
  final bool isFailed;
  final bool isPaused;
  final bool isSavingCompletion;
  final String? completionError;
  final int earnedStars;
  final int earnedXp;
  final int earnedCoins;

  const BridgeMasterState({
    required this.levelNumber,
    required this.title,
    required this.budget,
    required this.targetBudget,
    required this.gapWidth,
    required this.vehicleWeight,
    required this.joints,
    required this.members,
    this.selectedMaterial = BridgeMaterialType.roadDeck,
    this.isSimulating = false,
    this.vehicleX = 0.0,
    this.peakStressRatio = 0.0,
    this.isSolved = false,
    this.isFailed = false,
    this.isPaused = false,
    this.isSavingCompletion = false,
    this.completionError,
    this.earnedStars = 0,
    this.earnedXp = 0,
    this.earnedCoins = 0,
  });

  int get totalCost =>
      members.fold(0, (sum, m) => sum + m.calculateCost(joints));

  int get remainingBudget => budget - totalCost;

  bool get isOverBudget => totalCost > budget;

  bool get isCompleted => isSolved || isFailed;

  bool get isCompletionPending => isSavingCompletion || completionError != null;

  BridgeMasterState copyWith({
    int? levelNumber,
    String? title,
    int? budget,
    int? targetBudget,
    double? gapWidth,
    double? vehicleWeight,
    Map<String, BridgeJoint>? joints,
    List<BridgeMember>? members,
    BridgeMaterialType? selectedMaterial,
    bool? isSimulating,
    double? vehicleX,
    double? peakStressRatio,
    bool? isSolved,
    bool? isFailed,
    bool? isPaused,
    bool? isSavingCompletion,
    String? completionError,
    bool clearCompletionError = false,
    int? earnedStars,
    int? earnedXp,
    int? earnedCoins,
  }) {
    return BridgeMasterState(
      levelNumber: levelNumber ?? this.levelNumber,
      title: title ?? this.title,
      budget: budget ?? this.budget,
      targetBudget: targetBudget ?? this.targetBudget,
      gapWidth: gapWidth ?? this.gapWidth,
      vehicleWeight: vehicleWeight ?? this.vehicleWeight,
      joints: joints ?? this.joints,
      members: members ?? this.members,
      selectedMaterial: selectedMaterial ?? this.selectedMaterial,
      isSimulating: isSimulating ?? this.isSimulating,
      vehicleX: vehicleX ?? this.vehicleX,
      peakStressRatio: peakStressRatio ?? this.peakStressRatio,
      isSolved: isSolved ?? this.isSolved,
      isFailed: isFailed ?? this.isFailed,
      isPaused: isPaused ?? this.isPaused,
      isSavingCompletion: isSavingCompletion ?? this.isSavingCompletion,
      completionError: clearCompletionError
          ? null
          : completionError ?? this.completionError,
      earnedStars: earnedStars ?? this.earnedStars,
      earnedXp: earnedXp ?? this.earnedXp,
      earnedCoins: earnedCoins ?? this.earnedCoins,
    );
  }
}
