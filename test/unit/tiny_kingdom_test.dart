import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/features/tiny_kingdom/domain/kingdom_board.dart';
import 'package:mindverse/features/tiny_kingdom/domain/kingdom_tile.dart';
import 'package:mindverse/features/tiny_kingdom/domain/tiny_kingdom_level_factory.dart';

KingdomBoard place(KingdomBoard board, int x, int y, BuildingType type) {
  return board.withTile(board.tileAt(x, y)!.copyWith(buildingType: type));
}

void main() {
  group('Tiny Kingdom Domain & Factory', () {
    test('Builds all 10 Tiny Kingdom levels successfully', () {
      for (int i = 1; i <= 10; i++) {
        final level = TinyKingdomLevelFactory.build(i);
        expect(level.levelNumber, equals(i));
        expect(level.initialBoard.targetGold, greaterThan(0));
      }
    });

    test('farm next to mill earns an adjacency synergy', () {
      final board = TinyKingdomLevelFactory.build(2).initialBoard;
      final withFarm = place(board, 0, 0, BuildingType.farm);
      final withMill = place(withFarm, 1, 0, BuildingType.mill);

      // 15 + 25 base plus a single 25-point farm/mill synergy.
      expect(withMill.gold, 65);
    });

    test('house next to market earns an adjacency synergy', () {
      final board = TinyKingdomLevelFactory.build(2).initialBoard;
      final withHouse = place(board, 0, 0, BuildingType.house);
      final withMarket = place(withHouse, 1, 0, BuildingType.market);

      // 10 + 40 base plus a single 15-point house/market synergy.
      expect(withMarket.gold, 65);
    });

    test('adjacent pairs are counted once, not twice', () {
      final board = TinyKingdomLevelFactory.build(2).initialBoard;
      final withFarm = place(board, 0, 0, BuildingType.farm);
      final withMill = place(withFarm, 1, 0, BuildingType.mill);

      expect(withMill.gold, 65);
    });

    test('non-synergy neighbours only produce base gold', () {
      var board = TinyKingdomLevelFactory.build(2).initialBoard;
      for (var x = 0; x < 4; x++) {
        board = place(board, x, 0, BuildingType.house);
      }
      // Houses do not synergise with each other.
      expect(board.gold, 40);
    });

    test('level 1 solves exactly after five houses', () {
      final level = TinyKingdomLevelFactory.build(1);
      var board = level.initialBoard;
      for (var i = 0; i < 4; i++) {
        board = place(board, i % 3, i ~/ 3, BuildingType.house);
      }
      expect(board.isSolved, isFalse);
      board = place(board, 1, 1, BuildingType.house);
      expect(board.gold, 50);
      expect(board.isSolved, isTrue);
    });
  });
}
