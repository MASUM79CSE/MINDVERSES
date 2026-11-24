import 'perspective_board.dart';
import 'perspective_shape.dart';

class PerspectiveLevel {
  final int levelNumber;
  final String title;
  final int maxMoves;
  final int targetMoves;
  final PerspectiveBoard initialBoard;

  const PerspectiveLevel({
    required this.levelNumber,
    required this.title,
    required this.maxMoves,
    required this.targetMoves,
    required this.initialBoard,
  });
}

class PerspectiveLevelFactory {
  PerspectiveLevelFactory._();

  static const int levelCount = 10;

  static PerspectiveLevel build(int levelNumber) {
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

  static PerspectiveLevel _level1() {
    final shapes = {
      's1': const PerspectiveShape(
        id: 's1',
        angleX: 0.5,
        angleY: 1.2,
        targetAngleX: 0.0,
        targetAngleY: 0.0,
      ),
    };
    return PerspectiveLevel(
      levelNumber: 1,
      title: 'First Alignment',
      maxMoves: 15,
      targetMoves: 5,
      initialBoard: PerspectiveBoard(
        shapes: shapes,
        isSolved: false,
      ),
    );
  }

  static PerspectiveLevel _level2() => _buildStandardLevel(2, 'Optical Illusion', 16, 6);
  static PerspectiveLevel _level3() => _buildStandardLevel(3, 'Shadow Match', 18, 7);
  static PerspectiveLevel _level4() => _buildStandardLevel(4, 'Angle Shift', 20, 8);
  static PerspectiveLevel _level5() => _buildStandardLevel(5, 'Dual Projection', 22, 9);
  static PerspectiveLevel _level6() => _buildStandardLevel(6, 'Geometric Twist', 24, 10);
  static PerspectiveLevel _level7() => _buildStandardLevel(7, 'Spatial Mirage', 26, 11);
  static PerspectiveLevel _level8() => _buildStandardLevel(8, 'Prism Alignment', 28, 12);
  static PerspectiveLevel _level9() => _buildStandardLevel(9, 'Dimensional Shift', 30, 13);
  static PerspectiveLevel _level10() => _buildStandardLevel(10, 'Master Perspective', 35, 15);

  static PerspectiveLevel _buildStandardLevel(int num, String title, int maxMoves, int targetMoves) {
    final shapes = {
      's1': const PerspectiveShape(
        id: 's1',
        angleX: 1.5,
        angleY: 2.1,
        targetAngleX: 0.0,
        targetAngleY: 0.0,
      ),
      's2': const PerspectiveShape(
        id: 's2',
        angleX: 0.8,
        angleY: 1.7,
        targetAngleX: 0.0,
        targetAngleY: 0.0,
      ),
    };
    return PerspectiveLevel(
      levelNumber: num,
      title: title,
      maxMoves: maxMoves,
      targetMoves: targetMoves,
      initialBoard: PerspectiveBoard(
        shapes: shapes,
        isSolved: false,
      ),
    );
  }
}
