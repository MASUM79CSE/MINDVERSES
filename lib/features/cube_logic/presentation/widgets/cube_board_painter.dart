import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/cube_board.dart';
import '../../domain/cube_tile.dart';

/// CustomPainter executing isometric simulated 3D rendering for a [CubeBoard].
class CubeBoardPainter extends CustomPainter {
  final CubeBoard board;
  final double angleX;
  final double angleY;
  final (int x, int y, int z)? hintTile;

  CubeBoardPainter({
    required this.board,
    required this.angleX,
    required this.angleY,
    this.hintTile,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final tileSize = size.width / (math.max(board.width, board.height) * 2.8);

    // Sort tiles back-to-front (painter's algorithm) based on projected depth
    final sortedTiles = board.tiles.values.toList()
      ..sort((a, b) {
        final depthA = _projectDepth(a.x, a.y, a.z);
        final depthB = _projectDepth(b.x, b.y, b.z);
        return depthA.compareTo(depthB);
      });

    for (final tile in sortedTiles) {
      _drawTile(canvas, center, tileSize, tile);
    }
  }

  double _projectDepth(int x, int y, int z) {
    final cx = x - (board.width - 1) / 2.0;
    final cy = y - (board.height - 1) / 2.0;
    final cz = z - (board.depth - 1) / 2.0;

    final cosY = math.cos(angleY);
    final sinY = math.sin(angleY);
    final cosX = math.cos(angleX);
    final sinX = math.sin(angleX);

    final rz = cy * sinX + (-cx * sinY + cz * cosY) * cosX;
    return rz;
  }

  Offset _projectPoint(int x, int y, int z, Offset center, double tileSize) {
    final cx = x - (board.width - 1) / 2.0;
    final cy = y - (board.height - 1) / 2.0;
    final cz = z - (board.depth - 1) / 2.0;

    final cosY = math.cos(angleY);
    final sinY = math.sin(angleY);
    final cosX = math.cos(angleX);
    final sinX = math.sin(angleX);

    final rx = cx * cosY + cz * sinY;
    final ry = cy * cosX - (-cx * sinY + cz * cosY) * sinX;

    final px = center.dx + rx * tileSize * 1.5;
    final py = center.dy + ry * tileSize * 1.5;

    return Offset(px, py);
  }

  void _drawTile(Canvas canvas, Offset center, double tileSize, CubeTile tile) {
    final pos = _projectPoint(tile.x, tile.y, tile.z, center, tileSize);
    final isHint = hintTile != null &&
        hintTile!.$1 == tile.x &&
        hintTile!.$2 == tile.y &&
        hintTile!.$3 == tile.z;

    final rect = Rect.fromCenter(center: pos, width: tileSize, height: tileSize);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(tileSize * 0.15));

    // Base card tile background
    final bgPaint = Paint()
      ..color = tile.isLocked
          ? AppColors.surfaceElevated.withValues(alpha: 0.6)
          : AppColors.borderSubtle.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rrect, bgPaint);

    // Border paint
    final borderPaint = Paint()
      ..color = isHint
          ? AppColors.stressWarning
          : (tile.isPowered ? AppColors.secondary : AppColors.borderSubtle)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHint ? 3.0 : 1.5;

    canvas.drawRRect(rrect, borderPaint);

    // Conduit path drawing
    _drawConduits(canvas, pos, tileSize, tile);

    // Source / Terminal indicator overlay
    if (tile.type == ConduitType.source) {
      final sourcePaint = Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, tileSize * 0.22, sourcePaint);
    } else if (tile.type == ConduitType.terminal) {
      final termPaint = Paint()
        ..color = tile.isPowered ? AppColors.energyActive : AppColors.stressCritical
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, tileSize * 0.22, termPaint);
    }
  }

  void _drawConduits(Canvas canvas, Offset center, double tileSize, CubeTile tile) {
    if (tile.connections.isEmpty) return;

    final conduitPaint = Paint()
      ..color = tile.isPowered ? AppColors.secondary : AppColors.energyInactive
      ..style = PaintingStyle.stroke
      ..strokeWidth = tileSize * 0.14
      ..strokeCap = StrokeCap.round;

    final half = tileSize / 2.0;

    for (final dir in tile.connections) {
      Offset end;
      switch (dir) {
        case ConduitDirection.north:
          end = Offset(center.dx, center.dy - half * 0.7);
          break;
        case ConduitDirection.south:
          end = Offset(center.dx, center.dy + half * 0.7);
          break;
        case ConduitDirection.east:
          end = Offset(center.dx + half * 0.7, center.dy);
          break;
        case ConduitDirection.west:
          end = Offset(center.dx - half * 0.7, center.dy);
          break;
      }
      canvas.drawLine(center, end, conduitPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CubeBoardPainter oldDelegate) {
    return oldDelegate.board != board ||
        oldDelegate.angleX != angleX ||
        oldDelegate.angleY != angleY ||
        oldDelegate.hintTile != hintTile;
  }
}
