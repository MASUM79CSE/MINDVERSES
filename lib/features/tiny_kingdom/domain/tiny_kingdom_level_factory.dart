import 'kingdom_board.dart';
import 'kingdom_tile.dart';

class TinyKingdomLevel {
  final int levelNumber;
  final String title;
  final int maxTurns;
  final int targetTurns;
  final KingdomBoard initialBoard;

  const TinyKingdomLevel({
    required this.levelNumber,
    required this.title,
    required this.maxTurns,
    required this.targetTurns,
    required this.initialBoard,
  });
}

class TinyKingdomLevelFactory {
  TinyKingdomLevelFactory._();

  static const int levelCount = 10;

  static TinyKingdomLevel build(int levelNumber) {
    switch (levelNumber) {
      case 1: return _level1();
      case 2: return _level2();
      case 3: return _level3();
      case 4: return _level4();
      case 5: return _level5();
      case 6: return _level6();
      case 7: return _level7();
      case 8: return _level8();
      case 9: return _level9();
      case 10: return _level10();
      default: return _level1();
    }
  }

  static TinyKingdomLevel _level1() {
    final tiles = <String, KingdomTile>{};
    for (int y = 0; y < 3; y++) {
      for (int x = 0; x < 3; x++) {
        final t = KingdomTile(x: x, y: y);
        tiles[t.id] = t;
      }
    }
    return TinyKingdomLevel(
      levelNumber: 1,
      title: 'Settlement',
      maxTurns: 5,
      targetTurns: 3,
      initialBoard: KingdomBoard(
        width: 3,
        height: 3,
        tiles: tiles,
        gold: 0,
        targetGold: 50,
      ),
    );
  }

  static TinyKingdomLevel _level2() => _buildStandardLevel(2, 'Growing Village', 4, 4, 100, 6);
  static TinyKingdomLevel _level3() => _buildStandardLevel(3, 'Farming Valley', 4, 4, 150, 7);
  static TinyKingdomLevel _level4() => _buildStandardLevel(4, 'Market Town', 5, 5, 250, 8);
  static TinyKingdomLevel _level5() => _buildStandardLevel(5, 'Kingdom Outpost', 5, 5, 350, 9);
  static TinyKingdomLevel _level6() => _buildStandardLevel(6, 'Protected Realm', 5, 5, 450, 10);
  static TinyKingdomLevel _level7() => _buildStandardLevel(7, 'Royal Capital', 6, 6, 600, 11);
  static TinyKingdomLevel _level8() => _buildStandardLevel(8, 'Imperial Empire', 6, 6, 800, 12);
  static TinyKingdomLevel _level9() => _buildStandardLevel(9, 'Crown Dominion', 6, 6, 1000, 13);
  static TinyKingdomLevel _level10() => _buildStandardLevel(10, 'Legendary Dynasty', 6, 6, 1500, 15);

  static TinyKingdomLevel _buildStandardLevel(int num, String title, int w, int h, int targetGold, int maxTurns) {
    final tiles = <String, KingdomTile>{};
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final t = KingdomTile(x: x, y: y);
        tiles[t.id] = t;
      }
    }
    return TinyKingdomLevel(
      levelNumber: num,
      title: title,
      maxTurns: maxTurns,
      targetTurns: (maxTurns * 0.7).round(),
      initialBoard: KingdomBoard(
        width: w,
        height: h,
        tiles: tiles,
        gold: 0,
        targetGold: targetGold,
      ),
    );
  }
}
