import 'gear.dart';
import 'gear_board.dart';

class GearLevel {
  final int levelNumber;
  final String title;
  final int maxMoves;
  final int targetMoves;
  final GearBoard initialBoard;

  const GearLevel({
    required this.levelNumber,
    required this.title,
    required this.maxMoves,
    required this.targetMoves,
    required this.initialBoard,
  });
}

class GearLevelFactory {
  GearLevelFactory._();

  static const int levelCount = 10;

  static GearLevel build(int levelNumber) {
    switch (levelNumber) {
      case 1:
        return _level1();
      case 2:
        return _level2();
      case 3:
        return _level3();
      case 4:
        return _level4();
      case 5:
        return _level5();
      case 6:
        return _level6();
      case 7:
        return _level7();
      case 8:
        return _level8();
      case 9:
        return _level9();
      case 10:
        return _level10();
      default:
        return _level1();
    }
  }

  static GearLevel _level1() {
    final gears = {
      'g_driver': const Gear(id: 'g_driver', x: 2, y: 5, teeth: 16, isDriver: true, isFixed: true),
      'g_target': const Gear(id: 'g_target', x: 8, y: 5, teeth: 16, isTarget: true, isFixed: true),
    };
    final inventory = [const Gear(id: 'g_mid', x: 0, y: 0, teeth: 8)];
    return GearLevel(
      levelNumber: 1,
      title: 'First Mesh',
      maxMoves: 10,
      targetMoves: 3,
      initialBoard: GearBoard(
        width: 10,
        height: 10,
        gears: gears,
        inventory: inventory,
        pegs: const [
          GearPeg(id: 'bridge', x: 5, y: 5),
          GearPeg(id: 'upper', x: 5, y: 2),
        ],
      ),
    );
  }

  static GearLevel _level2() => _buildStandardLevel(2, 'Dual Gear', 12, 6);
  static GearLevel _level3() => _buildStandardLevel(3, 'Gear Train', 14, 7);
  static GearLevel _level4() => _buildStandardLevel(4, 'Speed Ratio', 15, 8);
  static GearLevel _level5() => _buildStandardLevel(5, 'Power Transmission', 16, 9);
  static GearLevel _level6() => _buildStandardLevel(6, 'Complex Array', 18, 10);
  static GearLevel _level7() => _buildStandardLevel(7, 'Kinetic Network', 20, 11);
  static GearLevel _level8() => _buildStandardLevel(8, 'Clockwork Matrix', 22, 12);
  static GearLevel _level9() => _buildStandardLevel(9, 'Master Mechanism', 25, 13);
  static GearLevel _level10() => _buildStandardLevel(10, 'Perpetual Engine', 30, 15);

  static GearLevel _buildStandardLevel(int num, String title, int maxMoves, int targetMoves) {
    const gears = {
      'g_driver': Gear(id: 'g_driver', x: 2, y: 5, teeth: 16, isDriver: true, isFixed: true),
      'g_target': Gear(id: 'g_target', x: 11, y: 5, teeth: 24, isTarget: true, isFixed: true),
    };
    const inventory = [Gear(id: 'g_inv_1', x: 0, y: 0, teeth: 16), Gear(id: 'g_inv_2', x: 0, y: 0, teeth: 8)];
    return GearLevel(
      levelNumber: num,
      title: title,
      maxMoves: maxMoves,
      targetMoves: targetMoves,
      initialBoard: const GearBoard(
        width: 14,
        height: 10,
        gears: gears,
        inventory: inventory,
        pegs: [
          GearPeg(id: 'bridge', x: 6, y: 5),
          GearPeg(id: 'upper', x: 6, y: 2),
        ],
      ),
    );
  }
}
