import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/cube_board.dart';
import 'cube_board_painter.dart';

/// Gesture-controlled viewport widget providing 3D orbit rotation and tile tap selection.
class Cube3DViewport extends StatefulWidget {
  final CubeBoard board;
  final (int x, int y, int z)? hintTile;
  final void Function(int x, int y, int z) onTileTapped;

  const Cube3DViewport({
    super.key,
    required this.board,
    required this.onTileTapped,
    this.hintTile,
  });

  @override
  State<Cube3DViewport> createState() => _Cube3DViewportState();
}

class _Cube3DViewportState extends State<Cube3DViewport> {
  double _angleX = 0.25; // default tilt
  double _angleY = 0.35; // default orbit angle

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _angleY += details.delta.dx * 0.008;
              _angleX += details.delta.dy * 0.008;
              _angleX = _angleX.clamp(-math.pi / 3, math.pi / 3);
            });
          },
          onTapUp: (details) {
            final tappedTile = _hitTestTile(details.localPosition, size);
            if (tappedTile != null) {
              widget.onTileTapped(tappedTile.$1, tappedTile.$2, tappedTile.$3);
            }
          },
          child: CustomPaint(
            size: size,
            painter: CubeBoardPainter(
              board: widget.board,
              angleX: _angleX,
              angleY: _angleY,
              hintTile: widget.hintTile,
            ),
          ),
        );
      },
    );
  }

  (int x, int y, int z)? _hitTestTile(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final tileSize = size.width / (math.max(widget.board.width, widget.board.height) * 2.8);

    (int x, int y, int z)? closestTile;
    double minDistance = double.infinity;

    for (final tile in widget.board.tiles.values) {
      final pos = _projectPoint(tile.x, tile.y, tile.z, center, tileSize);
      final distance = (localPosition - pos).distance;

      if (distance < tileSize * 0.75 && distance < minDistance) {
        minDistance = distance;
        closestTile = (tile.x, tile.y, tile.z);
      }
    }

    return closestTile;
  }

  Offset _projectPoint(int x, int y, int z, Offset center, double tileSize) {
    final cx = x - (widget.board.width - 1) / 2.0;
    final cy = y - (widget.board.height - 1) / 2.0;
    final cz = z - (widget.board.depth - 1) / 2.0;

    final cosY = math.cos(_angleY);
    final sinY = math.sin(_angleY);
    final cosX = math.cos(_angleX);
    final sinX = math.sin(_angleX);

    final rx = cx * cosY + cz * sinY;
    final ry = cy * cosX - (-cx * sinY + cz * cosY) * sinX;

    final px = center.dx + rx * tileSize * 1.5;
    final py = center.dy + ry * tileSize * 1.5;

    return Offset(px, py);
  }
}
