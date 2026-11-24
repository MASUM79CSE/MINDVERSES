import 'cube_board.dart';
import 'cube_tile.dart';

/// Data class describing a Cube Logic level definition.
class CubeLevel {
  final int levelNumber;
  final String title;
  final int maxMoves;
  final int targetMoves; // For 3-star efficiency
  final CubeBoard initialBoard;

  const CubeLevel({
    required this.levelNumber,
    required this.title,
    required this.maxMoves,
    required this.targetMoves,
    required this.initialBoard,
  });
}

/// Factory that constructs all 20 Cube Logic level definitions.
class CubeLevelFactory {
  CubeLevelFactory._();

  static CubeLevel build(int levelNumber) {
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
      case 11: return _level11();
      case 12: return _level12();
      case 13: return _level13();
      case 14: return _level14();
      case 15: return _level15();
      case 16: return _level16();
      case 17: return _level17();
      case 18: return _level18();
      case 19: return _level19();
      case 20: return _level20();
      default: return _level1();
    }
  }

  static Map<String, CubeTile> _tiles(List<CubeTile> list) =>
      {for (final t in list) t.id: t};

  // ─────────────────────────── LEVEL 1 ───────────────────────────
  // 2x2x1 · 1 Source / 1 Terminal · Straight, Corner · Max 6 / Target 3
  static CubeLevel _level1() {
    final tiles = _tiles([
      const CubeTile(x: 0, y: 0, z: 0, type: ConduitType.source),
      const CubeTile(x: 1, y: 0, z: 0, type: ConduitType.corner, rotation: 1),
      const CubeTile(x: 0, y: 1, z: 0, type: ConduitType.straight),
      const CubeTile(x: 1, y: 1, z: 0, type: ConduitType.terminal),
    ]);
    return CubeLevel(
      levelNumber: 1,
      title: 'First Circuit',
      maxMoves: 6,
      targetMoves: 3,
      initialBoard: CubeBoard(width: 2, height: 2, depth: 1, tiles: tiles).withPropagatedPower(),
    );
  }

  // ─────────────────────────── LEVEL 2 ───────────────────────────
  // 2x2x1 · 1 Source / 1 Terminal · Corners only · Max 8 / Target 4
  static CubeLevel _level2() {
    final tiles = _tiles([
      const CubeTile(x: 0, y: 0, z: 0, type: ConduitType.source),
      const CubeTile(x: 1, y: 0, z: 0, type: ConduitType.corner, rotation: 2),
      const CubeTile(x: 0, y: 1, z: 0, type: ConduitType.corner, rotation: 0),
      const CubeTile(x: 1, y: 1, z: 0, type: ConduitType.terminal),
    ]);
    return CubeLevel(
      levelNumber: 2,
      title: 'Corner Routing',
      maxMoves: 8,
      targetMoves: 4,
      initialBoard: CubeBoard(width: 2, height: 2, depth: 1, tiles: tiles).withPropagatedPower(),
    );
  }

  // ─────────────────────────── LEVEL 3 ───────────────────────────
  // 2x2x2 · 1 Source / 1 Terminal · Straight, Corner, 1 Locked · Max 10 / Target 6
  static CubeLevel _level3() {
    final tiles = _tiles([
      const CubeTile(x: 0, y: 0, z: 0, type: ConduitType.source),
      const CubeTile(x: 1, y: 0, z: 0, type: ConduitType.corner, rotation: 1),
      const CubeTile(x: 0, y: 1, z: 0, type: ConduitType.straight, rotation: 1),
      const CubeTile(x: 1, y: 1, z: 0, type: ConduitType.corner, rotation: 2, isLocked: true),
      const CubeTile(x: 0, y: 0, z: 1, type: ConduitType.straight),
      const CubeTile(x: 1, y: 0, z: 1, type: ConduitType.corner),
      const CubeTile(x: 0, y: 1, z: 1, type: ConduitType.corner, rotation: 3),
      const CubeTile(x: 1, y: 1, z: 1, type: ConduitType.terminal),
    ]);
    return CubeLevel(
      levelNumber: 3,
      title: 'Depth Dive',
      maxMoves: 10,
      targetMoves: 6,
      initialBoard: CubeBoard(width: 2, height: 2, depth: 2, tiles: tiles).withPropagatedPower(),
    );
  }

  // ─────────────────────────── LEVEL 4 ───────────────────────────
  // 2x2x2 · 1 Source / 2 Terminals · Split paths · Max 12 / Target 7
  static CubeLevel _level4() {
    final tiles = _tiles([
      const CubeTile(x: 0, y: 0, z: 0, type: ConduitType.source),
      const CubeTile(x: 1, y: 0, z: 0, type: ConduitType.straight, rotation: 1),
      const CubeTile(x: 0, y: 1, z: 0, type: ConduitType.corner, rotation: 0),
      const CubeTile(x: 1, y: 1, z: 0, type: ConduitType.terminal),
      const CubeTile(x: 0, y: 0, z: 1, type: ConduitType.corner, rotation: 2),
      const CubeTile(x: 1, y: 0, z: 1, type: ConduitType.straight),
      const CubeTile(x: 0, y: 1, z: 1, type: ConduitType.straight),
      const CubeTile(x: 1, y: 1, z: 1, type: ConduitType.terminal),
    ]);
    return CubeLevel(
      levelNumber: 4,
      title: 'Split Stream',
      maxMoves: 12,
      targetMoves: 7,
      initialBoard: CubeBoard(width: 2, height: 2, depth: 2, tiles: tiles).withPropagatedPower(),
    );
  }

  // ─────────────────────────── LEVEL 5 ───────────────────────────
  // 3x3x1 · 1 Source / 1 Terminal · Cross conduits · Max 12 / Target 8
  static CubeLevel _level5() {
    final tiles = _tiles([
      const CubeTile(x: 0, y: 0, z: 0, type: ConduitType.source),
      const CubeTile(x: 1, y: 0, z: 0, type: ConduitType.straight, rotation: 1),
      const CubeTile(x: 2, y: 0, z: 0, type: ConduitType.corner, rotation: 1),
      const CubeTile(x: 0, y: 1, z: 0, type: ConduitType.corner, rotation: 3),
      const CubeTile(x: 1, y: 1, z: 0, type: ConduitType.cross),
      const CubeTile(x: 2, y: 1, z: 0, type: ConduitType.straight),
      const CubeTile(x: 0, y: 2, z: 0, type: ConduitType.corner, rotation: 0),
      const CubeTile(x: 1, y: 2, z: 0, type: ConduitType.straight, rotation: 1),
      const CubeTile(x: 2, y: 2, z: 0, type: ConduitType.terminal),
    ]);
    return CubeLevel(
      levelNumber: 5,
      title: 'Crossroads',
      maxMoves: 12,
      targetMoves: 8,
      initialBoard: CubeBoard(width: 3, height: 3, depth: 1, tiles: tiles).withPropagatedPower(),
    );
  }

  // ─────────────────────────── LEVEL 6 ───────────────────────────
  // 3x3x1 · 1 Source / 2 Terminals · T-Junctions · Max 14 / Target 9
  static CubeLevel _level6() {
    final tiles = _tiles([
      const CubeTile(x: 0, y: 1, z: 0, type: ConduitType.source),
      const CubeTile(x: 1, y: 1, z: 0, type: ConduitType.tJunction, rotation: 1),
      const CubeTile(x: 2, y: 1, z: 0, type: ConduitType.corner, rotation: 1),
      const CubeTile(x: 0, y: 0, z: 0, type: ConduitType.empty),
      const CubeTile(x: 1, y: 0, z: 0, type: ConduitType.straight),
      const CubeTile(x: 2, y: 0, z: 0, type: ConduitType.terminal),
      const CubeTile(x: 0, y: 2, z: 0, type: ConduitType.empty),
      const CubeTile(x: 1, y: 2, z: 0, type: ConduitType.straight),
      const CubeTile(x: 2, y: 2, z: 0, type: ConduitType.terminal),
    ]);
    return CubeLevel(
      levelNumber: 6,
      title: 'Junction Jive',
      maxMoves: 14,
      targetMoves: 9,
      initialBoard: CubeBoard(width: 3, height: 3, depth: 1, tiles: tiles).withPropagatedPower(),
    );
  }

  // ─────────────────────────── LEVEL 7 ───────────────────────────
  // 3x3x2 · 1 Source / 2 Terminals · 2 Locked blocks · Max 16 / Target 10
  static CubeLevel _level7() {
    final layer0 = [
      const CubeTile(x: 0, y: 0, z: 0, type: ConduitType.source),
      const CubeTile(x: 1, y: 0, z: 0, type: ConduitType.straight, rotation: 1),
      const CubeTile(x: 2, y: 0, z: 0, type: ConduitType.corner, rotation: 1, isLocked: true),
      const CubeTile(x: 0, y: 1, z: 0, type: ConduitType.corner, rotation: 3),
      const CubeTile(x: 1, y: 1, z: 0, type: ConduitType.cross),
      const CubeTile(x: 2, y: 1, z: 0, type: ConduitType.straight),
      const CubeTile(x: 0, y: 2, z: 0, type: ConduitType.corner, rotation: 0, isLocked: true),
      const CubeTile(x: 1, y: 2, z: 0, type: ConduitType.straight, rotation: 1),
      const CubeTile(x: 2, y: 2, z: 0, type: ConduitType.terminal),
    ];
    final layer1 = [
      const CubeTile(x: 0, y: 0, z: 1, type: ConduitType.corner, rotation: 2),
      const CubeTile(x: 1, y: 0, z: 1, type: ConduitType.straight, rotation: 1),
      const CubeTile(x: 2, y: 0, z: 1, type: ConduitType.corner, rotation: 1),
      const CubeTile(x: 0, y: 1, z: 1, type: ConduitType.straight),
      const CubeTile(x: 1, y: 1, z: 1, type: ConduitType.corner, rotation: 3),
      const CubeTile(x: 2, y: 1, z: 1, type: ConduitType.straight),
      const CubeTile(x: 0, y: 2, z: 1, type: ConduitType.empty),
      const CubeTile(x: 1, y: 2, z: 1, type: ConduitType.straight, rotation: 1),
      const CubeTile(x: 2, y: 2, z: 1, type: ConduitType.terminal),
    ];
    final tiles = _tiles([...layer0, ...layer1]);
    return CubeLevel(
      levelNumber: 7,
      title: 'Obstacle Field',
      maxMoves: 16,
      targetMoves: 10,
      initialBoard: CubeBoard(width: 3, height: 3, depth: 2, tiles: tiles).withPropagatedPower(),
    );
  }

  // ─────────────────────────── LEVEL 8 ───────────────────────────
  // 3x3x2 · 2 Sources / 2 Terminals · Dual isolated circuits · Max 18 / Target 12
  static CubeLevel _level8() {
    final layer0 = [
      const CubeTile(x: 0, y: 0, z: 0, type: ConduitType.source),
      const CubeTile(x: 1, y: 0, z: 0, type: ConduitType.straight, rotation: 1),
      const CubeTile(x: 2, y: 0, z: 0, type: ConduitType.corner, rotation: 1),
      const CubeTile(x: 0, y: 1, z: 0, type: ConduitType.empty),
      const CubeTile(x: 1, y: 1, z: 0, type: ConduitType.empty),
      const CubeTile(x: 2, y: 1, z: 0, type: ConduitType.straight),
      const CubeTile(x: 0, y: 2, z: 0, type: ConduitType.source),
      const CubeTile(x: 1, y: 2, z: 0, type: ConduitType.straight, rotation: 1),
      const CubeTile(x: 2, y: 2, z: 0, type: ConduitType.corner, rotation: 2),
    ];
    final layer1 = [
      const CubeTile(x: 0, y: 0, z: 1, type: ConduitType.empty),
      const CubeTile(x: 1, y: 0, z: 1, type: ConduitType.corner, rotation: 2),
      const CubeTile(x: 2, y: 0, z: 1, type: ConduitType.terminal),
      const CubeTile(x: 0, y: 1, z: 1, type: ConduitType.empty),
      const CubeTile(x: 1, y: 1, z: 1, type: ConduitType.empty),
      const CubeTile(x: 2, y: 1, z: 1, type: ConduitType.empty),
      const CubeTile(x: 0, y: 2, z: 1, type: ConduitType.empty),
      const CubeTile(x: 1, y: 2, z: 1, type: ConduitType.corner, rotation: 1),
      const CubeTile(x: 2, y: 2, z: 1, type: ConduitType.terminal),
    ];
    final tiles = _tiles([...layer0, ...layer1]);
    return CubeLevel(
      levelNumber: 8,
      title: 'Dual Circuits',
      maxMoves: 18,
      targetMoves: 12,
      initialBoard: CubeBoard(width: 3, height: 3, depth: 2, tiles: tiles).withPropagatedPower(),
    );
  }

  // ─────────────────────────── LEVEL 9 ───────────────────────────
  // 3x3x3 · 1 Source / 1 Terminal · Full 3D orbital pathing · Max 20 / Target 12
  static CubeLevel _level9() {
    final tiles = <CubeTile>[];
    // Top layer source
    tiles.add(const CubeTile(x: 0, y: 0, z: 0, type: ConduitType.source));
    tiles.add(const CubeTile(x: 1, y: 0, z: 0, type: ConduitType.corner, rotation: 1));
    tiles.add(const CubeTile(x: 2, y: 0, z: 0, type: ConduitType.corner, rotation: 1));
    tiles.add(const CubeTile(x: 0, y: 1, z: 0, type: ConduitType.empty));
    tiles.add(const CubeTile(x: 1, y: 1, z: 0, type: ConduitType.empty));
    tiles.add(const CubeTile(x: 2, y: 1, z: 0, type: ConduitType.straight));
    tiles.add(const CubeTile(x: 0, y: 2, z: 0, type: ConduitType.empty));
    tiles.add(const CubeTile(x: 1, y: 2, z: 0, type: ConduitType.empty));
    tiles.add(const CubeTile(x: 2, y: 2, z: 0, type: ConduitType.corner, rotation: 2));
    // Mid layer
    tiles.add(const CubeTile(x: 0, y: 0, z: 1, type: ConduitType.empty));
    tiles.add(const CubeTile(x: 1, y: 0, z: 1, type: ConduitType.empty));
    tiles.add(const CubeTile(x: 2, y: 0, z: 1, type: ConduitType.empty));
    tiles.add(const CubeTile(x: 0, y: 1, z: 1, type: ConduitType.empty));
    tiles.add(const CubeTile(x: 1, y: 1, z: 1, type: ConduitType.cross));
    tiles.add(const CubeTile(x: 2, y: 1, z: 1, type: ConduitType.corner, rotation: 3));
    tiles.add(const CubeTile(x: 0, y: 2, z: 1, type: ConduitType.empty));
    tiles.add(const CubeTile(x: 1, y: 2, z: 1, type: ConduitType.corner, rotation: 2));
    tiles.add(const CubeTile(x: 2, y: 2, z: 1, type: ConduitType.corner, rotation: 2));
    // Bottom layer terminal
    tiles.add(const CubeTile(x: 0, y: 0, z: 2, type: ConduitType.empty));
    tiles.add(const CubeTile(x: 1, y: 0, z: 2, type: ConduitType.empty));
    tiles.add(const CubeTile(x: 2, y: 0, z: 2, type: ConduitType.empty));
    tiles.add(const CubeTile(x: 0, y: 1, z: 2, type: ConduitType.corner, rotation: 0));
    tiles.add(const CubeTile(x: 1, y: 1, z: 2, type: ConduitType.straight, rotation: 1));
    tiles.add(const CubeTile(x: 2, y: 1, z: 2, type: ConduitType.empty));
    tiles.add(const CubeTile(x: 0, y: 2, z: 2, type: ConduitType.corner, rotation: 3));
    tiles.add(const CubeTile(x: 1, y: 2, z: 2, type: ConduitType.straight, rotation: 1));
    tiles.add(const CubeTile(x: 2, y: 2, z: 2, type: ConduitType.terminal));
    return CubeLevel(
      levelNumber: 9,
      title: 'Deep Space',
      maxMoves: 20,
      targetMoves: 12,
      initialBoard: CubeBoard(width: 3, height: 3, depth: 3, tiles: _tiles(tiles)).withPropagatedPower(),
    );
  }

  // ─────────────────────────── LEVELS 10-20 ───────────────────────────
  // For levels 10–20 we build progressively larger boards with the same
  // factory pattern. These are condensed but each has unique topology.

  static CubeLevel _level10() => _buildGeneric(
    levelNumber: 10, title: 'Color Code', w: 3, h: 3, d: 3,
    maxMoves: 22, targetMoves: 14,
    tiles: _generate3x3x3TwoSourcesBoard(EnergyColor.cyan, EnergyColor.amber),
  );

  static CubeLevel _level11() => _buildGeneric(
    levelNumber: 11, title: 'Color Crossover', w: 3, h: 3, d: 3,
    maxMoves: 22, targetMoves: 15,
    tiles: _generate3x3x3TwoSourcesThreeTerminalsBoard(),
  );

  static CubeLevel _level12() => _buildGeneric(
    levelNumber: 12, title: 'Locked Maze', w: 3, h: 3, d: 3,
    maxMoves: 24, targetMoves: 16,
    tiles: _generate3x3x3FourLockedBoard(),
  );

  static CubeLevel _level13() => _buildGeneric(
    levelNumber: 13, title: 'Triple Routing', w: 3, h: 3, d: 3,
    maxMoves: 25, targetMoves: 17,
    tiles: _generate3x3x3ThreeSourcesBoard(),
  );

  static CubeLevel _level14() => _buildGeneric(
    levelNumber: 14, title: 'Flat Matrix', w: 4, h: 4, d: 1,
    maxMoves: 24, targetMoves: 16,
    tiles: _generate4x4x1Board(),
  );

  static CubeLevel _level15() => _buildGeneric(
    levelNumber: 15, title: 'Depth Wrap', w: 4, h: 4, d: 2,
    maxMoves: 26, targetMoves: 18,
    tiles: _generate4x4x2Board(),
  );

  static CubeLevel _level16() => _buildGeneric(
    levelNumber: 16, title: 'High Density', w: 4, h: 4, d: 2,
    maxMoves: 28, targetMoves: 19,
    tiles: _generate4x4x2ThreeSourcesBoard(),
  );

  static CubeLevel _level17() => _buildGeneric(
    levelNumber: 17, title: 'Quad Terminal', w: 3, h: 3, d: 3,
    maxMoves: 28, targetMoves: 20,
    tiles: _generate3x3x3FourTerminalsBoard(),
  );

  static CubeLevel _level18() => _buildGeneric(
    levelNumber: 18, title: 'Obstacle Grid', w: 4, h: 4, d: 3,
    maxMoves: 30, targetMoves: 22,
    tiles: _generate4x4x3Board(),
  );

  static CubeLevel _level19() => _buildGeneric(
    levelNumber: 19, title: '3D Labyrinth', w: 4, h: 4, d: 3,
    maxMoves: 32, targetMoves: 23,
    tiles: _generate4x4x3ComplexBoard(),
  );

  static CubeLevel _level20() => _buildGeneric(
    levelNumber: 20, title: 'Master Circuit', w: 4, h: 4, d: 4,
    maxMoves: 35, targetMoves: 24,
    tiles: _generate4x4x4MasterBoard(),
  );

  static CubeLevel _buildGeneric({
    required int levelNumber,
    required String title,
    required int w, required int h, required int d,
    required int maxMoves, required int targetMoves,
    required List<CubeTile> tiles,
  }) {
    return CubeLevel(
      levelNumber: levelNumber,
      title: title,
      maxMoves: maxMoves,
      targetMoves: targetMoves,
      initialBoard: CubeBoard(
        width: w, height: h, depth: d,
        tiles: _tiles(tiles),
      ).withPropagatedPower(),
    );
  }

  // ─── Board generator helpers ─────────────────────────────────

  /// 3×3×3 board with 2 sources and 2 color-coded terminals.
  static List<CubeTile> _generate3x3x3TwoSourcesBoard(EnergyColor c1, EnergyColor c2) {
    final t = <CubeTile>[];
    for (int z = 0; z < 3; z++) {
      for (int y = 0; y < 3; y++) {
        for (int x = 0; x < 3; x++) {
          final rot = (x + y + z) % 4;
          if (x == 0 && y == 0 && z == 0) {
            t.add(CubeTile(x: x, y: y, z: z, type: ConduitType.source, energyColor: c1));
          } else if (x == 2 && y == 2 && z == 2) {
            t.add(CubeTile(x: x, y: y, z: z, type: ConduitType.terminal, energyColor: c1));
          } else if (x == 0 && y == 2 && z == 0) {
            t.add(CubeTile(x: x, y: y, z: z, type: ConduitType.source, energyColor: c2));
          } else if (x == 2 && y == 0 && z == 2) {
            t.add(CubeTile(x: x, y: y, z: z, type: ConduitType.terminal, energyColor: c2));
          } else {
            final type = (x == 1 && y == 1) ? ConduitType.cross : ConduitType.corner;
            t.add(CubeTile(x: x, y: y, z: z, type: type, rotation: rot));
          }
        }
      }
    }
    return t;
  }

  static List<CubeTile> _generate3x3x3TwoSourcesThreeTerminalsBoard() =>
      _buildFlatBoard3x3x3(sources: 2, terminals: 3, lockedCount: 0);

  static List<CubeTile> _generate3x3x3FourLockedBoard() =>
      _buildFlatBoard3x3x3(sources: 2, terminals: 2, lockedCount: 4);

  static List<CubeTile> _generate3x3x3ThreeSourcesBoard() =>
      _buildFlatBoard3x3x3(sources: 3, terminals: 3, lockedCount: 0);

  static List<CubeTile> _generate3x3x3FourTerminalsBoard() =>
      _buildFlatBoard3x3x3(sources: 2, terminals: 4, lockedCount: 0);

  static List<CubeTile> _buildFlatBoard3x3x3({
    required int sources,
    required int terminals,
    required int lockedCount,
  }) {
    final t = <CubeTile>[];
    // Deterministically place sources at corners, terminals at opposite corners
    final srcPositions = [(0,0,0), (2,0,0), (0,2,0)];
    final termPositions = [(2,2,2), (0,2,2), (2,0,2), (0,0,2)];
    final lockPositions = [(1,1,0), (1,0,1), (0,1,1), (2,1,1)];
    final srcSet = srcPositions.take(sources).toSet();
    final termSet = termPositions.take(terminals).toSet();
    final lockSet = lockPositions.take(lockedCount).toSet();
    int idx = 0;
    for (int z = 0; z < 3; z++) {
      for (int y = 0; y < 3; y++) {
        for (int x = 0; x < 3; x++) {
          final pos = (x, y, z);
          final rot = idx % 4;
          if (srcSet.contains(pos)) {
            t.add(CubeTile(x: x, y: y, z: z, type: ConduitType.source));
          } else if (termSet.contains(pos)) {
            t.add(CubeTile(x: x, y: y, z: z, type: ConduitType.terminal));
          } else if (lockSet.contains(pos)) {
            t.add(CubeTile(x: x, y: y, z: z, type: ConduitType.corner, rotation: rot, isLocked: true));
          } else {
            final type = (x == 1 && y == 1 && z == 1) ? ConduitType.cross :
                         (z % 2 == 0) ? ConduitType.corner : ConduitType.straight;
            t.add(CubeTile(x: x, y: y, z: z, type: type, rotation: rot));
          }
          idx++;
        }
      }
    }
    return t;
  }

  static List<CubeTile> _generate4x4x1Board() {
    final t = <CubeTile>[];
    for (int y = 0; y < 4; y++) {
      for (int x = 0; x < 4; x++) {
        final rot = (x * 2 + y) % 4;
        if ((x == 0 && y == 0) || (x == 2 && y == 0)) {
          t.add(CubeTile(x: x, y: y, z: 0, type: ConduitType.source));
        } else if ((x == 3 && y == 3) || (x == 1 && y == 3)) {
          t.add(CubeTile(x: x, y: y, z: 0, type: ConduitType.terminal));
        } else {
          final type = (x == 1 && y == 1) || (x == 2 && y == 2)
              ? ConduitType.cross : ConduitType.corner;
          t.add(CubeTile(x: x, y: y, z: 0, type: type, rotation: rot));
        }
      }
    }
    return t;
  }

  static List<CubeTile> _generate4x4x2Board() {
    final t = <CubeTile>[];
    for (int z = 0; z < 2; z++) {
      for (int y = 0; y < 4; y++) {
        for (int x = 0; x < 4; x++) {
          final rot = (x + y + z * 2) % 4;
          if (x == 0 && y == 0 && z == 0) {
            t.add(CubeTile(x: x, y: y, z: z, type: ConduitType.source));
          } else if (x == 2 && y == 0 && z == 0) {
            t.add(CubeTile(x: x, y: y, z: z, type: ConduitType.source));
          } else if (x == 3 && y == 3 && z == 1) {
            t.add(CubeTile(x: x, y: y, z: z, type: ConduitType.terminal));
          } else if (x == 1 && y == 3 && z == 1) {
            t.add(CubeTile(x: x, y: y, z: z, type: ConduitType.terminal));
          } else if (x == 3 && y == 0 && z == 1) {
            t.add(CubeTile(x: x, y: y, z: z, type: ConduitType.terminal));
          } else {
            final type = (x % 2 == 1 && y % 2 == 1) ? ConduitType.cross : ConduitType.corner;
            t.add(CubeTile(x: x, y: y, z: z, type: type, rotation: rot));
          }
        }
      }
    }
    return t;
  }

  static List<CubeTile> _generate4x4x2ThreeSourcesBoard() {
    final t = <CubeTile>[];
    final srcPos = {(0,0,0), (3,0,0), (0,3,0)};
    final termPos = {(3,3,1), (0,3,1), (3,0,1)};
    for (int z = 0; z < 2; z++) {
      for (int y = 0; y < 4; y++) {
        for (int x = 0; x < 4; x++) {
          final pos = (x, y, z);
          final rot = (x + y * 2 + z) % 4;
          if (srcPos.contains(pos)) {
            t.add(CubeTile(x: x, y: y, z: z, type: ConduitType.source));
          } else if (termPos.contains(pos)) {
            t.add(CubeTile(x: x, y: y, z: z, type: ConduitType.terminal));
          } else {
            final type = (x == 1 || x == 2) && (y == 1 || y == 2) ? ConduitType.cross : ConduitType.corner;
            t.add(CubeTile(x: x, y: y, z: z, type: type, rotation: rot));
          }
        }
      }
    }
    return t;
  }

  static List<CubeTile> _generate4x4x3Board() {
    final t = <CubeTile>[];
    final srcPos = {(0,0,0), (3,0,0), (0,3,0)};
    final termPos = {(3,3,2), (0,3,2), (3,0,2), (1,1,2)};
    final lockPos = {(1,1,0), (2,2,0), (1,2,1), (2,1,1), (0,2,0), (3,1,0)};
    for (int z = 0; z < 3; z++) {
      for (int y = 0; y < 4; y++) {
        for (int x = 0; x < 4; x++) {
          final pos = (x, y, z);
          final rot = (x * 3 + y + z * 2) % 4;
          if (srcPos.contains(pos)) {
            t.add(CubeTile(x: x, y: y, z: z, type: ConduitType.source));
          } else if (termPos.contains(pos)) {
            t.add(CubeTile(x: x, y: y, z: z, type: ConduitType.terminal));
          } else if (lockPos.contains(pos)) {
            t.add(CubeTile(x: x, y: y, z: z, type: ConduitType.corner, rotation: rot, isLocked: true));
          } else {
            final type = (x + y) % 3 == 0 ? ConduitType.cross : ConduitType.corner;
            t.add(CubeTile(x: x, y: y, z: z, type: type, rotation: rot));
          }
        }
      }
    }
    return t;
  }

  static List<CubeTile> _generate4x4x3ComplexBoard() {
    final t = <CubeTile>[];
    final srcPos = {(0,0,0), (3,0,0), (0,3,0)};
    final termPos = {(3,3,2), (0,3,2), (3,0,2), (1,1,2)};
    for (int z = 0; z < 3; z++) {
      for (int y = 0; y < 4; y++) {
        for (int x = 0; x < 4; x++) {
          final pos = (x, y, z);
          final rot = (x + y * 3 + z) % 4;
          if (srcPos.contains(pos)) {
            t.add(CubeTile(x: x, y: y, z: z, type: ConduitType.source));
          } else if (termPos.contains(pos)) {
            t.add(CubeTile(x: x, y: y, z: z, type: ConduitType.terminal));
          } else {
            final isLock = (x == 1 && y == 2 && z == 0) || (x == 2 && y == 1 && z == 2);
            final type = isLock ? ConduitType.corner :
                         (z == 1 && x == 1 && y == 1) ? ConduitType.tJunction :
                         (x % 2 == 0 && y % 2 == 0) ? ConduitType.cross : ConduitType.corner;
            t.add(CubeTile(x: x, y: y, z: z, type: type, rotation: rot, isLocked: isLock));
          }
        }
      }
    }
    return t;
  }

  static List<CubeTile> _generate4x4x4MasterBoard() {
    final t = <CubeTile>[];
    final srcPos = {(0,0,0), (3,0,0), (0,3,0), (3,3,0)};
    final termPos = {(0,0,3), (3,0,3), (0,3,3), (3,3,3)};
    for (int z = 0; z < 4; z++) {
      for (int y = 0; y < 4; y++) {
        for (int x = 0; x < 4; x++) {
          final pos = (x, y, z);
          final rot = (x + y + z) % 4;
          if (srcPos.contains(pos)) {
            t.add(CubeTile(x: x, y: y, z: z, type: ConduitType.source));
          } else if (termPos.contains(pos)) {
            t.add(CubeTile(x: x, y: y, z: z, type: ConduitType.terminal));
          } else {
            final isLock = (z == 1 || z == 2) && x == 1 && y == 1;
            final type = isLock ? ConduitType.corner :
                         (x == 1 && y == 2 && z == 1) ? ConduitType.cross :
                         (x + y + z) % 3 == 0 ? ConduitType.tJunction : ConduitType.corner;
            t.add(CubeTile(x: x, y: y, z: z, type: type, rotation: rot, isLocked: isLock));
          }
        }
      }
    }
    return t;
  }
}
