/// Route path string constants for GoRouter.
class RoutePaths {
  RoutePaths._();

  static const String splash = '/';
  static const String hub = '/hub';
  static const String gameDetail = '/game/:gameId';
  static const String levelSelect = '/game/:gameId/levels';
  static const String gameplay = '/game/:gameId/play/:levelNumber';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String achievements = '/achievements';
  static const String dailyChallenge = '/daily-challenge';

  // Helper route generators
  static String gameDetailPath(String gameId) => '/game/$gameId';
  static String levelSelectPath(String gameId) => '/game/$gameId/levels';
  static String gameplayPath(String gameId, int levelNumber) => '/game/$gameId/play/$levelNumber';
}
