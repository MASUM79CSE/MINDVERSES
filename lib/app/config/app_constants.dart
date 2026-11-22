/// System-wide constants for the MINDVERSE application.
class AppConstants {
  AppConstants._();

  static const String appName = 'MINDVERSE';
  static const String appTagline = 'Think. Solve. Explore.';
  static const String appVersion = '1.0.0';

  // Game IDs
  static const String gameCubeLogic = 'cube_logic';
  static const String gameBridgeMaster = 'bridge_master';
  static const String gameMazeArchitect = 'maze_architect';
  static const String gamePatternMatrix = 'pattern_matrix';
  static const String gameGravityOrb = 'gravity_orb';
  static const String gameQuantumLock = 'quantum_lock';
  static const String gameChronoShift = 'chrono_shift';
  static const String gameGearTheory = 'gear_theory';
  static const String gameTinyKingdom = 'tiny_kingdom';
  static const String gamePerspective = 'perspective';
  static const String gameMemoryMatrix = 'memory_matrix';

  // Economy defaults
  static const int startingCoins = 100;
  static const int baseHintCost = 30;
  static const int fullSolutionHintCost = 100;

  // Level progression
  static const int cubeLogicTotalLevels = 20;
  static const int bridgeMasterTotalLevels = 15;
  static const int mazeArchitectTotalLevels = 15;
  static const int totalMvpLevels = 50;

  // Storage
  static const int currentSchemaVersion = 1;
}
