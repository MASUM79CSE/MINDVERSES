/// Route path string constants for GoRouter.
class RoutePaths {
  RoutePaths._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String hub = '/hub';
  static const String gameDetail = '/game/:gameId';
  static const String levelSelect = '/game/:gameId/levels';
  static const String gameplay = '/game/:gameId/play/:levelNumber';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String achievements = '/achievements';
  static const String dailyChallenge = '/daily-challenge';
  static const String cubeLogic = '/cube-logic/:levelId';
  static const String bridgeMaster = '/bridge-master/:levelId';
  static const String mazeArchitect = '/maze-architect/:levelId';
  static const String gearTheory = '/gear-theory/:levelId';
  static const String tinyKingdom = '/tiny-kingdom/:levelId';
  static const String perspective = '/perspective/:levelId';
  static const String memoryMatrix = '/memory-matrix/:levelId';

  // Helper route generators
  static String gameDetailPath(String gameId) => '/game/$gameId';
  static String levelSelectPath(String gameId) => '/game/$gameId/levels';
  static String gameplayPath(String gameId, int levelNumber) => '/game/$gameId/play/$levelNumber';
  static String cubeLogicLevel(int level) => '/cube-logic/$level';
  static String bridgeMasterLevel(int level) => '/bridge-master/$level';
  static String mazeArchitectLevel(int level) => '/maze-architect/$level';
  static String gearTheoryLevel(int level) => '/gear-theory/$level';
  static String tinyKingdomLevel(int level) => '/tiny-kingdom/$level';
  static String perspectiveLevel(int level) => '/perspective/$level';
  static String memoryMatrixLevel(int level) => '/memory-matrix/$level';
}
